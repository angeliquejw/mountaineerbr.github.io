#!/bin/bash
# interleave lines from different files
# v0.1.2  oct/2020  by mountaineerbr
 
#will skip empty and blank lines

FILES=( "$@" ) 

for f in "${FILES[@]}"
do
	((n++))
	m="MAP$n"
	maps+=( "$m" )
	
	mapfile -t "$m" <"$f" || exit 1
done
unset f m n

#find the longest numeric string in results
for r in "${maps[@]}"
do
	eval s="\${#${r}[@]}"
	(( s > x )) && x=$s
done
unset r s

for ((i=0 ;i<=x ;i++))
do
	for o in "${maps[@]}"
	do
		eval l="\"\${${o}[$i]}\""
		[[ -n "${l// }" ]] || continue

		lines+=( "$l" )
	done

	(( ${#lines[@]} )) || continue

	printf '%s\n' "${lines[@]}"
	unset lines
done
unset "${maps[@]}"
unset i l o x maps

