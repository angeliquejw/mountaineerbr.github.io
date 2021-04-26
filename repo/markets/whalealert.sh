#!/bin/bash
# WhaleAlert.sh -- whale-alert.io API Access
# v0.1.14  oct/2020  by mountaineerbr

# Your own api key
#WALERTAPIKEY=
export WALERTAPIKEY

# Defaults
# Minimum Tx value
# For the Free plan the minimum transaction value is USD 500000
MVALUE=500000
# Max Tx history for Free plans is 3600 seconds
STIME=58m
# Results limit per page -- max 100
RESULTS=100

#make sure locale is set correctly
export LC_NUMERIC=C

HELP="NAME
	WhaleAlert.sh -- whale-alert.io API Access


SYNOPSIS
	whalealert.sh [-hv] [-p NUM] [-r NUM] [-t NUM]

	This script gets data from whale-alert.io with the latest whale
	transactions. Unfortunately, the free api key has very stringent
	limits.

	It needs recent version of Bash, cURL and JQ to work properly.


ENVIRONMENT, API KEY AND LIMITS
	Please create a free account and api key for your personal use,
	set and export variable \$WALERTAPIKEY\" or set that in the script
	head source code.

	Free accounts have some limitations:
		Minimum transaction value: 500000 USD.
		Maximum history time : 3600 seconds (~60 minutes).
		Maximum results per page: 100.


	A builtin key was added for demo purposes, however that may stop
	working at any time or get rate limited quickly.
	
	Currently, this script fetches only the first page of results.


WARRANTY
	Licensed under the GNU Public License v3 or better.
 	This programme is distributed without support or bug corrections.

	If you found this useful, please consider sending me a nickle!
		=)

		bc1qlxm5dfjl58whg6tvtszg5pfna9mn2cr2nulnjr


OPTIONS
	-d 	Debug; prints received data.

	-h 	Show this help page.

	-p 	Minimum price; min(USD)=500000.

	-r 	Maximum number of results per page; max=100.

	-t 	Time of history start; accepts \"s\" (seconds) and 
		\"m\" (minutes); max~=59m.

	-v 	Print script version."


# Parse options
while getopts ":hvp:r:t:d" opt; do
	case ${opt} in
		h ) # Help
			head "${0}" | grep -e '# v'
			echo -e "${HELP}"
			exit 0
			;;
		v ) # Version of Script
			head "${0}" | grep -e '# v'
			exit 0
			;;
		p ) # Price minimum
			MVALUE="${OPTARG}"
			;;
		r ) # Results minimum
			RESULTS="${OPTARG}"
			;;
		t ) # Time of history start
			STIME="${OPTARG}"
			;;
		d ) # Debug -- print JSON/Data?
			PJSON=1
			;;
		\? )
			echo "Invalid Option: -$OPTARG" 1>&2
			exit 1
			;;
	 esac
done
shift $((OPTIND -1))

#Check for API KEY
if [[ -z "${WALERTAPIKEY}" ]]; then
	#printf "Please create a free API key and add it to the script source-code or set it as an environment variable.\n" 1>&2
	#exit 1

	#dev demo key
	WALERTAPIKEY=0iritsuoJcKFzTQ5hf26fg0ch7vpbBQ7
fi

# Test options
# Results max 100
if [[ "${RESULTS}" -gt "100" ]]; then
	printf "Maximum results for free account is 100.\n" 1>&2
	exit 1
fi
# Tx Value minimum
if [[ "${MVALUE}" -lt "500000" ]]; then
	printf "Minimum transaction value for free account is 500000 (USD).\n" 1>&2
	exit 1
fi

stimecheck() {
	if test -n "${STIMESET}"; then
		cat - 1>&2 <<-'MSG'
		Only one argument is accepted: "s" OR "m".
		Decimal scale is accepted.
		MSG
		exit 1
	fi
	return 0
}
stime() {
	#Test input
	if ! grep -q "[0-9]" <<< "${STIME}"; then
		printf "Numeric argument missing. Ignoring...\n" 1>&2
	fi
	#Check for time and convert to sec
	if grep -iq "[a-ln-rt-z]" <<< "${STIME}"; then
		cat - 1>&2 <<-'MSG'
		Time format invalid.
		Accepted arguments: "s" OR "m".
		MSG
		exit 1
	fi
	if grep -iq "s" <<< "${STIME}"; then
		STIME="${STIME//s}"
		STIME="${STIME//S}"
		STIMESET=1
	fi
	if grep -iq "m" <<< "${STIME}"; then
		STIME="${STIME//m}"
		STIME="${STIME//M}"
		STIME="(${STIME}*60)"
		STIMESET=1
	fi
	# Calculate seconds
	STIME="$(bc <<< "scale=0;${STIME}/1")"
	STIMESECS="${STIME}"
	# Free plan max is 3600 secs
	if [[ "${STIME}" -gt 3600 ]]; then
		printf "For the Free plan the maximum transaction history is 3600 seconds.\n" 1>&2
		#exit 1
	fi
	# Date minus calculated secs
	STIME="$(bc <<< "$(date +%s)-${STIME}")"
	#echo $STIME
	}

#Start time calculation
stime

# Get data
PAGE="$(curl --compressed -s "https://api.whale-alert.io/v1/transactions?api_key=${WALERTAPIKEY}&min_value=${MVALUE}&start=${STIME}&limit=${RESULTS}")"
#&cursor=2bc7e46-2bc7e46-5c66c0a7
#&limit=100 # default:100 max:100

# Print Page received?
if [[ -n "${PJSON}" ]]; then
	printf "%s\n" "${PAGE}"
	exit
fi

#Test data
if [[ "$(jq -r '.result' <<< "${PAGE}")" =~ "error" ]]; then
	jq -r '.message' <<< "${PAGE}" 1>&2
	exit 1
fi
#More testing
if [[ "$(jq -r '.count' <<< "${PAGE}")" -eq "0" ]]; then
	printf "No transactions in the last %s seconds.\n" "${STIMESECS}" 1>&2
	exit 1
fi

# Process with JQ
jq -er '"\(.transactions[]|
		"",
		"Blockchain: \(.blockchain)  TxType: \(.transaction_type)",
		"Hash  : \(.hash)",
		"Amount: \(.amount) \(.symbol) (\(.amount_usd) USD)  TxCount: \(.transaction_count)",
		"Time  : \(.timestamp | strftime("%Y-%m-%dT%H:%M:%SZ"))  LocalT: \(.timestamp |strflocaltime("%Y-%m-%dT%H:%M:%S%Z"))",
		"  From:",
		"    \(.from.address) \(.from.owner_type // "ownerType?") \(.from.owner // "owner?")",
		"  To  :",
		"    \(.to.address) \(.to.owner_type // "ownerType?") \(.to.owner // "owner?")"
	)",
	"",
	"While-alert.io Information",
	.result,
	"Count : \(.count)"' <<< "${PAGE}"
#"Cursor: \(.cursor)",
[[ "${?}" -eq "0" ]] && printf "History time: last %s seconds (approx. %s minutes).\n" "${STIMESECS}" "$((STIMESECS/60))"


exit 0

# Dead Code
# ENDPOINTS
#https://api.whale-alert.i
#Status
#GET /v1/status
#Tx info by Hx
#GET /v1/transaction/{blockchain}/{hash}
# Latest big Tx
#GET /v1/transactions
#
#Error codes/mgs
#ERRORMGS='-e "Bad Request -- Your request was not valid." -e "Unauthorized -- No valid API key was provided" -e "Forbidden -- Access to this resource is restricted for the given caller." -e "Not Found -- The requested resource does not exist." -e "Method Not Allowed -- An invalid method was used to access a resource." -e "Not Acceptable -- An unsupported format was requested." -e "Too Many Requests -- You have exceeded the allowed number of calls per minute. Lower call frequency or upgrade your plan for a higher rate limit." -e "Internal Server Error -- There was a problem with the API host server. Try again later." -e "Service Unavailable -- API is temporarily offline for maintenance. Try again later."'
#
#	if grep -iq "h" <<< "${STIME}"; then
#		stimecheck
#		STIME="${STIME//h}"
#		STIME="${STIME//H}"
#		STIME="(${STIME}*60*60)"
#		STIMESET=1
#	fi
#	if grep -iq "d" <<< "${STIME}"; then
#		stimecheck
#		STIME="${STIME//d}"
#		STIME="${STIME//D}"
#		STIME="(${STIME}*24*60*60)"
#	fi
