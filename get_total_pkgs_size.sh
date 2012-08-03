#! /bin/sh

# ever wanted to know how much disk size a group of packages consume?
#
# e.g. try: get_total_pkgs_size.sh "kde-base/*"

for x in `equery -q l "$1"`; do echo $x >&2; equery -q s $x | sed -r "s/(.*):.*size\(([0-9]+)\)/\2 \1/"; done | awk '{SUM+=$1; NUM+=1} END {print NUM " packages consume " SUM " bytes"}'
