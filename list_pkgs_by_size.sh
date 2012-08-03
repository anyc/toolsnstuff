#! /bin/sh

# get size of all packages, sort and write to packages_size.txt

for x in `equery -q l "*"`; do echo $x >&2; equery -q s $x | sed -r "s/(.*):.*size\(([0-9]+)\)/\2 \1/"; done | sort -g > packages_size.txt
