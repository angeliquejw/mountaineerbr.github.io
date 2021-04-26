#!/bin/bash
#!/bin/zsh
# grep.sh  --  grep with shell built-ins
# v0.2.5l  jan/2021  by mountaineerbr

#todo
#1.merge test functions that can be merged with (un)setting glob/anchor
#variables intead of hard coding all test modes (zsh requires GLOBSUBST);
#2.fix? painting matched results: $ grep.sh 'b?sh' .bashrc
#will change resulting output from bash to b?sh;
#3.try to use bash ${BASH_REMATCH[@]} and zsh $match[@] after test with regular; zsh = setopt BASH_REMATCH
#expressions for painting results, check: https://thoughtbot.com/blog/the-unix-shells-humble-if;
#very good ref for development: https://blog.burntsushi.net/ripgrep/

#defaults
#colours (for filename highlighting)
COLOUR1='\e[3;35;40m' #PURPLE
COLOUR2='\e[2;36;40m' #SEAGREEN
COLOUR3='\e[1;31;40m' #BOLDRED
COLOUR4='\e[3;32;40m' #GREEN
NC='\e[m'

#use start glob by defaults
STAR=1

#set fixed locale
#export LC_NUMERIC=C

#script name
SN="${0##*/}"

#help page
HELP="NAME
	$SN - grep with shell built-ins


SYNOPSIS
	$SN [OPTION...] PATTERN [FILE...]
	$SN [OPTION...] -e PATTERN ... [FILE...]


	Use shell builtins to grep text. Reads from FILES or stdin.
	Set multiple PATTERNS with option -e.

	Use the same syntax for describing PATTERN as the shell
	built-in test command. Option -r enables regular expres-
	sions instead of simple wild-cards.


WARRANTY
	Licensed under the GNU Public License v3 or better and is
	distributed without support or bug corrections.
   	
	This script requires bash or zsh to work properly.

	Please consider sending me a nickle!  =)

		bc1qlxm5dfjl58whg6tvtszg5pfna9mn2cr2nulnjr


BUGS
	Painting of matches may change output when using globs in
	searching pattern. Additionally, although patterns may be
	matched, they may not be painted in stdout.

	Slower than GNU grep. Zsh performance is slower than bash.


OPTIONS
	-c 	   Suppress normal output; instead print only a count
		   of matching lines for each input file. With the -v
		   option, count non-matching lines.
	-e PATTERN Use PATTERN as the target string. If this option is
		   used multiple times, search for all patterns given. 
	-F 	   Interpret PATTERNS as fixed strings.
	-h         Print this help page.
	-i 	   Case insensitive match.
	-ii 	   Same as -i but prints matched line in uppercase.
	-k 	   Disable colour output.
	-m NUM 	   Maximum NUM results to print.
	-n 	   Prefix each line of output with the line number
		   within its input file.
	-q         Quiet, exit with zero on first match found.
	-r         Interpret PATTERNS as extended regular expressions.
	-v         Invert sense of matching, prints non-matching lines.
	-V         Print script version.
	-x 	   Whole-line matching, select only matches that exactly
		   match the whole line; this is like surrounding the
		   pattern with ^ and $ in a regex."


#loop checking function
#print line
echoresultf()
{
	local linex patternx
	
	#print filename (multiple files)
	(( PRINTFILENAME )) && printf "$STRFILE" "$FILE"
	#print line number
	(( OPTN )) && printf "$STRLNUM" "$lnum"
	
	#-c print match count?
	if (( OPTC ))
	then
		echo "${linematch:-0}"
		unset linematch
		return 0
	#print matched line
	#don't mess with $LINE if colour opt is not set
	elif (( OPTK ))
	then
		echo "$LINE"
	else
		#try to paint matches
		linex="${LINE//\\/\\\\}"
		patternx="${PATTERN//\\/\\\\}"
		patternx="${patternx#^}"
		patternx="${patternx%$}"
		#(( OPTR )) && patternx="${patternx//./?}"

		echo -e "${linex//${patternx}/${COLOUR3}${patternx}${NC}}"
		#echo -e "${linex//"${patternx}"/"${COLOUR3}${patternx}${NC}"}"
	fi
}

#main func
mainf()
{
	#loop through document
	while IFS=  read -r LINE || [[ -n "$LINE" ]]
	do
		#-i option case-insensitive catches here
		STRING="$LINE"

		#count line numbers
		(( ++lnum ))

		#loop through PATTERNS
		for PATTERN in "${PATTERNARRAY[@]}"
		do
			#test for a match in line
			testf || continue

			#-q quiet? exit on first match
			(( QUIET )) && exit 0

			#count lines with matches
			(( ++linematch ))
			#-c only count matched lines
			(( OPTC )) && continue
			
			#print matched line
			echoresultf

			#-m max results set?
			if (( MAX )) && ! (( linematch - MAX ))
			then
				unset linematch
				return 0
			fi
		done
	done

	#set proper exit code
	(( linematch )) && exitsignal=0
}

#simple test
testf()
{
	#escape spaces
	testpattern="${PATTERN// /\\ }"
	[[ "$STRING" = *${testpattern}* ]]
}
testnostarf()
{
	#escape spaces
	testpattern="${PATTERN// /\\ }"
	[[ "$STRING" = $testpattern ]]
}

#fixed-string test
testfixedf()
{
	[[ "$STRING" = *"$PATTERN"* ]]
}
#fixed-string test
testfixednostarf()
{
	[[ "$STRING" = "$PATTERN" ]]
}

#regex test
testregexf()
{
	#escape spaces
	testpattern="${PATTERN// /\\ }"
	[[ "$STRING" =~ ^$testpattern$ ]]
}
#regex test
testregexnoanchorf()
{
	#escape spaces
	testpattern="${PATTERN// /\\ }"
	[[ "$STRING" =~ $testpattern ]]
}


#parse options
while getopts ce:Fhiykm:nqrvVxz c
do
	case $c in
		c)
			#count matched lines
			OPTC=1
			;;
		e)
			#search arguments
			if [[ -z "${PATTERNARRAY[@]}" ]]
			then
				PATTERNARRAY=( "$OPTARG" )
			else
				PATTERNARRAY=( "${PATTERNARRAY[@]}" "$OPTARG" )
			fi
			;;
		F)
			#fixed strings
			OPTF=1
			;;
		h)
			#help
			echo "$HELP"
			exit 0
			;;
		[iy])
			#case-insensitive search
			if (( OPTI ))
			then
				#-ii print matched line in uppercase
				typeset -u LINE
			else
				typeset -u PATTERN STRING
			fi
			(( ++OPTI ))
			;;
		k)
			#no colour
			OPTK=1
			;;
		m)
			#max results
			MAX="$OPTARG"
			;;
		n)
			#print match line number
			OPTN=1
			;;
		q)
			#quiet
			QUIET=1
			;;
		r)
			#test regex
			OPTR=1
			;;
		v)
			#invert match
			OPTV=1
			;;
		V)
			#script version
			#"$0" -m1 -k '# v' "$0"
			while read
			do
				if [[ "$REPLY" = \#\ v* ]]
				then
					echo "$REPLY"
					exit 0
				fi
			done < "$0"
			;;
		x)
			#whole-line match
			ANCHOR=1
			STAR=0
			;;
		z)
			#run this script with zshell
			(( ZSH_VERSION )) || {
				zsh "$0" "$@"
				exit
			}
			;;
		?)
			#illegal option
			exit 1
			;;
	esac
done
shift $(( OPTIND - 1 ))
unset c

#is zshell?
if (( ZSH_VERSION ))
then
	setopt GLOBSUBST  #SHWORDSPLIT
fi

#set test type

#-F fixed strings
if (( OPTF ))
then
	#use star globs (defaults)
	if (( STAR ))
	then
		testf()
		{
			testfixedf
		}
	#-x no star globs
	else
		testf()
		{
			testfixednostarf
		}
	fi
#-r regex
elif (( OPTR ))
then
	#-x regex anchors
	if (( ANCHOR ))
	then
		testf()
		{
			testregexf
		}
	#no regex anchors (defaults)
	else
		testf()
		{
			testregexnoanchorf
		}
	fi
#-x simple test no star glob
elif (( STAR < 1 ))
then
	testf()
	{
		testnostarf
	}
fi

#-v option invert matched lines
if (( OPTV ))
then
	ORIGFUNC="$( declare -f testf  )"
	ORIGFUNC="${ORIGFUNC/testf ()/testforig ()}"
	eval "$ORIGFUNC"

	testf()
	{
		! testforig
	}
fi


#more than one argument? is file?
while (( $# ))
do
	#is last positional argument a file?
	if [[ -f "${@: -1}" ]]
	then
		if [[ -z "${FILEARRAY[*]}" ]] 
		then
			FILEARRAY=( "${@: -1}" )
		else
			FILEARRAY=( "${@: -1}" "${FILEARRAY[@]}" )
		fi
		set -- "${@:1:$(( $# - 1 ))}"
	else
		break
	fi
done

#is there any file? is stdin free?
if [[ -z "${FILEARRAY[*]}" ]] && [[ -t 0 ]]
then
	echo "$SN: err  -- input required" >&2
	exit 1
fi

#more than one file?
if (( ${#FILEARRAY[@]} > 1 ))
then
	PRINTFILENAME=1
fi

#check positional arguments
if [[ -z "${PATTERNARRAY[*]}" ]]
then
	if (( $# < 2 ))
	then
		PATTERNARRAY=( "$1" )
		set --
	elif (( $# < 1 ))
	then
		echo "$SN: err  -- PATTERN required" >&2
		exit 1
	fi
fi

#there should not be anything left
#as positional parameters by now
if (( $# ))
then
	echo "$SN: err: no such file -- ${@: -1}" >&2
	exit 1

fi

#colour?
if [[ ! -t 1 ]] || (( OPTK ))
then
	unset COLOUR1 COLOUR2 COLOUR3 COLOUR4 NC
fi

#echoresultf printf string
STRFILE="${COLOUR1}%s${COLOUR2}:${NC}"
#-n line number colour
STRLNUM="${COLOUR4}%s${COLOUR2}:${NC}"

#loop through files
for FILE in "${FILEARRAY[@]:-/dev/stdin}"
do
	[[ "$FILE" = /dev/stdin ]] || exec 0< "$FILE"
	mainf
	
	#-c only print matched line count?
	(( OPTC )) && echoresultf

	#unset count line numbers
	unset lnum
done


exit "${exitsignal:-1}"

#modeline
# vim:filetype=bash

