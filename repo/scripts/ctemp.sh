#!/bin/bash
# Convert amongst temperature units
# v0.4.8  feb/2021  by mountaineerbr

#defaults

#scale
SCALEDEF=2

#script name
SN="${0##*/}"

#temporary file for toggling temp convertion c <> f
TOGGLETTEMP="/tmp/$SN.$USER.togglet"

#make sure locale is set correctly
export LC_NUMERIC=C

#help
HELP="$SN - Convert amongst temperature units


SYNOPSIS
	$SN [-r] [-sNUM] TEMP [c|f|k] [c|f|k]


	The default function is to convert amongst absolute temperatures.
	For example, if it is 45 degrees Fahrenheit outside, it is 7.2
	degrees Celsius. TEMP is a floating point number and can be a
	simple arithmetic expression.

	If no unit is given, toggling between Celsius and Fahrenheit
	units will be activated for absolute temperature conversions.
	Toggling creates a temporary file at $TOGGLETTEMP .

	Option -r deals with relative temperatures conversions; for
	example, a change of 45 degrees Fahrenheit corresponds to a
	change of 25 degrees Celsius. 

	Option -s sets scale, NUM must be an integer; defaults=$SCALEDEF .

	Temperature unit conversions are nonlinear; for example, temper-
	ature conversions between Fahrenheit and Celsius scales cannot
	be done by simply multiplying by conversion factors. These equa-
	tions can only be used to convert from one specific temperature
	to another specific temperature; for example, you can show that
	the specific temperature of 0.0 Celsius equals 32 Fahrenheit, or
	that the specific temperature of 100 Celsius equals 212 Fahrenheit.
	However, a temperature difference of 100 degrees in the Celsius
	scale is the same as a temperature difference of 180 degrees in
	the Fahrenheit scale.

	If script shebang is changed from bash to zsh, zsh builtin maths
	will be used intead of bash bc.


FORMULAS
	Formulas for absolute temperature convertions.
		Tc  = (5/9)*(Tf-32)
		Tf  = (9/5)*Tc+32
		Tk  = Tc+273.15

	Equivalences of absolute temperatures.
		37C =   98.60 F
		98F =   36.63 C
		 0K = -273.15 C

	Equivalences of relative temperature differences.
		45K =   25 C
		25C =   45 K
		25C =   25 K


SEE ALSO
	Please check Adrian Mariano's package \`units' and read manual
	section \`Temperature Conversions':
	<https://www.freebsd.org/cgi/man.cgi?query=units&sektion=1>

	Doctor FWG's post on temperature differences:
	<https://web.archive.org/web/20180705003041/http://mathforum.org/library/drmath/view/58418.html>
	
	Multiplications should be before divisions to avoid losing
	precision if scale is small:
	https://www.linuxquestions.org/questions/ubuntu-63/shell-script-to-convert-celsius-to-fahrenheit-929261/


WARRANTY
	This programme is licensed under GNU GPLv3 and above. It is
	distributed without support or bug corrections.

	Tested with GNU Bash 5.0 and Zsh 5.8.

	If useful, please consider sending me a nickle!
		=)

		bc1qlxm5dfjl58whg6tvtszg5pfna9mn2cr2nulnjr


USAGE EXAMPLES
	$ $SN 10
	$ $SN 10 c
	$ $SN 10 f k
	$ $SN -s4 10cf
	$ $SN -r -- 10cf
	$ $SN -- -273.15 C K


OPTIONS
	-r 	Convert relative temperatures.
	-s NUM	Set scale; defaults=$SCALEDEF ."


#functions

#convert amongst absolute temps
absolutef()
{
	#don't calculate if $FROMT = $TOT
	dontf "$*" || return

	#from fahrenheit
	if [[ "$FROMT" = f ]] || [[ -z "$FROMT" && "$*" != "$TOGGLET" ]]
	then
		#toggle
		[[ -z "$FROMT" ]] && TOGGLET="$*"
	
		#to celsius
		if [[ -z "${TOT/c}" ]]
		then printf '%s  C\n' "$( calcf "( (${1}) - 32) * 5/9" )"
		#to kelvin
		else printf '%s  K\n' "$( calcf "( ( (${1}) - 32) * 5/9) + 273.15" )"
		fi
	#from celsius
	elif [[ "$FROMT" = c ]]  || [[ -z "$FROMT" && "$*" = "$TOGGLET" ]]
	then
		#toggle
		[[ -z "$FROMT" ]] && unset TOGGLET
	
		#to fahrenheit
		if [[ -z "${TOT/f}" ]]
		then printf '%s  F\n' "$( calcf "( (${1}) * 9/5) + 32" )"
		#to kelvin
		else printf '%s  K\n' "$( calcf "(${1}) + 273.15/1" )"
		fi
	#from kelvin
	else
		#to celsius
		if [[ -z "${TOT/c}" ]]
		then printf '%s  C\n' "$( calcf "(${1}) - 273.15/1" )"
		#to fahrenheit
		else printf '%s  F\n' "$( calcf "( ( (${1}) - 273.15) * 9/5) + 32" )"
		fi
	fi
	
}
#helper, cut out unit
_absolutef()
{
	local RES=( $( absolutef "$@" ) )
	echo "${RES[0]}"
}

#calculator command
calcf()
{
	bc -l <<<"scale=${SCALE}; $*"
}

#don't convert
dontf()
{
	if [[ "${FROMT:-x}" = "$TOT" ]]
	then
		printf '%s  %s\n' "$*" "$TOT"
		return 2
	fi
	return 0
}

#convert amongst relative temps
relativef()
{
	#don't calculate if $FROMT = $TOT
	dontf "$*" || return

	#from farenheit or kelvin
	if [[ "$FROMT$TOT" = [fk] ]] || [[ -z "$FROMT" && "$*" != "$TOGGLET" ]]
	then
		#toggle
		[[ -z "$FROMT" ]] && TOGGLET="$*"
	
		TOT=c
	#from celsius
	elif [[ "$FROMT$TOT" = c ]] || [[ -z "$FROMT" && "$*" = "$TOGGLET" ]]
	then
		#toggle
		[[ -z "$FROMT" ]] && unset TOGGLET
	
		TOT=f
	fi
	
	#normalise temp unit for comparison in kelvin
	KZERO="$( TOT=k _absolutef 0)"
	KVAR="$( TOT=k _absolutef "$1")"
	KDELTA="$( calcf "$KVAR - ( $KZERO )" )"

	#transform kelvin delta in target temp delta
	TZERO="$( FROMT=k _absolutef 0 )"
	TVAR="$( FROMT=k _absolutef "$KDELTA" )"
	TDELTA="$( calcf "$TVAR - ( $TZERO )" )"

	printf '%s  %s\n' "$TDELTA" "$TOT"
}


#parse opts
while getopts hHs:S:dDrR c
do
	case $c in
		[hH])
			#help
			echo "$HELP"
			exit 
			;;
		[dDrR])
			#relative temps
			OPTR=relative
			;;
		[sS]) 
			#scale
			SCALE="${OPTARG%%[.,]*}"
			;;
		?)
			exit 1
			;;
	esac
done
shift $(( OPTIND - 1 ))
unset c

#set all args to lowercase
set -- "${@,,}"
#change comma to dot
set -- "${@/,/.}"

#are there no arguments?
if ((${#@}==0))
then
	#usage help
	echo "$HELP" >&2
	exit 1
elif
	#are there illegal temperature units?
	ILLEGAL='abdeg-jl-z'
	[[ "$*" = *[${ILLEGAL}]* ]]
then
	printf '%s: err: illegal units -- %s\n' "$SN" "${*//[^${ILLEGAL}]}" >&2
	exit 2
fi

#set defaults if $SCALE contains letters
if [[ "$SCALE" = *[a-zA-Z]* ]]
then
	printf '%s: err: option -s requires an integer -- %s\n' "$SN" "$SCALE" >&2
	exit 1
#set scale to defaults if not set by the user
elif [[ -z "$SCALE" ]]
then
	SCALE="$SCALEDEF"
fi

#units array
UNITS=( $( grep -o '[a-z]' <<<"$*" ) )
set -- "${@//[a-z]}"

#from-unit is always the first
(( ${#UNITS[@]} )) && FROMT="${UNITS[0]}"

#to-unit is always the last
(( ${#UNITS[@]} > 1 )) && TOT="${UNITS[-1]}"

#load $TOGGLET
[[ -z "$FROMT" && -r "$TOGGLETTEMP" ]] && TOGGLET="$( head -1 "$TOGGLETTEMP" )"

#select conversion type
if [[ -n "$OPTR" ]]
then relativef "$@"
else absolutef "$@"
fi
code="$?"

#set toggle temp file?
if [[ -n "$TOGGLET" ]]
then
	#make the toggle file
	if ! echo "$TOGGLET" >"$TOGGLETTEMP"
	then
		printf '%s: err: cannot create tmp file -- %s\n' "$SN" "$TOGGLETTEMP" >&2
		exit 1
	fi
elif [[ -f "$TOGGLETTEMP" ]]
then
	#remove temp file
	rm "$TOGGLETTEMP" || exit
fi

exit "${code:-0}"

