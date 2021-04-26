#!/bin/bash
# stocks.sh  -- Stock and index rates in Bash
# v0.2.19  sep/2020  by mountaineerbr

#your finantial modeling api key
#FMPKEY=
export FMPKEY

#defaults
#stock
DEFSTOCK=TSLA

#make sure locale is set correctly
export LC_NUMERIC=C

#index symbol array
INDEXARRAY=( .DJI  ^DJT  ^FCHI .INX  ^IXCO .IXIC ^MID  ^NDX  ^NYA 
		^OEX  ^PSE  ^RUI  ^RUT  ^SOX  ^XAU  ^XAX  ^XMI  )

HELP="NAME
	stocks.sh  -- Stock and index rates in Bash


SYNOPSIS
	stocks.sh [AMOUNT] [STOCK|INDEX]
	stocks.sh -p [STOCK]
	stocks.sh -q STRING
	stocks.sh -tt [STOCK]
	stocks.sh -ihsv


 	Fetch realtime rates of stocks and indexes from public APIs of
	<financialmodelingprep.com>. Default function is to fetch rate
	of one STOCK or INDEX. If no symbol is given, sets $DEFSTOCK.
	Symbol case is insensitive. 

	The script tries to fetch real-time data from the server. If it
	cannot, it uses the same data available for the profile ticker
	option -p.

	AMOUNT is optional. It accepts any simple expression that
	GNU bc works with.
	
	Check various world indexes rates with option -i and stock rates
	with option -s. Historical prices (time series) of a stock can
	be printed with option -t.

	User can search for a symbol with the -q option, which requires
	one STRING as argument. Check usage examples.

	As of may/2020, a free API is required. Please create that and
	set it as an environment variable. Check ENVIRONMENT section.


ENVIRONMENT
	<Financialmodelingprep.com> requires a free api key. After
	claiming your api key, please set and export an environment
	variable \$FMPKEY with your api key.

	There is also a script option to set api key for one time use with
	option -kKEY .

	A builtin key was added for demo purposes, however that may stop
	working at any time or get rate limited quickly.


LIMITS
	Cryptocurrency rates will not be implemented.

	Stock prices should be updated in real-time, company profiles hourly,
	historial prices and others daily. See
	<financialmodelingprep.com/developer/docs/>. 

	According to discussion at
	<github.com/antoinevulcain/Financial-Modeling-Prep-API/issues/1>:

		\"[..] there are no limit on the number of API
		       requests per day.\"


WARRANTY
	Licensed under the GNU Public License v3 or better and is distributed
	without support or bug corrections.
   	
	This script needs Bash,	cURL or Wget, Gzip and JQ to work properly.

	That is _not_ advisable to depend solely on this script for serious
	trading. Do your own research!

	If you found this useful, please consider sending me a nickle.
		=)

		bc1qlxm5dfjl58whg6tvtszg5pfna9mn2cr2nulnjr


USAGE EXAMPLES
	( 1 ) 	Real-time price of 334 thousands Apple shares:
		
		$ stocks.sh 334000 AAPL


	( 2 )   List all symbols and grep for oil stocks:

		$ stocks.sh -s | grep Oil


	( 3 )   All major indexes:

		$ stocks.sh -i


	( 4 )   Nasdaq index rate only:

		$ stocks.sh .IXIC


	( 5 )   Search for symbols by keywords:

		$ stocks.sh -q Apple

		$ stocks.sh -q Oil


OPTIONS
	-h           Show this help page.
	-i           Index symbols and rates.
	-j           Debug, print json.
	-k  KEY      Set one-shot user api key.
	-s           Stock symbols and rates.
	-p  [STOCK]  Profile ticker; defaults=$DEFSTOCK.
	-q  STRING   Query for symbols.
	-tt [STOCK]  Time series of stock (historical prices); pass twice
	             to get more information per line; defaults=$DEFSTOCK
	-v           Show this script version."


##functions

#historical prices
histf() {
	#test stock symbol
	testsf "$2"

	#get data
	if (( "$HOPT" - 1 )); then
		DATA="$( "${YOURAPP[@]}" "https://financialmodelingprep.com/api/v3/historical-price-full/$2?apikey=$FMPKEY" )"
	else
		DATA="$( "${YOURAPP[@]}" "https://financialmodelingprep.com/api/v3/historical-price-full/$2?serietype=line&apikey=$FMPKEY" )"
	fi
	
	#print json? (debug)
	if [[ -n  "${PJSON}" ]]; then
		printf "%s\n" "${DATA}"
		exit 0
	fi
	checkf
	
	if (( "$HOPT" - 1 )); then
		HIST="$(jq -r '(.historical|reverse[]|"\(.date)\t\(.open)\t\(.high)\t\(.low)\t\(.close)\t\(.volume)\t\(.unadjustedVolume)\t\(.change)\t\(.changePercent)")' <<<"${DATA}")"

		tabs 4
		printf "%s\n" "${HIST}" | 
			column -et -s$'\t' -N'DATE,OPEN,HIGH,LOW,CLOSE,VOL,UNADVOL,CHANGE,CHANGE%'
		printf -- 'DATE,OPEN,HIGH,LOW,CLOSE,VOL,UNADVOL,CHANGE,CHANGE%%\n' >&2
		jq -r '"Symbol: \(.symbol)"' <<<"${DATA}"
		printf "Registers: %s\n" "$(wc -l <<<"${HIST}")"
	else
		HIST="$(jq -r '(.historical|reverse[]|"\(.date)\t\(.close)")' <<<"${DATA}")"

		printf "%s\n" "${HIST}" | 
			column -et -s$'\t' -N'DATE,CLOSE'
		printf -- 'DATE,CLOSE\n' >&2
		jq -r '"Symbol: \(.symbol)"' <<<"${DATA}"
		printf "Registers: %s\n" "$(wc -l <<<"${HIST}")"
	fi


	exit
}

#list index symbols or rates
indexf() {
	#get data
	DATA="$("${YOURAPP[@]}" "https://financialmodelingprep.com/api/v3/majors-indexes?apikey=$FMPKEY" )"
	
	#print json? (debug)
	if [[ -n  "${PJSON}" ]]; then
		printf "%s\n" "${DATA}"
		exit 0
	fi
	checkf
	
	#decode url codes -- why they do it??
	#DATA="$(sed 's/%5E/^/g' <<<"${DATA}")"	
	DATA="${DATA//%5E/^}"	
	
	#check index symbol and	print one index rate (only rate value)
	if [[ -n "$2" ]] && jq -er '.majorIndexesList[]|select(.ticker == "'$2'")' <<<"${DATA}" &>/dev/null; then
		r="$( jq -r '.majorIndexesList[]|select(.ticker == "'$2'")|.price' <<<"${DATA}" )"
		bc <<<"($1)*$r/1"

	#list all major indexes and their rates
	elif [[ -z "$2" ]]; then
		#test if stdout is to tty
		[[ -t 1 ]] && TRIMCOL="-TNAME" 

		INDEX="$(jq -r '.majorIndexesList[]|"\(.ticker)\t\(.price)\t\(.changes)\t\(.indexName)"' <<<"${DATA}")"
		
		sort <<<"${INDEX}" | column -et -s$'\t' -N'TICKER,VALUE,CHANGE,NAME' ${TRIMCOL}
		printf 'Indexes: %s\n' "$(wc -l <<<"${INDEX}")"
	else
		return 1
	fi
}

#stock rate list
stocklistf() {
	#get data
	DATA="$("${YOURAPP[@]}" "https://financialmodelingprep.com/api/v3/company/stock/list?apikey=$FMPKEY" )"
	
	#print json? (debug)
	if [[ -n  "${PJSON}" ]]; then
		printf '%s\n' "${DATA}"
		exit 0
	fi
	checkf
	
	#test if stdout is to tty
	[[ -t 1 ]] && TRIMCOL='-TNAME' 
	
	LIST="$(jq -r '.symbolsList[]|"\(.symbol)\t\(.price)\t\(.name)"' <<<"${DATA}")"
	sort <<<"${LIST}" | column -et -s$'\t' -N'SYMBOL,PRICE,NAME' ${TRIMCOL}
	printf 'Symbols: %s\n' "$(wc -l <<<"${LIST}")"
}

#stock price
stockf() {
	#list stocks?
	[[ -z "$*" ]] && stockslistf && exit

	#test stock symbol
	testsf "$2"

	#try to get real-time data
	DATA="$( "${YOURAPP[@]}" "https://financialmodelingprep.com/api/v3/stock/real-time-price/$2?apikey=$FMPKEY" )"
	
	#print json? (debug)
	if [[ -n  "${PJSON}" ]]; then
		printf '%s\n' "${DATA}"
		exit 0
	fi

 	if [[ "${DATA}" = '{ }' ]]; then
		printf 'stocks.sh: err -- no real-time data\n' >&2
	
		#get static data
		DATA="$( "${YOURAPP[@]}" "https://financialmodelingprep.com/api/v3/company/profile/$2?apikey=$FMPKEY" )"
		checkf
		jq -r '.profile.price' <<<"${DATA}"
	else
		checkf
		
		#process real-time data
		r="$( jq -r '.price' <<<"${DATA}" )"
		bc <<<"($1)*$r/1"
	fi
}

#simple profile ticker
profilef() {
	#test stock symbol
	testsf "$2"

	#get data
	DATA="$( "${YOURAPP[@]}" "https://financialmodelingprep.com/api/v3/profile/$2?apikey=$FMPKEY" )"
	#print json? (debug)
	if [[ -n  "${PJSON}" ]]; then
		printf '%s\n' "${DATA}"
		exit 0
	fi
	checkf
	
	#process ticker data
	jq -r '.[] |
		"Profile ticker for \(.symbol)",
		"CorpName: \(.companyName)",
		"CEO_____: \(.ceo//empty)",
		"Industry: \(.industry)",
		"Sector__: \(.sector)",
		"Exchange: \(.exchange)",
		"Cap_____: \(.mktCap)",
		"LastDiv_: \(.lastDiv)",
		"Beta____: \(.beta)",
		"VolAvg__: \(.volAvg)",
		"Range___: \(.range)",
		"Change%_: \(.changesPercentage)",
		"Change__: \(.changes)",
		"Price___: \(.price)"
		' <<<"${DATA}"
	
	exit
}

#query symbols
queryf() {
	#set -- $( sed 's/ /%20/g' )

	#get data
	DATA="$( "${YOURAPP[@]}" "https://financialmodelingprep.com/api/v3/search?query=$1&limit=1000&apikey=$FMPKEY" )"
	#print json? (debug)
	if [[ -n  "${PJSON}" ]]; then
		printf '%s\n' "${DATA}"
		exit 0
	fi
	checkf

	#process ticker data
	jq -r '.[] | "\(.symbol)\t\(.currency)\t\(.exchangeShortName)\t\(.name)"' <<<"$DATA" |
		column -et -s$'\t' -NSYMBOL,CUR,EXCHANGE,NAME -TNAME
	printf 'Items: %s\n' "$( wc -l <<<"$DATA" )"

}

#simple json check
checkf() {
	if jq -er '.["Error Message"] // empty' <<<"$DATA" >&2 2>/dev/null ||
 		[[ "${DATA}" = '{ }' ]] || [[ "${DATA}" = '[ ]' ]] ||
		[[ -z "$DATA" ]]; then
		printf 'stocks.sh: no result or err\n' >&2
		exit 1
	fi
	return 0
}


#test if stock symbol is valid
testsf() {
	if [[ -n "$PJSON" ]]; then
		return 0
	elif ! "${YOURAPP[@]}" "https://financialmodelingprep.com/api/v3/company/stock/list?apikey=$FMPKEY" |
		jq -er '.symbolsList[]| select( .symbol == "'$1'" )' &>/dev/null; then

		printf 'stocks.sh: err -- invalid symbol or api key\n' >&2
		#exit 1
	else
		return 0
	fi
}


# Parse options
while getopts ':htHijk:lpqslv' opt; do
	case ${opt} in
		( h ) #help
			printf '%s\n' "${HELP}"
			exit 0
			;;
		( t|H ) #historical prices
			[[ -z "$HOPT" ]] && HOPT=1 ||
				HOPT=2
			;;
		( i ) #indexes
			IOPT=1
			;;
		( j ) #debug; print json
			PJSON=1
			;;
		( k ) #api key
			FMPKEY="$OPTARG"
			;;
		( s|l ) #stock related
			SOPT=1
			;;
		( p ) #simple profile ticker
			POPT=1
			;;
		( q ) #query symbol
			QOPT=1
			;;
		( v ) #version of this script
			grep -m1 '\# v' "${0}"
			exit 0
			;;
		( \? )
			printf 'stocks.sh: err: invalid option -- -%s\n' "${OPTARG}" 1>&2
			exit 1
			;;
	esac
done
shift $((OPTIND -1))

#test for must have packages
if ! command -v jq &>/dev/null; then
	printf 'stocks.sh: err -- jq is required\n' >&2
	exit 1
elif command -v curl &>/dev/null; then
	YOURAPP=( curl -sL --compressed )
elif command -v wget &>/dev/null; then
	YOURAPP=( wget -qO- )
else
	printf 'stocks.sh: err -- curl or wget is required\n' >&2
	exit 1
fi

#check for api key
if [[ -z "$FMPKEY" ]]
then
	#printf 'stocks.sh: err -- api is required\n' >&2
	#printf 'stocks.sh: please check <https://financialmodelingprep.com/developer/docs/login>\n' >&2
	#exit 1

	#dev demo key
	FMPKEY=842734c932ba00fb822aac7996550913
fi

##call opt functions
#stock and index lists
if [[ -z "$*" ]] && [[ -n "${IOPT}${SOPT}" ]]; then

	[[ -n "${SOPT}" ]] && stocklistf
	[[ -n "${IOPT}" ]] && printf '\n' && indexf
	exit 0
elif [[ -n "$QOPT" ]]; then
	[[ -z "$*" ]] && {
		printf 'stocks.sh: err -- user argument required\n' >&2
		exit 1
	}

	#query symbols
	queryf "$@"
	exit
fi

# Set equation arguments
# If first argument does not have numbers
if [[ "$1" != *[0-9]* ]]
then
	set -- 1 "${@}"
# if AMOUNT is not a valid expression for Bc
elif [[ -z "${OPTHIST}${TOPT}" ]] &&
	[[ ! "$1" =~ ^[0-9]+$ ]] &&
	[[ -z "$( bc <<< "$1" )" ]]
then
	echo "Invalid expression in AMOUNT -- $1" >&2
	exit 1
fi

#set default currencies if none set
if [[ -z "$2" ]]
then
	set -- "$1" "${DEFSTOCK}"
fi
if [[ -n "$3" ]]
then
	echo "Ignoring \$3 -- $3" >&2
fi

#set all caps
set -- "${@^^}"


#call opt funcs
#company profile ticker
if [[ -n "${POPT}" ]]; then
	profilef "${@}"
#historical prices
elif [[ -n "${HOPT}" ]]; then
	histf "${@}"
#default function, stock or index rate
#major indexes list or single index
elif [[ -n "$IOPT" || "${INDEXARRAY[*]}" = *\ $2\ * ]] &&
	[[ -z "$SOPT" ]]; then

	indexf "$@"
else
	#stock option
	stockf "$@"
fi

