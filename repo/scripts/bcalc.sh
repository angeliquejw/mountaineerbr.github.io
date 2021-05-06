#!/bin/bash
#!/bin/zsh
# bcalc.sh -- shell maths wrapper
# v0.11.7  may/2021  by mountaineerbr

#defaults

#script path
SCRIPT="$0"
#script name
SN="${0##*/}"

#record file path
#comment it out to disable
#defaults="$HOME/.bcalc_record"
BCRECFILE="$HOME/.bcalc_record"
#extensions file
#if not under $PATH, may need setting full path
#defaults=bcalc_ext.bc
EXTFNAME="${SN%.sh}_ext.bc"

#special variables to hold last result
#requires record file
BCHOLD='ans|res'

#scale
BCSCALE=20

#option -r
#number of last lines of record file
BCRECTAIL=10

#make sure locale is set correctly
#printf does not add thousands separator for C locale
LC_NUMERIC=en_US.UTF-8
export LC_NUMERIC

#max line length of a result (bash bc)
BC_LINE_LENGTH=0
export BC_LINE_LENGTH
#newer bash bc accepts 0 to disable multiline results
#alternatively, set a large value, e.g. 10000

#man page
HELP_LINES="NAME
	$SN -- shell maths wrapper


SYNOPSIS
	$SN  [-,.eftv] [-sNUM|-NUM] EXPRESSION
	$SN  [-eehrrRuV]
	$SN  -n TEXT


DESCRIPTION
	$SN wraps the powerful Bash calculator (bc) with its maths
	library or Zshell maths evaluation and adds some useful features.
	EXPRESSIONS should preferably be one-liners and may need escaping.

	A record file (a history) is stored at \`${BCRECFILE}'.
	To disable the record file, set script option -f or comment out
	variable \$BCRECFILE in the script head source code.

	If a record file is available, special variables can be used to
	retrieve results from former operation. These variables will be
	replaced before maths evaluation. For example, \`res' or \`res0'
	will be changed to the last result, however \`res1' and so forth
	will be changed to the specified result index, in this case 1.
	Defaults variables \`${BCHOLD//|/\' and \'}'. Update the record file index
	with option -u.

	If no EXPRESSION is given, read stdin from pipe or wait for user
	input. Press <CTRL+D> to send the EOF signal and flush user input.
	If no user input is given, prints last result of record file.

	Scale can be set with -sNUM with a maximum precision of 20
	digits in bash and 16 digits in zshell. User may set scale in
	bash bc via \`scale=NUM ; [EXPRESSION]' syntax before user
	EXPRESSION, in which NUM is an integer.

	In bash bc, number of decimal plates (scale) of floating point
	numbers is dependent on user input for all operations except
	division. However, script defaults scale to $BCSCALE if none
	given with option -s .

	In zshell maths, floating point evaluation is performed auto-
	matically depending on user input. Note that \`3' is an interger
	while \`3.' is a floating point number. This script defaults
	to setting results to an internal double-precision floating point
	representation (double C type), hence expression \`3/4' evaluates
	to \`.75' rather than \`0'. Also note that results will be converted
	back to the closest decimal notation from the internal double-
	point.

	Trailing zeroes will be trimmed unless extensions option -e
	is set, in which case output/result is printed in raw format.

	Option -e loads bash bc extension file or zshell mathfunc module.
	Bash bc is more powerful. For example, bash bc accepts setting
	variables in the begining of EXPRESSION, while zshell maths does
	not. Bash bc has more extensions developed by the community over
	the years. See their respective description sections below. The
	defaults extension file is located at the same path as $SN
	and must be named ${EXTFILE}.

	Multiline input will skip output format settings defined with
	script options when using bash bc. Zsh cannot handle multiline.
	Multiline resuts are not appended in the record file.


DECIMAL AND THOUSANDS SEPARATOR
	Decimal separator defaults to a dot \`.', however user can manually
	enforce if a dot or a comma is the decimal separator (for input
	and output). Beware that some bash bc and zsh functions may need
	comma as operators.

	Option -t prints thousands separator in result. It can be combined
	with -., .

	Set option -, if decimal separator of EXPRESSION input is comma \`,' :
		
		(input) 	    (input) 	    (output)
		1.234.567,00 	--> 1234567.00 	--> 1234567,00


	Set option -. if decimal separator of EXPRESSION input is dot \`.' :

		(input) 	    (input) 	    (output)
		1,234,567.00 	--> 1234567.00 	--> 1234567.00


	Set option -t to print thousands separator in result:

		(input) 	    (output)
		1234567.00 	--> 1,234,567.00


	Strictly, setting \`-..' means to treat input with . (dot) as decimal
	separator and to print output with . with decimal separator. Rather,
	setting \`-.,' means input decimal separtor is . and to print output
	with decimal separator , (comma).


BASH BC STANDARD FUNCTIONS
	There are a few functions provided in bc enabled by defaults.
	These are user-defined and standard functions. They all appear
	as \"name(parameters)\". The standard functions are:
	
	length ( expression )
	    The value of the length function is the number of significant
	    digits in the expression.

	read ( )
	    The read function (an extension) will read a number from the 
	    standard input, regardless of where the function occurs.
	    Beware, this can cause problems with the mixing of data and
	    program in the standard input. The best use for this function
	    is in a previously written program that needs input from the
	    user, but never allows program code to be input from the user.
	    The value of the read function is the number read from the
	    standard input using the current value of the variable ibase
	    for the conversion base. 

	scale ( expression )
	    The value of the scale function is the number of digits after
	    the decimal point in the expression. 

	sqrt ( expression )
	    The value of the sqrt function is the square root of the
	    expression. If the expression is negative, a run time error
	    is generated. 


	Mathlib scale defaults to 20 plus one uncertainty digit.


BASH BC MATH LIBRARY
	Option -e will load bash bc builtin math library, which contain
	more function, as well as external extensions.
	
	Be aware that the accuracy of indeed many a function written in
	bc is directly affected by the value of the scale variable. 

	Check \`man bc' and \`info bc' for detailed instructions on usage.
	Bash bc built-in math library defines the following functions:

		s (x)  Sine of x, x is in radians.
		c (x)  Cosine of x, x is in radians.
		a (x)  Arctangent of x, arctangent returns radians.
		l (x)  Natural logarithm of x.
		e (x)  Exponential function of raising e to the value x.
		j (n,x)
		       Bessel function of integer order n of x.


	The scientific extensions defaults to 100 digits.


BASH BC EXTENSIONS
	Option -e will load further bc funtions after mathblib. The de-
	faults extension file define scientific constants such as Avogadro
	number, Planck constant, the proton rest mass, pi, as well as extra
	math functions such as \`ln(x)' (natural log) and \`log(x)' (base 10).
	Run the script with option -ee to print extensions file.

	Phodd's libraries contain sizeable comments explaining exactly
	what the file is, what it does and what each of the functions do.
	This is not the best way of providing documentation, but the
	expectation is that people should use and learn from these files,
	and so putting some documentation in with the code is a good first
	step. In his website the user will find further documentation.

	With the exception of Phodd's prime number library, other exten-
	sions are included in this wrapper script. The defaults extension
	file was compiled from different sources and may have some dupli-
	cate function definitions. However, that should not present
	problems.

	Comments in bc start with the characters \`/*' and end with the
	characters \`*/'. To support the use of bc in scripts, support
	for a single line comment has been added. A single line comment
	starts at a \`#' character and continues to the next end of the
	line.

	The user may create his own extensions file or use the defaults
	available at <https://github.com/mountaineerbr/scripts>. By de-
	faults, the extensions file should be placed at the same direc-
	tory as this script and named ${EXTFILE}.

	References:

		<http://x-bc.sourceforge.net/scientific_constants.bc>
		<http://x-bc.sourceforge.net/extensions.bc>
		<http://phodd.net/gnu-bc/>
		<http://www.pixelbeat.org/scripts/bc>


ZSHELL MATHFUNC MODULE
	Option -e will load zsh mathfunc module. The zshell mathfunc module
	is a library of floating point functions you can load (actually
	it's just a way of linking in the system mathematical library).
	The usual incantation is \`zmodload zsh/mathfunc'. The shell
	calculator zcalc also uses that module, see shell alises section
	in this script for more on that.

	Check \`man zshmodules' for zsh mathfunc module and \`man zshcontrib'
	for detailed explanation and mathematical function descriptions. 
	Below are some excerpts from man pages.

        An  arithmetic expression uses nearly the same syntax and as-
	sociativity of expressions as in C. In the native mode of oper-
	ation, the following operators are supported (listed in decreas-
	ing order of precedence):

		 + - ! ~ ++ --
			unary plus/minus, logical NOT, complement, 
			{pre,post}{in,de}crement
		 << >>  bitwise shift left, right
		 &      bitwise AND
		 ^      bitwise XOR
		 |      bitwise OR
		 **     exponentiation
		 * / %  multiplication, division, modulus (remainder)
		 + -    addition, subtraction
		 < > <= >=
			comparison
		 == !=  equality and inequality
		 &&     logical AND
		 || ^^  logical OR, XOR
		 ? :    ternary operator
		 = += -= *= /= %= &= ^= |= <<= >>= &&= ||= ^^= **=
			assignment
		 ,      comma operator


	The mathematical library \`zsh/mathfunc' will be loaded if it is
	available. Mathematical functions correspond to the raw system
	libraries, so trigonometric functions are evaluated using radians,
	and so on.

	Most functions take floating point arguments and return a float-
	ing point value. However, any necessary conversions from or to
	integer type will be performed automatically by the shell. Any
	arguments out of range for the function in question will be
	detected by the shell and an error reported.
	
	The following functions take a single floating point argument:
	acos, acosh,asin, asinh, atan, atanh, cbrt, ceil, cos, cosh, erf,
	erfc, exp, expm1, fabs, floor, gamma, j0, j1, lgamma, log, log10,
	log1p, log2, logb, sin,  sinh,  sqrt, tan, tanh, y0, y1. The atan
	function can optionally take a second argument, in which case it
	behaves like the C function atan2. The ilogb function takes a
	single floating point argument, but returns an integer.
	
	The functions min, max, and sum are defined in the zmathfunc
	autoloadable function, described in the section \`Mathematical
	Functions' in zshcontrib(1).


SHELL INTERPRETERS
	This script code is compatible with Bash and Zshell, even though
	it requires GNU utilities for some operations. If the script
	interpreter is bash, maths will be performed with bash bc. If
	interpreter is zsh, maths will use zsh internal built-ins.

	Change the script shebang or set option -z to rerun script with
	the zshell interpreter.

	Warning: some script functions will change slightly between
	shells.


ALIASES
	There are two interesting functions for using with pure bash bc
	interactively. Function (I) is really useful.

		(I)  function c() { bc -l <<< \"\$*\" ;}

		(II) alias c=\"bc -l <<<'\"


	In (II) user must type a \"'\" end quote mark after expression
	when using the alias every time, but avoids forgetting to type
	the start quote mark.

	For zshell, it may be useful to use alias and function interac-
	tions to avoid quoting expression. To alias this script, add to
	~/.zshrc:

		(III)  alias c='noglob /path/to/$SN'


	Use pure zsh maths evaluation built-in and zcalc; a calculator
	function called zcalc is bundled with the shell. You type a
	standard arithmetic expression and the shell evaluates the for-
	mula and prints it out. Typeset for fixed-point decimal notation
	of 10 decimal plates. To load zcalc execute \`autoload -Uz zcalc'.

		(IV)   alias c='noglob calcMain'
		      function calcMain() { (
				setopt forcefloat
				typeset -F 10 exp
				exp=\"\$*\"
				print \"\$exp\"
			) ;}
		
		(V) alias c='noglob zcalc -f -e'


DEFAULTS
	Script defaults are define in the head source code.

	Set special variables to change for previous results in the
	record file with variable \`\$BCHOLD'.

	Set the record file path with variable \`\$BCRECFILE'. If file
	does not exist, it will be initialised. To disable using a
	record file, just comment it out or set as blank.

	Defaults:
		\$BCHOLD=\"$BCHOLD\"
		\$BCRECFILE=\"$BCREC\"


WARRANTY
	This programme is licensed under GPLv3 and above. It is distrib-
	uted without support or bug corrections.

	Tested with GNU Bash 5.0 and ZSH 5.8. Requires GNU coreutils.

	If useful, please consider sending me a nickle! =)

		bc1qlxm5dfjl58whg6tvtszg5pfna9mn2cr2nulnjr

	  
BUGS
	Multiline input will skip output format settings defined with
	script options when using bash bc. Zsh cannot handle multiline.


USAGE EXAMPLES
	(I)   Escaping

		$ $SN '(-20-20)/2'
		
		$ $SN \\(20*20\\)/2

		$ $SN -- -3+30


	      Zshell precommand noglob:

		$ noglob $SN (20*20)/2


	(II)  Bash bc syntax to define reusable parameters within 
	      expression;  do note variables must be _lowercase_:

		$ $SN 'a=4; dog=1; cat=dog; a/(cat+dog)'

		
	(III) Scale (result = 0.33)

		$ $SN -s2 1/3

		$ $SN -2 1/3
		
		$ echo 0.333333333 | $SN -2


	      Thousand delimiter (result = 100,000,000.00)

		$ $SN -t 100000000


	      Bash bc accepts the following syntax in EXPRESSION:

		$ $SN 'scale=2; EXPRESSION'


	(IV)  Bash bc extensions

		$ $SN -e 'ln(0.3)'   #natural log function

		$ $SN -e 0.234*na    #na is Avogadro number


	(V)   Adding notes

		$ $SN -n This is my note.
		
		$ $SN -n '<This; is my w||*ird not& & >'
	

OPTIONS
	Record file
	-f 	Do not use a record file.
	-n TEXT	Add note to the last entry in record file.
	-r 	print last ${BCRECTAIL} lines.
	-rr 	Print entire record file.
	-R 	Edit record file with \$VISUAL or \$EDITOR;vdefaults=vi.
	-u 	Update result index.
	Extensions
	-e 	Load bc extensions/zsh mathfunc, unformatted output.
	-ee 	Print bc extensions (bash bc only).
	Output formatting
	-NUM 	Shortcut for scale setting, same as -sNUM.
	-s NUM	Set scale (decimal plates).
	-t 	Thousand delimiter in result, same as -o.
	Miscellaneous
	-, 	Set decimal separator as (,) and remove dots from user
		input.
	-. 	Set decimal separator as (.) and remove commas from
		user input.
	-b 	Run script with bash interpreter.
	-z 	Run script with zsh interpreter.
	-h 	Show this help page.
	-v 	Verbose output, may set multiple times.
	-V 	Print script interpreter and version."


#functions

#check for multiline input
checklinef()
{
	local eq line
	eq="$1"
	line=0

	while read
	do ((++line)) ;((line>1)) && break
	done <<<"$eq"

	case $line
	in
		0)
			#empty
			((OPTV>1)) && echo "$SN: input is empty" >&2
			;;
		1)
			#one-liner
			((OPTV>1)) && echo "$SN: one liner" >&2
			;;
		*)
			#multiline
			if (( ZSH_VERSION ))
			then
				print "$SN: err  -- zshell maths does not support multiline" >&2
				exit 1
			elif [[ -n "$OPTS$OPTT" ]]
			then
				echo "warning -- multiline skips formatting" >&2
			fi
			
			return 1
		;;
	esac

	#not multiline
	return 0
}

#calc new result
#load extensions & check result
calcf()
{
	local eq out
	eq="$1"

	#zshell
	if (( ZSH_VERSION ))
	then
		#if extensions opt is set
		#load mathfunc module
		(( OPTC == 1 )) && zmodload zsh/mathfunc

		#set float numbers
		setopt FORCE_FLOAT
		typeset -F "${OPTS:-$BCSCALE}" out

		out="$eq"
	#bash bc
	#if extensions opt is set
	elif (( OPTC ))
	then
		#path of bc extensions
		#if not under $PATH, may need setting full path
		#defaults=bcalc_ext.bc
		EXTFILE="$(dirname "$SCRIPT")/$EXTFNAME"

		#does extensions file exist?
		if [[ -e "$EXTFILE" ]]
		then
			#load extensions before user expression
			out="$( bc -l "$EXTFILE" <<<"scale=${OPTS:-$BCSCALE} ; ${eq%;} / 1" )"
		else
			echo "$SN: err: extensions file not available -- $EXTFILE" >&2
			exit 1
		fi
	else
		#don't load extensions
		out="$( bc <<<"scale=${OPTS:-$BCSCALE} ; ${eq%;} / 1" )"
	fi

	#error on empty output (calculation err)
	echo "${out:?$SN: err  -- ${eq}}"
}

#try to get results from record file
#WARNING: this will reset $EQ 
getresf()
{
	local res index eq i
	#input equation
	eq="$2"
	i="$1"

	#get index or last index if empty
	if ((i>0))
	then index="$i" || return 1
	else index="$(lastindexf)" || return 1
	fi

	#get result
	res="$(sed -nE "s/(.*)#+\s*${index}#+\s*$/\1/ p" "$BCRECFILE")"
	res="${res//[$'\t' ]}"  #get rid of empty spaces

	#check $res and substitute in equation
	if [[ -z "$res" ]]
	then
		echo "error: cannot retrieve special variable index -- $index" >&2
		return 1
	fi
	VARINDEX+=( $index )
	
	#reset result in $EQ
	EQ="$(sed -E "s/\<($BCHOLD)([0-9]*)?\>/${res}/" <<<"$eq")"
}

#-n add note function
notef()
{
	if [[ -n "$*" ]]
	then
		sed -i "$ i\>> $*" "$BCRECFILE"
	else
		echo "warning -- note is empty" >&2
		false
	fi
}
#https://superuser.com/questions/781558/sed-insert-file-before-last-line
#http://www.yourownlinux.com/2015/04/sed-command-in-linux-append-and-insert-lines-to-file.html

#-eecc print extensions to user
opteef()
{
	#does extensions file exist?
	if [[ ! -e "$EXTFILE" ]]
	then
		echo "$SN: err: extensions file not available -- $EXTFILE" >&2
		return 1
	#check whether zsh is running
	elif (( ZSH_VERSION ))
	then
		print "$SN: warning: for zsh, check zsh/mathfunc" >&2
	fi

	#print bc extensions
	cat "$EXTFILE"
}

#print or edit record file
precff()
{
	#edit record file
	if ((OPTP<0))
	then command "${VISUAL:-${EDITOR:-vi}}" "$BCRECFILE"
	#print record file tail
	elif ((OPTP==1))
	then tail -n"${BCRECTAIL:-10}" "$BCRECFILE"
	#print entire record file
	elif ((OPTP))
	then cat "$BCRECFILE"
	fi
}

#print equation and result to record file
recfilef()
{
	#WARNING: $INDEX is used elsewhere
	local eq eqlast line res ret
	typeset -a eqlast
	eq="$1"
	res="$2"

	#grep last expression in history
	while read line
	do eqlast+=( "$line" )
	done <<< "$( tail "$BCRECFILE" | sed -n 's/^## { \(.*\) }\s*$/\1/p' )"

	#check record for last equation duplicates
	if [[ "${eq//[$'\t' ]}" != "${eqlast[-1]//[$'\t' ]}" ]]
	then
		ret=0
		#get last result and add one
		INDEX="$(lastindexf)"
		INDEX="$((INDEX+1))" 2>/dev/null

		#append timestamp, equation and result
		cat >>"$BCRECFILE" <<-!
		## $( date "+%FT%T%Z" )
		## { $eq }
		$res 	#${INDEX}#
		!
	fi

	return "${ret:-1}"
}

#update equation index in record file
updateindexf()
{
	local i index lnum map maplength sedeq batch REPLY

	map=( $(grep -nv -e '^[>#]' -e '^\s*$' -ve '\\[\s\t]*$' "$BCRECFILE" | cut -d: -f1) )
	maplength="${#map[@]}"
	maplength="${#maplength}"
	batch=280

	for lnum in "${map[@]}"
	do
		((++i))
		sedeq="${sedeq}${sedeq+ ;}${lnum}s/[\t\s]*(#+[0-9 ]*#+\s*)?$/\t#${i}#/"

		#feedback 
		printf 'results: %*d/%*d  \r' "${#maplength}" "$i" "${#maplength}" "${#map[@]}" >&2

		#update record file in batches
		if ((i%batch==0))
		then
			sed -i -E "$sedeq" "$BCRECFILE" || return
			unset sedeq
		fi
	done
	echo >&2
		
	#update record file in batches if nay left
	if ((i%batch))
	then sed -i -E "$sedeq" "$BCRECFILE" || return
	else true
	fi
}

#get last equation index from record file
lastindexf()
{
	local ids
	typeset -a ids

	ids=( $( sed -nE '/^[^#>]/ s/.*#+\s*([0-9]+)#+\s*$/\1/p' "$BCRECFILE") )
	[[ -n "${ids[-1]}" ]] 2>/dev/null || return 1
	echo "${ids[-1]}"
}


#parse options
while getopts :,.0123456789cefhnorRs:tuvVz opt
do
	case $opt in
		,)
			#clean and change input (and output) decimal separator
			OPTDEC+=,
			;;
		\.)
			#clean and change input (and output) decimal separator
			OPTDEC+=.
			;;
		[0-9])
			#scale, same as '-sNUM'
			OPTS="$OPTS$opt"
			;;
		c|e)
			#load or print bc extensions
			if ((OPTC))
			then
		      		#print bc extensions and exit
				opteef
				exit
			else
				((++OPTC))
			fi
			;;
		f)
			#disable record file
			unset BCRECFILE
			;;
		h)
			#show this help
			echo "$HELP_LINES"
			exit
			;;
		n)
			#add note to record
			((++OPTN))
			;;
		r)
			#print record
			((++OPTP)) 
			;;
		R)
			#edit record
			OPTP=-100
			;;
		s)
			#scale (decimal plates)
			OPTS="$OPTARG"
			;;
		t|o)
			#thousand separator
			OPTT="'"
			;;
		u)
			#update equation index in record file
			OPTU=1
			;;
		v)
			#verbose
			((++OPTV))
			;;
		V)
			#show this script version
			echo "${ZSH_VERSION:-BASH}  ${BASH_VERSION:-ZSH}" 
			grep -m1 '^\# v' "$SCRIPT"
			exit
			;;
		z)
			#change interpreter to zsh
			if [[ -z "$ZSH_VERSION" ]]
			then
				zsh "$SCRIPT" "$@"
				exit
			fi
			;;
		\?)
			#is that punctuation?
			PASS='!?"#$%&@[]\\^_`{|}~(),.-/:<=>'
			if [[ "$OPTARG" = ["$PASS"]* ]]
			then
				((OPTV)) && echo "$SN: err  -- try escaping EXPRESSION" >&2

				OPTIND="$(( --OPTIND ))"
				(( OPTIND )) || (( ++OPTIND ))
				break
			fi

			echo "$SN: invalid option -- -$OPTARG" >&2
			exit 1
			;;
	esac
done
shift $(( --OPTIND ))

#bash or zsh arrays?
BZ="${ZSH_VERSION+1}${BASH_VERSION+0}"

#check if there is any positional arguments
if (($#))
then
	EQ="$*"
#stdin input, only if some opts are not set
elif (( OPTN + OPTP + OPTU == 0))
then
	#capture user input or pipe (one line)
	#<ctrl-d> = EOF
	[[ -t 0 ]] && ((OPTV)) && echo "$SN: flush user input with Ctrl+D" >&2
	
	#EQ="${EQ:-"$( read ;echo "$REPLY" )"}"
	EQ="${EQ:-"$(</dev/stdin)"}"
fi

#copy original value
#get rid of ending ;
EQ_ORIG="$EQ"
EQ="${EQ%;}"
#is input a simple request of special variable? eg. "res3900"
SIMPLEVAREQ="$( grep -Ec "^\s*(${BCHOLD:-#*#*})[0-9]*\s*$" <<<"$EQ_ORIG" )"

#use result record file?
if [[ -n "$BCRECFILE" ]]
then
	typeset -a VARINDEX eqvars
	#init if it does not exist
	if [[ ! -e "$BCRECFILE" ]]
	then
		echo -e "## ${SN^^} RECORD\n" >> "$BCRECFILE" || exit 1
		echo "$SN: record file init -- $BCRECFILE" >&2
	fi
	#check if it exists on disk
	if [[ ! -e "$BCRECFILE" ]]
	then
		echo "$SN: err  -- cannot create record file -- $BCRECFILE" >&2
		exit 1
	fi

	#call some opt functions
	if (( OPTN ))
	then
		#add note to record
		notef "$*"
		exit
	elif (( OPTP ))
	then
		#print or edit record file
		precff
		exit
	elif (( OPTU ))
	then
		#update equation index in record file
		updateindexf
		exit
	fi
	
	#change $BCHOLD to results in recod file
	#or use last entry if $EQ is empty
	while
		EQ="${EQ:-${BCHOLD##*|}}"
		eqvars=( $(grep -oE "\<(${BCHOLD:-#*#*})([0-9]*)\>" <<<"$EQ") )
	do
		#get $BCHOLD index
		#substitute in equation by special var index
		getresf "${eqvars[BZ]//[^0-9]}" "$EQ"
		[[ -n "${EQ:?$SN: err  -- equation is empty}" ]]
	done
	unset eqvars
#error handling for some options
elif ((OPTN+OPTP+OPTU)) || grep -qE "\<(${BCHOLD:-#*#*})([0-9]*)\>" <<<"$EQ"
then
	echo "$SN: err  -- record file is required" >&2
	exit 1
fi

#change decimal separator of user input?
#dot decimal separator
if [[ "$OPTDEC" = .* ]]
then
	EQ="${EQ//,}"
#comman is decimal separator
elif [[ "$OPTDEC" = ,* ]]
then
	EQ="${EQ//.}"
	EQ="${EQ//,/.}"
fi

#did input change?
((OPTV && SIMPLEVAREQ==0)) && [[ "$EQ" != "$EQ_ORIG" ]] &&
	echo "input change -- $EQ" >&2

#check for bad input (dots and commas)
#for ex: '1.2.', '1,2,', '1.2,3.',  ',.,'  
if [[
	"$EQ" =~ [0-9]*[.][0-9]*[.] ||
	"$EQ" =~ [0-9]*[,][0-9]*[,] ||
	"$EQ" =~ [0-9]*[.][0-9]*[,][0-9]*[.] ||
	"$EQ" =~ [0-9]*[,][0-9]*[.][0-9]*[,] 
]]
then
	#just print a waning
	echo "warning: possible excess of decimal separators  -- $EQ" >&2
fi

#check if input is one-liner
checklinef "$EQ" || MULTILINE=1

#calc new result
#load extensions & check result
RES="$(calcf "$EQ")" || exit

#print to record file?
#don't try this with multiline input
#don't record duplicate results from special variables 
if [[ -n "$BCRECFILE" ]] &&
	((MULTILINE+SIMPLEVAREQ==0))
then
	recfilef "$EQ" "$RES"
fi

#format and print result
#raw if opt -c is set
if [[ -z "$OPTS$OPTT" && -n "$OPTC" ]] ||
	((MULTILINE))
then
	#raw output
	RES="$RES"

#if scale -s[NUM] or thousand separator -t is set
elif [[ -n "$OPTS$OPTT" ]]
then
	#user-set scale; thousand separator
	RES="$(printf "%${OPTT}.*f\n" "${OPTS:-2}" "$RES")"
	#printf honours LANG and LC_NUMERIC for floating point number format

#bash hack to remove tailing zeroes
elif [[ -z "$ZSH_VERSION" ]]  #&& ((MULTILINE==0))
then
	#trim trailing zeroes from result
	#bc func to trim zeroes of one-line result
	RES="$(
		bc <<-!
		define trunc(x){auto os;scale=${OPTS:-200};os=scale;
		for(scale=0;scale<=os;scale++)if(x==x/1){x/=1;scale=os;return x}};
		trunc($RES)
		!
	)"
else
	#trim traling zeroes with sed
	RES="$(sed '/\./ s/\.\{0,1\}0\{1,\}$//' <<<"$RES")"

fi

#print special variable index, too?
((OPTV)) && ((${INDEX:-${VARINDEX[BZ]}})) &&
	RES+="    #${INDEX:-${VARINDEX[*]}}#"

#change output decimal and thousands separators?
if [[ "$OPTDEC" = *, ]]
then tr ., ,. <<<"$RES"
else echo "$RES"
fi

