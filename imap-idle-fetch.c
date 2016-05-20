/*
 * imap-idle-fetch
 * ---------------
 * 
 * Simple IMAP client that shows how to enable push notifications with IMAP IDLE
 * (RFC 2177). The only dependency is OpenSSL for the TLS encryption (STARTTLS).
 * 
 * Written 2006 by Mario Kicherer (dev@kicherer.org)
 * 
 * License: MIT (see https://opensource.org/licenses/MIT)
 * 
 * Build:
 *
 *   gcc imap-idle-fetch.c -o imap-idle-fetch $(pkg-config --cflags --libs openssl) -g -Wall
 *
 * Usage:
 *
 *   imap-idle-fetch <server-ip> <user> <password> <folder (e.g. inbox)>
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <errno.h>
#include <regex.h>

#include <openssl/bio.h>
#include <openssl/ssl.h>
#include <openssl/err.h>
#include <openssl/pem.h>
#include <openssl/x509.h>
#include <openssl/x509_vfy.h>

struct imap_ctx {
	int sock;
	SSL *ssl;
	char ssl_active;
	
	unsigned int cmd_idx;
	char *line;
	size_t line_size;
	size_t line_strlen;
	
	char idle_active;
	unsigned int n_mails;
};

int send_cmd(struct imap_ctx *ctx, char *cmd, char **response, size_t *response_len);
int read_resp(struct imap_ctx *ctx, char **response, size_t *response_len, char resp_to_cmd);
int readline(struct imap_ctx *ctx);

// parse the response to a FETCH command
int recv_fetch(struct imap_ctx *ctx, int bytes_read, char **response, size_t *response_len) {
	char *pos;
	regex_t preg;
	size_t     nmatch = 3;
	regmatch_t pmatch[3];
	unsigned int bodylen;
	char buf[24];
	char *endptr;
	char *body;
	size_t len;
	
	if (!response)
		return 1;
	
	/*
	 * please note, there are better ways to parse the response, this works as example
	 */
	
	// safety check
	pos = &ctx->line[bytes_read+1];
	if (*pos != '(') {
		printf("parse error\n");
		return 1;
	}
	pos++;
	
	/*
	 * get the length of the data
	 */
	
	regcomp(&preg, "BODY\\[([A-Za-z]+)\\] \\{([0-9]+)\\}", REG_ICASE|REG_EXTENDED);
	regexec(&preg, pos, nmatch, pmatch, 0); 
	regfree(&preg);
	
	// copy length into own string
	if (pmatch[2].rm_eo - pmatch[2].rm_so > 23) {
		printf("parse error bodylen\n");
		return 1;
	}
	strncpy(buf, &pos[pmatch[2].rm_so], pmatch[2].rm_eo - pmatch[2].rm_so);
	buf[pmatch[2].rm_eo - pmatch[2].rm_so] = 0;
	
	// parse number string
	errno = 0;
	bodylen = strtol(buf, &endptr, 10);
	if ((errno == ERANGE && (bodylen == LONG_MAX || bodylen == LONG_MIN))
		|| (errno != 0 && bodylen == 0))
	{
		perror("strtol");
		return 1;
	}
	if (endptr == buf) {
		fprintf(stderr, "No digits were found\n");
		return 1;
	}
	
	// allocate space for the additional data
	*response = (char*) realloc(*response, (*response_len) + bodylen + 1);
	body = &(*response)	[*response_len];
	
	if (!body) {
		printf("error allocating memory %u\n", bodylen);
		return 1;
	}
	
	// read the data
	if (!ctx->ssl_active) {
		len = read(ctx->sock, body, bodylen);
	} else {
		len = SSL_read(ctx->ssl, body, bodylen);
	}
	
	if (len != bodylen) {
		printf("error reading body\n");
		return 1;
	}
	
	(*response)[(*response_len) + len] = 0;
	*response_len += bodylen;
	
	printf("received BODY:\n---\n%s\n---\n", body);
	
	// read closing brace
	readline(ctx);
	if (ctx->line[0] != ')') {
		printf("parse error fetch end\n");
		return 1;
	}
	
	return 0;
}

// read one line from the server
int readline(struct imap_ctx *ctx) {
	char buf[1024];
	size_t len;
	
	if (!ctx->line) {
		ctx->line_size = 32;
		ctx->line = (char*) malloc(ctx->line_size);
	}
	
	ctx->line_strlen = 0;
	while (1) {
		if (!ctx->ssl_active) {
			len = read(ctx->sock, buf, 1);
		} else {
			len = SSL_read(ctx->ssl, buf, 1);
		}
		buf[len] = 0;
		
		if (len == -1) {
			if (errno == EINTR)
				continue;
			else
				return -1;
		} else if (len == 0) {
		} else {
			if (ctx->line_strlen + len >= ctx->line_size) {
				ctx->line_size *= 2;
				ctx->line = (char*) realloc(ctx->line, ctx->line_size);
			}
			if (buf[0] != '\n') {
				ctx->line[ctx->line_strlen] = buf[0];
				ctx->line_strlen += len;
			} else {
				ctx->line[ctx->line_strlen] = 0;
				printf("s: %s\n", ctx->line);
				break;
			}
		}
	}
	
	return 0;
}

// wait for and read response of the server
int read_resp(struct imap_ctx *ctx, char **response, size_t *response_len, char resp_to_cmd) {
	char failed = 0;
	
	while (1) {
		// read one line
		readline(ctx);
		
		if (ctx->line_size > 0) {
// 			if (response) {
// 				*response = (char*) realloc(*response, *response_len + ctx->line_strlen + 1);
// 				memcpy(&(*response)[*response_len], ctx->line, ctx->line_strlen);
// 				*response_len += ctx->line_strlen;
// 				(*response)[*response_len] = 0;
// 			}
			
			if (!resp_to_cmd) {
				// stop after one line if we don't wait for completion of a
				// specific command
				break;
			} else
			if (ctx->line[0] != '*' && ctx->line[0] != '+') {
				unsigned int uint;
				int res, bytes_read;
				char cmd[32];
				
				// check if we received a command completion response
				res = sscanf(ctx->line, "a%3u %32s%n", &uint, cmd, &bytes_read);
				cmd[31] = 0;
				
				if (res == 2) {
					if (uint == ctx->cmd_idx-1 && !strcmp(cmd, "OK")) {
						// command finished successfully
						printf("cmd %u finished\n", uint);
						break;
					} else
					if (uint == ctx->cmd_idx-1 && !strcmp(cmd, "BAD")) {
						printf("cmd %u finished with error: %s\n", uint, ctx->line);
						failed = 1;
						break;
					} else
					if (uint == ctx->cmd_idx-1 && !strcmp(cmd, "NO")) {
						printf("cmd %u finished with response NO: %s\n", uint, ctx->line);
						failed = 1;
						break;
					}
				}
			} else {
				unsigned int uint;
				int res, bytes_read;
				char cmd[32];
				
				/*
				 * check what kind of data the server sends us
				 */
				
				res = sscanf(ctx->line, "* %u %32s%n", &uint, cmd, &bytes_read);
				cmd[31] = 0;
				if (res == 2 && !strcmp(cmd, "EXISTS")) {
					unsigned int diff;
					
					/*
					 * new mail(s) arrived
					 */
					
					// amount of new mails?
					diff = uint - ctx->n_mails;
					ctx->n_mails = uint;
					
					// EXISTS is also send during SELECT mailbox, hence we only
					// fetch mails if we are in IDLE mode
					if (ctx->idle_active) {
						char *new_mail = 0;
						size_t new_mail_len = 0;
						unsigned int i;
						char buf[64];
						
						// disable IDLE while we fetch new mails
						if (!ctx->ssl_active) {
							write(ctx->sock, "DONE\n", 5);
						} else {
							SSL_write(ctx->ssl, "DONE\n", 5);
						}
						read_resp(ctx, 0, 0, 1);
						
						// fetch header and body of new mails
						for (i=uint - diff; i < uint; i++) {
							snprintf(buf, 64, "FETCH %d BODY.PEEK[HEADER]", i);
							send_cmd(ctx, buf, &new_mail, &new_mail_len);
							
							snprintf(buf, 64, "FETCH %d BODY.PEEK[TEXT]", i);
							send_cmd(ctx, buf, &new_mail, &new_mail_len);
							
							printf("new mail (%zu):\n%s\n", new_mail_len, new_mail);
						}
						
						// enable IDLE again
						send_cmd(ctx, "IDLE", 0, 0);
					}
				}
				
				// do we receive the data of a mail?
				if (res == 2 && !strcmp(cmd, "FETCH")) {
					recv_fetch(ctx, bytes_read, response, response_len);
				}
			}
		}
	}
	
	return failed;
}

// send a command to the server
int send_cmd(struct imap_ctx *ctx, char *cmd, char **response, size_t *response_len) {
	char buf[1024];
	size_t len;
	int failed = 0;
	
	if (strlen(cmd) > 1019) {
		printf("error cmd_len > 1019\n");
		return 1;
	}
	
	len = snprintf(buf, 1024, "a%03u %s\n", ctx->cmd_idx, cmd);
	ctx->cmd_idx++;
	
	if (!ctx->ssl_active) {
		write(ctx->sock, buf, len);
	} else {
		SSL_write(ctx->ssl, buf, len);
	}
	printf("c: sent command a%03u\n", ctx->cmd_idx-1);
	
	// wait for response
	failed = read_resp(ctx, response, response_len, 1);
	
	return failed;
}

int main(int argc, char **argv) {
	struct sockaddr_in server;
	struct imap_ctx imap_ctx;
	int sock;
	SSL_CTX *ctx;
	SSL *ssl;
	
	
	if (argc < 5) {
		fprintf(stderr, "Usage: %s <server-ip> <user> <password> <folder>\n", argv[0]);
		return 1;
	}
	
	memset(&imap_ctx, 0, sizeof(struct imap_ctx));
	imap_ctx.cmd_idx = 1;
	imap_ctx.ssl_active = 0;

	sock = socket(AF_INET, SOCK_STREAM, 0);

	server.sin_port = htons(143);
	server.sin_addr.s_addr = inet_addr(argv[1]);
	server.sin_family = AF_INET;

	if(connect(sock, (struct sockaddr *) &server, sizeof(server)) < 0) {
		printf("erro socket\n");
		exit(1);
	}
	
	imap_ctx.sock = sock;
	
	// receive greetings
	read_resp(&imap_ctx, 0, 0, 0);
	
	if (strstr(imap_ctx.line, "IDLE") == NULL) {
		printf("error, server does not support IDLE command\n");
		shutdown(sock, SHUT_RDWR);
		return 1;
	}
	
	// notify server that we want to initiate a secure connection
	send_cmd(&imap_ctx, "STARTTLS", 0, 0);
	
	// initialize OpenSSL
	SSL_load_error_strings();
	SSL_library_init();
	OpenSSL_add_all_algorithms();
	SSL_load_error_strings();
	
	ctx = SSL_CTX_new(SSLv23_client_method());
	if (ctx == NULL) {
		ERR_print_errors_fp(stderr);
	}
	
	SSL_CTX_set_options(ctx, SSL_OP_NO_SSLv2);
	
	ssl = SSL_new(ctx);
	if (!SSL_set_fd(ssl, sock)) {
		ERR_print_errors_fp(stderr);
		return 1;
	}
	
	if (ssl) {
		char buf[128];
		int r;
		
		if (SSL_connect((SSL*)ssl) < 1) {
			ERR_print_errors_fp(stderr);
			return 1;
		}
		
		/*
		 * we now have a secure connection
		 */
		
		imap_ctx.ssl = ssl;
		imap_ctx.ssl_active = 1;
		
		// uncomment to see get the capabilities
// 		send_cmd(&imap_ctx, "CAPABILITY", 0, 0);
		
		
		// send login
		snprintf(buf, 128, "login %s %s", argv[2], argv[3]);
		r = send_cmd(&imap_ctx, buf, 0, 0);
		if (r) {
			printf("login failed\n");
			return 1;
		}
		
		// select IMAP folder
		snprintf(buf, 128, "select %s ", argv[4]);
		r = send_cmd(&imap_ctx, buf, 0, 0);
		if (r) {
			printf("select folder failed\n");
			return 1;
		}
		
		// notify server that we wait for new mails (this call will not
		// return in this example)
		imap_ctx.idle_active = 1;
		send_cmd(&imap_ctx, "idle", 0, 0);
	} else {
		printf("ssl setup failed\n");
		return 1;
	}
	
	return 0;
}
