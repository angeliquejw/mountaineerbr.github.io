#!/bin/bash
#!/bin/zsh
# grep.sh  --  grep with shell built-ins
# v0.3alpha  may/2021  by mountaineerbr

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

#star glob
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


	Reads from FILES or stdin.
	By defaults, performs pattern matching with \`globs'.
	Set option -E to use regular expressions instead.

	Set multiple PATTERNS with -e.


WILD-CARD VS GLOB VS REGEX



   GLOBBING PATTERNS
       The pattern arguments may contain any of the following special characters, which are a superset of those supported by  string
       match:

       ?         Matches any single character.

       *         Matches any sequence of zero or more characters.

       [chars]   Matches  any  single  character in chars. If chars contains a sequence of the form a-b then any character between a
                 and b (inclusive) will match.

       \x        Matches the character x.

       {a,b,...} Matches any of the sub-patterns a, b, etc.



REGULAR EXPRESSIONS
       A  regular  expression  is  a  pattern  that  describes a set of strings.  Regular expressions are constructed analogously to
       arithmetic expressions, by using various operators to combine smaller expressions.

       grep understands three different versions of regular expression syntax: “basic” (BRE), “extended” (ERE)  and  “perl”  (PCRE).
       In GNU grep there is no difference in available functionality between basic and extended syntaxes.  In other implementations,
       basic regular expressions are less powerful.  The following description applies to extended regular expressions;  differences
       for  basic regular expressions are summarized afterwards.  Perl-compatible regular expressions give additional functionality,
       and are documented in pcresyntax(3) and pcrepattern(3), but work only if PCRE is available in the system.

       The fundamental building blocks are the regular expressions that match a single character.  Most  characters,  including  all
       letters  and digits, are regular expressions that match themselves.  Any meta-character with special meaning may be quoted by
       preceding it with a backslash.

       The period . matches any single character.  It is unspecified whether it matches an encoding error.

   Character Classes and Bracket Expressions
       A bracket expression is a list of characters enclosed by [ and ].  It matches any single character  in  that  list.   If  the
       first  character  of  the  list  is  the  caret ^ then it matches any character not in the list; it is unspecified whether it
       matches an encoding error.  For example, the regular expression [0123456789] matches any single digit.

       Within a bracket expression, a range expression consists of two characters separated by a  hyphen.   It  matches  any  single
       character  that  sorts  between  the two characters, inclusive, using the locale's collating sequence and character set.  For
       example, in the default C locale, [a-d] is equivalent to [abcd].  Many locales sort characters in dictionary  order,  and  in
       these  locales  [a-d] is typically not equivalent to [abcd]; it might be equivalent to [aBbCcDd], for example.  To obtain the
       traditional interpretation of bracket expressions, you can use the C locale by setting the LC_ALL environment variable to the
       value C.

       Finally,  certain  named  classes  of characters are predefined within bracket expressions, as follows.  Their names are self
       explanatory, and they are [:alnum:], [:alpha:], [:blank:], [:cntrl:], [:digit:], [:graph:], [:lower:], [:print:],  [:punct:],
       [:space:],  [:upper:],  and  [:xdigit:].   For  example,  [[:alnum:]] means the character class of numbers and letters in the
       current locale.  In the C locale and ASCII character set encoding, this is the same as [0-9A-Za-z].  (Note that the  brackets
       in  these class names are part of the symbolic names, and must be included in addition to the brackets delimiting the bracket
       expression.)  Most meta-characters lose their special meaning inside bracket expressions.  To include a literal  ]  place  it
       first  in the list.  Similarly, to include a literal ^ place it anywhere but first.  Finally, to include a literal - place it
       last.

   Anchoring
       The caret ^ and the dollar sign $ are meta-characters that respectively match the empty string at the beginning and end of  a
       line.

   The Backslash Character and Special Expressions
       The  symbols  \<  and  \>  respectively match the empty string at the beginning and end of a word.  The symbol \b matches the
       empty string at the edge of a word, and \B matches the empty string provided it's not at the edge of a word.  The  symbol  \w
       is a synonym for [_[:alnum:]] and \W is a synonym for [^_[:alnum:]].

   Repetition
       A regular expression may be followed by one of several repetition operators:
       ?      The preceding item is optional and matched at most once.
       *      The preceding item will be matched zero or more times.
       +      The preceding item will be matched one or more times.
       {n}    The preceding item is matched exactly n times.
       {n,}   The preceding item is matched n or more times.
       {,m}   The preceding item is matched at most m times.  This is a GNU extension.
       {n,m}  The preceding item is matched at least n times, but not more than m times.

   Concatenation
       Two  regular expressions may be concatenated; the resulting regular expression matches any string formed by concatenating two
       substrings that respectively match the concatenated expressions.

   Alternation
       Two regular expressions may be joined by the infix operator |; the resulting regular expression matches any  string  matching
       either alternate expression.

   Precedence
       Repetition  takes  precedence over concatenation, which in turn takes precedence over alternation.  A whole expression may be
       enclosed in parentheses to override these precedence rules and form a subexpression.

   Back-references and Subexpressions
       The back-reference \n, where n is a single  digit,  matches  the  substring  previously  matched  by  the  nth  parenthesized
       subexpression of the regular expression.

   Basic vs Extended Regular Expressions
       In basic regular expressions the meta-characters ?, +, {, |, (, and ) lose their special meaning; instead use the backslashed
       versions \?, \+, \{, \|, \(, and \).




[[:alpha:]] [[:alnum:]]


in [[ = ]] [!x] and [^x] are the same
not so in [[ =~ ]]


SEE ALSO
	man glob
	man grep

	A Brief Introduction to Regular Expressions
	<https://tldp.org/LDP/abs/html/x17129.html>


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
	Pattern Syntax
	-E, -r     Interpret PATTERNS as extended regular expressions.
	-F 	   Interpret PATTERNS as fixed strings.

	Matching Control
	-e PATTERN Use PATTERN as the target string. If this option is
		   used multiple times, search for all patterns given. 
	-i, -y 	   Case insensitive match.
	-ii 	   Same as -i but prints matched line in uppercase.
	-v         Invert sense of matching, prints non-matching lines.
	-x 	   Whole-line matching, select only matches that exactly
		   match the whole line; this is like surrounding the
		   pattern with ^ and $ in a regex.
	-w


	Miscellaneous
	-h         Print this help page.
	-V         Print script version.
	-h, -H  conflicts with
	

	General Output Control
	-c 	   Suppress normal output; instead print only a count
		   of matching lines for each input file. With the -v
		   option, count non-matching lines.

	-k 	   Disable colour output.
	-m NUM 	   Maximum NUM results to print.
	-o
	-q         Quiet, exit with zero on first match found.


	Output Line Prefix Control
	-n 	   Prefix each line of output with the line number
		   within its input file.
	-Z

		   "


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

