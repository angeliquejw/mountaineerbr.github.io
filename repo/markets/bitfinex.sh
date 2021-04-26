#!/bin/bash
# Bitfinex.sh  -- Websocket access to Bitfinex.com
# v0.2.26  aug/2020  by mountainner_br

## Some defaults
#if no stock is given, use this:
DEFMARKET=BTCUSD
#decimal plates (scale)
DECDEF=2

#don't change these:
export LC_NUMERIC=C

# BITFINIEX API DOCS
#https://docs.bitfinex.com/reference#ws-public-ticker

HELP="SYNOPSIS
	Bitfinex.sh [-c] [-sNUM|NUM] [SYMBOL]
	Bitfinex.sh [-hlv]


DESCRIPTION
	This script accesses the Bitfinex Exchange public API and fetches
	market data.

	Currently, only the trade live stream is implemented. If no market
	is given, uses ${DEFMARKET}.
	

WARRANTY
	Licensed under the GNU Public License v3 or better and is
	distributed without support or bug corrections.

	It needs the latest version of Bash, Curl or Wget, Gzip, JQ,
	Websocat and Lolcat to work properly.

	If you found this script useful, consider sending me a nickle!
		=)

		bc1qlxm5dfjl58whg6tvtszg5pfna9mn2cr2nulnjr


OPTIONS
	-NUM 	Shortcut for -sNUM .
	-c 	Coloured live stream price (requires Lolcat).
	-h 	Show this help.
	-l 	List available markets.
	-s NUM 	Set number of decimal plates (scale).
		defaults=${DECDEF} .
	-v 	Show script version."

#functions

#list markets
listf() {
	printf "Markets:\n"
	${YOURAPP} "https://api-pub.bitfinex.com/v2/tickers?symbols=ALL" |
		jq -r '.[][0]' | grep -v "^f[A-Z][A-Z][A-Z]*$" |
		tr -d 't' | sort | column -c80
	exit
}

# Bitfinex Websocket for Price Rolling -- Default opt
streamf() {
	#trap user INT signal
	trap 'printf "\nUser interrupt\n" >&2; exit 1' INT

	while true
	do
		echo "{ \"event\": \"subscribe\",  \"channel\": \"trades\",  \"symbol\": \"t${1^^}\" }" |
			websocat -nt --ping-interval 5 "wss://api-pub.bitfinex.com/ws/2 " |
			jq --unbuffered -r '..|select(type == "array" and length == 4)|.[3]' |
			while read
			do
				printf "\n%.${DECIMAL:-${DECDEF}}f" "$REPLY"
			done |
			"${COLOROPT[@]:-cat}"

		N=$((++N))	
		printf "\nPress Ctrl+C to exit.\n"
		printf "Reconnection #%s\n" "${N}" 1>&2
		sleep 5
	done
	exit
}

# Parse options
while getopts :s:lhcv1234567890 opt
do
	case $opt in
		[0-9] ) #decimal setting, same as '-sNUM'                
			DECIMAL="${DECIMAL}${opt}"                               
			;;
			l ) # List Currency pairs
			LOPT=1
			;;
		s ) # Decimal plates (scale)
			DECIMAL="${OPTARG}"
			;;
		h ) # Show Help
			printf "%s\n" "${HELP}"
			exit 0
			;;
		c ) # Coloured price stream
			COLOROPT=( lolcat -p 2000 -F 5 )
			;;
		v ) # Version of Script
			grep -m1 '# v' "${0}"
			exit 0
			;;
		\? )
			printf "Invalid option: -%s\n" "${OPTARG}" 1>&2
			exit 1
			;;
	esac
done
shift $((OPTIND -1))

# Test for must have packages
if ! command -v jq &>/dev/null; then
	printf "JQ is required.\n" 1>&2
	exit 1
fi
if command -v curl &>/dev/null; then
	YOURAPP='curl -sL --compressed'
elif command -v wget &>/dev/null; then
	YOURAPP="wget -qO-"
else
	printf "cURL or Wget is required.\n" 1>&2
	exit 1
fi

#request compressed response
if ! command -v gzip &>/dev/null; then
	printf 'warning: gzip may be required\n' 1>&2
fi

if [[ -z "${LOPT}" ]] && ! command -v websocat &>/dev/null; then
	printf "Websocat is required.\n" 1>&2
	exit 1
fi

#call opt functions
test -n "${LOPT}" && listf

## Check if there is any argument
## And set defaults
if [[ -z "${1}" ]]; then
	set -- "${DEFMARKET}"
fi

## Check for valid market pair
if ! grep -qi "^t${1}$" <<< "$(${YOURAPP} "https://api-pub.bitfinex.com/v2/tickers?symbols=ALL" | jq -r '.[][0]')"; then
	printf "Not a supported currency pair.\n" 1>&2
	printf "List available markets with \"-l\".\n" 1>&2
	exit 1
fi

#default option -- latest trade prices
streamf "${1}"

