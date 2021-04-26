#!/bin/bash
# clay.sh -- <currencylayer.com> currency rates api access
# v0.4.23  aug/2020  by mountaineerbr

#your own personal api key
#CLAYAPIKEY=
export CLAYAPIKEY

#defaults
#default to_currency
DEFTOCUR=USD

#number of decimal plates (scale):
SCLDEFAULTS=20   #bash calculator defaults is 20 plus one uncertainty digit

#don't change these
LC_NUMERIC='en_US.UTF-8'
#troy ounce to gram ratio
TOZ='31.1034768'

#manual and help
#usage: clay.sh [amount] [from currency] [to currency]
HELP_LINES="NAME
 	Clay.sh -- Currency Converter
		   CurrencyLayer.com API Access


SYNOPSIS

	clay.sh [-tg] [-sNUM] [AMOUNT] FROM_CURRENCY [TO_CURRENCY]

	clay.sh [-hjlv]


DESCRIPTION
	This programme fetches updated currency rates from the internet
	and can convert any amount of one supported currency into another.
	If user does not specify TO_CURRENCY, script defaults to ${DEFTOCUR}.

	Free plans should get currency updates daily only. It supports
	very few cyrpto currencies. Please, access <https://currencylayer.com/>
	and sign up for a free private API key.

	Use option \"-g\" to convert precious metal rates using grams
	instead of troy ounces for precious metals (${TOZ}grams/troyounce).

	Bash Calculator uses a dot '.' as decimal separtor. Default pre-
	cision is ${SCLDEFAULTS}, plus an uncertainty digit.

		
ENVIRONMENT AND API KEY
	Please create a free API key and add it to the script source-code
	or set and export \$CLAYAPIKEY .

	A builtin key was added for demo purposes, however that may stop
	working at any time or get rate limited quickly.


WARRANTY
	Licensed under the GNU Public License v3 or better. This programme
	is distributed without support or bug corrections.

	If you found this script useful, consider sending me a nickle! =)

		bc1qlxm5dfjl58whg6tvtszg5pfna9mn2cr2nulnjr


USAGE EXAMPLES
		
		(1) One Canadian Dollar in US Dollar, two decimal plates:

			$ clay.sh -s2 1 cad usd

			$ clay.sh -2 cad usd


		(2) 50 Djiboutian Franc in Chinese Yuan with three decimal
		    plates (scale):

			$ clay.sh -s3 50 djf cny


		(3) One CAD in JPY using math expression in AMOUNT:
			
			$ clay.sh -2 '(3*15.5)+40.55' cad jpy


		(4) One gram of gold in US Dollars:
					
			$ clay.sh -g xau usd 


OPTIONS
	-NUM 	  Shortcut for scale setting, same as '-sNUM'.
	-g 	  Use grams instead of troy ounces for precious metals.
	-h 	  Show this help.
	-j 	  Debug; print JSON.
	-l 	  List supported currencies.
	-s NUM    Set decimal plates; defaults=${SCLDEFAULTS}.
	-t 	  Print timestamp.
	-v 	  Show this programme version."

#functions

#precious metals in grams?
ozgramf() {	
	#troy ounce to gram
	#currencylayer does not support platinum(xpt) and palladium(xpd) yet
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

#parse options
while getopts ':1234567890lghjs:tv' opt; do
	case ${opt} in
		( [0-9] ) #scale, same as '-sNUM'
			SCL="${SCL}${opt}"
			;;
		( l ) #list available currencies
			LIST="$(curl --compressed -s 'https://currencylayer.com/site_downloads/cl-currencies-table.txt' | sed -e 's/<[^>]*>//g' -e 's/^[ \t]*//' -e '/^$/d'| sed -e '$!N;s/\n/ /')"
			printf '%s\n' "${LIST}"
			printf 'Currencies: %s\n' "$(($(wc -l <<<"${LIST}")-1))" 
			exit 0
			;;
		( g ) #gram opt
			GRAMOPT=1
			;;
		( h ) #help
			echo -e "${HELP_LINES}"
			exit 0
			;;
		( j ) #print json
			PJSON=1
			;;
		( s ) #decimal plates
			SCL=${OPTARG}
			;;
		( t ) #print Timestamp with result
			TIMEST=1
			;;
		( v ) #version
			grep -m1 '# v' "${0}"
			exit
			;;
		( \? )
			printf 'Invalid option: -%s\n' "$OPTARG" 1>&2
			exit 1
			;;
	esac
done
shift $((OPTIND -1))

#check for any arg
if [[ -z "${*}" ]]; then
	printf 'Run with -h for help.\n' 1>&2
	exit 1
fi

#check for api key
if [[ -z "${CLAYAPIKEY}" ]]; then
	#printf 'Create a free api key and set it in the script or export it as an environment variable.\n' 1>&2
	#exit 1

	#dev demo key
	CLAYAPIKEY=35324a150b81290d9fb15e434ed3d264
fi

#set default scale if no custom scale
if [[ -z ${SCL} ]]; then
	SCL=${SCLDEFAULTS}
fi

#set equation arquments
if ! [[ ${1} =~ [0-9] ]]; then
	set -- 1 "${@:1:2}"
fi

if [[ -z ${3} ]]; then
	set -- "${@:1:2}" "${DEFTOCUR}"
fi

#get json once
CLJSON="$(curl --compressed -s "http://www.apilayer.net/api/live?access_key=${CLAYAPIKEY}")"

#print json?
if [[ -n ${PJSON} ]]; then
	printf '%s\n' "${CLJSON}"
	exit 0
#test for error
elif [[ "$(jq -r '.success' <<<"${CLJSON}")" = false ]]; then
	jq -r '.error|.code//empty,.info//empty' <<<"${CLJSON}"
	exit 1
fi

#are user input symbols valid?
if [[ "${2^^}" != USD ]] && ! jq -e ".quotes.USD${2^^}" <<<"${CLJSON}" &>/dev/null; then
	printf 'Err: unsupported FROM_CURRENCY -- %s\n' "${2^^}" 1>&2
	exit 1
elif [[ "${3^^}" != USD ]] && ! jq -e ".quotes.USD${3^^}" <<<"${CLJSON}" &>/dev/null; then
	printf 'Err: unsupported FROM_CURRENCY -- %s\n' "${3^^}" 1>&2
	exit 1
fi

#get currency rates
if [[ ${2^^} = USD ]]; then
	FROMCURRENCY=1
	TOCURRENCY=$(jq -r ".quotes.USD${3^^}" <<< "${CLJSON}")
elif [[ ${3^^} = USD ]]; then
	FROMCURRENCY=$(jq -r ".quotes.USD${2^^}" <<< "${CLJSON}")
	TOCURRENCY=1
else
	FROMCURRENCY=$(jq -r ".quotes.USD${2^^}" <<< "${CLJSON}")
	TOCURRENCY=$(jq -r ".quotes.USD${3^^}" <<< "${CLJSON}")
fi

#transform 'e' to '*10^'
if [[ "${FROMCURRENCY}" =~ e ]]; then
	FROMCURRENCY=$(sed 's/[eE]/*10^/g' <<< "${FROMCURRENCY}")
fi
if [[ "${TOCURRENCY}" =~ e ]]; then
	TOCURRENCY=$(sed 's/[eE]/*10^/g' <<< "${TOCURRENCY}") 
fi

#print timestamp?
if [[ -n ${TIMEST} ]]; then
	JSONTIME=$(jq '.timestamp' <<< "${CLJSON}")
	date -d@"$JSONTIME" '+#%FT%T%Z'
fi

#precious metals in grams?
ozgramf "${2}" "${3}"

#calc equation and print result
bc -l <<< "scale=${SCL};(((${1})*${TOCURRENCY}/${FROMCURRENCY})${GRAM}${TOZ})/1;"

