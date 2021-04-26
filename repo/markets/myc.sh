#!/bin/bash
# myc.sh - Currency converter, API access to MyCurrency.com
# v0.4.2  jan/2021  by mountaineerbr

## Defaults

#from currency
DEFFROMCUR=EUR
#to currency
DEFTOCUR=USD

# Scale (decimal plates):
DEFSCL=6

#Do not change the following
#make sure locale is set correctly
export LC_NUMERIC=C

## Manual and help
## Usage: $ myc.sh [amount] [from currency] [to currency]
HELP_LINES="NAME
	Myc.sh -- Currency converter
	       -- Bash interface for <MyCurrency.com> free API
	       -- 免費版匯率API接口


SYNOPSIS
	myc.sh [-sNUM] [AMOUNT] [FROM_CURRENCY] [TO_CURRENCY]
	myc.sh [-hlv]


DESCRIPTION
	Myc.sh fetches central bank currency rates from <mycurrency.net>
	and can convert any amount of one supported currency into another.
	It supports 163 currency rates at the moment. Precious metals
	and cryptocurrency rates are not supported.	

	AMOUNT can be a floating point number or a math expression that
	is understandable by GNU bc.

	If no currency is given, FROM_CURRENCY defaults to $DEFFROMCUR and
	TO_CURRENCY always defaults to $DEFTOCUR if not given.

	Set decimal plates with option -sNUM, in which NUm is an integer,
	or simple -NUM , scale defaults=$DEFSCL .

	Rates are updated every hour. This is a really simple and good
	API.


NOTICE
	There is now extensive documentation at <https://info.mycurrency.com>
	which describes new API points.

	The old API point from <mycurrency.net> is working alright for
	now. However, if the old API stops being supported, I may not
	implement the new ones in this script.


WARRANTY
	Licensed under the GNU Public License v3 or better and is
	distributed without support or bug corrections.

	Required packages: bash, jq, curl or wget and gzip.

	If you found this script useful, consider sending me a nickle!
		=)

		bc1qlxm5dfjl58whg6tvtszg5pfna9mn2cr2nulnjr


USAGE EXAMPLES
	(1) One Brazilian real in US Dollar:

		$ myc.sh brl

		$ myc.sh 1 brl usd

		
	(2) One thousand US Dollars in Japanese Yen:
		
		$ myc.sh 100 usd jpy
		

		Using math expression in AMOUNT:
		
		$ myc.sh '101+(2*24.5)+850' usd jpy


	(3) Half a Danish Krone in Chinese Yuan with 3 decimal 
	    plates (scale):

		$ myc.sh -s3 0.5 dkk cny


OPTIONS
	-NUM 	Same as -sNUM .
	-h 	Show this help.
	-j 	Debug, print JSON.
	-l [CURRENCY]
		List supported currencies; if CURRENCY is not given
		rates defaults to $DEFTOCUR .
	-s NUM 	Scale (decimal plates), defaults=$DEFSCL .
	-v 	Print this script version."

# Parse options
while getopts :0123456789lhjs:v opt; do
  case $opt in
	[0-9] ) #scale setting
		SCL="${SCL}${opt}"
		;;
  	l ) ## List available currencies
		LISTOPT=1
		;;
	h ) # Show Help
		echo "$HELP_LINES"
		exit 0
		;;
	j ) # Print JSON
		PJSON=1
		;;
	s ) # Decimal plates
		SCL=$OPTARG
		;;
	v ) # Version of Script
		grep -m1 '# v'
		exit 
		;;
	\? )
		echo "Invalid option: -$OPTARG" >&2
		exit 1
		;;
  esac
done
shift $((OPTIND -1))

#Check for JQ
if ! command -v jq &>/dev/null; then
	echo "JQ is required" >&2
	exit 1
fi

# Test if cURL or Wget is available
if command -v curl &>/dev/null; then
	YOURAPP=(curl -sL --compressed)
elif command -v wget &>/dev/null; then
	YOURAPP=(wget -qO-)
else
	echo "Package cURL or Wget is required" >&2
	exit 1
fi

#request compressed response
#warning: gzip may be required


## Set default scale if no custom scale
[[ -n "$SCL" ]] || SCL="$DEFSCL"

# Check arguments (currencies)
# Set equation arquments
if [[ "$1" != *[0-9]* ]]; then
	set -- 1 "${@:1:2}"
fi

if [[ -z "$2" ]]; then
	set -- "$1" "$DEFFROMCUR" "${@:3:1}"
fi

if [[ -z "$3" ]]; then
	set -- "${@:1:2}" "$DEFTOCUR"
fi

# Check if you are requesting any precious metals.
if grep -qwi -e "XAU" -e "XAG" -e "XAP" -e "XPD" <<<"$*"; then
	echo "Mycurrency.com does not support precious metals" >&2
	exit 1
fi

## Get JSON once
JSON="$("${YOURAPP[@]}" "https://www.mycurrency.net/US.json")"

## Print JSON?
if ((PJSON)); then
	echo "$JSON"
	exit
fi
## List all suported currencies and USD rates?
if ((LISTOPT)); then

	# Test screen width
	# If stdout is open, trim some wide columns
	if [[ -t 1 ]]; then
		COLCONF=(-TCOUNTRY,CURRENCY)
	fi

	echo "Supported currencies (against USD)"
	jq -r '.rates[]|"\(.currency_code)=\(.rate)=\(.name) (\(.code|ascii_downcase))=\(.currency_name)=\(.hits)"' <<< "$JSON" |
		column -et -s'=' -N'SYMBOL,RATE,COUNTRY,CURRENCY,WEBHITS' ${COLCONF[@]}
	echo "Currencies: $(jq -r '.rates[].currency_code' <<< "$JSON" | wc -l)"
	exit
fi

#check that symbols are supported
CURS="$(jq -r '.rates[].currency_code'<<<"$JSON")"
if ! grep -qwi "$2" <<<"$CURS"; then 
	printf 'Error: unsupported symbol -- %s\n' "${2^^}" 
	exit 1
elif ! grep -qwi "$3" <<<"$CURS"; then 
	printf 'Error: unsupported symbol -- %s\n' "${3^^}" 
	exit 1
fi

## Grep currency data and rates
CJSON=$(jq '[.rates[] | { key: .currency_code, value: .rate } ] | from_entries' <<< "$JSON")

## Get currency rates
FROMCURRENCY=$(jq ".${2^^}" <<< "$CJSON")
TOCURRENCY=$(jq ".${3^^}" <<< "$CJSON")

## Make equation and print result
bc <<< "scale=$SCL ;( ( $1 ) * $TOCURRENCY ) / $FROMCURRENCY"

