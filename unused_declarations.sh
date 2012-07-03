#! /bin/sh

# Written 2012 by Mario Kicherer (http://kicherer.org)

if [ "$#" -ne "4" ]; then
	echo "usage: $(basename $0) <file created by gcc -aux-info> <include> <exclude> <resulting binary>"
	echo ""
	echo "This script compares the list of declared symbols in a file with the list"
	echo "of symbols present in the resulting binary. If declared symbols are not"
	echo "present in the resulting binary, they are unused and can be removed in"
	echo "order to reduce compilation time and file size."
	echo ""
	echo "Example: - add \"-aux-info $<.aux\" to your Makefile CFLAGS"
	echo "         - make clean; make"
	echo "         - $(basename $0) one_of_my_files.c.aux myprefix_ myprefix_ignorethis_ libmyproject.so"
	exit 1
fi

# create temporary files
decls="$(mktemp)"
syms="$(mktemp)"

# grep for the interesting stuff in the aux file
cat "$1" | grep $2 | grep -v $3 | grep "C \*\/" | sed -r "s/.*[ \*]([a-z_0-9A-Z]+) \(.*/\1/" | grep -v int | grep -v void | sort | uniq > ${decls}

# get the symbols listed in the binary
# nm $4 | grep " T " | cut -c 20- | sort | uniq > ${syms}
nm "$4" | cut -c 20- | sort | uniq > ${syms}

# get symbols in $decls but not in $syms
unused="$(egrep -v -x -f ${syms} ${decls})"

# find line in the aux file that corresponds to the unused symbols
echo "$unused" | xargs -i bash -c " echo -n \"{} - \" ; grep -e {} \"$1\""

# remove temporary files
rm $decls $syms