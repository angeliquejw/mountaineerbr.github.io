#!/bin/zsh
# mountaineerbr  may/2021
# Make archive packages from directories
# usage: mktar.sh [FILE]
# otherwise archives all folder of $PWD
# requires `cksum' package

#script name
SN="${0##*/}"

#BASE HREF AND PATH
pbase=$HOME/www/mountaineerbr.github.io
#hbase=https://mountaineerbr.github.io
#DIRECTORY: REPOS
pbaserepos="$pbase/repo"

#cache checksum filename root
cksumf="$pbaserepos/cksum_"

#max file sizes
warningsize=94500  #(KB)
maxsize=100500     #(KB)

#checksum fun
cksumf()
{
	zargs -r -- "$1"/**(.) -- cksum --
	#zsh glob (.) excludes directories
}


#start
set -e
setopt extendedglob  
setopt nullglob
setopt nocaseglob 	#or use `(#i)(readme.md)*'
setopt dotglob  	#or use *(D)
typeset -a ret

#really make tar for repos
#read -q "?$SN: Create archive files? y/N  " || exit

cd "$pbaserepos"
autoload -U zargs

print
for repo in ${@:-*/}
do
	repo="${repo%/}"
	tarfile="${repo:u}".TXZ
	cksumfilename="${cksumf}${repo}"
	cksumfilenameold="$cksumfilename".txt
	cksumfilenamenew="$cksumfilename".new

	#check checksum
	if [[ -e "$cksumfilenameold" ]]
	then
		#check new against old checksum file
		cksumf "$repo" >"$cksumfilenamenew"

		if diff -q "$cksumfilenameold" "$cksumfilenamenew"
		then
			ret+=(1)
			rm -- "$cksumfilenamenew"
			print "$SN: repo is sync'd -- $repo" >&2
			continue
		else
			mv -fv -- "$cksumfilenamenew" "$cksumfilenameold"
		fi
	else
		#create a cksum file
		cksumf "$repo" >"$cksumfilenameold"
	fi

	print "$SN: creating -- $tarfile" >&2
	#: z (gzip), --zstd (zstd), J (xz)
	#tar --zstd -c -f "$tarfile" "$repo"
	tar cJf "$tarfile" "$repo"

	fsize=( $(du "$tarfile" ) )
	(( ${fsize[1]} > warningsize )) && {
		print "\a$SN: WARNING: large file -- $fsize[*]" >&2
	}
	(( ${fsize[1]} > maxsize )) && {
		rm -v "$tarfile"  #max of 100MB in GitHub
		print "\a$SN: WARNING: large file removed -- $fsize[*]" >&2
		read -q '?Press any key to continue' >&2
	}
done
unset tarfile repo fsize warningsize maxsize cksumfilename cksumfilenameold cksumfilenamenew

return $(( ${ret[@]/%/+} 0 ))

