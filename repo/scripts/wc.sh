#!/bin/bash
#!/bin/zsh
# wc.sh  --  print line, word and character count
# v0.3.19  may/2021  by mountaineerbr

#TODO: ask for help com.unix.shell or other groups about
#array splitting for counting words (line ~182), as
#there must be a more efficient and cleaner way to do it.
#check man 3 pcrepattern.

#defaults
#script name
SN="${0##*/}"

#help page
HELP="NAME
	$SN -   Print newline, word and byte counts for each file


SYNOPSIS
	$SN [-clLmw] FILE..
	$SN [-hv]


	Use shell builtins to print line, word, byte and character
	counts from FILES or stdin input. It can also print the
	maximum display width (longest line).

	Newline bytes are used to detect and count lines. Null bytes
	are ignored.
	
	This script uses shell builtins only and is compatible with bash
	and zsh. There may be differences between interpreter results.
	It is not supposed to compete with Grep, it is rather a tool
	for studying Shell functions.


ENVIRONMENT VARIABLES
	The \$LANG and \$LC_ALL environment variables shall affect
	the execution of this script , which will determine values of
	locale categories.


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
	local r

	r="$(printf "$fmtstring" "${results[@]}" "${FILE%/dev/stdin}")"
	echo "${r% }"
}

saveresultf()
{
	unset fmtstring

	results=( $( echoresulthelperf ) )
	opts=( $OPTM $OPTC $OPTL $OPTW $OPTMAX )  #"${!OPT@}" expands to OPTERR and OPTIND, too..
	fields=$(( ${#opts[@]} ))

	#find the longest numeric string in results
	for r in ${results[@]} $linestotal $wordstotal $charstotal $bytestotal
	do
		(( ${#r} > n )) && n=${#r}
	done

	#compose a printf formatting string
	#try to comply with gnu guidelines?
	if (( fields > 1 )) &&
		(( FILENUM < 1 ))
	then
		min_width=7
		(( n < min_width )) && n=$min_width
	fi

	strdecimal="%${n}d "
	for ((f=1 ;f<(fields+1) ;++f))  #one more field for filename
	do
		fmtstring="${fmtstring}${strdecimal}"
	done
	fmtstring="${fmtstring}%s\n"

	#save partially formatted result for printing later
	if [[ -n "$resultsall" ]]
	then
		resultsall="${resultsall}
${results[*]}"
		filesall=( "${filesall[@]}" "$FILE" )
	else
		resultsall="${results[*]}"
		filesall=( "$FILE" )
	fi

	unset lines words chars bytes min_width longest FILE
	unset r f m results opts fields strdecimal
}
#https://github.com/coreutils/coreutils/blob/master/src/wc.c

#longest line
mainmaxf()
{
	local buffer
		
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
}

#count attributes
mainf()
{
	local buffer nl w
		
	#loop through document
	while 
		nl=1
		IFS=  read -r buffer || {
		[[ -n "$buffer" ]] && nl=  #no newline bytes detected but line is non-empty
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
			#one at a time, very slow
			w=( ${buffer//$'\u00a0'/ } ) 	#nbsp
			w=( ${w[*]//$'\u2007'/ } ) 	#figure space
			w=( ${w[*]//$'\u202f'/ } ) 	#narrow nbsp
			w=( ${w[*]//$'\u2060'/ } ) 	#word joiner
			w=( ${w[*]//$'\u2009'/ } ) 	#thin space
			#w=( ${w[*]//$'\u2002'/ } ) 	#en space
			#w=( ${w[*]//$'\u2003'/ } ) 	#em space
			w=( ${w[*]//$'\f'/ } ) 		#page feed ^L
			w=( ${w[*]//$'\r'/ } ) 		#carriage return
			(( words = words + ${#w[@]} ))
		}

		#count characters
		(( OPTM )) && {
			#change $LANG $LC_ALL to user original (bash zsh)
			(( OPTW && ZSH_VERSION )) || LANG="$ORIGLANG" LC_ALL="$ORIGLCAL"
			
			(( chars = chars + nl + ${#buffer} ))
		}


		#revert $LANG $LC_ALL
		if (( OPTW && ZSH_VERSION )) || (( OPTM ))
		then
			LANG=C  LC_ALL=C
		fi
	done
}
##non-breaking spaces from gnu wc source code:
##$'\u00a0'$'\u2007'$'\u202f'$'\u2060'
#0020 = space
#00a0 = nbsp
#202f = narrow nbsp
#2002 = en-space
#2003 = em-space
#2007 = figure space
#2009 = thin space
#2060 = word joiner
#000a = form feed, also \f
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
				then
					echo "$REPLY"
					exit 0
				fi
			done < "$0"
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
FILENUM="$#"

#save original (user) values $LANG $LC_ALL
ORIGLANG="$LANG" ORIGLCAL="$LC_ALL"

#following params affects shell speed 
#(and GNU tools behaviour in general)
export POSIXLY_CORRECT=y
(( ZSH_VERSION )) || set -o posix
(( OPTMAX )) || LANG=C  LC_ALL=C

#consolidate options
if (( OPTMAX ))
then
	unset OPTM OPTC OPTL OPTW
elif [[ -z "$OPTM$OPTC$OPTL$OPTW" ]]
then
	(( ++OPTC ))
	(( ++OPTL ))
	(( ++OPTW ))
fi

#bash or zsh?
if (( ZSH_VERSION ))
then
	#unset shell globbing
	#zsh doesn't perform filename
	#generation upon command substitution.

	#set automatic word split
	#array index start at nought
	setopt  SH_WORD_SPLIT  KSH_ZERO_SUBSCRIPT
else
	#unset shell globbing
	set -f
fi

#is stdin free?
if [[ -t 0 ]]
then
	#is there any user argument?
	if (( FILENUM < 1 ))
	then
		echo "$SN: err  -- input (FILE or stdin) required" >&2
		exit 1
	fi
fi

#loop through files
#save partially formatted result and add values to totals
for FILE in "${@:-/dev/stdin}"
do
	#is it a file or stdin?
	if (( FILENUM ))
	then
		#check if that is a file (even if that is a fifo)
		if [[ -e "$FILE" ]]
		then
			#read file to stdin
			exec 0< "$FILE"
		else
			echo "$SN: no such file -- $FILE" >&2
			continue
		fi
	fi

	#call main function
	if (( OPTMAX ))
	then
		mainmaxf

		#add to total
		(( longest > longesttotal )) && longesttotal="$longest"
	else
		mainf

		#add to total
		(( OPTL )) && (( linestotal = linestotal + lines ))
		(( OPTW )) && (( wordstotal = wordstotal + words ))
		(( OPTM )) && (( charstotal = charstotal + chars ))
		(( OPTC )) && (( bytestotal = bytestotal + bytes ))
	fi

	saveresultf
done

#print individual results
i=0
(( ZSH_VERSION )) && i=1
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
	then
		results=( $longesttotal )
	else
		results=( $linestotal $wordstotal $bytestotal $charstotal )
	fi

	printresultf
fi

exit "${EXITCODE:-0}"

# modeline
# vim:filetype=bash

