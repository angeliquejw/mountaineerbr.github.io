#!/usr/bin/bash
#!/usr/bin/zsh
# unarchive and uncompress text files to stdout
# v0.4.3  jan/2021  by mountaineerbr

#script name
SN="${0##*/}"

#maximum simultaneous jobs
#default max jobs for shell looping
#user sets $JOBSMAX
JOBSDEF=4

#gnu parallel may need
#a large temp directory
TMPDIR=${TMPDIR:-/tmp}
export TMPDIR

#parallel feedback bar
BAR=--bar

#feedback string format
#for opt -s
FBACKSTR='\r>>>%s/%s %s  \r'

#help
HELP="NAME
	$SN - unarchive and uncompress text files to stdout


SYNOPSIS
	$SN [-sv] [-jNUM] FILE..


DESCRIPTION
	unarchive and uncompress a variety of file types and print to
	stdout.  recognised compressed file types: tar.bz2, tar.gz,
	bz2, rar, gz, tar, tbz2, tgz, zip, Z and 7z.

	useful for checking plain text files compressed in archives,
	such as those from usenet.

	file extensions are checked, so different file types can be
	set as FILES.

	filenames can be sent through stdin (one filepath per line)
	or set as positional parameters to the script.
	
	it defaults to launching new jobs with GNU parallel: guarantee
	output from each job is grouped together and is only printed
	when the job is finished.
	
	option -s to use shell asynchronous looping that runs faster
	than gnu parallel.  note that output is not grouped by job,
	meaning mixed outputs from different jobs is printed.

	option -j to set maximum simultaneous jobs.  when used together
	with GNU parallel, if NUM is zero that means \`\`run the maximum
	number of jobs possible'',  defaults=0 (for GNU parallel) and
	defaults=$JOBSDEF (for shell looping).

	option -v disables printing of progress feedback and parallel
	bar (quiet mode).


ENVIRONMENT
	GNU parallel reads \$TMPDIR to storing temporary data so that
	it can print output of each job orderly.  depending on the
	compressed file size that may be necessary to setting a direc-
	tory of larger capacity, defaults to TMPDIR=$TMPDIR .


OPTIONS
	-j NUM 	Set maximum number of simultaneous jobs.
	-s 	Use shell synchronous looping.
	-v 	Quiet, avoids printing some feedback info."


#GNU parallel
parallelf()
{
	#group files by extension
	EXTS=( $( printf '%s\n' "${FILES[@]}" | grep -Eo '\.([^.\/]+)$' | awk '!seen[$0]++' ) )

	for e in "${EXTS[@]}"
	do
		F=( $( printf '%s\n' "${FILES[@]}" | grep "$e\$" | awk '!seen[$0]++' ) )

		#set command based on first file extension
		extractorf "${F[0]}"

		((d++))

		#verbose
		(( OPTV )) || echo "file extension -- $e [$d/${#EXTS[@]}]" >&2

		#start parallel
		printf '%s\n' "${F[@]}" |
			parallel -j"${JOBSMAX:-1}" --group ${BAR} "${CMD[*]} {}"

	done
	unset EXTS F d e
}

#shell asynchronous looping
shellf()
{
	#check JOBSMAX
	if (( ${JOBSMAX+1} )) && (( JOBSMAX == 0 ))
	then
		printf '%s: warning -- minimum number of jobs must be 1\n' "$SN" >&2
		JOBSMAX=1
	fi

	#set trap
	trap cleanf EXIT INT TERM

	#make temporary file for job control
	TMP="$( mktemp "${TMPDIR:-/tmp}/$SN.$$.XXXXXXXX" || mktemp )" || exit 1

	#shell loop
	for f in "${FILES[@]}"
	do
		#counter
		(( ++n ))

		#job control
		while jobs -l > "$TMP"
			JOBS="$( while read ;do ((++lnum)) ;done <"$TMP" ;echo "$lnum" )"
			(( JOBS > ${JOBSMAX:-$JOBSDEF} ))
		do
			sleep 0.1
		done

		#async
		{
			#set command based on file extension
			extractorf "$f"

			#print asynchronously
			"${CMD[@]}" "$f"
			
			#feedback
			(( OPTV )) || printf "$FBACKSTR" "$n" "${#FILES[@]}" "${f##*/}" >&2
		} &
		#obs: that is technically possible to use buffer files
		#and print lock to orderly print output from different
		#jobs but let's not do it

	done
	unset f n

	#wait for subprocesses
	wait
}

#ex - archive extractor
extractorf()
{
	if [[ -f "$1" ]]
	then
		case "$1" in
			*.tar.bz2) CMD=(tar xOjf) ;;
			*.tar.gz)  CMD=(tar xOzf) ;;
			*.bz2)     CMD=(bunzip2 -c) ;;
			*.rar)     CMD=(unrar p) ;;
			*.gz)      CMD=(gunzip -c) ;;
			*.tar)     CMD=(tar xOf) ;;
			*.tbz2)    CMD=(tar xOjf) ;;
			*.tgz)     CMD=(tar xOzf) ;;
			*.zip)     CMD=(unzip -c) ;;
			*.Z)       CMD=(uncompress -c) ;;
			*.7z)      CMD=(7z x -so) ;;
			*.tar.*)   CMD=(tar xOvf) ;;
			*) 	printf '%s: err -- cannot extract %s\n' "$SN" "$1" >&2
				return 1
				;;
		esac
	else
		printf '%s: err: does not seem to be a file -- %s\n' "$SN" "$1" >&2
		return 1
	fi
}

#clean temp files
cleanf()
{
	#disable trap
	trap \  EXIT INT TERM

	#remove temp data
	[[ -f "$TMP" ]] && rm "$TMP"
	
	exit
}


#parse options
while getopts :hj:svq c
do
	case $c in
		h)
			#help
			printf '%s\n' "$HELP"
			exit 0
			;;
		j) 
			#maximum jobs
			JOBSMAX="$OPTARG"
			;;
		s)
			#shell async loop
			OPTSHELL=1
			;;
		[vq])
			#quiet
			OPTV=1
			unset BAR
			;;
		\?)
			#illegal option
			printf '%s: invalid option -- -%s\n' "$SN" "${OPTARG}" >&2
			exit 1
			;;
	esac
done
shift $(( OPTIND - 1 ))
unset c

#bash or zsh?
if (( ZSH_VERSION ))
then
	#array index start at nought
	setopt KSH_ZERO_SUBSCRIPT
fi

#check for a readable file or use glob
if (( $# == 0 ))
then
	if [[ ! -t 0 ]]
	then
		while read
		do
			if (( ${#FILES[@]} == 0 ))
			then
				FILES=( "$REPLY" )
			else
				FILES=( "${FILES[@]}" "$REPLY" )
			fi
		done
		unset REPLY
	fi

	if (( ${#FILES[@]} == 0 ))
	then
		printf '%s: file is required\n' "$SN" >&2
		exit 1
	fi
else
	FILES=( "$@" )

fi


#call funcs
if (( OPTSHELL ))
then
	#shell asynchronous looping
	shellf "$@"
else
	#check whether parallel is installed
	if ! command -v parallel &>/dev/null
	then
		printf '%s: parallel is required\n' "$SN" >&2
		exit 1
	fi

	#GNU parallel option (defaults)
	parallelf "$@"
fi

#sanity new line
echo >&2

