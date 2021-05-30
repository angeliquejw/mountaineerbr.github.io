#!/bin/zsh
# copy files from SOURCE to $PWD when they differ
# v0.3.8  may/2021  by mountaineerbr

#script name
SN="${0##*/}"

SYNOPSIS="NAME
	$SN -- copy files from SOURCE to \$PWD when they differ


SYNOPSIS
	diffcp.sh [-d] [SOURCE_DIR] [GLOB|FILE..]


DESCRIPTION
	Copy FILES from SOURCE_DIR to \$PWD when they differ. The script
	will only compare files that exist at \$PWD with SOURCE_DIR.
	
	Useful for updating files in a git repo from a source directory.

	Unless option -d is set the script performs a dry run.


ENVIRONMENT
	[
	\$HOTRUN 	If set to a value greater than 0, the sript will
			perform a hot-run instead of a dry-run, same as
			option -d.


OPTIONS
	-d 	Set a hot-run (disables dry-run).
	-h 	Prints this help page.
	-v 	Prints script version."

# useful shell opts: extendedglob globstarshort nullglob


#parse options
while getopts dDhv opt
do
	case ${opt} in
		d|D)
			# Hot run
			# Disables dry-run
			SATOPT=1
			;;
		h)
			# Show Help
			echo "$SYNOPSIS"
			exit
			;;
		v)
			# Version of Script
			grep -Fm1 '# v' "$0"
			exit 0
			;;
		\?)
			#illegal option
			#printf "Invalid option: -%s\n" "${OPTARG}" >&2
			exit 1
			;;
	esac
done
shift $((OPTIND - 1))


#check $1 (SOURCE_DIR) is a directory
SOURCE="$1"
SOURCE="${SOURCE%/}"

#target directory
#defaults to $PWD
#TARGET="${TARGET:-$PWD}"
TARGET="$PWD"
TARGET="${TARGET%/}"


[[ -d "$SOURCE" ]] || {
	print "$SN: err  -- non-empty source is required" >&2
	print "$SYNOPSIS" >&2
	exit 1
}
shift

#remaining args should be filenames
[[ -e "$1" ]] || {
	print "$SN: err  -- at least one file required" >&2
	print "$SYNOPSIS" >&2
	exit 1
}

#for files in $TARGET, compare with
#matching files from $SOURCE
n=0
for f in "${@#$TARGET}"
do
	#does filename from input really exist at $TARGET ?
	[[ -e "$f" ]] || continue

	#define/derive (probable) filepath to SOURCE_DIR
	e="$SOURCE/$f"
	
	#check if files differ 
	if [[ -e "$e" ]] &&
		! diff -q "$f" "$e" &>/dev/null
	then
		#counter
		((n++))

		#set $HOTRUN (confirm) to actually copy files
		if ((HOTRUN))
		then cp -vf "$e" "$TARGET/$f" ;ret=$((ret + $?))
		else print "copy << $e\n     >> $TARGET/$f" >&2
		fi
	else
		((HOTRUN)) || print "skip -- $e" >&2
	fi
done

((HOTRUN)) || {
	print ">>>DRY RUN" >&2
	print ">>>$n file(s) differ" >&2
	((n)) && print ">>>set variable \$HOTRUN to greater than 0 to copy files" >&2
}

exit ${ret:-0}

