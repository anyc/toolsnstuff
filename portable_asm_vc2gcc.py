#! /usr/bin/env python

# Mario Kicherer dev@kicherer.org

import sys, re

# This tool translates VC-specific inline assembler in a GCC-compatible format
# and inserts both separated by preprocessor macros.

print """Warning: this script is by to no means complete and you most likely need
to patch the output further! However, it does most of the stupid work for you."""

registers = ["ebp", "esp",
			"eax", "ax", "al", "ah",
			"ebx", "bx", "bl", "bh",
			"edi", "di", "esi", "si",
			"cx", "ecx", "ch", "cl",
			"dx", "edx", "dl", "dh",
		]

def isnumber(s):
	try:
		int(y)
	except:
		pass
	else:
		return True;
	
	try:
		int(y, 16)
	except:
		pass
	else:
		return True;
	
	# recognize 0123467h
	if y[-1] == "h":
		try:
			print y[:-1], int(y[:-1], 16)
			int(y[:-1], 16)
		except:
			pass
		else:
			return True;
	
	return False;

for x in sys.argv[1:]:
	f = open(x, "r");
	t = f.read()
	f.close()
	
	#
	# process multiline asm functions
	#
	
	r = re.findall(r"$(\s*)(__asm\s*){(.*?)}", t, re.MULTILINE | re.DOTALL);
	
	for i in r:
		inp = ""
		outp = ""
		
		if i[2].strip() == "":
			continue;
		
		ws = i[0].strip("\n") # indentation
		code = i[2]
		
		# replace 0123h with 0x0123
		code = re.sub(r"([0-9a-fA-F]+)h", r"0x\1", code);
		
		repl = []
		for c in code.split("\n"):
			if c.strip() == "" or c.strip().startswith("//"):
				continue;
			
			# split by space and strip elements
			test = [re.sub(r"\[(\w+)\]", r"\1", z.strip(",").strip().strip(";")) for z in c.split(" ")];
			
			# ignore jumps
			if test[0].startswith("j"):
				continue
			
			# check if element is a number or register, else assume it's a variable
			for y in test[1:]:
				if y.strip() == "":
					continue
				if isnumber(y):
					continue;
				if not y in registers:
					if not y in repl:
						outp += "[%s] \"+g\" (%s), " % (y,y);
						repl.append(y);
		
		for r in repl:
			code = code.replace(r, "%%[%s]" % r)
		
		if len(outp) > 2:
			outp = outp[:-2]
			outp = ": " + outp
		if len(inp) > 1:
			inp = ": " + inp
		
		split = code.split("\n")
		for l in range(len(split)-1):
			if split[l].strip().startswith("//"):
				split[l] = split[l].replace("//", "/*") + " */"
			if split[l].strip() != "":
				split[l] += " \t\\n\\";
			else:
				split[l] += "%s\\n\\" % ws;
		code = "\n".join(split);
		
		new = "__asm__ ( \".intel_syntax noprefix\\n \\\n%s \" %s %s);" % (code, outp, inp)
		t = t.replace("%s{%s}"%(i[1],i[2]), "#ifdef _MSC_VER\n%s%s{%s}\n%s#else\n%s%s\n%s#endif" %(ws, i[1], i[2], ws, ws, new, ws));
	
	tsplit = t.split("\n")
	
	
	#
	# process single line asm
	#
	
	for l in range(len(tsplit)):
		res = re.search(r"(__asm\s+)([^{\n\/]+)", tsplit[l]);
		if not res:
			continue;
		
		i = [res.group(1), res.group(2)]
		
		inp = ""
		outp = ""
		
		if i[1].strip() == "":
			continue;
		
		code = i[1]
		
		# replace 0123h with 0x0123
		code = re.sub(r"([0-9a-fA-F]+)h", r"0x\1", code);
		
		# split by space and strip elements
		test = [z.strip(",").strip().strip(";") for z in code.split(" ")];
		
		# ignore jumps
		if test[0].startswith("j"):
			continue
		
		# check if element is a number or register, else assume it's a variable
		for y in test[1:]:
			if y.strip() == "":
				continue
			if isnumber(y):
				continue;
			if not y in registers:
				outp += "[%s] \"+g\" (%s), " % (y,y);
				code = code.replace(y, "%%[%s]" % y)
		
		if len(outp) > 2:
			outp = outp[:-2]
			outp = ": " + outp
		if len(inp) > 1:
			inp = ": " + inp
		
		new = "__asm__ ( \".intel_syntax noprefix\\n %s \" %s %s);" % (code, outp, inp)
		tsplit[l] = tsplit[l].replace("%s%s"%(i[0],i[1]), "#ifdef _MSC_VER\n\t%s%s\n\t#else\n\t%s\n\t#endif\n"%(i[0],i[1],new));
	
	t = "\n".join(tsplit);
	
	f = open(x, "w");
	f.write(t);
	f.close()