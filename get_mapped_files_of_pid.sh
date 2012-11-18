#! /bin/sh

cat /proc/${1}/maps | awk '{print $(NF)}' | sort | uniq | grep -v "^\[.*\]$" | grep -v "^[0-9]*$"
