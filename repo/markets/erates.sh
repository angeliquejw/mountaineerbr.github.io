#!/bin/bash
# erates.sh -- Currency converter Bash wrapper for exchangeratesapi.io API
# v0.2.15  aug/2020  by mountaineerbr

#defaults

#default currencies
SCRIPTBASECUR=EUR
SCRIPTFROMCUR=USD

#decimal plates by default
SCLDEFAULTS=8  #max=10

#make sure locale is set correctly
export LC_NUMERIC=C

## Manual and help
## Usage: $ erates.sh [amount] [from currency] [to currency]
HELP_LINES="NAME
 	erates.sh -- bash currency converter for exchangeratesapi.io api


SYNOPSIS
	erates.sh [-j] [-sNUM] [AMOUNT] [FROM_CURRENCY] [TO_CURRENCY]
	erates.sh [-jt] [FROM_CURRENCY] [TO_CURRENCY] [START_DATE] [END_DATE]
	erates.sh [-hlv]


DESCRIPTION
	This programme fetches updated currency rates and can convert
	any amount of one supported currency into another. It is a
	wrapper for the exchangerates.io API.
	
	Exchangerates.io API is a free service for current and histor-
	ical foreign exchange rates published by the European Central
	Bank. Check their project:
	<https://github.com/exchangeratesapi/exchangeratesapi>

	33 central bank currencies are supported but precious metals.
 	
	The reference rates are usually updated around 16:00 CET on
	every working day, except on TARGET closing days. They are based
	on a regular daily  concertation  procedure between central banks
	across Europe, which normally takes place at 14:15 CET.

	Default TO_CURRENCY (base currency) is $SCRIPTBASECUR and FROM_CURRENCY
	defualts is $SCRIPTFROMCUR, if user input is missing.

	The -t timeseries function accepts two dates as arguments; some
	rates are availbale as far back as 04jan1999 but not for all
	currencies; make sure date format is understandable by GNU date
	programme.

	Bash Calculator uses a dot for decimal separator.


WARRANTY
 	This programme needs latest versions of Bash, Curl , Gzip and
	JQ to work properly.

	It is licensed under GPLv3 and distributed without support or
	bug corrections.


USAGE EXAMPLES
	(1) One US Dollar in Brazilian Real:

	$ erates.sh usd brl

	
	(2) One thousand Euro to Japanese yen using
	    math expression in AMOUNT:
	
	$ erates.sh '(3*245.75)+262+.75' eur jpy


	(3) Half a Danish Krone to Chinese Yuan, 
	   three decimal plates (scale):

	$ erates.sh -s3 0.5 dkk cny


	(4) Time series for usd vs cny:

	$ erates.sh -t usd cny 01jan2007


OPTIONS
	-h 	Show this help.
	-j 	Debug; print raw JSON.
	-l 	List supported currencies and rates.
	-s 	Set scale; defaults=$SCLDEFAULTS .
	-t 	Timeseries, some rates available since 04jan1999.
	-v 	Print this programme version."

## Functions
# List all suported currencies and EUR rates?
listf() {
	echo "Currency list and rates"

 	jq -r '.rates' <<<"${JSON}" | sed 's/[{}",]//g ; s/^[[:space:]]*//g ; /^$/d' | sort
	jq -r '"Base: \(.base)",
		"Date: \(.date)"' <<< "$JSON"
	
	echo "<https://www.ecb.europa.eu/stats/policy_and_exchange_rates/euro_reference_exchange_rates/html/index.en.html>"
	exit 0
}

#timeseries
histf()
{
	#get dates
	while last="${@: -1}"
		(( ${#last} > 4 )) &&
		date -d "${@: -1}" &>/dev/null
	do
		if [[ -z "$END" ]] 
		then
			END="${@: -1}"
		else
			START="${@: -1}"
		fi

		set -- "${@:1:$(( $# - 1 ))}"
	done

	# Set equation arquments
	if (( ${#1} < 3 )) || (( $1 ))
	then
		shift
	fi
	if [[ -z "${2^^}" ]] ||
		[[ "${2^^}" = *[0-9]* ]] ||
		(( ${#2} > 4 )) 
	then
		set -- "$1" "${SCRIPTBASECUR}"
	fi
	if [[ -z "${1^^}" ]] ||
		[[ "${1^^}" = *[0-9]* ]] ||
		(( ${#1} > 4 )) 
	then
		set -- "${SCRIPTFROMCUR}" "$2"
	fi
	
	#check base currency
	[[ "${1^^}" != EUR ]] && BASE="&base=${1^^}"

	#date range
	#time limit
	#>915415200
	#04jan1999
	END="$( date -d "${END:-yesterday}" +%Y-%m-%d )"
	START="$( date -d "${START:-"$END - 1 year"}" +%Y-%m-%d )"
	#START=1999-01-04

	## Get JSON once
	JSON="$( curl --compressed "https://api.exchangeratesapi.io/history?start_at=${START}&end_at=${END}${BASE}" )"
	## Print JSON?
	if [[ -n "${PJSON}" ]]; then
		echo "${JSON}"
		exit
	fi

	#check json
	if ! jq -e . <<< "$JSON" &>/dev/null
	then
		echo "bad json data" >&2
		exit 1
	fi
	if jq -er '.error//empty' <<< "$JSON" >&2 2>/dev/null
	then
		exit 1
	fi

	#dates
	timestamps="$( jq -r '.rates|keys_unsorted[]' <<< "$JSON" )"
	#rates
	rates="$( jq -r ".rates[].${2^^}" <<< "$JSON" )"

	paste <(echo "$rates") <(echo "$timestamps") |
		#requires GNU sort
		sort -V -k2 |
		column -et -NRATE,DATE

	jq -r '"--------",
		"Currency rate timeseries",
		"Quote: '${2^^}'",
		"Base_: \(.base)",
		"Start: \(.start_at)",
		"End__: \(.end_at)"' <<< "$JSON"
}


# Parse options
while getopts :lhjs:vHtT opt
do
  case ${opt} in
  	l ) ## List available currencies
		LISTOPT=1
		;;
	h ) # Show Help
		echo "${HELP_LINES}"
		exit 0
		;;
	j ) # Print JSON
		PJSON=1
		;;
	s ) # Decimal plates
		SCL=${OPTARG}
		;;
	[tTH]) #timeseries
		HISTOPT=1
		;;
	v ) # Version of Script
		grep -m1 '\# v' "$0"
		exit
		;;
	\? )
		printf "Invalid option: -%s\n" "$OPTARG" 1>&2
		exit 1
		;;
  esac
done
shift $((OPTIND -1))

## Check for some needed packages
if ! command -v curl &> /dev/null; then
	echo "Package not found: curl" >&2
	exit 1
elif ! command -v jq &> /dev/null; then
	echo "Package not found: jq" >&2
	echo "Ref: https://stedolan.github.io/jq/download/" >&2
	exit 1
fi

# Call opt functions
if [[ -n "${HISTOPT}" ]]
then
	histf "$@"
	exit
fi

## Set default scale if no custom scale
if [[ -z ${SCL} ]]; then
	SCL=${SCLDEFAULTS}
fi

# Set equation arquments
if [[ -z "$1" ]] ||
	[[ ${1^^} = *[A-Z]* ]]
then
	set -- 1 "$1" "$2"
fi
if [[ -z "$3" ]] ||
	[[ "${3^^}" = *[0-9]* ]] ||
	(( ${#3} > 4 )) 
then
	set -- "$1" "$2" "${SCRIPTBASECUR}"
fi
if [[ -z "$2" ]] ||
	[[ "${2^^}" = *[0-9]* ]] ||
	(( ${#2} > 4 )) 
then
	set -- "$1" "${SCRIPTFROMCUR}" "$3"
fi

#set a base currency
[[ "${2^^}" != EUR ]] && BASE="?base=${2^^}"

## Get JSON once
JSON="$(curl --compressed -s "https://api.exchangeratesapi.io/latest${BASE}")"
## Print JSON?
if [[ -n "${PJSON}" ]]; then
	echo "${JSON}"
	exit
fi
#check json
if ! jq -e . <<< "$JSON" &>/dev/null
then
	echo "bad json data" >&2
	exit 1
fi

# Call opt functions
if [[ -n "${LISTOPT}" ]]
then
	listf
fi

#get json base symbol
JSONBASE="$(jq -r '.base // empty' <<< "$JSON" 2>/dev/null )"

## Default function -- Currency converter
## Check if request is a supported currency:
if [[ "${2^^}" != "$JSONBASE" ]]
then
	jq -er '.error' <<< "$JSON" >&2 ||
		echo "Base currency error -- ${2^^}" >&2
	exit 1
fi
if [[ "${3^^}" != "$JSONBASE" ]] && 
	! jq -er ".rates.${3^^}" <<< "$JSON" &>/dev/null
then
	echo "Not a supported currency -- ${3^^}" >&2
	exit 1
fi

#get rate
if [[ "${3^^}${2^^}" = EUREUR ]]
then
	RATE=1
else
	RATE="$( jq -r ".rates.${3^^}" <<< "${JSON}" )"
fi

## Make equation and print result
bc <<< "scale=${SCL}; ( ${1} ) * $RATE / 1"

