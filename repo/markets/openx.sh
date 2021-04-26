#!/bin/bash
# openx.sh - bash (crypto)currency converter
# v0.6.18  aug/2020  by mountaineerbr

## Please make a free account and update this script
## with your Open Exchange Rates API ID ( app_id ).
#OPENXAPPID=
export OPENXAPPID

#defaults
#default to_currency
DEFTOCUR=USD

# Number of decimal plates (scale):
SCLDEFAULTS=16

## You should not change these:
export LC_NUMERIC=C
## Troy ounce to gram ratio
TOZ='31.1034768'

## Help
## Usage: $ openx.sh [amount] [from currency] [to currency]
HELP_LINES="NAME
 	OpenX.sh - Bash Currency Converter
		   OpenExchangeRates.org API access


SYNOPSIS
	openx.sh [-tg] [-sNUM] [AMOUNT] [FROM_CURRENCY] [TO_CURRENCY]
	openx.sh [-hlv]


DESCRIPTION
	This programme fetches updated currency rates from the internet	and
	can convert any amount of one supported currency into another. Rates
	are retrieved from openexchangerates.org with a free personal API key.

	Please create a free API key and add it to the script source-code or
	set it as an environment variable as \"OPENXAPPID\".

	Openexchangerates.org offers 193 currency rates currently, including
	alternative,  black  market  and some digital currencies. These rates
	should not be used to perform precise forex trades, as the free plan
	updates hourly only and has a limit of 1000 accesses per month.

	Use option \"-g\" to convert precious metal rates using grams instead
	of troy ounces for precious metals (${TOZ}grams/troyounce).

	Bash Calculator uses a dot \".\" as decimal separtor. Default preci-
	sion is ${SCLDEFAULTS}, plus an uncertainty digit.

	
ENVIRONMENT AND API KEY
	Please create a free API key and add it to the script source-code or
	set and export variable \$OPENXAPPID .

	A builtin key was added for demo purposes, however that may stop
	working at any time or get rate limited quickly.


WARRANTY
	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	<https://www.gnu.org/licenses/>.  
	

	If you found this useful, consider sending me a nickle! =)

		bc1qlxm5dfjl58whg6tvtszg5pfna9mn2cr2nulnjr
     

ACCURACY
      As with all exchange rate data, accuracy can never be guaranteed when
      you're not paying through the teeth for the service - and when money
      changes currencies, everyone takes a cut. 
      
      Also see: <https://openexchangerates.org/license>
                <https://openexchangerates.org/terms>


USAGE EXAMPLES

		(1) One Canadian Dollar in US Dollar:
		
			$ openx.sh cad usd
			
			$ openx.sh 1 cad usd
	

		(2) One thousand Danish Krones to Chinese Yuans with
		    three decimal plates (scale):

			$ openx.sh -s3  dkk cny
			

		(3) 	Using a math expression in AMOUNT:

			$ openx.sh -3 '(3*245.75)+262+.75' dkk cny


		(4)    One gram of gold in US Dollars:
					
			$ openx.sh -g xau usd 
		

OPTIONS
		-NUM 	  Shortcut for scale setting, same as \"-sNUM\".
		-g 	 Use grams instead of troy ounces; only for
			 precious metals.
	 	-h	 Show this help.
		-j	 Debug; print JSON.
		-l	 List available currency codes.
		-s [NUM] Set number of decimal plates. Defaults=${SCLDEFAULTS}.
		-t 	 Print JSON timestamp.
		-v 	 Show this programme version."


## Functions
ozgramf() {	
	# Precious metals - ounce to gram
	#CGK does not support Platinum(xpt) and Palladium(xpd) yet
	if [[ -n "${GRAMOPT}" ]]; then
		[[ "${2^^}" =~ ^(XAU|XAG)$ ]] && TMET=1
		[[ "${1^^}" =~ ^(XAU|XAG)$ ]] && FMET=1

		if (( TMET - FMET )); then
			if (( TMET )); then
				GRAM='*'
			else
				GRAM='/'
			fi

			return 0
		fi
	else
		unset TOZ
		unset GRAM
	fi
}


## Check for some needed packages
if ! command -v curl &> /dev/null; then
	printf "cURL is required." 1>&2
	exit 1
elif ! command -v jq &> /dev/null; then
	printf "JQ is required." 1>&2
	printf "Ref: https://stedolan.github.io/jq/download/" 1>&2
	exit 1
fi

# Check if there is any argument
if ! [[ ${*} =~ [a-zA-Z]+ ]]; then
	printf "Run with -h for help.\n"
	exit 1
fi

# Parse options
while getopts ":glhjs:tv1234567890" opt; do
	case ${opt} in
		[0-9] ) #scale, same as '-sNUM'
			SCL="${SCL}${opt}"
			;;
		l ) ## List available currencies
			LISTOPT=1
			;;
		g ) # Gram opt
			GRAMOPT=1
			;;
		h ) # Show Help
			echo -e "${HELP_LINES}"
			exit 0
			;;
		j ) # Print JSON
			PJSON=1
			;;
		s ) # Decimal plates
			SCL=${OPTARG}
			;;
		t ) # Print Timestamp with result
			TIMES=1
			;;
		v ) # Version of Script
			head "${0}" | grep -e '# v'
			exit
			;;
		\? )
			printf "Invalid option: -%s" "${OPTARG}" 1>&2
			exit 1
			;;
	esac
done
shift $((OPTIND -1))

#Check for API KEY
if [[ -z "${OPENXAPPID}" ]]; then
	#printf "Please create a free API key and add it to the script source-code\n" 1>&2
	#printf "or set it as an environment variable.\n" 1>&2
	#exit 1

	#dev demo key
	OPENXAPPID='ab605d846f3f40fabd4db64bf2258519'
fi

## Set default scale if no custom scale
if [[ -z ${SCL} ]]; then
	SCL=${SCLDEFAULTS}
fi

# Set equation arquments
if ! [[ ${1} =~ [0-9]+ ]]; then
	set -- 1 ${@:1:2}
fi

if [[ -z ${3} ]]; then
	set -- ${@:1:2} "${DEFTOCUR^^}"
fi

## Grep JSON from server
JSON=$(curl --compressed -s "https://openexchangerates.org/api/latest.json?app_id=${OPENXAPPID}&show_alternative=true")
## Print JSON?
if [[ -n "${PJSON}" ]]; then
	printf "%s\n" "${JSON}"
	exit 0
fi

# -l Print Currency List
if [[ -n "${LISTOPT}" ]]; then
	printf "List of supported currency codes.\n"
	jq -r ".rates|keys[]" <<< "${JSON}" | column -c 80
	printf "Currencies: %s.\n" "$(jq -r ".rates|keys[]" <<< "${JSON}" | wc -l)"
	printf "<https://docs.openexchangerates.org/docs/supported-currencies>.\n"
	exit 0
fi

## Check if input has supported currencies:
if ! jq -r '.rates | keys[]' <<< "${JSON}" | grep -qi "^${2}$"; then
	printf "Not a supported currency: %s\n" "${2}" 1>&2
	exit 1
fi
if ! jq -r '.rates | keys[]' <<< "${JSON}" | grep -qi "^${3}$"; then
	printf "Not a supported currency: %s\n" "${3}" 1>&2
	exit 1
fi

## -t Timestamp option
if [[ -n "${TIMES}" ]]; then
	TIMES=$(jq -r ".timestamp" <<< "${JSON}")
	date -d@"$TIMES" "+# %Y-%m-%dT%H:%M:%S%Z"
fi

## Get currency rates
FROMCURRENCY=$(jq ".rates.${2^^}" <<< "${JSON}" | sed 's/e/*10^/g')
TOCURRENCY=$(jq ".rates.${3^^}" <<< "${JSON}" | sed 's/e/*10^/g')

# Precious metals in grams?
ozgramf "${2}" "${3}"
# Make currency exchange rate equation 
# and send to Bash Calculator to get results
bc -l <<< "scale=${SCL};(((${1})*${TOCURRENCY}/${FROMCURRENCY})${GRAM}${TOZ})/1"

exit

#  Dead code
#
# █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░
#  █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░
#   █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░
#  █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░
# █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░
#  █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░
#   █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░ █▓▒░

