#!/bin/bash
# Binance.sh  --  Market data from Binance public APIs
# v0.12.3  apr/2021  by mountaineerbr

#defaults

#data server
WHICHB=com
#com -- Malta
#us -- US
#je -- Jersey (DEPRECATED)

#scale, server defaults
SCLDEFAULTS=16

#option -r
#sleep between repeated curl calls
RSLEEP=2  #defaults=2 seconds

#make sure locale is set correctly
export LC_NUMERIC=en_US.UTF-8

#script name
SN="${0##*/}"

#binance resource files (optional)
#use cache files? set to 0 to disable
OPTE=1
#expiration of cache files in seconds
#set to 0 or unset to disable expiration
#BNCEXPIRATION=259200  #(3 days)
#cache directory
USERCACHE=/tmp
#USERCACHE="${XDG_CACHE_HOME:-$HOME/.cache}"
#list of from_currencies  (binance.sh.json)
BNCTEMPLIST="$USERCACHE/$SN.json"

HELP="NAME
	$SN - Market data from Binance public APIs


SYNOPSIS
	$SN [-NUM] [-eouv] [AMOUNT] MARKET
	$SN [-NUM] -n [-eov] [AMOUNT] FROM_CURRENCY TO_CURRENCY
	$SN [-NUM] [-aeciorstwzX] [-u] MARKET
	$SN [-bbt] [-ue] MARKET
	$SN [-hlUV]

	Get the latest data from Binance markets from public APIs. This 
	script can calculate any amount of one cryptocurrency into
	another crypto or supported bank currency.


DESCRIPTION
	MARKET is formed by a currency pair. Currency pair symbols should 
	preferably be separated by a blank space.

	List all supported markets with option -l. Note that the reverse
	rate of those markets listed is also supported, i.e both XRP/BTC
	and BTC/XRP rates are supported.  

	Choose which Binance server to get data from. Option -u to set
	<binance.us> US, otherwise defaults to <binance.com> from Malta.
	Option -j is deprecated (set <binance.je> Jersey server).

	If no market is given, defaults to BTC/USDT. If option -u is set,
	defaults to BTC/USD.

	The number of decimal plates is the same received from the server
	unless explicitly set with option -NUM, in which NUM is a natural
	number (integer).

	Option -o sets thousands separator in printing results.

	To keep trying to reconnect to the websocket automatically on
	error or EOF, set option -a (only if using Websocat package).
	Beware this option may cause high CPU usage until reconnection
	is achieved!

	Some functions use Curl/Wget to fetch data from REST APIs and
	some use Websocat (defaults) or Wscat packages to fetch data from
	websockets. Set -X if you prefer using Wscat instead of Websocat.

	Option -r sets Curl or Wget to fetch data instead of opening
	a websocket, defaults sleep time (seconds) between consecutive
	calls is $RSLEEP .

	Setting options for REST APIs instead of websockets update
	little slower because REST depend on connecting repeatedly,
	whereas websockets leave an open connection.

	Option -n calculates rates for national (bank) currency pairs,
	such as \`EUR GBP', \`USD BRL', or pairs that are neither sup-
	ported by Binance nor their reverse, such as \`XRP DOGE'. Some
	market rates may have implicit Binance spreads when calculated,
	which may be up to ~1-2% off from rates elsewhere. I reckon
	Binance has got diferential spreads for some currency pairs and
	possibly between Binance Malta and Binance US, which become
	evident when calculating custom rates with this option, see usage
	example (7). This option is set automatically if the script cannot
	fetch rates for user-input market pair with the defaults function.

	By defaults, the script will keep a local cache of the available
	currency ids from Binance. That will avoid flooding the server
	with requests of mostly static data and will improve script speed.
	If you do not want to create/use cache files, set option -e. Run
	script with option -U to force updating cache files, otherwise
	they will not be updated automatically unless \$BNCEXPIRATION is
	set, see script head source code. Cache defaults=$USERCACHE .


LIMITS ON WEBSOCKET
	From Binance API website:

		<<A single connection to stream.binance.com is only
		valid for 24 hours; expect to be disconnected at the
		24 hour mark>>

	<binance-docs.github.io/apidocs/spot/en/#symbol-order-book-ticker>


WARRANTY
	Licensed under the GNU Public License v3 or better and is
	distributed without support or bug corrections.
   	
	This script requires Bash, cURL or Wget, Gzip, JQ , Websocat or
	Wscat, Lolcat and GNU Coreutils to work properly.

	If you found this useful, please consider sending me a nickle! 
		=)

		bc1qlxm5dfjl58whg6tvtszg5pfna9mn2cr2nulnjr


BUGS
	While not a bug due to this script code, beware of unlimited
	scrollback buffers of your terminal emulator. As a lot of data
	is printed, scrollback buffers should be kept small or completely
	unset in order to avoid system freezes due to buffer usage.


USAGE EXAMPLES
	(1) 	One Bitcoin in US Dollar from <binance.com> US:
		
		$ $SN -u btc usd


	(2)     Half a Dash in Binance Coin, using a math
		expression in AMOUNT:
		
		$ $SN '(3*0.15)+.05' dash bnb 


	(3)     Price of one XRP in USDC, four decimal plates:
		
		$ $SN -4 xrp usdc 

	
	(4)     Price stream of BTCUSDT, group thousands; print
		only one decimal plate and add thousand separator:
		
		$ $SN -s -o -1 btc usdt

		$ $SN -so1 btc usdt


	(5) 	Order book depth view of ETHUSDT (20 levels on
		each side), data from <binance.us> US server:

		$ $SN -bbu eth usdt


	(6)     Get rates for all Bitcoin markets; run grep to
		search for specific markets:
		
		$ $SN -l  |  grep BTC


		OBS: \"grep '^BTC'\" matches markets starting
		with BTCxxx; \"grep 'BTC$'\" matches markets
		ending  with xxxBTC.


	(7)     Calculate rates for EUR against GBP (some other
		markets may have spreads calculated with them):
		
		$ $SN -n eur gbp 


OPTIONS
	Formatting
	-NUM 	   Decimal plate setting (scale).
	-o 	   Add a thousands separator to printed results.

	Miscellaneous
	-a 	   Autoreconnect in case of temporary errors, only when
		   using Websocat package; defaults=unset.
	-d 	   Print raw data from API, for debugging.
	-e 	   Don't make or keep cache data (currency ids).
	-h 	   Show this help.
	-j 	   Set <binance.je> server; defaults=<binance.com>.
	-l 	   List supported markets.
	-r 	   Set Curl/Wget instead of websocket with options -swi .
	-U 	   Force update cache data from Binance.
	-u 	   Set <binance.us> server; defaults=<binance.com>.
	-V 	   Print script version.
	-v 	   Print market pair.
	-X 	   Set Wscat instead of Websocat package for websockets.
	
	Functions
	-b  [LEVELS] MARKET
		   Order book depth; valid limits 5, 10 and 20; defaults=20.
	-bb [LEVELS] MARKET
		   Calculate bid and ask sizes from order book;
		   max levels 5000-10000; defaults=10000.
	-c  [LIMIT] MARKET 
		   Price in columns; optionally, limit number of orders 
		   fetched at a time; max=1000; defaults=250.
	-i  MARKET 
		   Detailed information of the trade stream.
	-n [AMOUNT] FROM_CURRENCY TO_CURRENCY
		   Fetch rates for national (bank) currency pairs or
		   unsupported pairs; some market rates may have
		   implicit spreads when calculated.
	-t  MARKET Rolling 24h ticker.
	-s  MARKET Stream of latest trades.
	-w  MARKET Coloured stream of latest trades, requires lolcat.
	-z 	   Print UTC0 (GMT) time with options -it ."


#functions

#national (bank) currency function
#rates `may' differ up to ~1-2% from elsewhere
#that is because Binance has got spreads that
#are taken into account these customrates are calculated
bankf()
{
	local WHICHB MKT REVMKT ADDR DATA BRATE RATE whichs c
	typeset -a whichs

	#verbose?
	((OPTV)) && echo Spread fees may apply >&2

	#for each currency
	for c in "${@:2:2}"
	do
		#try Binance Malta and Binance US
		for WHICHB in com us
		do
			#verbose
			((OPTV)) && echo "Checking server: Binance.${WHICHB}" >&2

			#get supported market list
			loadmarketsarrayf

			#check and see if reverse market rate is in order
			if [[ ! \ "${MARKETS[*]}"\  = *\ BTC${c^^}\ * ]] &&
				[[ \ "${MARKETS[*]}"\  = *\ ${c^^}BTC\ * ]]
			then
				REVMKT=1/

				#verbose
				((OPTV)) && echo "Reverse rate of supported market: $c BTC" >&2
			elif [[ ! \ "${MARKETS[*]}"\  = *\ BTC${c^^}\ * ]]
			then
				if [[ "$WHICHB" = us ]]
				then
					echo "err: invalid currency -- $c" >&2
					return 1
				else
					continue
				fi
			fi

			#save selected binance server
			whichs+=( "$WHICHB" )

			#set market (is the reverse market rate?)
			[[ -z "$REVMKT" ]] && MKT="BTC${c}" || MKT="${c}BTC"

			#address for default func (get rates only)
			ADDR="https://api.binance.${WHICHB}/api/v3/ticker/price?symbol=$MKT" 
			#get data
			DATA="$( "${YOURAPP[@]}" "$ADDR" )"
			#print raw data for debug?
			(( DOPT )) && echo "$DATA" && continue

			BRATE=$( jq -er .price <<<"$DATA" )
			RATE="$( bc <<< "scale=20 ; ( $1 ) * ( $REVMKT $BRATE )" )"

			break
		done
		
		[[ -z "$FROMRATE" ]] && FROMRATE="$RATE" || TORATE="$RATE"

		unset ADDR DATA MKT BRATE RATE R c
	done

	#verbose
	((OPTV)) && echo "Selected servers: ${whichs[*]}" >&2

	#debug opt is enabled?
	(( DOPT )) && return

	#calculate result and print raw result
	bc <<< "scale=16; ( (${1}) * ${TORATE})/${FROMRATE}"
}

## Cache manager
cachef()
{
	local file url ret stamp0 stamp
	file="$1" url="$2"

	#check cache files availability
	if ((OPTE)) && [[ -d "$USERCACHE" ]]
	then
		#if cache file exists
		#if file stamp is less than expiration
		if [[ -s "$file" ]] && {
			(( BNCEXPIRATION==0)) || {
			stamp0=$(date +%s) stamp=$(stat --printf='%Y\n' "$file") &&
			(( stamp0 < (stamp+BNCEXPIRATION) ))
			}
		}
		then cat "$file" ;return
		elif "${YOURAPP[@]}" "$url" >"$file"
		then cat "$file" ;return
		fi
	fi
 	
	#print to stdout (no cache)
	"${YOURAPP[@]}" "$url"
}
#update user cahe files
cacheupf()
{
	local ret
	#check cache files availability
	if ((OPTE)) && [[ -d "$USERCACHE" ]]
	then
		#update cache files manually
		echo 'Updating Binance resource file(s) (JSON data)..' >&2
		#update cache
		echo "$BNCTEMPLIST" >&2
		"${YOURAPP[@]}" "$LISTADDR" >"$BNCTEMPLIST" ;ret+=( $? )
	else
		((OPTE)) || echo "$SN: err -- option -e is set" >&2
		[[ -d "$USERCACHE" ]] || echo "$SN: user cache unavailable -- $USERCACHE" >&2
		ret+=( 1 )
	fi

	#sum exit codes
	return $(( ${ret[@]/%/+} 0 ))
}

#get supported market list, required for following funcs
loadmarketsarrayf()
{
	if (( ${#MARKETS[@]} == 0 ))
	then MARKETS=( $( cachef "$BNCTEMPLIST" "$LISTADDR" | jq -r '.[].symbol' ) ) ;return
	fi

	return 0
}

#check to currency
checktocurf()
{
	#test if market/currency is valid
	if ((BANK==0)) && loadmarketsarrayf &&
		[[ ! \ "${MARKETS[*]}"\  = *\ ${2^^}${3^^}\ * ]]
	then
		#default option
		#check and see if reverse market rate is available
		if [[ -z "$IOPT$SOPT$BOPT$BOPT$TOPT$COPT" ]] &&
			[[ \ "${MARKETS[*]}"\  = *\ ${3^^}${2^^}\ * ]]
		then REVMKT=1/  ;((OPTV)) && echo "Reverse rate of supported market: $3 $2" >&2
		else return 1
		fi
	fi

	return 0
}

#error check
errf() {
	#test for error signals
	if grep -iq -e 'err' -e 'code' <<< "$JSON"
	then
		#set log file
		LOGF="/tmp/binance_err.log$( date +%s )"
		
		#print json and log, too
		echo "$JSON" | tee "$LOGF" >&2
		echo "$SN: err detected in json" >&2
		echo "$SN: log file at $LOGF" >&2
		
		exit 1
	fi
}

#-c price in columns
colf() {
	#check if given limit is valid - max 1000
	if (( $1 < 2 )) || (( $1 > 1000 ))
	then set -- 250 "$2" "$3"
	fi
	 
	#set addr
	ADDR="https://api.binance.${WHICHB}/api/v3/aggTrades?symbol=${2}${3}&limit=${1}"
	
	#print raw data for debug?
	if (( DOPT ))
	then
		"${YOURAPP[@]}" "$ADDR"
		echo
		exit 
	fi

	#loop to get prices and print
	while true
	do
		#get data
		JSON="$( "${YOURAPP[@]}" "$ADDR" )"
		
		#check for errors
		errf

		#process data
		jq -r '.[] | .p' <<< "$JSON" |
			awk '{ printf "'${FSTR}'\n", $0 }' |
			column 

		echo
	done
}

#-i price and trade info
infof() {
	#-r use curl
	curlmode() {
		#set addr
		ADDR="https://api.binance.${WHICHB}/api/v3/trades?symbol=${2}${3}&limit=1"

		#print raw data for debug?
		if [[ -n "$DOPT" ]]; then
			"${YOURAPP[@]}" "$ADDR"
			printf '\n'
			exit 
		fi

		#heading
		printf -- 'Rate, quantity, quote quantity and time (%s)\n' "$2$3"
		
		#print data in one column and update regularly
		while true; do
			#get data
			JSON="$( "${YOURAPP[@]}" "$ADDR" )"
			
			#check for errors
			errf
			
			#process data
			RATE="$(jq -r '.[] | .price' <<< "$JSON")"
			QT="$(jq -r '.[] | .qty' <<< "$JSON")"
			QQT="$(jq -r '.[] | .quoteQty' <<< "$JSON")"
			TS="$(jq -r '.[] | .time | tostring | .[0:10]' <<< "$JSON" )"
			DATE="$(date -d@"$TS" '+%T%Z' )"
			
			#print
			printf "\nP: ${FSTR}\tQ: %s\tPQ: %'f \t%s" "$RATE" "$QT" "$QQT" "$DATE" 

			sleep "$RSLEEP"
		done
		exit 0
	}
	(( CURLOPT )) && curlmode "$@"

	#websocat mode

	#set addr
	ADDR="$WSSADD${2,,}${3,,}@aggTrade" 

	#print raw data for debug?
	if (( DOPT ))
	then
		"${WEBSOCATC[@]}" "$ADDR"
		echo
		exit 
	fi
	
	#heading
	printf -- 'Detailed stream of %s %s\n' "${2^^}" "${3^^}"
	printf -- 'Price, quantity, quote quantity and time\n'
	
	#open websocket
	"${WEBSOCATC[@]}" "$ADDR" |
		jq --unbuffered -r '"P: \(.p|.[0:11])\tQ: \(.q|.[0:11])\tPQ: \(((.p|tonumber)*(.q|tonumber))|tostring|.[0:10])\t\(if .m == true then "MAKER" else "TAKER" end)\t\(.T/1000|strflocaltime("%Y-%m-%dT%H:%M:%S%Z"))"'
}

#-s -w stream of prices
socketf() {
	#-r use curl
	curlmode() { 
		#set addr
		ADDR="https://api.binance.${WHICHB}/api/v3/aggTrades?symbol=${2}${3}&limit=1"

		#print raw data for debug?
		if (( DOPT ))
		then
			"${YOURAPP[@]}" "$ADDR"
			echo
			exit 
		fi

		#heading
		printf -- 'Rate for %s %s\n' "${2^^}" "${3^^}"

		while true
		do
			JSON="$( "${YOURAPP[@]}" "$ADDR" )"
	 		errf

			jq -r '.[] | .p' <<< "$JSON" | 
				awk '{ printf "\n'${FSTR}'", $1 }' |
				"${COLORC[@]}"

			sleep "$RSLEEP"
		done
		exit 0
		}
	(( CURLOPT )) && curlmode "$@"
	
	#websocat Mode

	#set addr
	ADDR="$WSSADD${2,,}${3,,}@aggTrade" 


	#print raw data for debug?
	if (( DOPT ))
	then
		"${WEBSOCATC[@]}" "$ADDR"
		echo
		exit 
	fi

	#heading
	printf 'Stream of %s %s\n' "${2^^}" "${3^^}"

	#open websocket
	"${WEBSOCATC[@]}" "$ADDR" |
		jq --unbuffered -r '.p' |
		while read
		do
			printf "\n${FSTR}" "$REPLY"
		done |
		"${COLORC[@]}"
}
#stdbuf -i0 -o0 -e0 cut -c-8

#-b depth view of order book
bookdf() {
	#test if user set depth limit
	if [[ ! "$1" =~ ^(5|10|20)$ ]]
	then
		set -- 20 "$2" "$3"
		(( $1 - 1 )) || echo -e "$SN: warning -- invalid limit\n\n" >&2
		sleep 1
	fi

	#set addr
	ADDR="$WSSADD${2,,}${3,,}@depth${1}@100ms" 
	
	#print raw data for debug?
	if (( DOPT ))
	then
		"${WEBSOCATC[@]}" "$ADDR"
		echo
		exit 
	fi

	#heading
	printf 'Order book %s %s\n' "${2^^}" "${3^^}"
	printf 'Price and quantity\n'
	
	#open websocket and process data
	"${WEBSOCATC[@]}" "$ADDR" |
	jq -r --arg FCUR "$2" --arg TCUR "$3" '
		"\nORDER BOOK \($FCUR)\($TCUR)",
		"",
		(.asks|[.[range(1;length)]]|reverse[]|
			"\t\(.[0]|.[0:14])\t\(.[1]|tonumber)"
		),
		(.asks[0]|"     > \(.[0]|.[0:15])\t\(.[1]|tonumber)"),
		(.bids[0]|"     < \(.[0]|.[0:15])\t\(.[1]|tonumber)"),
		(.bids|.[range(1;length)]|
			"\t\(.[0]|.[0:14])\t\(.[1]|tonumber)"
		)'

	echo
}

#-bb order book total sizes
booktf() {
	#check if user set limit
	if
		deflimit=10000
		valid='5|10|20|50|100|500|1000|5000|10000'
		[[ ! "$1" =~ ^($valid)$ ]]
	then
		set -- $deflimit "$2" "$3"
		echo "$SN: valid limits -- ${valid//|/ }" >&2
		echo "$SN: warning -- limit level set to $deflimit" >&2
	fi

	#set addr
	ADDR="https://api.binance.${WHICHB}/api/v3/depth?symbol=${2}${3}&limit=${1}" 
	
	#print raw data for debug?
	if (( DOPT ))
	then
		"${YOURAPP[@]}" "$ADDR"
		echo
		exit 
	fi

	#heading
	printf 'Order book sizes\n\n'

	#get data
	BOOK="$( "${YOURAPP[@]}" "$ADDR" )"
	
	#process data
	#bid levels and total size
	if ! BIDS=($(jq -er '.bids[]|.[1]' <<<"$BOOK"))
	then
		#if there was error, check if there is a message
		jq -r .msg//empty <<<"$BOOK"
		exit 1
	fi
	BIDSL="${#BIDS[@]}"
	BIDST="$(bc <<<"${BIDS[*]/%/+}0")"
	BIDSQUOTE=($(jq -r '.bids[]|((.[0]|tonumber)*(.[1]|tonumber))' <<<"$BOOK")) 
	BIDSQUOTET="$(bc <<<"scale=2;(${BIDSQUOTE[*]/%/+}0)/1")"
	
	#ask levels and total size
	ASKS=($(jq -r '.asks[]|.[1]' <<<"$BOOK"))
	ASKSL="${#ASKS[@]}"
	ASKST="$(bc <<<"${ASKS[*]/%/+}0")"
	ASKSQUOTE=($(jq -r '.asks[]|((.[0]|tonumber)*(.[1]|tonumber))' <<<"$BOOK")) 
	ASKSQUOTET="$(bc <<<"scale=2;(${ASKSQUOTE[*]/%/+}0)/1")"
	
	#total levels and total sizes
	TOTLT="$(bc <<<"${BIDSL}+${ASKSL}")"
	TOTST="$(bc <<<"${BIDST}+${ASKST}")"
	TOTQUOTET="$(bc <<<"${BIDSQUOTET}+${ASKSQUOTET}")"

	#bid/ask rate
	BARATE="$(bc <<<"scale=4;${BIDST}/${ASKST}")"
	
	#print stats
	#ratio  #printf 'BID/ASK  %s\n\n' "$BARATE"
	
	#table
	column -ts= -N"${2}${3},SIZE,QUOTESIZE,LEVELS" -TSIZE <<-!
	ASKS=${ASKST}=${ASKSQUOTET}=${ASKSL}
	BIDS=${BIDST}=${BIDSQUOTET}=${BIDSL}
	TOTAL=${TOTST}=${TOTQUOTET}=${TOTLT}
	BID/ASK=${BARATE}
	!
}

#-t 24-h ticker
tickerf() {
	#set addr
	ADDR="$WSSADD${2,,}${3,,}@ticker" 
	
	#print raw data for debug?
	if (( DOPT ))
	then
		"${WEBSOCATC[@]}" "$ADDR"
		echo
		exit 
	fi

	#open websocket and process data
	"${WEBSOCATC[@]}" "$ADDR" |
		jq -r '"","---",
			.s,.e,(.E/1000|strflocaltime("%Y-%m-%dT%H:%M:%S%Z")),
			"TimeRang: \(((.C-.O)/1000)/(60*60)) hrs",
			"",
			"Price",
			"Change__: \(.p|tonumber)  \(.P|tonumber)%",
			"Weig.Avg: \(.w|tonumber)",
			"Open____: \(.o|tonumber)",
			"High____: \(.h|tonumber)",
			"Low_____: \(.l|tonumber)",
			"Base_Vol: \(.v|tonumber)",
			"QuoteVol: \(.q|tonumber)",
			"",
			"Trades",
			"Number__: \(.n)",
			"First_ID: \(.F)",
			"Last__ID: \(.L)",
			"FirstT-1: \(.x)",
			"Best_Bid: \(.b|tonumber)  Qty: \(.B)",
			"Best_Ask: \(.a|tonumber)  Qty: \(.A)",
			"LastTrad: \(.c|tonumber)  Qty: \(.Q)"'

	echo
}

#-l list markets and prices
lcoinsf() {
	#set addr
	ADDR="https://api.binance.${WHICHB}/api/v3/ticker/price" 

	#get data
	DATA="$( "${YOURAPP[@]}" "$ADDR" )"
	
	#print raw data for debug?
	if (( DOPT ))
	then
		echo "$DATA"
		exit 
	fi

	#get data
	PRELIST="$(jq -er '.[] | "\(.symbol)\t\(.price)"' <<< "$DATA")" || return
	
	#format data
	<<<"$PRELIST" sort | column -s$'\t' -et -N 'Market,Rate'
	
	#stats
	printf 'Markets: %s\n' "$(jq -r '.[].symbol' <<< "$DATA"| wc -l)"
	printf '<https://api.binance.%s/api/v3/ticker/price>\n' "$WHICHB"
}


#parse options
while getopts 1234567890abcdeofhjlnistUuvVwrXz opt
do
	case $opt in
		[0-9]) #scale setting
			SCL="$SCL$opt"
			;;
		a) 	#autoreconnect
			AUTOR=( - autoreconnect: )
			;;
		b) #order book depth view
			(( BOPT )) && BOPT=2 ||	BOPT=1
			;;
		c) #price in columns
			COPT=1
			;;
		d) #print lines that fetch data
			#printf 'Script cmds to fetch data:\n'
			#grep -e 'YOURAPP' -e 'WEBSOCATC' <"$0" | sed -e 's/^[ \t]*//' | sort
			DOPT=1
			;;

		e )
			## Dont use cache files
			OPTE=0
			;;
		o|f) #format thousands option
			THOUSANDOPT="'"
			;;
		h) #help
			echo "$HELP"
			exit 0
			;;
		i) #detailed latest trade information
			IOPT=1
			;;
		j) #binance jersey (DEPRECATED)
			echo "$SN: deprecation notice -- option -j" >&2
			WHICHB=je
			;;
		l) #list markets
			LOPT=1
			;;
		n)
			#bank/national currencies
			BANK=1
			;;
		r) #curl instead of websocat
			CURLOPT=1
			;;
		s) #stream of trade prices
			COLORC=(cat)
			SOPT=1
			;;
		t) #rolling ticker 
			TOPT=1
			;;
		u) #binance us
			WHICHB='us'
			;;
		U )
			## update user cache files
			OPTU=1
			;;
		V) #script version
			grep -m1 '\# v' "$0"
			exit 0
			;;
		v) #verbose, currently little implemented
			OPTV=1
			;;
		w) #coloured stream of trade prices
			SOPT=1
			COLORC=(lolcat -p 2000 -F 5)
			;;
		X) #prefer wscat instead of websoccat
			XOPT=1
			;;
		z) #time in UTC and nanoseconds
			export TZ=UTC
			;;
		\?)
			#echo "$SN: invalid option -- -$OPTARG" >&2
			exit 1
			;;
	esac
done
shift $((OPTIND -1))

#set and export variables
LISTADDR="https://api.binance.${WHICHB}/api/v3/ticker/price" 
export LISTADDR MARKETS
typeset -a MARKETS


#must have packages
if ! command -v jq &>/dev/null
then echo "$SN: JQ is required" >&2 ;exit 1
elif command -v curl &>/dev/null
then YOURAPP=( curl -sL --compressed )
elif command -v wget &>/dev/null
then YOURAPP=( wget -qO- )
else echo "$SN: curl or wget is required" >&2 ;exit 1
fi

#call opt funcs
if (( LOPT ))
then
	lcoinsf
	exit
#update user cahe files
elif (( OPTU ))
then
	cacheupf
	exit
fi

#set websocket pkg
#websocat command
if [[ -n "$IOPT$SOPT$BOPT$TOPT" ]] && [[ -z "$CURLOPT" ]]
then
	#choose websocat or wscat
	if ((XOPT==0)) && command -v websocat &>/dev/null
	then WEBSOCATC=( websocat -nt --ping-interval 20 -E --ping-timeout 42 ${AUTOR[0]} )
	elif command -v wscat &>/dev/null
	then WEBSOCATC=( wscat -c ) ;unset AUTOR
	else echo "$SN: websocat or wscat is required" >&2 ;exit 1
	fi
	
	#set websocket address
	WSSADD="${AUTOR[1]}wss://stream.binance.${WHICHB}:9443/ws/"
fi

#make printf string (1)
[[ -z "$THOUSANDOPT$SCL" ]] && FSTR=%s

#set scale
if [[ "$SCL" != 0 ]] && ! (( SCL ))
then
	SCL="$SCLDEFAULTS"

	#if option -o is set, scale defaults to 2
	[[ -n "$THOUSANDOPT" ]] && SCL=2
fi

#make printf formatting string
[[ -z "$FSTR" ]] && FSTR="%${THOUSANDOPT}.${SCL}f"

#arrange arguments
#if first arg does not have numbers OR isnt a valid bc expression
if [[ "$1" != *[0-9]* ]] ||
	[[ -z "$( bc -l <<< "$1" 2>/dev/null )" ]]
then
	set -- 1 "${@:1:2}"
fi
#save user args
UARGS=("$@")

#split pairs such as XRP/BTC, XRP,BTC, XRP-BTC and XRP.BTC
spliters='\/,.-'
if [[ "$2" =~ ^[${spliters}]+$ || "$3" =~ ^[${spliters}]+$ ]]
then
	echo "$SN: err: bad currency pair -- ${@:2:2}" >&2
	exit 1
else
	#split
	set -- "$1" ${2//[${spliters}]/ } ${3//[${spliters}]/ }
fi
unset spliters
#set all to caps
set -- "${@^^}"

#set btc as 'from_currency' for market code formation
[[ -z "$2" ]] && set -- "$1" BTC

#set to_currency if none given
if [[ -z "$3" ]]
then
	#set default vs_currency
	if [[ "$WHICHB" = us ]]
	then set -- "$1" "$2" USD  #Binance US
	elif [[ "$WHICHB" = je ]]
	then set -- "$1" "$2" EUR  #Binance Jersey (DEPRECATED)
	else set -- "$1" "$2" USDT #Binance.com (Malta)
	fi
fi 
	
#check and set $REVMKT if needed
if ! checktocurf "$@"
then
	#try setting the bank function automatically?
	#call national currency function
	#rates may contain Binance spread for some markets
	if
		#verbose?
		((OPTV)) && echo Setting option -n automatically.. >&2
		R="$( bankf "$@" )"
	then
		#calc and printf results
		printf "${FSTR}\n" "$R"
		exit 0
	else
		echo "$SN: unsupported market -- ${UARGS[@]:1:2}" >&2
		(( ${#2} > 4 )) && echo "$SN: try adding a space between currency symbols" >&2
		exit 1
	fi
fi


#call opt functions
#detailed trade info
if (( IOPT ))
then infof "$@"
#price websocket stream
elif (( SOPT ))
then socketf "$@"
#order book depth opts
#order book depth 10
elif (( BOPT == 1 ))
then bookdf "$@"
#order book total sizes
elif (( BOPT == 2 ))
then booktf "$@"
#24-h ticker
elif (( TOPT ))
then tickerf "$@"
#price in columns
elif (( COPT ))
then colf "$@"
#default function -- market rates
else
	#verbose
	((OPTV)) && echo "Input:" "${@:1:3}"

	#call opt funcs
	#national (bank) currencies?
	if ((BANK))
	then
		#call national currency function
		#rates may contain Binance spread for some markets
		R="$( bankf "$@" )" || exit
	else
		#defaults
		#set market (is the reverse market rate?)
		[[ -z "$REVMKT" ]] && MKT="$2$3" || MKT="$3$2"

		#address for default func (get rates only)
		ADDR="https://api.binance.${WHICHB}/api/v3/ticker/price?symbol=$MKT" 
		#get data
		DATA="$( "${YOURAPP[@]}" "$ADDR" )"
		
		#print raw data for debug?
		if (( DOPT ))
		then
			echo "$DATA"
			exit 
		fi

		BRATE=$( jq -r .price <<<"$DATA" )
		R="$( bc <<< "scale=16 ; ( $1 ) * ( $REVMKT $BRATE )" )"
	fi
	
	#calc and printf results
	printf "${FSTR}\n" "$R"
fi

