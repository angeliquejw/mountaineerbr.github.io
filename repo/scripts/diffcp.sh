#!/bin/zsh
# copy files from $SOURCE to $PWD when they differ
# useful for updating files in a git repo from a source directory
# v0.3.5  jan/2021  by mountaineerbr
# KISS

SYNOPSIS='synopsis: [RUN=1] diffcp.sh [SOURCE_DIR] [GLOB|FILE..]
description: copy FILES from SOURCE_DIR to $PWD when they differ.
the script will only compare files that exist at $PWD with SOURCE_DIR.
unless $RUN is set to an integer greater than zero, the script
performs a dry run.'
# useful shell opts: extendedglob globstarshort nullglob

#script name
SN="${0##*/}"

#target directory
#defaults to $PWD
#TARGET="${TARGET:-$PWD}"
TARGET="$PWD"


#check $1 (SOURCE_DIR) is a directory
SOURCE="$1"
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
	if
		[[ -e "$e" ]] &&
		! diff -q "$f" "$e" &>/dev/null
	then
		#counter
		((n++))

		#set $RUN (confirm) to actually copy files
		if
			((RUN))
		then
			cp -vf "$e" "$TARGET/$f"
			ret=$((ret + $?))
		else
			print "copy << $e\n     >> $TARGET/$f" >&2
		fi
	else
		((RUN)) || print "skip -- $e" >&2
	fi
done

((RUN)) || {
	print ">>>DRY RUN" >&2
	print ">>>$n file(s) differ" >&2
	((n)) && print ">>>set variable \$RUN to greater than 0 to copy files" >&2
}

exit ${ret:-0}

