#!/bin/bash
# v0.1.23  jan/2021  by castaway

#make sure locale is set correctly
export LC_NUMERIC=C

HELP="SYNOPSIS
	bakkt.sh [-t NUM]
	bakkt.sh [-hv]

	Bakkt price ticker and contract volume from <https://www.bakkt.com/>
	at the terminal. The default option lists ICE Bakkt Bitcoin (USD) 
	Monthly Futures.

	Option -t for time series of contract price. Change range with
	arguments 1-3. The list is tab-separated.

	Market data delayed a minimum of 15 minutes. 

	Required software: Bash, JQ, gzip and cURL or Wget.


WARRANTY
	Licensed under the GNU Public License v3 or better and is
	distributed without support or bug corrections.

	If you found this script useful, consider sending me a nickle!
		=)

		bc1qlxm5dfjl58whg6tvtszg5pfna9mn2cr2nulnjr


OPTIONS
	-j 	Debug; print JSON.
	-h 	Show this help.
	-t NUM	Time series, contract price; select time range
		with NUM 1-3; defaults=3.
	-v 	Print this script version."


# Contracts func
contractsf()
{
	CONTRACTURL='https://www.theice.com/marketdata/DelayedMarkets.shtml?getContractsAsJson=&productId=23808&hubId=26066' 
	DATA0="$("${YOURAPP[@]}" "${CONTRACTURL}")"

	# Print JSON?
	if [[ -n ${PJSON} ]]; then
		printf "%s\n" "${DATA0}"
		exit
	fi

	printf "Bakkt Contract List\n"
	jq -r 'reverse[]|"",
		"Market_ID: \(.marketId // empty)",
		"Strip____: \(.marketStrip // empty)",
		"Last_time: \(.lastTime // empty)",
		"End_date_: \(.endDate // empty)",
		"LastPrice: \(.lastPrice // empty)",
		"Change(%): \(.change // empty)",
		"Volume___: \(.volume // empty)"' <<< "${DATA0}"
}

#time series func
timeseriesf()
{
	[[ "$1" != [0-4] ]] && set -- 3 && echo 'set to default opt 3' 1>&2

	#time series Contracts opt -- Default option
	CONTRACTURL="https://www.theice.com/marketdata/DelayedMarkets.shtml?getHistoricalChartDataAsJson=&marketId=6137574&historicalSpan=$1"
	DATA0="$("${YOURAPP[@]}" "${CONTRACTURL}")"
	# Print JSON?
	if [[ -n ${PJSON} ]]; then
		printf "%s\n" "${DATA0}"
		exit
	fi

	list="$( jq -r '.bars[]|reverse|@tsv' <<< "${DATA0}" )"
	echo "Bakkt Contract List"
	echo "$list"
	echo "Entries: $(wc -l <<<"$list")"
}


# Parse options
while getopts :jhtv opt
do
	case $opt in
		j ) # Print JSON
			PJSON=1
			;;
		h ) # Help
	      		echo -e "${HELP}"
	      		exit 0
	      		;;
		t ) #time series
			tsopt=1
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

#Check for JQ
if ! command -v jq &>/dev/null
then
	printf "JQ is required.\n" 1>&2
	exit 1
fi

# Test if cURL or Wget is available
if command -v curl &>/dev/null; then
	YOURAPP=(curl -sL --compressed)
elif command -v wget &>/dev/null; then
	YOURAPP=(wget -qO-)
else
	printf "Package cURL or Wget is needed.\n" 1>&2
	exit 1
fi

#request compressed response
#gzip may be required

if [[ -n "$tsopt" ]]
then
	#time series func
	timeseriesf "$@"
else
	# Contracts opt -- Default option
	contractsf "$@"
fi

