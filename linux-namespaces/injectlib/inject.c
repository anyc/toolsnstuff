/*
 * This lib returns a custom hostid and hostname for certains queries
 * of an application.
 *
 * Compile with: gcc -shared -o libinject.so gethostid.c -fPIC -ldl
 *
 * Mario Kicherer (http://kicherer.org)
 */

#define __USE_GNU
#define _GNU_SOURCE
#include <stdlib.h>
#include <unistd.h>
#include <dlfcn.h>
#include <netdb.h>

struct hostent * (*real_gethostbyname)(const char *name);

long gethostid(void) {
	return 0x001234567890;
}

struct hostent * gethostbyname(const char *name) {
	if (!real_gethostbyname) {
		real_gethostbyname = dlsym(RTLD_NEXT, "gethostbyname");
	}
	
	if (!strcmp(name, "oldhost")) {
		return real_gethostbyname("newhost");
	} else {
		return real_gethostbyname(name);
	}
}
