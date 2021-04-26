#!/bin/zsh
# check which pkgs are required by other pkgs from the same list
# v0.2.2  jan/2021  by mountaineerbr
#
# usage: archPkgCrossCheck.sh [PKGLIST.txt]
#
# if you use Arch Linux, probably you have made a list of packages
# to install in a fresh system and may want to check which packages
# are required against packages from the same list.
#
# this does not check for aur packages or metapackages such as 'base'.
# a text file containing package names, one per line, is required.
# empty lines and lines with '#' will be ignore.
# package ``expac'' is required.

#pkg list
pkglist="$1"


#get pkg info
#make pg list
list=( $(grep -ve \# -e '^\s*$' "$pkglist" | sort) )
((${#list[@]})) || exit

#extract pkg 'depends on' fields or 'group provides' 
#normal pkgs and group  pkgs
info="$(expac -S %n:\ %D\  "$list[@]")
$(expac -Sg  %G:\ %n\ %D\  "$list[@]")"
#expac: %G groups; %n file name; %D depends on
#expac: use (pacman) -S flag

#check if a package from list is required by another package
m=0
for entry in "$list[@]"
do
	#counter
	((++n))
	#printf '%d/%d  \r' "$n" "${#list[@]}" >&2  #verbose
	
	if 
		#check if pkg is required by another pkg from the same list
		res="$( grep -v "^$entry:" <<<"$info" | grep -i " $entry ")"
	then
		#counter
		((++m))
		
		reqby=( $(cut -f1 -d: <<<"$res") )
		print "$entry is required by -- $reqby[*]"
	fi
done

	
print
print "$m pkgs require other pkgs from the same list"

