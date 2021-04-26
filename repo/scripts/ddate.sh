#!/bin/bash
# v0.8.9  apr/2021  by mountaineerbr
# calculate time ranges in different units
# convert between human and UNIX time formats

#script name
SN="${0##*/}"

#human date format for output printing
#user may set $FMT
#FMT=+%FT%T%Z

#by defaults, unset output format
#use GNU date defaults
FMTDEF=--

#default date
DATEDEF=now

#ISO8601 TZ timestamp format
#GNU date compatible
#ns for nanoseconds
FMTISO=--iso-8601=seconds

#generic result display (B)
#year
#gregorian           = 31556952  365.2425
#julian astronomical = 31557600  365.25
#common year         = 31536000  365
#leap year           = 31622400  366
#month
#29 days = 2505600
#30 days = 2592000
#31 days = 2678400 
#see also: https://pumas.nasa.gov/files/04_21_97_1.pdf
DAYYEAR=365.2425

#set locale
export LC_NUMERIC=en_US.UTF-8

#export timezone var
export TZ

HELP="NAME
	$SN - Calculate time ranges in different units
		   convert between human and UNIX time formats


SYNOPSIS
	$SN [-@aituy] [-sNUM] DATE1 [DATE2] [UNIT]
	$SN [-@iu] -c DATE
	$SN -l YEAR
	$SN [-hv]


DESCRIPTION
	The default function is to calculate time range between
	DATE1 and DATE2.  DATE strings must be compatible with
	GNU date programme.

	To flag a DATE as UNIX time, please add '@' in front of
	it, for example '@1231006505'.  If DATE2 is not specified,
	defaults to '${DATEDEF:-null}' .

	The result is a range of time and it can be expressed as
	UNIT, such as (y)ear, (mo)nth, (w)eek, (d)ay, (h)our,
	(m)in or (s)econd.  Case is sensitive.

	Set option -a to disable autocorrections of user input,
	for eg. \`mo' to \`month' and \`m' to \`minute'; this option
	also inhibits translation of some portuguese words in input
	to english, for eg. \`dia' to \`day' and \`segunda' to \`monday'.

	Input may be from stdin, one DATE string per line;  mul-
	tiple lines are accepted.  Default mode is to calculate
	time difference every two consecutive lines.  One posi-
	tional parameter is accept, in which case DATE strings
	from stdin are compared relatively to it.

	Set option -y to calculate time differences between every
	consecutive line.  One positional parameter is accepted,
	in which case it is compared once to the first date string
	from stdin.

	Option -c performs a simple convertion between human and
	UNIX time formats, only one DATE string is required;
	with this option set, integers may be treated as UNIX
	time, set option -@ to be explicit;  DATE strings from
	stdin are accepted.

	Set result scale with option -sNUM.  To print result with
	thousands separator, use option -t.
	
	Use option -u to interpret and print human dates in uni-
	versal time (UTC) or set TZ=UTC0.

	Option -i sets '$FMTISO'.  The script reads
	variable \$FMT and sets a time format for printing;
	ex: FM=+%FT%T%Z, defaults=${FMT:-unset}.

	Option -l to check if a year in the format YYYY is a leap
	or not.

	GNU date has not got a means to set input time format, such
	as option -j in the BSD date programme.

	The displayed precision of UNIX time in nanoseconds is for
	visual reference purposes only and to present the user with
	the (obvious) fact that time has a definite sense and even
	two commands run consecutively will spend some time.


SHELL INTERPRETERS
	Dropped support for Z-shell and Z-shell maths as this script does
	not work without GNU Date, anyways. Therefore we will stick to
	using GNU tools.


SOME HISTORY
	About the diversity of time formats:

		<<Our units of temporal measurement, from seconds on
		up to months, are so complicated, asymmetrical and
		disjunctive so as to make coherent mental reckoning
		in time all but impossible. Indeed, had some tyran-
		nical god contrived to enslave our minds to time, to
		make it all but impossible for us to escape subjection
		to sodden routines and unpleasant surprises, he could
		hardly have done better than handing down our present
		system. It is like a set of trapezoidal building
		blocks, with no vertical or horizontal surfaces,
		like a language in which the simplest thought demands
		ornate constructions, useless particles and lengthy
		circumlocutions.>>

		from Robert Grudin, Time and the Art of Living,
		also cited in GNU date documentations.


	Interesting excerpt about leap years:
	
		<<The Gregorian calendar came into use in Roman
		Catholic countries in October 1582 when the seasons
		were brought back into step by eliminating 10 days
		from the calendar then in use. Thursday, October 4,
		was followed by Friday, October 15 (which caused
		some consternation among the populace, especially
		those with birthdays on the eliminated dates!).
		Britain and its colonies did not introduce the
		Gregorian calendar until September 1752 by which
		time an additional one day correction was required
		(actually, {1752 - 1582} x 0.0078 = 1.33 day).
		Some British documents from the period before the
		British reform actually contain two dates, an old
		and a new.>>

		<https://www.grc.nasa.gov/WWW/K-12/Numbers/Math/Mathematical_Thinking_ppc/calendar_calculations.htm>


CALCULATION PRECISION
	That must be clear how we interpret one year in terms of days.
	In this script, we admit a year contains an absolute value
	of \`\`$DAYYEAR days'' as per the gregorian calendar.

	That is an accurate value because it contemplates leap years
	in long periods of time but may be somewhat rough approximation
	for shorter time intervals and other certain conditions.
	Therefore the importance to stress this limit in our methodology.

	Note that the script has not got this limitation when
	calculating results in days, hours, minutes and seconds.


SEE ALSO
	Package \`datediff' from \`dateutils' <www.fresse.org/dateutils/>
	and package \`units' from GNU <https://www.gnu.org/software/units/>.


BUGS
	User input date interpretation may not be as expected. Mostly
	because time formats vary so often accross the globe that it
	is hard to interpret, as described in the SOME HISTORY section,
	so stick with time formats GNU Date reads.

	Be sure to understand how this script interprets a year in amount
	of days (1 year = $DAYYEAR days ) and also how GNU date interprets
	time formats, see section CALCULATION PRECISION in this help page,
	\`man date\` and \`info date\` .


WARRANTY
	Licensed under the GNU general public license 3 or better and
	is distributed without support or bug corrections.
	
	Packages GNU Date and Bash v4+ are required.

	If you found this programme interesting, please consider
	sending me a nickle!  =)
  
		bc1qlxm5dfjl58whg6tvtszg5pfna9mn2cr2nulnjr


EXAMPLE EXAMPLES
	For en extensive example list of GNU date usage, please execute
	\`info date\` and check section \`\`21.1.7 Examples of ‘date’'' .

	An explicitly empty argument ' ' is understood the same as
	'today 00:00' by GNU date;  if you say '10 hours', it is
	understood as 'now 10hours' (10 hours hence now).

	$ $SN 'next monday'
	$ $SN 2019/6/28 1Aug
	$ $SN '5min 34s' seconds
	$ $SN 1aug1990-9month now
	$ $SN -- -2week-3day
	$ $SN '10 years ago' months
	$ $SN '1hour ago 30min ago'
	$ $SN @1561243015 @1592865415
	$ $SN -s2 -- today00:00 '12 May 2020 14:50:50' w
	$ TZ=UTC+00 $SN now  #UTC time
	$ TZ=UTC-1  $SN now  #local time in Berlin
	$ TZ=UTC+5  $SN now  #local time in New York
	$ $SN '01january2020 - 6mon' 01january2020  months
	$ $SN '05 jan 2005' 'now - 43years -13 days' y
	$ $SN '3 dias atrás' horas


OPTIONS
	-@ 	Flag input strings as UNIX time (requires GNU date 5.3+).
	-a 	Disable auto-correction of user input.
	-c 	simple conversion between human and UNIX time formats.
	-h 	show this help.
	-i 	set print time format to --iso-8601=seconds.
	-l YEAR check if is leap year; year format=YYYY.
	-t 	print result with thousands separator.
	-s NUM 	result scale (decimal plates). 
	-u 	interpret and print human dates in universal time (UTC).
	-v 	Print less verbose output.
	-y 	Time difference between every consecutive line (stdin)."

#https://unix.stackexchange.com/questions/24626/quickly-calculate-date-differences


#auto-correction function
#homogenise user input
#english 			  #português
ey='years|yea|ye|y' 		  py='anos|ano|an|a'
emo='months|mont|mon|mo' 	  pmo='meses|m[eê]s|m[eê]'
ew='weeks|wee|we|w' 		  pw='semanas|semana|seman|sema|sem'
ed='days|da|d' 			  pd='dias|dia|di'
eh='hours|hou|ho|h' 		  ph='horas|hora|hor'
em='minutes|minut|minu|min|mi|m'  pm='minutos|minuto'
es='seconds|secon|seco|sec|se|s'  ps='segundos|segundo|segund|segun|segu|seg'
#mais português
pmonths="s/janeiro/january/gI;s/fev/feb/gI;s/fevereiro/february/gI;\
s/março/march/gI;s/abril/april/gI;s/maio?/may/gI;s/junho/june/gI;\
s/julho/july/gI;s/agosto/august/gI;s/setembro/september/gI;\
s/outubro/october/gI;s/novembro/november/gI;s/dezembro/december/gI;\
s/([0-9]+\s*|\b)abr(\s*[0-9]+|\b)/\1apr\2/gI;s/([0-9]+|\b)set(\s*[0-9]+|\b)/\1sep\2/gI;\
s/([0-9]+\s*|\b)out(\s*[0-9]+|\b)/\1oct\2/gI;s/([0-9]+|\b)dez(\s*[0-9]+|\b)/\1dec\2/gI;\
s/([0-9]+\s*)ago(\s*[0-9]+|\b)/\1aug\2/gI;"
pweekdays="s/segunda(-feira)?/monday/gI;s/terça(-feira)?/tuesday/gI;\
s/quarta(-feira)?/wednesday/gI;s/quinta(-feira)?/thursday/gI;\
s/sexta(-feira)?/friday/gI;s/s[aá]bado/saturday/gI;s/domingo/sunday/gI;\
s/Seg/Mon/g;s/Ter/Tue/g;s/Qua/Wed/g;s/Qui/Thu/g;s/Sex/Fri/g;s/S[aá]b/Sat/g;s/Dom/Sun/g;"
petc="s/(antes|atr[áa]s)/ago/gI;s/(desde|dali)/hence/gI;s/pr[óo]xim[ao]/next/gI;\
s/passad[ao]/last/gI;s/\bde\b/from/gI;s/agora/now/gI;s/amanh[aã]/tomorrow/gI"
pnum="s/\bh?um\b/one/gI;s/\bdois\b/two/gI;s/\btr[êe]s\b/three/gI;\
s/\bquatro\b/four/gI;s/\bcinco\b/five/gI;s/\bseis\b/six/gI;\
s/\bsete\b/seven/gI;s/\boito\b/eight/gI;s/\bnove\b/nine/gI"
_autof()
{
	local str="$1"

	#detect unix time and whether to autocorrect/translate
	#disable auto-correction of user input
	#translate some words from portuguese
	if [[ "$str" = @* ]] || (( NOAUTOMATIC ))
	then echo "$str"
	else
		#process
		<<<"$str" sed -E \
		-e "s/([0-9]+|\b)($ey|$py)\b/\1year/gI" \
		-e "s/([0-9]+|\b)($emo|$pmo)\b/\1month/gI" \
		-e "s/([0-9]+|\b)($ew|$pw)\b/\1week/gI" \
		-e "s/([0-9]+|\b)($ed|$pd)\b/\1day/gI" \
		-e "s/([0-9]+|\b)($eh|$ph)\b/\1hour/gI" \
		-e "s/([0-9]+|\b)($em|$pm)\b/\1minute/gI" \
		-e "s/([0-9]+|\b)($es|$ps)\b/\1second/gI" \
		-e "$pmonths" -e "$pweekdays" -e "$petc" -e "$pnum"
	fi
}

#get unix time from user input
#print error msg only if DATE is not human or unix time
dateunixfhelper()
{
	#some unusual date input formats
	if date -d"$( sed -E "s:([0-9]{1,4})(${seprm}*)([a-zA-Z]{3,}|[0-9]{1,2})(${seprm}*)([0-9]{1,4}):\1${sep}\3${sep}\5:" <<<"$str" )" "$fmt" ||
	   date -d"$( sed -E "s:([0-9]{1,4})(${seprm}*)([a-zA-Z]{3,}|[0-9]{1,2})(${seprm}*)([0-9]{1,4}):\5${sep}\3${sep}\1:" <<<"$str" )" "$fmt"
	then return 0
	fi
	return 1
}
dateunixf()
{
	local fmt seprm str sep

	#internal format
	#nanosecond-precision
	fmt=+%s.%N
	#chars to remove
	seprm='[ /._-]'
	#set string
	str="$*"

	#disable auto-correction of user input?
	if (( NOAUTOMATIC ))
	then date -d"$str" "$fmt" ;return
	fi
	
	{
	#explicitly set unix time?
	if (( OPTUNIX ))
	then date -d@"${str#@}" "$fmt" ;return
	#defaults
	elif date -d"$str" "$fmt"
	then return 0
	elif date -d"${str//${seprm}}" "$fmt"
	then return 0
	fi

	#try these separators
	for sep in \  \/ \-
	do
		if dateunixfhelper "$@"
		then return 0
		#make sure locale is set
		elif dateunixfhelper "$@"
		then return 0
		fi
	done
	} 2>/dev/null
	
	#print GNU date defaults error msg
	date -d"$str" "$fmt" >&2
	return 1
}

#is leap year?
isleap()
{ 
	local year=$1
	#if date -d "${year}-02-29" &>/dev/null
	if (( !(year % 4) && ( year % 100 || !(year % 400) ) ))
	then return 0
	fi
	return 1
}
#https://stackoverflow.com/questions/32196628/my-shell-script-for-checking-leap-year-is-showing-error

##MAIN##
main()
{
	#get dates in unix time, nanoseconds
	#human or unix formats, whichever works 
	d1=$( dateunixf "${1:-$DATEDEF}" ) || return 1
	d2=$( dateunixf "${2:-$DATEDEF}" ) || return 1

	#calculate
	#math scale set 16 for accuracy
	range="$( bc <<< "scale=16; ( $d1 - $d2 ) / ( $exp )" )"
	
	#remove result sign
	range="${range#-}"
	
	#set plural
	if (( ${range%.*} ))
	then
		plural="${range#*.}"
		plural="${plural:0:${SCALE:-4}}"
	
		if [[ "$plural" = *[1-9]* ]]
		then plural=s
		else unset plural
		fi
	fi
	
	#print header info
	if (( OPTVERBOSE == 0 ))
	then
		cat <<-!
		date1: $( date -R -d@"$d1" "$FMT" )
		date2: $( date -R -d@"$d2" "$FMT" )
		unix1: $d1
		unix2: $d2
		!
	fi
	
	#print result
	#if user supplied a result unit in $3
	if [[ -z "$unitsdefaults" ]]
	then
		#print result with user unit and scale
		if (( OPTVERBOSE ))
		then printf "%${TSEP}.*f\n" "${SCALE:-4}" "$range"
		else printf "range: %${TSEP}.*f  %s%s\n" "${SCALE:-4}" "$range" "$unit" "$plural"
		fi
	
	else
		#use decimals only
		d1="$( printf '%.0f\n' "$d1" )"
		d2="$( printf '%.0f\n' "$d2" )"
	
		#generic result display (A)
		(( range = ( d1 - d2 ) ))
		range="${range#-}" 

		(( d = range / 86400 ))
		(( h = ( range / 3600 ) % 24 ))
		(( m = ( range % 3600 ) / 60 ))
		(( s = range % 60 ))

		#extra ranges (~year, ~month, ~week and ~day)
		y=$(   bc <<<"scale=0; $d / ${DAYYEAR}" )
		yy=$(  bc <<<"scale=0; $d % ${DAYYEAR} / 1" )

		mo=$(  bc <<<"scale=0; $yy / 30" )
		momo=$(bc <<<"scale=0; $yy % 30 / 1" )

		w=$(   bc <<<"scale=0; $momo / 7" )

		dd=$(  bc <<<"scale=0; $momo % 7 / 1" )

		#set check
		check="${y%.*}${mo%.*}${w%.*}"
		
		#printf formatting strings
		strapprox='%02dY %02dM %02dW %02dD'
		strunit='%dD %02d:%02d:%02d'

		#print result
		if (( OPTVERBOSE ))
		then
			#is month greater than nought?
			if [[ -n "$check" ]] && [[ "$check" != 000 ]]
			then printf "~$strapprox\n" "$y" "$mo" "$w" "$dd"
			fi

			printf "$strunit\n" "$d" "$h" "$m" "$s"
		else
			if [[ -n "$check" ]] && [[ "$check" != 000 ]]
			then printf "range~ $strapprox\n" "$y" "$mo" "$w" "$dd"
			fi

			printf "range: $strunit\n" "$d" "$h" "$m" "$s"
		fi
	fi
}

#option -c helper func
simpleconvertf()
{
	#explicitly unix time?
	if (( OPTUNIX ))
	then date -d@"$1" "$FMT"
	else date -d"$1" +%s 2>/dev/null || date -d@"$1" "$FMT"
	fi
}


#parse options
while getopts @achiIls:tuvy c
do
	case $c in
		@)
			#explicitly unix time
			OPTUNIX=1
			DATEDEF="$( date -d"$DATEDEF" +%s )"
			;;
		a)
			#disable auto-correction of user input
			NOAUTOMATIC=1
			;;
		c)
			#simple convertion
			#between human and unix time
			OPTC=1
			;;
		h)
			#help page
			echo "$HELP"
			exit 0
			;;
		[iI])
			#set date format to iso-8601
			FMT="$FMTISO"
			;;
		l)
			#is leap year
			(( OPTL )) && OPTL=2 || OPTL=1
			;;
		s)
			#scale
			SCALE=$OPTARG
			;;
		t)
			#thousands separator
			TSEP="'"
			;;
		u)
			#print time in UTC (universal time)
			TZ=UTC0
			;;
		v)
			#less verbose
			OPTVERBOSE=1
			;;
		y)
			#or calculate time between every line
			OPTEVERY=1
			;;
		?) 
			#bad opt
			exit 1
	esac
done
shift $(( OPTIND - 1 ))
unset c

#check format \$FMT
if [[ -z "${FMT//[+% ]}" ]]
then FMT="$FMTDEF"
elif ! date "$FMT" >/dev/null
then exit 1
fi

#-c option simple convertion date
#between human and UNIX formats?
if (( OPTC ))
then
	#loop
	#if there are positional args
	if (( $# ))
	then
		#get postional arguments
		for arg in "$@"
		do simpleconvertf "$arg"
		done
	
	#if stdin is not free
	elif [[ ! -t 0 ]]
	then
		#dates from stdin
		while IFS=  read -r
		do simpleconvertf "$REPLY"
		done
	else
		echo "$SN: err  -- date string required" >&2
		exit 1
	fi

	exit
#is leap year optioni?
elif (( OPTL ))
then
	#is leap year?
	if [[ "$1" = [0-9][0-9][0-9][0-9] ]] ||
		[[ "$1" = -[0-9][0-9][0-9][0-9] ]]
	then
		if isleap "$1"
		then (( OPTL==1 )) && echo "leap year" || echo 1 ;exit 0
		else (( OPTL==1 )) && echo "not leap year" ;exit 1
		fi
	else
		echo "$SN: err  -- year must be in the format YYYY" >&2
		exit 1
	fi
fi

#defaults function, continue..
#check arg number

#check for arguments
if (( $# > 3 ))
then echo "$SN: err  -- too many arguments" >&2 ;exit 1
fi
#now we know there are three arguments at most..

#grab last argument
#will check if that is a 'unit string' later
ISUNIT="${@: -1}" 

#set result unit
unit="$( NOAUTOMATIC= _autof "${ISUNIT:-null}" )"
case $unit in
	year) 	exp="86400*${DAYYEAR}";;
	month) 	exp="86400*(${DAYYEAR}/12)";;
	week) 	exp='86400*7';;
	day)	exp=86400;;
	hour)	exp=86400/24;;
	minute)	exp='86400/(24*60)';;
	second)	exp='86400/(24*60*60)';;
	*)	
		#defaults
		exp='86400/(24*60*60)'
		unit=second
		unitsdefaults=true
		;;
esac

#if user has supplied 'units string'
if [[ -z "$unitsdefaults" ]]
then 
	#if two args, and last one is 'unit string'
	if (( $# == 2 )) && [[ "$2" = "$ISUNIT" ]]
	then set -- "$1"
	#if one arg and it is 'unit string'
	elif (( $# == 1 )) && [[ "$1" = "$ISUNIT" ]]
	then set --
	fi
fi
#at this point, if user only supplied 'unit string', $* should be empty

#autocorrections and removal of empty arguments
if [[ -n "$2" ]]
then set -- "$( _autof "$1" )" "$( _autof "$2" )"
elif [[ -n "$1" ]]
then set -- "$( _autof "$1" )"
fi


##MAIN_OPTIONS##

#-y function
(( OPTEVERY )) && DATE1="$1"

#is stdin taken? is there more than 1 positional argument?
if [[ ! -t 0 ]] && (( $# < 2 ))
then
	#read stdin
	while IFS=  read -r
	do
		#-y function
		if (( OPTEVERY )) && [[ -n "$DATE2" ]]
		then
			#sanity space
			(( OPTVERBOSE )) || echo

			#main function
			main "${DATE1:-$DATEDEF}" "${DATE2:-$DATEDEF}"

			#calculate time between every line
			DATE1="$DATE2"
			unset DATE2
		fi

		#set first line as first argument
		if [[ -z "$DATE1" ]]
		then
			DATE1="$REPLY"

			#is there one positional arg?
			if [[ -z "$1" ]]
			then continue
			else DATE2="$1"
			fi
		#set second line as second argument
		elif [[ -z "$DATE2" ]]
		then DATE2="$REPLY"
		fi

		#defaults function
		if (( OPTEVERY - 1 ))
		then
			#sanity space
			(( OPTVERBOSE )) || echo

			#main function
			main "${DATE1:-$DATEDEF}" "${DATE2:-$DATEDEF}"

			#calculate time every two lines
			unset DATE1 DATE2
		fi

	done
	
	#sanity space
	(( OPTVERBOSE )) || echo

	#any remaining DATES?
	if [[ -n "$DATE1$DATE2$OPTEVERY" ]]
	then main "${DATE1:-$DATEDEF}" "${DATE2:-$DATEDEF}"
	fi
else
	#main function
	main "$@"
fi

