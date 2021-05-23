#!/bin/bash
#!/bin/zsh
# wc.sh  --  print line, word and character count
# v0.4.10  may/2021  by mountaineerbr

#defaults
#script name
SN="${0##*/}"

#help page
HELP="NAME
	$SN -   Print newline, word and byte counts for each file


SYNOPSIS
	$SN [-clLmw] FILE..
	$SN [-hv]


	Use shell builtins to print line, word, byte and character counts
	from FILES or stdin input. It can also print the maximum display
	width (longest line).

	Newline bytes are used to detect and count lines. Null bytes are
	ignored.
	
	This script uses shell builtins only and is compatible with bash
	and zsh. There may be differences between interpreter results.
	It is not supposed to compete with Wc, it is rather a tool for
	studying Shell functions.


ENVIRONMENT VARIABLES
	LANG and LC_ALL environment variables determine values of locale
	categories and shall affect the execution of shell builtins.


SEE ALSO
	WHEELER, Fixing Unix/Linux/POSIX Filenames: Control Characters
	(such as Newline), Leading Dashes, and Other Problems
	<https://dwheeler.com/essays/fixing-unix-linux-filenames.html>	


WARRANTY
	Tested with GNU Bash 5.0+ and Zshell 5.8+ .
	
	Licensed under the GNU Public License v3 or better and is
	distributed without support or bug corrections.
   	
	Please consider sending me a nickle!  =)

		bc1qlxm5dfjl58whg6tvtszg5pfna9mn2cr2nulnjr


BUGS
	There may be count differences for some files when compared
	to GNU wc, mainly files with binary data.
	
	Expect Bash and Zsh to perform differently. Zsh performs slower
	in this script.


OPTIONS
	-c 	   Count bytes.
	-h 	   Print this help page.
	-L 	   Print the maximum display width.
	-l 	   Count lines.
	-m 	   Count characters.
	-w 	   Count words.
	-v 	   Print script version."


#print selected results
echoresulthelperf()
{
	(( OPTL )) && echo "${lines:-0}"
	(( OPTW )) && echo "${words:-0}"
	(( OPTM )) && echo "${chars:-0}"
	(( OPTC )) && echo "${bytes:-0}"
	(( OPTMAX )) && echo "${longest:-0}"
}

#print results
printresultf()
{
	local p

	p="$(printf "$fmtstring" "${results[@]}" "${FILE%/dev/stdin}")"
	echo "${p% }"
}

saveresultf()
{
	unset fmtstring

	results=( $( echoresulthelperf ) )
	opts=( $OPTM $OPTC $OPTL $OPTW $OPTMAX )  #"${!OPT@}" expands to OPTERR and OPTIND, too..
	fields=$(( ${#opts[@]} ))

	#find the longest numeric string in results
	for r in ${results[@]} $linestotal $wordstotal $charstotal $bytestotal
	do ((${#r} > n)) && n=${#r}
	done

	#compose a printf formatting string
	#try to comply with gnu guidelines?
	if ((fields > 1 && FILENUM < 1))
	then min_width=7 ;((n < min_width)) && n=$min_width
	fi

	strdecimal="%${n}d "
	for ((f=1 ;f<(fields+1) ;++f))  #one more field for filename
	do fmtstring="${fmtstring}${strdecimal}"
	done
	fmtstring="${fmtstring}%s\n"

	#save partially formatted result for printing later
	if [[ -n "$resultsall" ]]
	then
		filesall=( "${filesall[@]}" "$FILE" )
		resultsall="${resultsall}
${results[*]}"
	else
		filesall=( "$FILE" )
		resultsall="${results[*]}"
	fi

	unset lines words chars bytes min_width longest FILE nl 
	unset r f m results opts fields strdecimal
}
#https://github.com/coreutils/coreutils/blob/master/src/wc.c

#longest line
mainmaxf()
{
	local buffer
		
	#read file to stdin
	exec 0< "$1"

	#loop through document
	while IFS=  read -r buffer ||
		[[ -n "$buffer" ]]
	do
		#substitute tab with whitespaces
		buffer="${buffer//$'\t'/    }"

		#longest string
		(( ${#buffer} > longest )) && longest="${#buffer}"
	done
	#GNU wc -L gives the width of the widest line in its input by
	#using wcwidth(3) to determine the width of characters.

	#add to total (file totals)
	(( longest > longesttotal )) && longesttotal="$longest"
}

#main functions
#count file attributes
mainf()
{
	local buffer w nl
		
	#read file to stdin
	exec 0< "$1"
	
	#loop through document
	while 
		nl=1
		IFS=  read -r buffer || {
			#no newline bytes detected but line is non-empty
			[[ -n "$buffer" ]] && nl=
		}
	do
		#count lines
		(( OPTL )) && (( lines = lines + nl ))

		#count bytes, new line is one byte
		(( OPTC )) && (( bytes = bytes + nl + ${#buffer} ))


		#count words
		(( OPTW )) && {
			#change $LANG $LC_ALL to user original (zsh)
			(( ZSH_VERSION )) && LANG="$ORIGLANG" LC_ALL="$ORIGLCAL"
			
			#remove non-breaking spaces
			#and carriage returns
			IFS=$' \t\n\f\r'  w=( $buffer )  IFS=$' \t\n'
			(( words = words + ${#w[@]} ))
		}

		#count characters
		(( OPTM )) && {
			#change $LANG $LC_ALL to user original (bash zsh)
			(( OPTW && ZSH_VERSION )) || LANG="$ORIGLANG" LC_ALL="$ORIGLCAL"
			
			(( chars = chars + ${#buffer} ))
		}


		#revert $LANG $LC_ALL
		if (( ( OPTW && ZSH_VERSION ) || OPTM ))
		then LANG=C  LC_ALL=C
		fi
	done

	#add to totals
	(( OPTL )) && (( linestotal = linestotal + lines ))
	(( OPTW )) && (( wordstotal = wordstotal + words ))
	(( OPTM )) && (( charstotal = charstotal + chars ))
	(( OPTC )) && (( bytestotal = bytestotal + bytes ))
}
##non-breaking spaces from gnu wc source code:
##$'\u00a0'$'\u2007'$'\u202f'$'\u2060'
#0020 = space        #2002 = en-space      #2009 = thin space
#00a0 = nbsp         #2003 = em-space      #2060 = word joiner
#202f = narrow nbsp  #2007 = figure space  #000a = form feed, also \f
##was using: \u00a0 \u2007 \u202f \u2060 \u2009 \u2002 \u2003 \f \r
##spaces: https://www.compart.com/en/unicode/search?q=space#characters
##&nbsp; &thinsp; &ensp; and &emsp;
#In ASCII, &#09; is a TAB
#LFD key, typing C-j will produce the desired character (same as Enter)
##The stat and ls utilities just execut the lstat syscall and get the file
##length without reading the file. Thus, they do not need the read permission
##and their performance does not depend on the file's length. wc actually
##opens the file and usually reads it, making it perform much worse on large
##files. But GNU coreutils wc optimizes when only byte count of a regular file
##is wanted: it uses fstat and lseek syscalls to get the count. – Palec
##https://stackoverflow.com/questions/9195493/unix-find-average-file-size
#https://lists.gnu.org/archive/html/bug-bash/2016-09/msg00015.html
#https://stackoverflow.com/questions/46163678/get-rid-of-warning-command-substitution-ignored-null-byte-in-input
#read string without ending with newline
#https://unix.stackexchange.com/questions/418060/read-a-line-oriented-file-which-may-not-end-with-a-newline
#count length vs bytes:
#ipc#https://stackoverflow.com/questions/17368067/length-of-string-in-bash
##strict mode, check null chars: while IFS=  read -r -d ''
##https://stackoverflow.com/questions/36313562/how-to-redirect-stdin-to-file-in-bash

#notes on alternative method
#it should be faster if we can process the whole file at once.
#however, we cannot detect new line bytes directly (as opposed to null)
#and this info is needed for counting lines and bytes correctly.
#requires more memory.
##MAPFILE=( ${(ps:\n:)"$(<${(b)1})"} )
##mapfile -t <<<"$buffer"


#parse options
while getopts chLlmwvz c
do
	case $c in
		c)
			#count bytes
			(( ++OPTC ))
			;;
		m)
			#count characters
			(( ++OPTM ))
			;;
		h)
			#help
			echo "$HELP"
			exit 0
			;;
		L)
			#max line length
			(( ++OPTMAX ))
			;;
		l)
			#count lines
			(( ++OPTL ))
			;;
		w)
			#count words
			(( ++OPTW ))
			;;
		v)
			#script version
			while read
			do
				if [[ "$REPLY" = \#\ v* ]]
				then echo "$REPLY" ;exit 0
				fi
			done <"$0"
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
unset c  #OPTIND OPTERR

#save number of positional arguments
#if none left at this point, input
#is probably from /dev/stdin
FILENUM=$#

#save original (user) values $LANG $LC_ALL
ORIGLANG=$LANG ORIGLCAL=$LC_ALL

#following params affects shell speed 
#(and GNU tools behaviour in general)
export POSIXLY_CORRECT=y
(( OPTMAX )) || LANG=C  LC_ALL=C

#consolidate options
if (( OPTMAX ))
then unset OPTM OPTC OPTL OPTW
elif [[ -z "$OPTM$OPTC$OPTL$OPTW" ]]
then (( ++OPTC )) ;(( ++OPTL )) ;(( ++OPTW ))
fi

#bash or zsh?
if (( ZSH_VERSION ))
then
	#set automatic word split
	#array index start at nought
	setopt  SH_WORD_SPLIT  KSH_ZERO_SUBSCRIPT

	#shell array index
	BZ=1
else
	#unset shell globbing
	#conform to posix
	set -f -o posix
	
	#shell array index
	BZ=0
fi

#is stdin free?
#is there any user argument?
if ((FILENUM == 0)) && [[ -t 0 ]]
then echo "$SN: err  -- input (FILE or stdin) required" >&2 ;exit 1
fi

#warnings
((OPTA && OPTC+OPTL)) && echo "$SN: warning -- cannot detect null-ending lines" >&2

#set tests to mainf()
if ((OPTMAX))
then mainf() { mainmaxf "$@" ;}
elif ((OPTA))
then mainf() { mainaltf "$@" ;}
fi


#loop through files
#save partially formatted result and add values to totals
for FILE in "${@:-/dev/stdin}"
do
	#is it a file or stdin?
	#check if that is a file (even if that is a fifo)
	if ((FILENUM)) && [[ ! -e "$FILE" ]]
	then
		echo "$SN: no such file -- $FILE" >&2
		continue
	fi

	#call main function
	mainf "$FILE"

	saveresultf
done

#print individual results
i=$BZ
while read
do
	#is there any result?
	[[ -z "$REPLY" ]] && EXITCODE=1
	
	results=( $REPLY )
	FILE="${filesall[$i]}"

	printresultf
	(( ++i ))
done <<< "$resultsall"
unset i results FILE REPLY

#print totals
if (( FILENUM > 1 ))
then
	FILE=total
	
	#define printing variables
	if (( OPTMAX ))
	then results=( $longesttotal )
	else results=( $linestotal $wordstotal $bytestotal $charstotal )
	fi

	printresultf
fi

exit "${EXITCODE:-0}"

