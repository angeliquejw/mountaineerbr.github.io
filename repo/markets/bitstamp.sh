#!/bin/bash
# Bitstamp.sh  -- Websocket access to Bitstamp.com
# v0.3.12  jan/2021  by mountainner_br

#defaults
#market
MKTDEF=btcusd

#script name
SN="${0##*/}"
#do not change the following
export LC_NUMERIC=C
DECIMALDEF=2

HELP="SYNOPSIS
	bitstamp.sh [-cisX] [-fNUM] [MARKET]
	bitstamp.sh [-hlv]


DESCRIPTION
	This script accesses the Bitstamp Exchange public API and fetches
	market data. Currently, only the live trade stream is implemented.

	If no market is given, sets $MKTDEF by defaults. If no option is
	set, sets option -s by defaults.

	Options -s and -i shows the same data as in:
	<https://www.bitstamp.net/s/webapp/examples/live_trades_v2.html>

	For very small rates, set decimal plates with option -fNUM, in
	which NUM is an integer.


WARRANTY
	Licensed under the GNU Public License v3 or better and is
	distributed without support or bug corrections.

	This programme requires latest version of Bash, JQ, Websocat
	or Wscat and Lolcat.

	If you found this script useful, consider sending me a nickle!
		=)

		bc1qlxm5dfjl58whg6tvtszg5pfna9mn2cr2nulnjr


OPTIONS
	-NUM 		Same as -fNUM.
	-f [NUM] 	Set number of decimal plates; defaults=2 .
	-i [MARKET] 	Live trade stream with more info.
	-h 	 	Show this help.
	-l 	 	List available markets.
	-s [MARKET] 	Live trade stream (default opt).
	-c		Coloured prices; only with options -si .
	-v 		Show this programme version.
	-X 		Use wscat instead of websocat for websockets."
#https://www.bitstamp.net/websocket/v2/

#trap INT signal
trapf()
{
	trap \  INT HUP

	exit 130
}

#format and print price
printpricef()
{
	local REPLY
	
	while read
	do
		printf "\n%.*f" "${DECIMAL:-$DECIMALDEF}" "$REPLY"
	done
}

#color function, disabled by defaults
colorf()
{
	cat
}

#list mkts
listf()
{
	local url
	url=https://www.bitstamp.net/api/v2/trading-pairs-info/
	
	#just check a currency market?
	if [[ "$1" = check ]]
	then
		grep -qiw "$2" <<<"$("${YOURAPP[@]}" "$url" | jq -r '.[].url_symbol')"
		return
	fi

	#list markets
	"${YOURAPP[@]}" "$url" |
		jq -r '.[]|"\(.name)\t\(.url_symbol)\t\(.base_decimals)\t\(.counter_decimals)\t\(.trading)\t\(.description)"' |
		sort |
		column -et -s$'\t' -NName,Symbol,BaseDec,CountDec,TradeStats,Description -TDescription
}

## Trade stream - Bitstamp Websocket for Price Rolling
streamf() {
	local N tick url query

	#websocket url
 	url=ws.bitstamp.net
	query="{ \"event\": \"bts:subscribe\",\"data\": { \"channel\": \"live_trades_${1,,}\" } }"

	if ((ISTREAMOPT))
	then
		#more info in ticker
		printpricef() { cat ;}
		tick='.data|"P: \(.price // empty) \tQ: \(.amount // empty) \tPQ: \((if .price == null then 1 else .price end)*(if .amount == null then 1 else .amount end)|round)    \t\(.timestamp // empty|tonumber|strflocaltime("%Y-%m-%dT%H:%M:%S%Z"))"'
	else
		#only price ticker
		tick='.data.price // empty'
	fi

	while true
	do
		if ((OPTX==0)) && command -v websocat &>/dev/null
		then
			websocat -nt --ping-interval 20 "wss://$url" <<<"$query"
		elif command -v wscat &>/dev/null
		then
			wscat -w 1000000 -c "wss://$url" -x "$query"
		else
			echo "$SN: websocat or wscat is required" >&2
			exit 1
		fi |
			jq --unbuffered -r "$tick"  |
			printpricef | colorf

		((N++))
		printf "Recconection #${N}\n"
		sleep 4
	done
}

# Parse options
while getopts :1234567890cf:lhsivX opt
do
  case $opt in

	[0-9] ) #scale setting
		DECIMAL="$DECIMAL$opt"
		;;
  	l ) # List Currency pairs
		OPTL=1
		;;
	f ) # Decimal plates
		DECIMAL="${OPTARG}"
		;;
	h ) # Show Help
		echo "${HELP}"
		exit 0
		;;
	i ) # Price stream with more info
		ISTREAMOPT=1
		;;
	s ) # B&W price stream
		STREAMOPT=1
		;;
	c ) # Coloured price stream
		colorf() { lolcat -p 2000 -F 5 ;}
		;;
	v ) # Version of Script
		grep -m1 '# v' "$0"
		exit
		;;
	X ) #prefer wscat instead of websoccat
		OPTX=1
		;;
	\? )
		echo "Invalid Option: -$OPTARG" 1>&2
		exit 1
		;;
  esac
done
shift $((OPTIND -1))

#must have packages
if ! command -v jq &>/dev/null
then
	echo "$SN: JQ is required" >&2
	exit 1
fi

if command -v curl &>/dev/null
then
	YOURAPP=( curl -sL --compressed )
elif command -v wget &>/dev/null
then
	YOURAPP=( wget -qO- )
else
	echo "$SN: curl or wget is required" >&2
	exit 1
fi

## Check if there is any argument
## And set defaults
if [[ ! "$1" =~ [a-zA-Z]+ ]]
then
	set -- "$MKTDEF"
fi
#all to lower case
set -- "${@,,}"
#try to form a market pair
set -- $1$2

## Check for valid market pair
if ! listf check "$1"
then
	echo "Usupported market -- ${1,,}" >&2
	echo 'Run with -l to list available markets.' >&2
	exit 1
fi

#trap ctr+c
trap trapf  INT HUP

#call opt functions

if ((OPTL))
then
	#list markets
	cat <<-!
	Markets:
	$(listf)
	<https://www.bitstamp.net/websocket/v2/>
	!
else
	# Trade price stream
	#default opt
	streamf "${@}"
fi

