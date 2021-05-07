#!/bin/zsh
#  v0.4.1  may/2021  mountaineerbr
# Make archive packages from directories

#script name
SN="${0##*/}"

#BASE HREF AND PATH
pbase=$HOME/www/mountaineerbr.github.io
#hbase=https://mountaineerbr.github.io
#DIRECTORY: REPOS
pbaserepos="$pbase/repo"

#cache checksum dir root
cksumroot="$pbaserepos/cksum.d"

#max file sizes
warningsize=94500  #(KB)
maxsize=100500     #(KB)

#help page
HELP="$SN -- Make archive packages from directories
	$SN [FILE]


	Archives all dirs from \$PWD.

	Set environment parameter \$SUMONLY to update/recreate
	checksum cache files only (exits with 100).
	
	Requires \`cksum' package (because that is fast)."

#checksum fun
cksumf()
{
	#zsh glob (.) excludes directories
	zargs -r -- "$1"/**(.) -- cksum --
}


#start
#parse options
while getopts hvV c
do
	case $c in
		h)
			#help
			echo "$HELP"
			exit 0
			;;
		v)
			#verbose
			OPTV=1
			;;
		V)
			#print script version
			while IFS=  read -r
			do
				[[ "$REPLY" = \#\ v[0-9]* ]] && break
			done < "$0"
			echo "$REPLY"
			exit 0
			;;
		\?)
			exit 1
			;;
	esac
done
shift $(( OPTIND - 1 ))
unset c





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

	[[ "$repo" = "${cksumroot##*/}" ]] && continue  #don't make tar of _cksum/

	#check checksum
	if ((SUMONLY))
	then
		#create a cksum file
		cksumf "$repo" >"$cksumfilenamenew"
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

