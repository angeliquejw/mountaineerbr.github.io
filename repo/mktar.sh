#!/bin/zsh
# mountaineerbr  may/2021
# Make archive packages from directories
# usage: mktar.sh [FILE]
# by defaults, archives all folder of $PWD
# set $SUMONLY to update checksum only (exits with 100)
# requires `cksum' package

#script name
SN="${0##*/}"

#BASE HREF AND PATH
pbase=$HOME/www/mountaineerbr.github.io
#hbase=https://mountaineerbr.github.io
#DIRECTORY: REPOS
pbaserepos="$pbase/repo"

#cache checksum filename root
cksumroot="$pbaserepos/cksum"

#max file sizes
warningsize=94500  #(KB)
maxsize=100500     #(KB)

#checksum fun
cksumf()
{
	#zsh glob (.) excludes directories
	zargs -r -- "$1"/**(.) -- cksum --
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
	cksumfilename="${cksumroot%/}/${repo}"
	cksumfilenameold="$cksumfilename".cksum
	cksumfilenamenew="$cksumfilename".new.cksum

	#check checksum
	[[ "$repo" = "${cksumroot##*/}" ]] && continue  #don't make tar of _cksum/
	if ((SUMONLY))
	then
		#create a cksum file
		cksumf "$repo" >"$cksumfilenameold"
		ret=(100)
		print "$SN: cksum generated -- $repo" >&2
		continue
	elif [[ -e "$cksumfilenameold" ]]
	then
		#check new against old checksum file
		cksumf "$repo" >"$cksumfilenamenew"

		if (($#==0)) &&
			diff -q "$cksumfilenameold" "$cksumfilenamenew"
		then
			rm -- "$cksumfilenamenew"
			ret+=(0)
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
	ret+=($?)

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

