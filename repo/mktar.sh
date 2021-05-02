#!/bin/zsh
# mountaineerbr  apr/2021
# Make archive packages from directories
# usage: mktar.sh [FILE]
# otherwise archives all folder of $PWD

#script name
SN="${0##*/}"

#BASE HREF AND PATH
pbase=$HOME/www/mountaineerbr.github.io
#hbase=https://mountaineerbr.github.io
#DIRECTORY: REPOS
pbaserepos="$pbase/repo"

#max file sizes
warningsize=94500  #(KB)
maxsize=100500     #(KB)


#start
set -e
setopt extendedglob  
setopt nullglob
setopt nocaseglob  #or use `(#i)(readme.md)*'

cd "$pbaserepos"

#make tar for repos
if read -q "?$SN: Create archive files? y/N  "
then
	print
	for repo in ${@:-*/}
	do
		repo="${repo%/}"
		tarfile="${repo:u}".TXZ
		
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
	unset tarfile repo fsize warningsize maxsize
fi

