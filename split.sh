#!/bin/sh
# Moves the entries of a directory into N groups of about the same size.
# usage: split.sh <directory> <N> <output directory>   (creates <output directory>/1 ... /N)
set -e
dir=$1
n=$2
out=$3
i=1
while [ "$i" -le "$n" ]; do mkdir -p "$out/$i"; i=$((i + 1)); done
# Largest entries first, each into the group that is currently smallest.
du -sk "$dir"/* | sort -rn | awk -v n="$n" -v out="$out" '{
    best = 1
    for (i = 2; i <= n; i++) if (size[i] < size[best]) best = i
    size[best] += $1
    path = $0; sub(/^[0-9]+[ \t]+/, "", path)
    print "mv \"" path "\" \"" out "/" best "/\""
}' | sh
