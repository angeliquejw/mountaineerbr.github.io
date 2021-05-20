#!/bin/bash
#!/bin/zsh
# bcalc.sh -- shell maths wrapper
# v0.12.3  may/2021  by mountaineerbr

#defaults
#script path
SCRIPT="$0"
#script name
SN="${0##*/}"

#record file path
#comment it out to disable
#defaults="$HOME/.bcalc_record"
BCRECFILE="$HOME/.bcalc_record"

#extensions file, set full path if not under $PATH
#defaults=bcalc_ext.bc
EXTFNAME="${SN%.sh}"_ext.bc

#special variables to hold last result
#requires record file
BCHOLD='ans|res'

#scale
BCSCALE=16

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

#possible index delimiters
INDEL='<#%\\@/=>'
INDELR='%'  #right
INDELL='%'  #left

#word archors
WORDANCHOR='[^a-zA-Z0-9_]'

#man page
HELP_LINES="NAME
	$SN -- shell maths wrapper


SYNOPSIS
	$SN  [-,.eftv] [-sNUM|-NUM] EXPRESSION
	$SN  [-eehrrRuV]
	$SN  -n TEXT


DESCRIPTION
	$SN wraps Bash calculator (bc) and Zshell maths evaluation and
	adds some useful features.

	Input EXPRESSION should preferably be one-liner and may need
	escaping.

	A record file (a history) is stored at \`${BCRECFILE}'.
	To disable the record file, set script option -f.

	If a record file is available, special variables can be used to
	retrieve results from former operations. These variables are re-
	placed before maths evaluation. For example, \`${BCHOLD##*|}' or \`${BCHOLD##*|}0'
	will be changed to the last result, however \`${BCHOLD##*|}1' and so forth
	will be changed to the specified result index. Check results index
	with option -v. Update the record file index with option -u.
	Defaults special variables \`${BCHOLD//|/\' and \'}'.

	If no EXPRESSION is given and stdin is not free, reads stdin as
	input, otherwise prints last result from record file. If record
	file cannot be used then ask for user input, in which case press-
	ing <CTRL+D> sends the EOF signal and flush user input.

	Scale can be set with -sNUM. User may set scale in bash bc via
	\`scale=NUM ; [EXPRESSION]' syntax before user EXPRESSION, in
	which NUM is an integer.

	In bash bc, decimal plates (scale) of floating point numbers is
	dependent on user input for all operations except division. How-
	ever, script defaults scale to ${BCSCALE}.

	In zshell maths, floating point evaluation is performed auto-
	matically depending on user input. Note that \`3' is an integer
	while \`3.' is a floating point number. Zsh keeps an internal
	double-precision floating point representation (double C type)
	of numbers, hence expression \`3/4' evaluates to \`.75' rather
	than \`0'. Also note that results will be converted back to the
	closest decimal notation from the internal double-point.

	Trailing zeroes will be trimmed unless extensions option -e
	is set, in which case result is printed in raw format.

	Option -e loads bash bc extension file or zshell mathfunc module.
	Bash bc is more powerful. For example, bash bc accepts setting
	variables in the begining of EXPRESSION, while zshell maths does
	not. Bash bc has more extensions developed by the community over
	the years. See their respective description sections below. The
	defaults extension file should be located at the same path as
	$SN and named ${EXTFILE}.

	Multiline input will skip result format defined with script opt-
	ions when using bash bc. Zsh cannot handle multiline. Multiline
	resuts are not appended to the record file.


DECIMAL AND THOUSANDS SEPARATOR
	Decimal separator defaults to a dot (.). User can manually set
	-. for defining dot as decimal separator ot -, to set (,) comma
	as decimal separator (for input and output). Beware that some
	bash bc and zsh functions may use comma as operators.

	Option -t prints thousands separator in result. Note that there
	is an important limitation with option -t : result numbers cannot
	exceed 20 decimal plates worth of length in bash and 16 digits
	in zshell. This option can be combined with -., .


	Set option -, if decimal separator of EXPRESSION input is comma (,) :
		
		(input) 	    (input) 	    (output)
		1.234.567,00 	--> 1234567.00 	--> 1234567,00


	Set option -. if decimal separator of EXPRESSION input is dot (.) :

		(input) 	    (input) 	    (output)
		1,234,567.00 	--> 1234567.00 	--> 1234567.00


	Set option -t to print thousands separator in result:

		(input) 	    (output)
		1234567.00 	--> 1,234,567.00


	Strictly, setting \`-..' means to treat input with (.) dot as
	decimal separator and to print output with . with decimal sep-
	arator. Rather, setting \`-.,' means input decimal separtor is .
	and to print output with decimal separator (,) comma.


BASH BC STANDARD FUNCTIONS
	There are a few functions provided in bc enabled by defaults
	named user-defined and standard functions. They appear as
	\"name(parameters)\". The standard functions are:
	
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
	more functions, as well as external extensions.
	
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
	math functions such as \`ln(x)' (natural log) and \`log(x)' (base
	10). Run the script with option -ee to print extensions file.

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

		(I) 	function c() { bc -l <<< \"\$*\" ;}

		(II) 	alias c=\"bc -l <<<'\"


	In (II) user must type a \"'\" end quote mark after expression
	when using the alias every time, but avoids forgetting to type
	the start quote mark.

	For zshell, it may be useful to use alias and function interac-
	tions to avoid quoting expression. To alias this script, add to
	~/.zshrc:

		(III) 	alias c='noglob /path/to/$SN'


	Use pure zsh maths evaluation built-in and zcalc; a calculator
	function called zcalc is bundled with the shell. You type a
	standard arithmetic expression and the shell evaluates the for-
	mula and prints it out. Typeset for fixed-point decimal notation
	of 10 decimal plates. To load zcalc execute \`autoload -Uz zcalc'.

		(IV) 	alias c='noglob calcMain'
			function calcMain() { (
				setopt forcefloat
				typeset -F 10 exp
				exp=\"\$*\"
				print \"\$exp\"
			) ;}
		
		(V) 	alias c='noglob zcalc -f -e'


DEFAULTS
	Script defaults are define in the head source code.


	\$BCHOLD=\"$BCHOLD\"
		Special variable names that will be changed to results
		from record file index. Multiple variable names can be
		set separated by | .

	\$BCRECFILE=\"$BCRECFILE\"
		Record (history) file path. If file does not exist, it
		will be initialised. To disable using a record file,
		comment it out or set as blank.


WARRANTY
	This programme is licensed under GPLv3 and above. It is distrib-
	uted without support or bug corrections.

	Tested with GNU Bash 5.0 and ZSH 5.8. Requires GNU coreutils.

	If useful, please consider sending me a nickle! =)

		bc1qlxm5dfjl58whg6tvtszg5pfna9mn2cr2nulnjr

	  
BUGS
	Bash and Zsh have got decimal precision limits in their builtin
	maths and/or \`printf' function (option -t). Scale should not
	exceed 20 decimal plates worth of length in bash and 16 digits
	in Zsh.

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
	Miscellaneous
	-b 	  Run script with bash interpreter.
	-z 	  Run script with zsh interpreter.
	-h 	  Show this help page.
	-v 	  Verbose output, may set multiple times.
	-V 	  Print script interpreter and version.
	Record File
	-f 	  Disable use of record file.
	-n TEXT	  Add note to the last entry/result.
	-r 	  Print last ${BCRECTAIL} lines.
	-rr 	  Print entire record file.
	-R 	  Edit with \$VISUAL or \$EDITOR; defaults=vi.
	-u 	  Update result index.
	Extensions
	-e, -c 	  Load bc extensions/zsh mathfunc.
	-ee, -cc  Print bc extensions (bash bc).
	Input and Output Formatting
	Formatting
	-, 	  Set input/output decimal separator as (,) comma.
	-. 	  Set input/output decimal separator as (.) dot.
	-NUM 	  Shortcut for scale setting, same as -sNUM.
	-s NUM	  Set scale (decimal plates).
	-t, -o 	  Thousand delimiter in result."


#functions
#check for multiline input
checklinef()
{
	local eq line REPLY
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

	#get result, remove empty spaces
	res="$(sed -nE "s/(.*)[${INDEL}]+\s*${index}[${INDEL}]+\s*$/\1/ p" "$BCRECFILE")"
	res="${res//[$'\t' ]}"

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
	then tail -n"${1:-${BCRECTAIL:-10}}" "$BCRECFILE"
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
	eq="${1//[$'\t' ]}"
	res="${2//[$'\t' ]}"

	#grep last expression in history
	while read line
	do eqlast+=( "${line//[$'\t' ]}" )
	done <<<"$(tail -- "$BCRECFILE" | sed -n 's/^## { \(.*\) }\s*$/\1/p')"

	#check record for last equation duplicates
	if [[ "${eq}" != "${eqlast[-1]}" 
		&& "${eq}${BCHOLDUSED+@}" != "${res}@" ]]
	then
		ret=0
		#get last result and add one
		INDEX="$(($(lastindexf) + 1))" 2>/dev/null

		#append timestamp, equation and result
		cat >>"$BCRECFILE" <<-!
		## $( date "+%FT%T%Z" )
		## { $eq }
		$res 	${INDELL}${INDEX}${INDELR}
		!
	#if result is the same as last result
	elif [[ -n "$OPTV" && "${res}" != "${eqlast[-1]}" ]]
	then
		#get last result index
		INDEX="$(lastindexf)"
	fi

	return "${ret:-1}"
}

#update equation index in record file
updateindexf()
{
	local i index lnum map maplength sedeq batch REPLY

	#map lines that don't start with either >#, are not empty lines or have line break \
	map=( $(grep -nv -e '^[>#]' -e '^\s*$' -e '\\[\s\t]*$' "$BCRECFILE" | cut -d: -f1) )
	maplength="${#map[@]}"
	maplength="${#maplength}"
	batch=280

	for lnum in "${map[@]}"
	do
		((++i))
		sedeq="${sedeq}${sedeq+ ;}${lnum}s/[\t\s]*([${INDEL}]+[0-9 ]*[${INDEL}]+\s*)?$/\t${INDELL}${i}${INDELR}/"
		#index delimiter may be any of $INDEL

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

	ids=( $( sed -nE "/^[^#>]/ s/.*[${INDEL}]+\s*([0-9]+)[${INDEL}]+\s*$/\1/p" "$BCRECFILE") )
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
			PUNC='?"#$%&@[]\\^_`{|}~(),.-/:<=>'
			if [[ "$OPTARG" = [!"$PUNC"]* ]]
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

#set shell options
#bash and zsh arrays
BZ="${ZSH_VERSION+1}${BASH_VERSION+0}"

#check if there is any positional arguments
if (($#))
then
	EQ="$*"
#stdin input, only if some opts are not set and stdin is not free
elif ((OPTN+OPTP+OPTU==0))
then
	#if stdin not free, capture user input; <ctrl-d> = EOF
	#or from pipe (one line)
	if [[ ! -t 0 ]]
	then
		EQ="$(</dev/stdin)"
	#if there is no $BCRECFILE set, ask for user input
	elif [[ -z "$BCRECFILE" ]]
	then
		((OPTV)) && echo "$SN: flush user input with Ctrl+D" >&2
		EQ="$(</dev/stdin)"
		EQ="${EQ:?$SN: err  -- user input required}"
	else
		#
		EQLASTREC=1
	fi
fi

#copy original value
#get rid of ending ;
EQ_ORIG="$EQ"
EQ="${EQ%;}"
#is input a simple request of special variable? eg. "res3900"
[[ "$EQ" =~ ^\s*(${BCHOLD:-@%@%})[0-9]*\s*$ ]] && SIMPLEVAREQ=1

#use result record file?
if [[ -n "$BCRECFILE" ]]
then
	typeset -a VARINDEX eqvars
	#init if it does not exist
	if [[ ! -e "$BCRECFILE" ]]
	then
		echo -e "## ${SN} Record\n" >> "$BCRECFILE" || exit 1
		echo "$SN: record file init -- $BCRECFILE" >&2

		#check if it exists on disk
		if [[ ! -e "$BCRECFILE" ]]
		then
			echo "$SN: err  -- cannot create record file -- $BCRECFILE" >&2
			exit 1
		fi
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
		precff "$@"
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
		[[ "$EQ" =~ (^|$WORDANCHOR)(${BCHOLD:-@%@%})[0-9]*($WORDANCHOR|$) ]]
	do
		eqvar="${BASH_REMATCH[BZ]:-$MATCH}"
		eqvar="${eqvar#$WORDANCHOR}"
		eqvar="${eqvar%$WORDANCHOR}"
		#get $BCHOLD index
		#substitute special var in $EQ and set $VARINDEX
		getresf "${eqvar//[^0-9]}" "$EQ" || exit

		[[ -n "${EQ:?$SN: err  -- equation is empty}" ]]
		((++BCHOLDUSED))
	done
	unset eqvar
#error handling for some options
elif ((OPTN+OPTP+OPTU)) ||
	[[ "$EQ" =~ (^|$WORDANCHOR)(${BCHOLD:-@%@%})[0-9]*($WORDANCHOR|$) ]]
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
((OPTV && SIMPLEVAREQ==0)) \
&& [[ "$EQ" != "$EQ_ORIG" ]] \
&& echo "input change -- $EQ" >&2

#check for bad input (dots and commas)
#for ex: 1.2. 1,2, 1.2,3.  ,.,  
if [[
	"$EQ" =~ [0-9]*[.][0-9]*[.] ||
	"$EQ" =~ [0-9]*[,][0-9]*[,] ||
	"$EQ" =~ [0-9]*[.][0-9]*[,][0-9]*[.] ||
	"$EQ" =~ [0-9]*[,][0-9]*[.][0-9]*[,] 
]]
then
	#print a warning
	echo "warning: possible excess of decimal separators  -- $EQ" >&2
fi

#check if input is one-liner
checklinef "$EQ" || MULTILINE=1

#calc new result
#load extensions & check result
RES="$(calcf "$EQ")" || exit

#print to record file?
#dont try this with multiline input
#dont record duplicate results from special variables 
if [[ -n "$BCRECFILE" ]] && ((MULTILINE+SIMPLEVAREQ+EQLASTREC==0))
then recfilef "$EQ" "$RES"
fi

#format and print result
#raw if opt -c is set
if [[ -z "$OPTT" && -n "$OPTC$OPTS" ]] || ((MULTILINE))
then
	#raw output
	RES="$RES"

#if scale -s[NUM] or thousand separator -t is set
elif [[ -n "$OPTT" ]]
then
	#check shell number length limits for printf and internal maths
	if [[
		( -n "$BASH_VERSION" && "$OPTS" -gt 20 )
		|| ( -n "$ZSH_VERSION" && "$OPTS" -gt 16 )
	]]
	then
		echo "$SN: error  -- scale out of range for option -t"
		RES="$RES"  RET=1
	else
		#user-set scale; thousand separator
		RES="$(printf "%${OPTT}.*f\n" "${OPTS:-2}" "$RES")"
		#printf honours LANG and LC_NUMERIC for floating point number format
	fi

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
((OPTV)) \
&& ((${INDEX:-${VARINDEX[BZ]}})) \
&& RES+="	 #${INDEX:-${VARINDEX[*]}}#"

#change output decimal and thousands separators?
if [[ "$OPTDEC" = *, ]]
then tr ., ,. <<<"$RES"
else echo "$RES"
fi

exit "${RET:-0}"

