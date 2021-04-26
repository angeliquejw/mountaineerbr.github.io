#!/bin/bash
# AlphaAvantage Stocks and Currency Rates (Most popular Yahoo Finance API alternative)
# v0.3.16  oct/2020  by mountaineer_br

#your free api private key
#ALPHAAPIKEY=
export ALPHAAPIKEY

#some defaults
#default stock:
DEFSTOCK=TSLA

#make sure locale is set correctly
export LC_NUMERIC=C

## Manual and help
HELP="NAME
 	Alpha.sh -- Stocks and Currency Rates from <alphavantage.co> API


SYNOPSIS
	alpha.sh [STOCK]
	alpha.sh [-dwm] [STOCK]
	alpha.sh -s [KEYWORDS..]
	alpha.sh [FROM_CURRENCY] [TO_CURRENCY]
	alpha.sh [-dwm] [FROM_CURRENCY] [TO_CURRENCY]
	alpha.sh [-hlv]


DESCRIPTION
	This programme fetches updated rates for stocks, physical and
	digital currencies from	<alphavantage.co> APIs.

	It can also return daily/weekly and monthly time series (date,
	open, high, low, close and volume) of the stock or currency spec-
	ified, covering 20+ years of historical data. The most recent
	data point is the prices and volume information of the current
	trading day, updated in realtime. 

	Required packages are JQ, gzip and Curl or Wget.


ENVIRONMENT AND API KEY
	Please create a free API key and add it to the script source-code
	or export it as an environment variable \$ALPHAAPIKEY .

	Claim your free API key at <https://www.alphavantage.co/support/#api-key>.
 	They say they are committed to making it free forever.

	A builtin key was added for demo purposes, however that may stop
	working at any time or get rate limited quickly.


LIMITS
	API rate limits are 5 API requests per minute or 500 API requests
	per day for free accounts, according to <https://www.alphavantage.co/premium/>.


WARRANTY
	This programme is licensed under the GNU Public License v3 or
	better and is distributed without support or bug corrections.

	If you found this useful, consider sending me a nickle! =)

		bc1qlxm5dfjl58whg6tvtszg5pfna9mn2cr2nulnjr


USAGE EXAMPLES
	( 1 ) 	Get AAPL stock rate:
		
		alpha.sh aapl


	( 2 ) 	Get USD BRL market rate:
		
		alpha.sh usd brl


	( 3 ) 	Daily time series (historic rates) for AAPL:
		
		alpha.sh -d aapl


OPTIONS
	Time series
	-d 	Daily time series (historic data).
	-w 	Weekly time series.
	-m 	Monthly time series.
	Search/list symbols
	-s 	Search for stock (stocks only) given keywords.
	-l 	List supported currencies.
	Miscellaneous
	-D 	Demo mode (demo API Key), only MSFT.
	-h	Show this help.
	-jj 	Debug, print raw JSON; setting twice may dump CSV.
	-v   	Show this programme version."


#functions

stockf() {
	#get data
	DATA="$(${YOURAPP} "https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=${1^^}&apikey=${ALPHAAPIKEY}${CSVOPT}")"
	
	# Print raw data?
	if [[ -n ${PJSON} ]]; then
		printf "%s\n" "${DATA}"
		exit 0
	fi

	#test for error esponse
	if jq -e '."Error Message"' <<<"${DATA}" &>/dev/null; then
		printf 'Error: check symbol.\n' 1>&2
		exit 1
	elif grep -qi 'standard API call frequency is .* calls per minute and .* calls per day' <<<"${DATA}"; then
		printf 'Error: %s\n' "$(jq -r '.Note' <<<"${DATA}")" 1>&2
		exit 1
	fi

	jq -r '."Global Quote"|
			"Symbol_: \(."01. symbol")",
			"LastDay: \(."07. latest trading day")",
			"PrevClo: \(."08. previous close")",
			"Open___: \(."02. open")",
			"Low____: \(."04. low")",
			"High___: \(."03. high")",
			"Volume_: \(."06. volume")",
			"Change_: \(."09. change")",
			"Change%: \(."10. change percent")",
			"Price__: \(."05. price")"' <<< "${DATA}"
}

#search for stock symbol
searchf() {
	#process words
	WORDS="${*// /%20}"

	#get data
	DATA="$(${YOURAPP} "https://www.alphavantage.co/query?function=SYMBOL_SEARCH&keywords=${WORDS}&apikey=${ALPHAAPIKEY}${CSVOPT}")"
	
	# Print raw data?
	if [[ -n ${PJSON} ]]; then
		printf "%s\n" "${DATA}"
		exit 0
	fi
	
	#check for errors and process table
	if jq -e '.bestMatches[]' <<<"${DATA}" &>/dev/null; then
		#check if stdout is open and trim column NAME
		[[ -t 1 ]] && TRIMCOL='-TNAME,REGION'
		#process data and make table
		jq -r '.bestMatches|reverse[]|
			"\(."1. symbol"),\(."2. name"),\(."3. type"),\(."4. region"),\(."5. marketOpen"),\(."6. marketClose"),\(."7. timezone"),\(."8. currency"),\(."9. matchScore")"' <<<"${DATA}" | column -et -s',' -NSYMBOL,NAME,TYPE,REGION,MOPEN,MCLOSE,TZ,CUR,SCORE ${TRIMCOL} 
	elif grep -qi 'standard API call frequency is .* calls per minute and .* calls per day' <<<"${DATA}"; then
		printf 'Error: %s\n' "$(jq -r '.Note' <<<"${DATA}")" 1>&2
		exit 1
	else
		printf 'No results -- %s\n' "${*}" 1>&2
		exit 1
	fi
}

tsf() {
	if [[ -z "${2}" ]]; then
		#time series
		#get stock data
		DATA="$(${YOURAPP} "https://www.alphavantage.co/query?function=TIME_SERIES_${PERIOD}&symbol=${1^^}&outputsize=full&apikey=${ALPHAAPIKEY}&datatype=csv")"
	else
		#get forex data
		DATA="$(${YOURAPP} "https://www.alphavantage.co/query?function=FX_${PERIOD}&from_symbol=${1^^}&to_symbol=${2^^}&outputsize=full&apikey=${ALPHAAPIKEY}&datatype=csv")"
	fi

	# Print raw data?
	if [[ -n ${PJSON} ]]; then
		printf "%s\n" "${DATA}"
		[[ -z "${CSVOPT}" ]] && printf 'Using CSV data for this call.\n' 1>&2
		exit 0
	fi

	#get rid of windows carrige return ^M
	DATA="$(tr -d '\r' <<<"${DATA}")"

	#test for error esponse
	if jq -e '."Error Message"' <<<"${DATA}" &>/dev/null; then
		printf 'Error: invalid symbol or currency pair.\n' 1>&2
		exit 1
	elif grep -qi 'standard API call frequency is .* calls per minute and .* calls per day' <<<"${DATA}"; then
		printf 'Error: %s\n' "$(jq -r '.Note' <<<"${DATA}")" 1>&2
		exit 1
	fi

	#get number of records
	NREC="$(sed 1d <<<"${DATA}" | wc -l)"
	#get col names
	COLNAMES="$(sed -n 1p <<<"${DATA}")"
	
	#make table
	#cols: timestamp,open,high,low,close,volume
	sed 1d <<<"${DATA}" | tac | column -et -s, -N"${COLNAMES^^}"
	printf 'Symbol_: %s %s\n' "${1^^}" "${2^^}"
	printf 'Records: %s\n' "${NREC}"

	#jq -r '(."Meta Data"|
	#		"\(."1. Information")",
      	#		"\(."2. Symbol")",
      	#		"\(."3. Last Refreshed"),
      	#		"\(."4. Output Size"),
      	#		"\(."5. Time Zone")
	#	),
	#	(."Time Series (Daily)")'
}

forexf() {
	#currency rate
	
	#get data
	DATA="$(${YOURAPP} "https://www.alphavantage.co/query?function=CURRENCY_EXCHANGE_RATE&from_currency=${1^^}&to_currency=${2^^}&apikey=${ALPHAAPIKEY}")"

	# Print raw data?
	if [[ -n ${PJSON} ]]; then
		printf "%s\n" "${DATA}"
		[[ -n "${CSVOPT}" ]] && printf 'No CSV data for this call.\n' 1>&2
		exit 0
	fi

	#test for error esponse
	if jq -e '."Error Message"' <<<"${DATA}" &>/dev/null; then
		printf 'Error: check currency pairs.\n' 1>&2
		exit 1
	elif grep -qi 'standard API call frequency is .* calls per minute and .* calls per day' <<<"${DATA}"; then
		printf 'Error: %s\n' "$(jq -r '.Note' <<<"${DATA}")" 1>&2
		exit 1
	fi

	jq -r '."Realtime Currency Exchange Rate"|
		"Realtime Currency Exchange Rate",
		"Updated: \(."6. Last Refreshed") \(."7. Time Zone")",
		"FromCod: \(."1. From_Currency Code")",
		"FromNam: \(."2. From_Currency Name")",
		"To_Code: \(."3. To_Currency Code")",
		"To_Name: \(."4. To_Currency Name")",
        	"Bid____: \(."8. Bid Price")",
		"Ask____: \(."9. Ask Price")",
		"Rate___: \(."5. Exchange Rate")"' <<<"${DATA}"
}

lforexf() {
	#list currencies
	
	# Print raw data?
	if [[ -n ${PJSON} ]]; then
		${YOURAPP} "https://www.alphavantage.co/digital_currency_list/"
		printf '\n'
		${YOURAPP} "https://www.alphavantage.co/physical_currency_list/"
		exit 0
	fi

	#get data and process
	
	#digital/crypto currency
	DATA="$(${YOURAPP} "https://www.alphavantage.co/digital_currency_list/" | sed 1d)"
	NP="$(wc -l <<<"${DATA}")" 
	
	#digital currencies
	#cols: currency code,currency name
	printf 'Digital currencies:\n'
	column -et -s',' -NCODE,NAME <<<"${DATA}"
	
	#physical currency  #csv file
	DATA="$(${YOURAPP} "https://www.alphavantage.co/physical_currency_list/" | sed 1d)"
	ND="$(wc -l <<<"${DATA}")" 
	printf 'Physical currencies:\n'
	column -et -s',' -NCODE,NAME <<<"${DATA}"

	printf '\nDigital_: %s\n' "${ND}"
	printf 'Physical: %s\n' "${NP}"
}

# Parse options
while getopts ":Ddhjlmsvw" opt; do
	case ${opt} in
		( D ) #demo mode
			ALPHAAPIKEY=demo
			;;
		( d ) #daily time series
			PERIOD=DAILY
			;;
		( h ) # Show Help
			printf '%s\n' "${HELP}"
			exit 0
			;;
		( j ) # Print raw data
			[[ -z "${PJSON}" ]] && PJSON=1 || CSVOPT='&datatype=csv'
			;;
		( l ) #list currencies
			LFOREXOPT=1
			;;
		( m ) #montly time series
			PERIOD=MONTHLY
			;;
		( s ) #search symbols
			SOPT=1
			;;
		( v ) # Version of Script
			grep -m1 '# v' "${0}"
			exit
			;;
		( w ) #weekly time series
			PERIOD=WEEKLY
			;;
		( \? )
			printf "Invalid option: -%s\n" "$OPTARG" 1>&2
			exit 1
			;;
	esac
done
shift $((OPTIND -1))

# Test for must have packages
if ! command -v jq &>/dev/null && [[ -z "${PJSON}${LFOREXOPT}${PERIOD}" ]]; then
	printf "JQ is required.\n" 1>&2
	exit 1
fi
if command -v curl &>/dev/null; then
	YOURAPP="curl -sL --compressed"
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

#test for any arg?
[[ -z "${1}" ]] && set -- "${DEFSTOCK}"
#demo mode
[[ "${ALPHAAPIKEY}" = demo ]] && set -- MSFT

#Check for API KEY
if [[ -z "${ALPHAAPIKEY}" ]]; then
	#echo 'Please create a free API key and add it to the script source-code' >&2
	#echo 'or export it as an environment variable as per help page' >&2

	#defaults dev key (may stop working)
	ALPHAAPIKEY=DQZV46FOXV9JN64H
fi


#call opt functions
if [[ -n "${SOPT}" ]]; then
	searchf "${@}"
elif [[ -n "${LFOREXOPT}" ]]; then
	lforexf
elif [[ -n "${PERIOD}" ]]; then
	tsf "${@}"
elif [[ -z "${2}" ]]; then
	stockf "${@}"
else
	forexf "${@}"
fi

