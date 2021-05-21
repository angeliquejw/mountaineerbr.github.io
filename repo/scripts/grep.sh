#!/bin/bash
#!/bin/zsh
# grep.sh  --  grep with shell built-ins
# v0.3.3  may/2021  by mountaineerbr

#defaults
#script name
SN="${0##*/}"

#pattern matching
#extended regex
#defaults=1
OPTE=1

#match colour
#defaults=1
OPTK=1

#colours
COLOUR1='\e[3;35;40m'  #PURPLE
COLOUR2='\e[2;36;40m'  #SEAGREEN
COLOUR3='\e[1;31;40m'  #BOLDRED
COLOUR4='\e[3;32;40m'  #GREEN
NC='\e[m'              #NO COLOUR

#wild cards
DEFSTAR=\*
DEFANCHORL=\^
DEFANCHORR=\$
DEFANCHORWORD='[!a-zA-Z0-9_]'
DEFANCHORWORDEL='(^|[^a-zA-Z0-9_])'
DEFANCHORWORDER='([^a-zA-Z0-9_]|$)'
ANCHORWORDELR='[^a-zA-Z0-9_]'

#set fixed locale
#export LC_NUMERIC=C

#help page
HELP="NAME
	$SN - Grep with shell built-ins


SYNOPSIS
	$SN [OPTION...] PATTERN [FILE...]
	$SN [OPTION...] -e PATTERN ... [FILE...]


DESCRIPTION
	Read FILES or stdin and performs pattern matching. Set multiple
	PATTERNS with -e. When a line matches a pattern that is printed.

	By defaults, interpret PATTERN as POSIX BASIC REGEX. Please note
	that operators for EXTENDED REGEX need backslash escaping to be
	activated, otherwise they have got no special meaning. For example 
	'\\(foo\\|bar\\)' and 'baz.\\{1,5\\}'.

	Set option -g for EXTENDED GLOBBING syntax (PATTERNS will be
	treated as globs). Option -g adds star globs around *PATTERN*
	whereas -gg does not add these automatically and is functionally
	the same as -gx. With Zsh, -G enables KSH_GLOB and also sets -g
	once. Extended glob operators are active by defaults. Quote char-
	acters with backslash to treat them as literals when needed.

	This script uses shell builtins only and is compatible with bash
	and zsh. There may be differences between interpreter results.
	It is not supposed to compete with Grep, it is rather a tool
	for studying Shell functions.


REGULAR EXPRESSIONS
	A  regular expression is a pattern that describes a set of strings.
	When it is used, the string to the is considered a POSIX extended
	regular expression and matched accordingly (using the POSIX regcomp
	and regexec interfaces usually described in regex(3)). Note that
	blackslash quoting is required to activate operators such as
	'\\(foo\\|bar\\)' and 'baz.\\{1,5\\}'.

	The fundamental building blocks are the regular expressions that
	match a single character. Most characters, including all letters
	and digits, are regular expressions that match themselves. Any
	meta-character with special meaning may be quoted by preceding
	it with a backslash.

	The period . matches any single character. It is unspecified
	whether it matches an encoding error.


	CHARACTER CLASSES AND BRACKET EXPRESSIONS
	A bracket expression is a list of characters enclosed by [ and ].
	It matches any single character in that list. If the first char-
	acter of the list is the caret ^ then it matches any character
	not in the list.

	Certain named classes of characters are predefined within bracket
	expressions, as follows. Their names are self explanatory:
		[:alnum:], [:alpha:], [:blank:], [:cntrl:], [:digit:],
		[:graph:], [:lower:], [:print:],  [:punct:], [:space:],
		[:upper:], [:xdigit:]
	
	Note that the brackets in these class names are part of the sym-
	bolic names, and must be included in addition to the brackets
	delimiting the bracket expression.

	Most meta-characters lose their special meaning inside bracket
	expressions.  To include a literal ] place it first in the list.
	Similarly, to include a literal ^ place it anywhere but first.
	Finally, to include a literal - place it last.


	ANCHORING
	The caret ^ and the dollar sign $ are meta-characters that respec-
	tively match the empty string at the beginning and end of a line.


	NOTES
	Although NOT a supported special expression, the symbol \w is a
	synonym for [_[:alnum:]] which can be used instead, and \W is a
	synonym for [^_[:alnum:]].


	REPETITION
	Note that these operators need backslash \\ quoting to be activated.
	A regular expression may be followed by one of several repetition
	operators:

	?      The preceding item is optional and matched at most once.
	*      The preceding item will be matched zero or more times.
	+      The preceding item will be matched one or more times.
	{n}    The preceding item is matched exactly n times.
	{n,}   The preceding item is matched n or more times.
	{,m}   The preceding item is matched at most m times.
	{n,m}  The preceding item is matched at least n times, but not
	       more than m times.


	CONCATENATION
	Two  regular expressions may be concatenated; the resulting reg-
	ular expression matches any string formed by concatenating two
	substrings that respectively match the concatenated expressions.


	ALTERNATION
	Two regular expressions may be joined by the infix operator |;
	the resulting regular expression matches any  string  matching
	either alternate expression.


	PRECEDENCE
	Repetition takes precedence over concatenation, which in turn
	takes precedence over alternation. A whole expression may be en-
	closed in parentheses to override these precedence rules and form
	a subexpression.


GLOBBING PATTERNS
	The pattern arguments may contain any of the following special
	characters, which are a superset of those supported by string
	match:

	?         Matches any single character.
	*         Matches any sequence of zero or more characters.
	[chars]   Matches  any  single  character in chars. If chars
	          contains a sequence of the form a-b then any character
		  between a and b (inclusive) will match.
	\x        Matches the character x.


	EXTENDED GLOBBING
	Extended globbing test is enabled for Bash and Zsh.

	Zsh has got a more extensive globbing. Here are highlighted some
	features only. Check man pages to study options.

	Complicated extended pattern matching against long strings is
	slow, especially when the patterns contain alternations and the
	strings contain multiple matches. Using separate matches against
	shorter strings may be faster.


	KSH-LIKE GLOB OPERATORS (BASH AND OPTIONALLY ZSH)
	In the following description, a pattern-list is a list of one or
	more patterns separated by a |. Composite patterns may be formed
	using one or more of the following sub-patterns:

	?(pattern-list)
	       Matches zero or one occurrence of the given patterns
	*(pattern-list)
	       Matches zero or more occurrences of the given patterns
	+(pattern-list)
	       Matches one or more occurrences of the given patterns
	@(pattern-list)
	       Matches one of the given patterns
	!(pattern-list)
	       Matches anything except one of the given patterns

	To enable Ksh globbing in Zsh, set option -g twice.

	
	ZSH GLOB QUALIFIERS
	[...]  Matches any of the enclosed characters. Use with classes:
		[:alnum:], [:alpha:], [:ascii:], [:blank:], [:cntrl:],
		[:digit:], [:graph:], [:lower:], [:print:], [:punct:],
		[:space:], [:upper:], [:xdigit:], [:IDENT:], [:IFS:],
		[:IFSSPACE:], [:INCOMPLETE:], [:INVALID:], [:WORD:]

	[^...]
	[!...] Like [...], except that it matches any character which
	       is not in the given set.

	<[x]-[y]>
	       Matches any number in the range x to y, inclusive. Either
	       of the numbers may be omitted to make the range open-ended;
	       hence \`<->' matches any number. To match individual dig-
	       its, the [...] form is more efficient.

	(...)  Matches the enclosed pattern. This is used for grouping.
	       If the KSH_GLOB option is set, then a \`@', \`*', \`+',
	       \`?' or \`!' immediately  preceding  the  \`(' is treated
	       specially. Setting script option -g twice will enable this.

	x|y    Matches either x or y. The \`|' character must be within
	        parentheses to avoid interpretation as a pipeline. The
	        alternatives are tried in order from left to right.

	^x     Matches anything except the pattern x.

	x~y    Match anything that matches the pattern x but does not
	       match y.

	x#     Matches zero or more occurrences of the pattern x; note
	       that \`12#' is equivalent to \`1(2#)', rather than \`(12)#'.


	ZSH APPROXIMATE MATCHING
	When matching approximately, the shell keeps a count of the errors
	found, which cannot exceed the number specified in the (#anum)
	flags. Four types of error are recognised:

	1.     Different characters, as in fooxbar and fooybar.

	2.     Transposition of characters, as in banana and abnana.

	3.     A character missing in the target string, as with the pat-
	       tern road and target string rod.

	4.     An extra character appearing in the target string, as with
	       stove and strove.

	Thus, the pattern (#a3)abcd matches dcba, with the errors occur-
	ring by using the first rule twice and the second once, grouping
	the string as [d][cb][a] and [a][bc][d].


	ZSH GLOBBING FLAGS
	There are various flags which affect any text to their right up
	to the end of the enclosing group or to the end of the pattern;
	All take the form (#X) where X may have one of the following forms:

	i      Case insensitive: upper or lower case characters in the
	       pattern match upper or lower case characters.

	l      Lower case characters in the pattern match upper or lower
	       case characters; upper case characters in the pattern still
	       only match upper case characters.

	I      Case sensitive: locally negates the effect of i or l from
	       that point on.

	cN,M   The flag (#cN,M) can be used anywhere that the # or ##
	       operators can be used. It is equivalent to the form {N,M}
	       in regular expressions. The  previous  character or group
	       is required to match between N and M times, inclusive.
	       The form (#cN) requires exactly N matches; (#c,M) is equiv-
	       alent to specifying N as 0; (#cN,) specifies that there
	       is no maximum limit on the number of matches.

	s, e   Unlike the other flags, these have only a local effect,
	       and each must appear on its own. The \`(#s)' flag succeeds
	       only at the start of the test string, and the \`(#e)' flag
	       succeeds only at the end of the test string; they corres-
	       pond to \`^' and \`$' in standard regular expressions.

	       Note that assertions of the form \`(^(#s))' also work, i.e.
	       match anywhere except at the start of the string, although
	       this actually  means \`anything except a zero-length por-
	       tion at the start of the string';  you  need  to  use
	       \`(\"\"~(#s))' to match a zero-length portion of the string
	       not at the start.


	For example, the test string fooxx can be matched by the pattern
	(#i)FOOXX, but not by (#l)FOOXX, (#i)FOO(#I)XX or ((#i)FOOX)X.
	The string (#ia2)readme specifies case-insensitive matching of
	readme with up to two errors.


ENVIRONMENT
	LC_ALL
	       This variable overrides the value of the \`LANG' variable
	       and the value of any of the other variables starting with
	       \`LC_'.

	LC_COLLATE
	       This variable determines the locale category for character
	       collation information within ranges in glob brackets and
	       for sorting.

	LC_CTYPE
	       This variable determines the locale category for character
	       handling functions.


SEE ALSO
	Globbing and Regex: So Similar, So Different
	<https://www.linuxjournal.com/content/globbing-and-regex-so-similar-so-different>

	A Brief Introduction to Regular Expressions
	<https://tldp.org/LDP/abs/html/x17129.html>

	GNU Grep source code (GNU Savannah)
	<https://git.savannah.gnu.org/cgit/grep.git/tree/src/grep.c>

	BSD Grep source code (FreeBSD SVN)
	<https://svnweb.freebsd.org/base/stable/12/usr.bin/grep/>

	RIP Grep (development tips)
	<https://blog.burntsushi.net/ripgrep/>

	Man pages
	glob(1), test(1), grep(1), regex(3)
	bash(1), see Pattern Matching and extglob option
	zshexpn(1), see Glob Operators, Globbing Flags, Approximate Matching
	and Glob Qualifiers


WARRANTY
	Licensed under the GNU Public License v3 or better and is
	distributed without support or bug corrections.

	This script requires Bash or Zsh to work properly.

	Please consider sending me a nickle!  =)

		bc1qlxm5dfjl58whg6tvtszg5pfna9mn2cr2nulnjr


BUGS
	Option -k will colour the line between matches when using the
	glob pattern syntax.
	
	Option -k may not colour all matches or may colour matches
	incompletely.

	Option -k may interpret some backspace-escaped strings from
	input.


OPTIONS
	Pattern Syntax
	-E, -r  Interpret PATTERNS as extended regular expressions.
	-F      Interpret PATTERNS as fixed strings.
	-g      Interpret PATTERNS as globbing strings.
	-gg     Bare glob test, same as -g but no glob stars are added
	        around PATTERN automatically (functionally same as -gx).
	-G      Sets -g and enables Ksh extended glob operators in Zsh.

	Matching Control
	-e PATTERN
	        Pattern to match.
	-i, -y  Case insensitive match.
	-v      Select non-matching lines.
	-w      Match whole words only.
	-x      Match whole line only.

	General Output Control
	-c      Print only count of matching lines.
	-k      Disable colour output, set twice to force.
	-m NUM  Maximum NUM results to print.
	-q      Quiet, exit with zero on first match found.

	Output Line Prefix Control
	-H      Toggle filename prefix printing behaviour.
	-n      Add line number prefix to output.

	Miscellaneous
	-h      Print this help page.
	-V      Print script version."


#loop checking function
#print line
echoresultf()
{
	local linep linex linexr linexl linexm matchx
	
	#print filename (multiple files)
	((PRINTFNAME)) && printf "$STRFILE" "$FILE"
	#print line number
	((OPTN)) && printf "$STRLNUM" "$lnum"
	
	#-c print match count?
	if ((OPTC))
	then
		echo "${linematch:-0}"
		unset linematch
		return 0

	#print inverted match lines
	#print raw line if colour opt is not set
	elif ((OPTV || OPTK==0))
	then
		#print raw line
		echo "$LINE"

	#print colour match line
	else
		#regex test
		if ((OPTE))
		then
			#try to paint matches
			chars=2  linex="$LINE"  linep="$LINE"
			matchx="${BASH_REMATCH[0]:-$MATCH}"
			((OPTW)) && {
				matchx="${matchx#$ANCHORWORDELR}"
				matchx="${matchx%$ANCHORWORDELR}"
			}
			linep="${linep//"$matchx"/"${COLOUR3}${matchx}${NC}"}"

			while
				matchx="${BASH_REMATCH[0]:-$MATCH}"
				((OPTW)) && {
					matchx="${matchx#$ANCHORWORDELR}"
					matchx="${matchx%$ANCHORWORDELR}"
				}
				
				((${#BASH_REMATCH[0]} > chars || ${#MATCH} > chars)) \
				&& linex="${linex//"$matchx"}" \
				&& [[ -n "$linex" ]] \
				&& STRING="$linex" testf
			do
				linep="${linep//"$matchx"/"${COLOUR3}${matchx}${NC}"}"
			done
		
		#globbing test
		else
			#try to paint matches
			linep="$LINE"
			linexr="${linep##*$PATTERN}"  #line right
			linexl="${linep%%$PATTERN*}"  #line left
			
			#is whole-line a match?
			if [[ -z "$linexr$linexl" ]]
			then
				linep="${COLOUR3}${linep}${NC}"

			#if left and right templates are not the same..
			#escape templates and substitute further
			elif
				[[ "$linexr" = "$linep" ]] && unset linexr
				[[ "$linexl" = "$linep" ]] && unset linexl
				[[ "$linexr" != "$linexl" ]]
			then
				if ((ZSH_VERSION))
				then
					#zsh escaping
					linexm="${linep#${(b)linexl}}"
					linexm="${linexm%${(b)linexr}}"  #line middle

					linep="${linexl}${COLOUR3}${linep#${(b)linexl}}"
					linep="${linep%${(b)linexr}}${NC}${linexr}"
				else
					#bash escaping
					linexr="${linexr//\\/\\\\}"
					linexl="${linexl//\\/\\\\}"

					linexm="${linep#$linexl}"
					linexm="${linexm%$linexr}"       #line middle

					linep="${linexl}${COLOUR3}${linep#$linexl}"
					linep="${linep%$linexr}${NC}${linexr}"
				fi
			fi
		fi

		#print coloured line
		echo -e "$linep"
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
		for PATTERN in "${PATTERNAR[@]}"
		do
			#test for a match in line
			testf || continue

			#count lines with matches
			(( ++linematch ))
			#-c only count matched lines
			(( OPTC )) && continue
			
			#-q quiet? exit on first match
			(( OPTQ )) && exit

			#print matched line
			echoresultf

			#-m max results set?
			((MAXMATCH && linematch == MAXMATCH)) && {
				exitsig=0  linematch=  
				return
			}
		done
	done

	#set proper exit code
	(( linematch )) && exitsig=0
}

#posix extended regex test
testregexf()
{
	[[ "$STRING" =~ ${ANCHORL}${ANCHORWORDEL}${PATTERN}${ANCHORWORDER}${ANCHORR} ]]
}

#extended globbing test
testdeff()
{
	[[ "$STRING" = ${STAR}${PATTERN}${STAR} ]]
}

#extended globbing test + -w
testdefwf()
{
	[[ "$STRING" = ${STAR}${ANCHORWORD}${PATTERN}${ANCHORWORD}${STAR}
	|| "$STRING" = ${PATTERN}${ANCHORWORD}${STAR}
	|| "$STRING" = ${STAR}${ANCHORWORD}${PATTERN}
	|| "$STRING" = ${PATTERN} ]]
}

#parse options
while getopts cEe:FgGHhiyKkm:nqrvVxwz c
do
	case $c in
		c)
			#count matched lines
			OPTC=1
			;;
		E|r)
			#extended regex
			OPTE=1
			unset OPTG
			;;
		e)
			#search arguments
			if (( ${#PATTERNARPRE[@]} ))
			then PATTERNARPRE=( "${PATTERNARPRE[@]}" "$OPTARG" ) 
			else PATTERNARPRE=( "$OPTARG" )
			fi
			;;
		F)
			#fixed strings
			OPTF=1
			;;
		G)
			#globbing pattern matching
			#enables KSH_GLOB in zsh
			OPTGG=1
			((OPTG)) || OPTG=1
			unset OPTE
			;;
		g)
			#globbing pattern matching
			((++OPTG))
			unset OPTE
			;;
		H)
			#toggle print filename
			OPTH=1
			;;
		h)
			#help
			echo "$HELP"
			exit 0
			;;
		i|y)
			#case-insensitive search
			((++OPTI))
			;;
		K)
			#force colour
			OPTK=2
			;;
		k)
			#no colour
			OPTK=0
			;;
		m)
			#max results
			MAXMATCH=$OPTARG
			;;
		n)
			#print match line number
			OPTN=1
			;;
		q)
			#quiet
			OPTQ=1
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
				then echo "$REPLY" ;exit 0
				fi
			done <"$0"
			;;
		x)
			#whole line match
			OPTX=1
			;;
		w)
			#whole word match
			OPTW=1
			;;
		z)
			#try to change interpreter to zsh
			((ZSH_VERSION)) || {
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
shift $((OPTIND - 1))
unset c

#shell options
if ((ZSH_VERSION))
then setopt GLOBSUBST EXTENDED_GLOB ;((OPTGG)) && setopt KSH_GLOB
else shopt -s extglob
fi

#set star globs around *PATTERN* by defaults (globbing test only)
((OPTG>1)) || STAR=$DEFSTAR

#case insensitive
((OPTI)) && {
	if ((ZSH_VERSION))
	then setopt nocase_match
	else shopt -s nocasematch
	fi
}

#whole line match
((OPTX)) && {
	unset STAR

	#whole-line match
	ANCHORL=$DEFANCHORL
	ANCHORR=$DEFANCHORR
}

#whole word match
((OPTW)) && {
	ANCHORWORD=$DEFANCHORWORD
	ANCHORWORDEL=$DEFANCHORWORDEL
	ANCHORWORDER=$DEFANCHORWORDER
}

#declare test function
#-E regex test
if ((OPTE)) 
then
	#invert matches?
	eval "testf() { ${OPTV+!} testregexf ;}"

#globbing test + -w
elif ((OPTW))
then
	#invert matches?
	eval "testf() { ${OPTV+!} testdefwf ;}"

#globbing test
else
	#invert matches?
	eval "testf() { ${OPTV+!} testdeff ;}"
	
fi

#more than one argument? is file?
while (($#))
do
	#is last positional argument a file?
	if [[ -e "${@: -1}" && ! -d "${@: -1}" ]]
	then
		if ((${#FILEAR[@]}))
		then FILEAR=("${@: -1}" "${FILEAR[@]}")
		else FILEAR=("${@: -1}")
		fi
		set -- "${@:1:$(($# - 1))}"
	else
		break
	fi
done

#is there any file? is stdin free?
if ((${#FILEAR[@]}==0)) && [[ -t 0 ]]
then echo "$SN: err  -- input required" >&2 ;exit 1
fi

#more than one file?
((${#FILEAR[@]} > 1)) && PRINTFNAME=1

#toggle printing file name
((OPTH)) && {
	if ((PRINTFNAME))
	then PRINTFNAME=0
	else PRINTFNAME=1
	fi
}

#check positional arguments
((${#PATTERNARPRE[@]}==0)) && {
	if (($#==1))
	then PATTERNARPRE=("$1") ;shift
	elif (($#==0))
	then echo "$SN: err  -- PATTERN required" >&2 ;exit 1
	fi
}

#there should not be anything left
#as positional parameters by now
if (($#))
then echo "$SN: err: no such file -- ${@: -1}" >&2 ;exit 1
fi

#quote patterns 
if ((OPTF))
then
	#-F fixed, quote all chars
	for p in "${PATTERNARPRE[@]}"
	do
		if ((${#PATTERNAR[@]}))
		then PATTERNAR=("${PATTERNAR[@]}" "$(printf %q "$p")" )
		else PATTERNAR=( "$(printf %q "$p")" )
		fi
	done
	#obs: zsh quoting with "${(b)p}" works in this case
	#obs: bash quoting with "${p@Q}" does not work in this case
else
	#just quote spaces with backslash
	for p in "${PATTERNARPRE[@]}"
	do
		if ((${#PATTERNAR[@]}))
		then PATTERNAR=("${PATTERNAR[@]}" "${p// /\\ }" )
		else PATTERNAR=( "${p// /\\ }" )
		fi
	done
fi

#colour?
if ((OPTK<2)) && { ((OPTK==0)) || [[ ! -t 1 ]] ;}
then unset COLOUR1 COLOUR2 COLOUR3 COLOUR4 NC
fi

#echoresultf printf string
STRFILE="${COLOUR1}%s${COLOUR2}:${NC}"
#-n line number colour
STRLNUM="${COLOUR4}%s${COLOUR2}:${NC}"

#loop through files
for FILE in "${FILEAR[@]:-/dev/stdin}"
do
	[[ "$FILE" = /dev/stdin ]] || exec 0< "$FILE"
	mainf
	
	#-c only print matched line count?
	((OPTC)) && echoresultf
	#unset count line numbers
	unset lnum
done

exit "${exitsig:-1}"

