#!/bin/bash
# novad.sh  --  market rates from novadax public apis
# v0.1.7  aug/2020  by mountaineerbr

#defaults

#from currency
FROMCURDEF=BTC
#to currency
TOCURDEF=BRL

#scale, decimal plates
SCLDEF=8

#don't change these
export LC_NUMERIC=C
SCRIPT="${BASH_SOURCE[0]:-$0}"
export SCRIPT

HELP="NAME
	novad.sh - Market rates from NovaDax public APIs


SYNOPSIS
	novad.sh [-sNUM] [AMOUNT] [FROM_SYMBOL] [TO_SYMBOL]
	novad.sh -b [LEVELS] [FROM_SYMBOL] [TO_SYMBOL]
	novad.sh [-it] [FROM_SYMBOL] [TO_SYMBOL]
	novad.sh [-hlv]


	Novadax is a brazilian exchange. This script fetches the latest
	data from Novadax public apis. It can convert any amount of one
	currency into another as long as the market pair (ex. ETH BRL)
	is supported by Novadax, or is its reverse equivalent (ex. BRL ETH).

	Get a lits of supported markets with option '-l'. Set the number
	of decimal plates (scale) with '-sNUM' option. Options '-NUM' are
	shortcuts for '-sNUM', where NUM must be a natural number.

 	If currencies are not given, defaults to BTC BRL. Amount can be
	any number or arithmetic expression read by bash calculator bc.


LIMITS
	According to API documentation:


	<<Endpoint Rate Limits
		Public endpoints: up to 60 requests per second for each IP>>

	<https://doc.novadax.com/en-US/#api-access>


WARRANTY
	Licensed under the GNU Public License v3 or better and is dis-
	tributed without support or bug corrections.
   	
	This script requires Bash, cURL or Wget, Gzip and JQ to work
	properly.

	If you found this useful, consider sending me a nickle! =)

		bc1qlxm5dfjl58whg6tvtszg5pfna9mn2cr2nulnjr


USAGE EXAMPLES
		(1) 	One Cardano in brazilian Real:
			
			$ novad.sh ada brl


		(2) 	One thousand brazilian Reais in Bitcoin, eight decimal
			plates:
			
			$ novad.sh -s8 1000 brl btc
			
			$ novad.sh -8  1000 brl btc


		(3) 	Order book depth, 10 levels each side:
			
			$ novad.sh -d 10 eth btc


		(4) 	Detailed information of the last 20 trades:
			
			$ novad.sh -i 20 eth btc


OPTIONS
	-NUM 	  Shortcut for setting scale, same as -sNUM .
	-b LEVELS Order book depth; max levels=20; defaults=20 .
	-h 	  Show this help.
	-i        Detailed information of last trades; max trades=100; defaults=100 .
	-j 	  Debugging, print json.
	-l 	  List supported markets.
	-s NUM    Number of decimal plates; defaults=$SCLDEF .
	-t 	  Rolling 24h ticker of all markets.
	-v        Script version."

#functions

#error check
errf()
{
	local msg

	#test for error signals
	if msg="$( jq -re .message )" &&
		[[ "$msg" = [sS]uccess ]]
	then
		return 0
	else
		return 1
	fi
}

#novadax
#order book depth
bookdf()
{
	#set levels
	(( $1 - 1 )) || set -- 20 "$2" "$3"

	"${YOURAPP[@]}" "https://api.novadax.com/v1/market/depth?symbol=${2}_${3}&limit=${1}" |
		jq -r '.data|
			(.asks|reverse|.[range(1;length)]|"\t\(.[0])   \t\(.[1])"),
			(.asks|reverse[-1]|"     > \(.[0])   \t\(.[1])"),
			(.bids|reverse[-1]|"     < \(.[0])   \t\(.[1])"),
			(.bids|.[range(1;length)]|"\t\(.[0])   \t\(.[1])")'
}

#last trades info
infof()
{
	#how many trades?
	[[ "${NOUSRARG}" = *1* ]] && set -- 100 "${2}" "${3}"

	DATA="$("${YOURAPP[@]}" "https://api.novadax.com/v1/market/trades?symbol=${2}_${3}&limit=${1}")"

	#print json?
	if (( PJSON ))
	then
		printf '%s\n' "${DATA}"
		exit 0
	fi
	
	#print table
	jq -r '.data|reverse[]|"\(.price)\t\(.amount)\t\(.side)\t\(.timestamp/1000|strflocaltime("%FT%H:%M:%S%Z"))"' <<<"${DATA}" |
		column -et -NPRICE,AMOUNT,SIDE,TIME
}

#ticker 
tickerf()
{
	if [[ "${NOUSRARG}" = *2* ]]
	then

		DATA="$( "${YOURAPP[@]}" 'https://api.novadax.com/v1/market/tickers' )"
		
		#print json?
		if (( PJSON ))
		then
			printf '%s\n' "${DATA}"
			exit 0
		fi
		
		#test columns
		[[ "$(tput cols)" -lt 138 ]] && HCOL='-HQUOTEVOL,TIMESTAMP'
		[[ "$(tput cols)" -lt 110 ]] && HCOL='-HQUOTEVOL,TIMESTAMP,HIGH,LOW'
		[[ "$(tput cols)" -lt 82  ]] && HCOL='-HQUOTEVOL,TIMESTAMP,OPEN,HIGH,LOW'
		[[ -t 1 ]] || unset HCOL
		[[ -n "${HCOL}" ]] && printf 'More columns are needed to print more information!\n' 1>&2

		#format tickers
		jq -r '"All 24H rolling tickers",
			(.data[]|
				"\(.symbol)\t\(.lastPrice)\t\(.bid)\t\(.ask)\t\(.baseVolume24h)\t\(.quoteVolume24h)\t\(.open24h)\t\(.high24h)\t\(.low24h)\t\(.timestamp/1000|strflocaltime("%FT%H:%M:%S%Z"))"
			)' <<< "${DATA}" |
				column -et -NMARKET,LPRICE,BID,ASK,BASEVOL,QUOTEVOL,OPEN,HIGH,LOW,TIMESTAMP ${HCOL}
			
		printf 'Markets: %s\n' "$(jq -r '.data[].symbol' <<<"${DATA}" | wc -l)"
	else
		DATA="$( "${YOURAPP[@]}" "https://api.novadax.com/v1/market/ticker?symbol=${2}_${3}" )"
		
		#print json?
		if (( PJSON ))
		then
			printf '%s\n' "${DATA}"
			exit 0
		fi
		
		#format single ticker
		jq -r '"24H rolling ticker",
			(.data|
				"LoclTime: \(.timestamp/1000|strflocaltime("%FT%H:%M:%S%Z"))",
				"Market__: \(.symbol)",
				"Base_Vol: \(.baseVolume24h)",
				"QuoteVol: \(.quoteVolume24h)",
				"Open____: \(.open24h)",
				"High____: \(.high24h)",
				"Low_____: \(.low24h)",
				"Ask_____: \(.ask)",
				"Bid_____: \(.bid)",
				"LastPric: \(.lastPrice)"
			)' <<< "${DATA}"
	fi
}

#list currencies
listf()
{
	if [[ -z "${LIST}" ]]
	then
		DATA="$( "${YOURAPP[@]}" 'https://api.novadax.com/v1/common/symbols' )"
	
		#print json?
		if [[ -n "${PJSON}" ]] && [[ -n "${LOPT}" ]]
		then
			printf '%s\n' "${DATA}"
			exit 0
		fi
		
		#make a simple list, do not print yet
		export LIST="$(jq -r '.data[].symbol' <<<"${DATA}")"
	else
		return 0
	fi
}

#parse options
while getopts 1234567890bhjlis:tv opt
do
	case ${opt} in
		( [0-9] )
			#decimal setting
			SCL="${SCL}${opt}"
			;;
		( b )
			#order book depth view
			(( BOPT )) && BOPT=2 || BOPT=1
			;;
		( h )
			#help
			echo "${HELP}"
			exit 0
			;;
		( i )
			#detailed latest trade information
			IOPT=1
			;;
		( j )
			#print json?
			PJSON=1
			;;
		( l )
			#list markets
			LOPT=1
			;;
		( s )
			#scale
			SCL="${OPTARG}"
			;;
		( t )
			#rolling ticker 
			TOPT=1
			;;
		( v )
			#script version
			grep -m1 '\# v' "${0}"
			exit 0
			;;
		( \? )
			#illegal option
			#echo 'Invalid option: -${OPTARG}" >&2
			exit 1
			;;
	esac
done
shift $((OPTIND -1))

#must have packages
if ! command -v jq &>/dev/null
then
	echo 'JQ is required' >&2
	exit 1
fi
if command -v curl &>/dev/null
then
	YOURAPP=(curl -sL --compressed)
elif command -v wget &>/dev/null
then
	YOURAPP=(wget -qO-)
else
	echo 'Curl or wget is required' >&2
	exit 1
fi
#warning: gzip may be required

#all caps and split at _/.,-
set -- $( tr 'a-z_/.,-' 'A-Z ' <<< "$*" )

#arrange arguments
#if first arg does not have numbers OR isn't a valid bc expression
if [[ ! "${1}" =~ ^[0-9]*$ ]] ||
	[[ -z "$(bc <<< "${1}" 2>/dev/null)" ]]
then
	NOUSRARG=1
	set -- 1 "${@:1:2}"
fi

#set btc as 'from_currency' for market code formation
if [[ -z ${2} ]]
then
	NOUSRARG+=2
	set -- "${1}" "$FROMCURDEF"
fi


#set btc as 'from_currency' for market code formation
if [[ -z ${3} ]]
then
	set -- "${1}" "${2}" "$TOCURDEF"
fi

#set scale
if [[ ! "${SCL}" =~ ^[0-9]+$ ]]
then
	SCL="${SCLDEF}"
fi

#call opt functions
if (( LOPT ))
then
	listf
	sort <<< "${LIST}" | column -c"$(tput cols)"

	printf 'Markets: %s\n' "$(wc -l <<<"${LIST}")"
#check if pair is valid
elif listf ;! grep -q "^${2}_${3}$" <<<"${LIST}"
then
	#check if reverse market is available
	#only for the currency converter opt
	if [[ -z "${IOPT}${BOPT}${TOPT}" ]] &&
		grep -q "^${3}_${2}$" <<< "${LIST}"
	then
		INV="$( bash "${SCRIPT}" -s16 "${3}" "${2}" )"
		INVINV="$( bc <<< "scale=16;${1}*(1/${INV})" )"
		printf "%.${SCL}f\n" "${INVINV}"
		exit
	else
		echo "Err: invalid market -- ${2} ${3}" >&2
		exit 1
	fi
#call more opt functions
#last trade inf
elif (( IOPT ))
then
	infof "${@}"
#order book depth
elif (( BOPT ))
then
	bookdf "${@}"
#ticker
elif (( TOPT ))
then
	tickerf "${@}"
#default function -- currency converter
else
	#get price data
	DATA="$( "${YOURAPP[@]}" "https://api.novadax.com/v1/market/ticker?symbol=${2}_${3}" )"

	#print json?
	if (( PJSON ))
	then
		printf '%s\n' "${DATA}"
		exit 0
	fi

	RATE="$( jq -r '.data.lastPrice' <<< "${DATA}" )"

	#calc and printf results
	printf "%.${SCL}f\n" "$( bc <<< "scale=16; (${1}) * ${RATE} / 1" )"
fi

