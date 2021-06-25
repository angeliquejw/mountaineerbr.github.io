#!/bin/bash
# binfo.sh -- bitcoin blockchain explorer for bash
# v0.9.19  jun/2021  by mountaineerbr

#defaults

#try to set lc_numeric to C 
export LC_NUMERIC=C

#format
FMT='?format=json'
FMTb='&format=json'

FMT2='?format=hex'
FMT2b='&format=hex'

#user agent
#chrome on windows 10
UAG='user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.83 Safari/537.36'

HELP="NAME
    binfo.sh  -- Bitcoin Blockchain Explorer for Bash
    		 Bash Interface for <blockchain.info> and
		 <blockchair.com> APIs


SYNOPSIS
	$ binfo.sh  HASH
	$ binfo.sh  [-aass] ADDR_HASH..
	$ binfo.sh  -b [-x] [BLK_HASH..|ID..]
	$ binfo.sh  -n BLK_HEIGHT.. 
	$ binfo.sh  [-tt] [-x] [TX_HASH..|ID..]
	$ binfo.sh  [-ehiilruv]


	Fetch information of Bitcoin blocks, addresses and transactions
	from <blockchain.info> public APIs. It is intended to be used as
	a simple Bitcoin blockchain explorer. Most options accept multiple
	arguments. If the server declines data for multiple addresses or
	other requests at once, try one at a time.

	This script should choose appropriate options depending on user
	input automatically. However, in some cases it is best to set
	them explicitly. See USAGE EXAMPLES.

	<Blockchain.info> and <blockchair.com> may provide an internal
	index number (ID) of blocks, transactions, etc to use instead of
	their respective hashes.

	<Blockchain.info> still does not support segwit (bech32) addresses.
	On the other hand, <blockchair.com> supports segwit and other
	types of addresses and therefore <blockchair.com> api was also
	implemented in this programme to ammend those instances.

	The new block notification option -e websocket connection is ex-
	pected to drop occasionally, so we try to auto reconnect in a loop.
	After a block is mined, it takes some time, usually about one
	minute, until the server sends out a new notification through the
	web socket stream. If the notification arrival time is behind the
	time at which the block was mined, the user computer has got the
	wrong hardware clock time set.


BLOCKCHAIN STRUCTURE
	The blockchain has four basic levels of organisation:

		(0)  Blockchain itself
		(1)  Block
		(2)  Address
		(3)  Transaction

	If you do not have a specific address or transaction to lookup,
	try fetching the latest block hash and transaction info (option
	-l). Note that the latest block takes a while to process, so you
	only get transaction IDs at first. For thorough block information,
	use option -b with the block hash. You can also inspect a block
	with option -n and its height number.


ABBREVIATIONS
	Addrs 			Addresses
	Avg 			Average
	AvgBlkS 		Average block size
	B,Blk 			Block
	BEndian 		Transaction hash big endian
	BlkHgt 			Block height
	BlkS,BlkSize 		Block size
	BlkT,BlkTime 		Block time (time between blocks)
	BTC 			Bitcoin
	Cap 			Capital
	CDD 			Coin days destroyed
	Desc 			Description
	Diff 			Difficulty
	Dominan 		Dominance
	DSpent 			Double spent
	Est 			Estimated
	ETA 			Estimated Time of arrival
	Exa 			10^18
	FrTxID 			From-transaction index number
	H,Hx 			Hash, hashes
	ID 			Identity, index
	Inflat 			Inflation
	LocalT 			Local time
	Med 			Median
	MerklRt 		Merkle Root
	Prev 			Previous
	Rc,Rcv,Receivd 		Received
	sat 			satoshi
	S 			Size
	Suggest 		Suggested
	ToTxID 			To-transaction index number
	T,Tt,Tot 		Total
	TimLeft 		Time left
	TStamp 			Timestamp
	Tx 			Transaction
	Vol 			Volume


API LIMITS
	It is difficult to find the true limitations of each api. Some-
	times, the information is not updated or is only partial.

	There are two major types of limits to deal with in this script.
	The first one is the api request limit and the second one is the
	response limit.

	Response limits were maxed out where possible. However do not
	expect to get all transactions for a given address, for example.
	Dependending on the api, usually you will get about the most
	recent 50-100 results.

	There are some possibilities to use loops and offsets to retrieve
	more  results in some cases, but i do not have time to implement
	these so do expect to get only the first page of results for each
	call.


	Blockchain.info

	Very recently, an api key was granted by blockchain.com for this
	script to work with higher request limits. It would be implemented,
	however blockchain.info offers no intruction as to how to implement
	an api key call, and some tips i could find over internet forms
	do not seem to work, so i guess we will have to bear the request
	limits..
	
		\"Please limit your queries to a maximum
		 of 1 every 10 seconds\"

	<https://www.blockchain.com/api/blockchain_api>
	<https://www.blockchain.com/api/q>


	Blockchair.com
	
		\"For personal or non-comercial use, 1440 requests a day
		 and 30 requests a minute.\"
	
	<https://blockchair.com/api/docs>


WARRANTY
	Licensed under the GNU Public License v3 or better and is
	distributed without support or bug corrections.

	This script needs the latest Bash, cURL or Wget, Gzip, JQ,
	Websocat and GNU Coreutils packages to work properly.

	If you found this script useful, please consider sending me
	a nickle.
		=)

		bc1qlxm5dfjl58whg6tvtszg5pfna9mn2cr2nulnjr


BUGS
	Blockchain.com server does not seem as reliable anymore. Some-
	times it will decline giving data, rate limit the user or block
	him after just a few requests. Its APIs documentation is not very
	complete nor is it always up-to-date.

	Unfortunately, multiple requests are quickly rate limited, try
	to wait a short time between requests in bulk.


USAGE EXAMPLES
	The script will try to set an option automatically based on user
	input. General references for some options are presented below.


	(1) Get latest block Hash and Transaction indexes:

		binfo.sh -l


	(2) Get full information of the latest block:

		binfo.sh -b


	(3) Information for block by hash (first block with peer-to-peer tx):

		binfo.sh -b 00000000d1145790a8694403d4063f323d499e655c83426834d4ce2f8dd4a2ee


	(4) Information for block by height number (genesis block):

		binfo.sh -n 0


	(5) Summary address information (Binance cold wallet):

		binfo.sh -s 34xp4vRoCGJym3xR7yCVPFHoCNxv4Twseo


	(6) Complete address information:

		binfo.sh -a 34xp4vRoCGJym3xR7yCVPFHoCNxv4Twseo


	(7) Transaction information from Blockchair (pass '-t' twice) (the
	    pizza tx):

		binfo.sh -tt a1075db55d416d3ca199f55b6084e2115b9345e16c5cf302fc80e9d5fbf5d48d


	(8) Market information from Blockchair:

		binfo.sh -ii


OPTIONS
    Options that can be passed twice use Blockchair's API, all others
    use Blockchain.com APIs.

    Miscellaneous
      -e 	Socket stream for new block notification.
      -h 	Show this help.
      -j 	Debug, print JSON.
      -r 	Get a table with bitcoin hash rate history.
      -u 	Unconfirmed transactions (mempool) from Blockchair.
      -v 	Print script version.
      -x 	Get only hex, use with -bt ; blockchain.info api only.

    Blockhain
      -i, -ii 	Bitcoin blockchain info (24H rolling ticker).
    
    Block
      -b 	Block information by hash or ID, if empty fetches
      		latest block.
      -l 	Latest block summary information.
      -n 	Block information by height.
    
    Address
      -a  	Addresses information; for a single address: base58 or
      		hash160; response limit=50 txs; for multiple addresses:
		base58 or xpub; response limit=100 txs.
      -aa 	Address information, response limit=10000 txs.
      -s	Summary address information; for multiple addresses:
      		base58 or xpub.
      -ss	Summary address information.
      -p 	List unspent tx outputs from addresses; for multiple
      		addresses: base58 or xpub; response limit=1000 txs.
    
    Transaction
      -t, -tt	Transaction information by hash or ID."

#functions

#check for error response from blockchair
chairerrf() {
	if [[ "$(jq -r '.context.code' <<<"$1")" != 200 ]]; then
		printf 'Err: <blockchair.com> -- server response\n' 1>&2
		return 1
	fi
}

#-e socket stream for new blocks
sstreamf() {
	#print json?
	if [[ -n  "$PJSON" ]]; then
		printf 'JSON from latest block.\n' 1>&2
		websocat --text 'wss://ws.blockchain.info/inv' <<< '{"op":"ping_block"}'
		return
	fi

	#logfile
	logfile=/tmp/binfo.sh_reconnection.log
	
	#trap sigint ctrl+c
	trap exit INT TERM
	
	#start websocket connection
	#loop for recconeccting
	while true; do
		((++N))  #counter
		printf 'New-block-found notification stream\n'
		websocat --text --no-close --ping-interval 15 'wss://ws.blockchain.info/inv' <<< '{"op":"blocks_sub"}' |
			jq -r '"",
				"--------",
				"New block found!",
				(.x|
					"Hash___:",
					"  \(.hash)",
					"MerklRt:",
					"  \(.mrklRoot)",
					"Bits___: \(.bits)\t\tNonce__: \(.nonce)",
					"Height_: \(.height)\t\t\tDiff___: \(.difficulty)",
					"TxCount: \(.nTx)\t\t\tVersion: \(.version)",
					"Size___: \(.size) (\(.size/1000) KB)\tWeight_: \(.weight) WU",
					"Output_: \(.totalBTCSent/100000000) BTC\tEstVol_: \(.estimatedBTCSent/100000000) BTC",
					"BlkTime: \(.time|strftime("%Y-%m-%dT%H:%M:%SZ"))\tLocalT_: \(.time|strflocaltime("%Y-%m-%dT%H:%M:%S%Z"))",
					"Receivd: \(now|round|strftime("%Y-%m-%dT%H:%M:%SZ"))\tLocalT_: \(now|round|strflocaltime("%Y-%m-%dT%H:%M:%S%Z"))"
				)'
		printf '\nLog: %s\n' "$logfile" >&2
		printf 'Reconnection #%s at %s\n' "$N" "$(date '+%Y-%m-%dT%H:%M:%S%Z')" | tee -a "$logfile" >&2
		printf '\n' >&2
		sleep 4
	done
	#{"op":"blocks_sub"}
	#{"op":"unconfirmed_sub"}
	#{"op":"ping"}
}

#-i 24-h ticker for the bitcoin blockchain
blkinfof() {
	printf 'Bitcoin Blockchain General Info\n'
	CHAINJSON="$( "${YOURAPP2[@]}" "https://api.blockchain.info/stats${key1}" )"
	echo >&2

	#print json?
	if [[ -n  "$PJSON" ]]; then
		printf 'JSON from the 24H ticker function.\n' 1>&2
		echo "$CHAINJSON"
		return
	fi

	#print the 24-h ticker
	jq -r '"Time___: \((.timestamp/1000)|strflocaltime("%Y-%m-%dT%H:%M:%S%Z"))",
		"",
		"Blockchain",
		"Height_: \(.n_blocks_total) blocks",
		"HxRate_: \(.hash_rate) GH/s",
		"         \(.hash_rate/1000000000) EH/s",
		"Diff___: \(.difficulty)",
		"BlkETA_: \((.difficulty*4294967296/(.hash_rate*1000000000))/60 | tostring | .[0:6]) min",
		"TtMined: \(.totalbc/100000000) BTC",
		"",
		"Rolling 24H Ticker",
		"BlkTime: \(.minutes_between_blocks) min",
		"TtMined: \(.n_btc_mined/100000000) BTC \(.n_blocks_mined) blocks",
		"Reward_: \((.n_btc_mined/100000000)/.n_blocks_mined) BTC/block",
		"24HSize: \(.blocks_size/1000000) MB",
		"AvgBlkS: \((.blocks_size/1000)/.n_blocks_mined) KB/block",
		"",
		"Transactions and Mining Costs -- Last 24H",
		"EstVol_: \(.estimated_btc_sent/100000000) BTC",
		"         \(.estimated_transaction_volume_usd|round) USD",
		"Revenue: \(.miners_revenue_btc) BTC",
		"         \(.miners_revenue_usd|round) USD",
		"TotFees: \(.total_fees_btc/100000000) BTC",
		"",
		"FeeVol% (TotFees/Revenue):",
		"  \(((.total_fees_btc/100000000)/.miners_revenue_btc)*100) %",
		"RevenueVol% (Revenue/EstVol):",
		"  \((.miners_revenue_btc/(.estimated_btc_sent/100000000))*100) %",
		"",
		"Market",
		"Price__: \(.market_price_usd) USD",
		"TxVol__: \(.trade_volume_btc) BTC (\(.trade_volume_usd|round) USD)",
		"",
		"Next Retarget",
		"@Height: \(.nextretarget)",
		"Blocks_: -\(.nextretarget-.n_blocks_total)",
		"Days___: -\( (.nextretarget-.n_blocks_total)*.minutes_between_blocks/(60*24))"' <<< "$CHAINJSON"

	#some more stats
	printf '\nMempool (unconfirmed txs)\n'
	printf 'TxCount: %s\n' "$( "${YOURAPP[@]}" 'https://blockchain.info/q/unconfirmedcount' 2>/dev/null )"
	printf 'Blk_ETA: %.2f minutes\n' "$(bc -l <<< "$( "${YOURAPP[@]}" 'https://blockchain.info/q/eta' 2>/dev/null )/60" )"
	printf 'Last 100 blocks\n'
	printf 'AvgTx/B: %.0f\n' "$( "${YOURAPP[@]}" 'https://blockchain.info/q/avgtxnumber' 2>/dev/null )"
	printf 'AvgBlkT: %.2f minutes\n' "$(bc -l <<< "$( "${YOURAPP[@]}" 'https://blockchain.info/q/interval' 2>/dev/null )/60" )"
}

#-ii ticker for the bitcoin blockchain from blockchair (updates every ~5min)
chairblkinfof() {
	#get data
	CHAINJSON="$( "${YOURAPP2[@]}" "https://api.blockchair.com/bitcoin/stats" )"

	#print json?
	if [[ -n  "$PJSON" ]]; then
		printf 'JSON from the chair 24H ticker function.\n' 1>&2
		echo "$CHAINJSON"
		return
	fi

	#check for error response
	chairerrf "$CHAINJSON"

	#print the 24h ticker
	jq -r '"Bitcoin Blockchain Stats (Blockchair)",
		"TStamp_: \(.context.cache.since)",
		"",
		"Blockchain",
		(.data|
			"Height_: \(.blocks)  Nodes: \(.nodes)",
			"Size___: \(.blockchain_size) bytes",
			"         \(.blockchain_size/1000000000) GB",
			"HxRate_: \(.hashrate_24h) H/s",
			"         \(.hashrate_24h|tonumber/1000000000000000000) EH/s",
			"Diff___: \(.difficulty)",
			"BlkETA_: \((.difficulty*4294967296/(.hashrate_24h|tonumber))/60 | tostring | .[0:6]) min",
			"TxCount: \(.transactions)",
			"OutTxs_: \(.outputs)",
			"Supply_: \(.circulation) sat",
			"         \(.circulation/100000000) BTC",
			"",
			"Latest Block",
			"Hash___: \(.best_block_hash)",
			"Height_: \(.best_block_height)",
			"Time___: \(.best_block_time)",
			"",
			"Rolling stats of the last 24H",
			"Blocks_: \(.blocks_24h)  Txs: \(.transactions_24h)",
			"Volume_: \(.volume_24h) sat",
			"         \(.volume_24h/100000000) BTC",
			"Inflat_: \(.inflation_usd_24h) USD",
			"         \(.inflation_24h/100000000) BTC",
			"CDC____: \(.cdd_24h) BTC/24H",
			"",
			"Transaction Fee",
			"Average: \(.average_transaction_fee_24h) sat",
			"         \(.average_transaction_fee_usd_24h) USD",
			"Median_: \(.median_transaction_fee_24h) sat",
			"         \(.median_transaction_fee_usd_24h) USD",
			"Suggest: \(.suggested_transaction_fee_per_byte_sat) sat/byte",
			"",
			"Largest Transaction (last 24H)",
			"TxHash_: \(.largest_transaction_24h.hash)",
			"Value__: \(.largest_transaction_24h.value_usd) USD",
			"",
			"Market",
			"Price__: \(.market_price_usd) USD  (\(.market_price_btc) BTC)",
			"Change_: \(.market_price_usd_change_24h_percentage) %",
			"Capital: \(.market_cap_usd) USD",
			"Dominan: \(.market_dominance_percentage) %",
			"",
			"Mempool",
			"TxCount: \(.mempool_transactions)",
			"Size___: \(.mempool_size) b  \(.mempool_size/1000000) Mb",
			"Tx/sec_: \(.mempool_tps)",
			"TotFees: \(.mempool_total_fee_usd) USD",
			"",
			"Next Retarget",
			"Date___: \(.next_retarget_time_estimate)UTC",
			"EstDiff: \(.next_difficulty_estimate)",
			"VarDiff: \(((.next_difficulty_estimate-.difficulty)/.difficulty)*100) %",
			if .countdowns[0].event != null then "\nOther Events/Countdowns" else empty end,
			(.countdowns[]|"Event__: \(.event//empty)","TimLeft: \(.time_left/86400) days")
		)' <<< "$CHAINJSON"
}

#-n block info by height
hblockf() {
	#if no user arg, call raw block function
	if [[ -n "$HEXOPT" || "$*" = *[a-zA-Z]* ]]; then
		true
	elif [[ -n "$1" ]]; then
	
		#fetch data
		RAWBORIG="$( "${YOURAPP2[@]}" "https://blockchain.info/block-height/${1}${key1}${FMTb}" )"
		RAWB="$( jq -er '.blocks[]' <<< "$RAWBORIG" 2>/dev/null )" || unset RAWB
		echo >&2
	
		#print json?
		if [[ -n  "$PJSON" ]]; then
			printf -- 'JSON for -h/-n functions\n' 1>&2
			echo "$RAWBORIG"
			return
		fi
	fi
	
	#call raw block function
	rblockf "$1"
}

#-l latest block summary info
latestf() {
	#get json ( only has hash, time, block_index, height and txindexes )
	LBLOCK="$( "${YOURAPP[@]}" "https://blockchain.info/latestblock${key1}" )"

	#print json?
	if [[ -n  "$PJSON" ]]; then
		printf 'JSON from the lastest block function.\n' 1>&2
		echo "$LBLOCK"
		return 
	fi

	#print the other info
	jq -r '"Latest block",
		"Blk_Hx: \(.hash)",
		"Height: \(.height)",
		"Time__: \(.time | strftime("%Y-%m-%dT%H:%M:%SZ"))",
		"LocalT: \(.time |strflocaltime("%Y-%m-%dT%H:%M:%S%Z"))"' <<< "$LBLOCK"
}

#-b raw block info
rblockf() {
	#unset $FMT2b if user did not request it
	[[ -n "$HEXOPT" ]] || unset FMT2 FMT2b

	#check whether input has block hash or
	#whether rawb is from the hblockf function
	if [[ -z "$RAWB" ]] && [[ -z "$1" ]]
	then
		echo 'Fetching latest block data..' >&2

		set -- "$( "${YOURAPP[@]}" "https://blockchain.info/latestblock${key1}" 2>/dev/null | jq -r '.hash' )" || return 1
	fi

	[[ -z "$RAWB" ]] &&
		RAWB="$( "${YOURAPP2[@]}" "https://blockchain.info/rawblock/${1}${key1}${FMT2b}" )"
	echo >&2

	#print json?
	if [[ -n "$PJSON" ]]; then
		printf 'JSON from the raw block info function.\n' 1>&2
		echo "$RAWB"
		return 0
	#print hex opt
	elif [[ -n "$HEXOPT" ]]; then
		echo "$RAWB"
		return 0
	fi

	#print txs info
	#get txs and call rawtxf function
	RAWTX="$(jq -r '.tx[]' <<< "$RAWB")" || return
	rtxf

	#print block info
	printf '\n\nBlock Info\n'
	jq -r '"",
		"--------",
		"Hash___: \(.hash)",
		"MerklRt: \(.mrkl_root)",
		"PrevBlk: \(.prev_block)",
		"NextBlk: \(.next_block[])",
		"Bits___: \(.bits)\tNonce__: \(.nonce)",
		"Version: \(.ver)\tChain__: \(if .main_chain == true then "Main" else "Secondary" end)",
		"Height_: \(.height)\t\tWeight_: \(.weight)",
		"BlkSize: \(.size/1000) KB\tTxCount: \(.n_tx)",
		"TotlFee: \(.fee/100000000) BTC",
		"Avg_Fee: \(.fee/.size) sat/byte",
		"Relayed: \(.relayed_by // empty)",
		"Time___: \(.time|strftime("%Y-%m-%dT%H:%M:%SZ"))",
		"LocalT_: \(.time | strflocaltime("%Y-%m-%dT%H:%M:%S%Z"))"' <<< "$RAWB"

	#some more stats
	#calculate total volume
	II=($(jq -r '.tx[].inputs[].prev_out.value // empty' <<< "$RAWB"))
	OO=($(jq -r '.tx[].out[].value // empty' <<< "$RAWB"))
	VIN="$(bc -l <<< "(${II[*]/%/+}0)/100000000")"
	VOUT="$(bc -l <<< "(${OO[*]/%/+}0)/100000000")"
	BLKREWARD="$(printf '%s-%s\n' "$VOUT" "$VIN" | bc -l)"
	printf "Reward_: %'.8f BTC\n" "$BLKREWARD"
	printf "Input__: %'.8f BTC\n" "$VIN"
	printf "Output_: %'.8f BTC\n" "$VOUT"
}

#-a address info
raddf() {
	#-s address sumary?
	if [[ -n "$SUMMARYOPT" ]]; then

		#multiple addresses?
		#get raw multi addr data
		set -- ${@//|/ }
		addrs=( ${@/%/|} )
		add="${addrs[*]}"
		add="${add// }"
		add="${add%|}"

		SUMADD="$( "${YOURAPP[@]}" "https://blockchain.info/balance${key1}&active=${add}" )"

		#print json?
		if [[ -n  "$PJSON" ]]; then
			printf 'JSON from the summary address function.\n' 1>&2
			echo "$SUMADD"
			return
		fi

		#check for error, then try blockchair
		if grep -iq -e 'err:' -e 'illegal' -e 'invalid' -e 'Checksum does not validate' <<< "$SUMADD"; then
			echo "Err: <blockchain.com> -- $(jq -r '.reason' <<<"$SUMADD")" >&2
			echo "Trying with <blockchair.com>.." >&2
			((${#addrs[@]})) && echo "Only one address supported at a time" >&2
			chairaddf "$1"
			return
		fi

		#print addr information
		printf 'Summary Addresses Info\n'
		
		#getaddresses
		addrs=( $( jq -r 'keys[]' <<< "$SUMADD" ) )
		for addr in "${addrs[@]}"; do

			jq -r '"",
				"--------",
				"Address: '$addr'",
				(
				.["'$addr'"] |
				"TxCount: \(.n_tx)",
				"Receivd: \(.total_received)  \(.total_received/100000000) BTC",
				"Sent___: \(.total_received-.final_balance)  \((.total_received-.final_balance)/100000000) BTC",
				"Balance: \(.final_balance)  \(.final_balance/100000000) BTC"
				)' <<< "$SUMADD"
		done
	#full address information
	#single or multiaddrs?
	#multi addr
	elif [[ "${#@}" -gt 1 || "$*" = *\|* ]]; then

		#get raw multi addr data
		set -- ${@//|/ }
		addrs=( ${@/%/|} )
		add="${addrs[*]}"
		add="${add// }"
		add="${add%|}"
		
		RAWADD="$( "${YOURAPP2[@]}" "https://blockchain.info/multiaddr${key1}&active=${add}&limit=100" )" 
		echo >&2
	
		#print json?
		if [[ -n  "$PJSON" ]]; then
			printf 'JSON from the address function\n' 1>&2
			echo "$RAWADD"
			return 0
		fi
	
		#check for error, try blockchair
		#if grep -iq -e 'err:' -e 'illegal' -e 'invalid' -e 'Checksum does not validate' <<< "$RAWADD"; then
		if ! jq -e '.addresses' <<< "$RAWADD" &>/dev/null; then
			#printf '%s\nError: raw address data\n' >&2 "$RAWB"
			printf 'Err: <blockchain.com> -- %s\n' "$( grep -F '<p>' <<<"$RAWADD" | sed 's/<[^>]*>//g ; s/^\s*//' )" >&2
			return 1
		fi
	
		#txs info
		#get txs and call rawtxf function
		RAWTX="$(jq -r '.txs|reverse[]' <<< "$RAWADD")"
		rtxf

		printf '\n\nAddresses Info\n'
		jq -r '.addresses[] |
			"",
			"--------",
			"Address: \(.address)",
			"TxCount: \(.n_tx)  \(if .n_unredeemed == null then "" else "Unredeemed: \(.n_unredeemed)" end)",
			"Receivd: \(.total_received)  \(.total_received/100000000) BTC",
			"Sent___: \(.total_sent)  \(.total_sent/100000000) BTC",
			"Balance: \(.final_balance)  \(.final_balance/100000000) BTC"' <<< "$RAWADD"

	#single addrr
	else

		#get raw addr data
		RAWADD="$( "${YOURAPP2[@]}" "https://blockchain.info/rawaddr/${1}${key1}" )"
		echo >&2
	
		#print json?
		if [[ -n  "$PJSON" ]]; then
			printf 'JSON from the address function\n' 1>&2
			echo "$RAWADD"
			return
		fi
	
		#check for error, try blockchair
		#if grep -iq -e 'err:' -e 'illegal' -e 'invalid' -e 'Checksum does not validate' <<< "$RAWADD"; then
		if ! jq -e '.txs' <<< "$RAWADD" &>/dev/null; then
			#printf '%s\nError: raw address data\n' >&2 "$RAWB"
			printf 'Err: <blockchain.com> -- %s\n' "$( grep -F '<p>' <<<"$RAWADD" | sed 's/<[^>]*>//g ; s/^\s*//' )" >&2
			printf '\nTrying with <blockchair.com>..\n' 1>&2
			chairaddf "$1"
			return 
		fi
	
		#tx info
		#get txs and call rawtxf function
		RAWTX="$( jq -r '.txs|reverse[]' <<< "$RAWADD" )"
		rtxf
		printf '\n\nAddress Info\n'
		jq -r '"",
			"--------",
			"Address: \(.address)",
			"Hx160__: \(.hash160)",
			"TxCount: \(.n_tx)  \(if .n_unredeemed == null then "" else "Unredeemed: \(.n_unredeemed)" end)",
			"Receivd: \(.total_received)  \(.total_received/100000000) BTC",
			"Sent___: \(.total_sent)  \(.total_sent/100000000) BTC",
			"Balance: \(.final_balance)  \(.final_balance/100000000) BTC"' <<< "$RAWADD"
	fi
}

#-aa address info ( from blockchair )
chairaddf() {
	#get address info
	[[ -n "$SUMMARYOPT" ]] && YOURAPP2=( "${YOURAPP[@]}" )
	CHAIRADD="$( "${YOURAPP2[@]}"  "https://api.blockchair.com/bitcoin/dashboards/address/${1}?limit=10000" )"
	echo >&2

	#print json?
	if [[ -n  "$PJSON" ]]; then
		printf 'JSON from the blockchair addr function.\n' 1>&2
		echo "$CHAIRADD"
		return 
	fi

	#check for error response
	chairerrf "$CHAIRADD"

	#check for no results
	if [[ "$(jq -r '.context.results' <<<"$CHAIRADD")" = 0 ]]; then
		printf 'Warning: <blockchair.com> -- no results for this address\n' 1>&2
		return 1
	fi

	#-s summary address information ?
	if [[ -n "$SUMMARYOPT" ]]; then
		printf 'Summary Address Info (Blockchair)\n'
		jq -r '"Address: \(.data|keys[0])",
			(.data[].address|
				"TxCount: \(.transaction_count)",
				"Receivd: \(.received)  \(.received/100000000) BTC  \(.received_usd|round) USD",
				"Sent___: \(.spent)  \(.spent/100000000) BTC  \(.spent_usd|round) USD",
				"Balance: \(.balance)  \(.balance/100000000) BTC  \(.balance_usd|round) USD"
			)' <<< "$CHAIRADD"
		return
	fi

	#print tx hashes (only last 10000)
	printf '\nTx Hashes (max 10000):\n'
	jq -r '.data[] | "\t\(.transactions|reverse[])"' <<< "$CHAIRADD"

	#print unspent tx
	printf '\nUnspent Txs:\n'
	jq -er '.data[].utxo[]|
			"\t\(.transaction_hash)",
			"\t ^Block: \(.block_id)  Value: \(.value)  \(.value/100000000) BTC"' <<< "$CHAIRADD" || printf 'No unspent tx list.\n'

	#print address info
	printf '\n\nAddress Info\n'
	jq -r '"",
		"--------",
		"Address: \(.data|keys[0])",
		"Updated: \(.context.cache.since)Z",
		(.data[].address|
			"Type___: \(.type)",
			"TxCount: \(.transaction_count)  Unspent: \(.unspent_output_count)",
			"OutTxs_: \(.output_count)",
			"1st_Rcv: \(.first_seen_receiving // empty)",
			"Last_Rc: \(.last_seen_receiving // empty)",
			"1st_Spt: \(.first_seen_spending // empty)",
			"Last St: \(.last_seen_spending // empty )",
			"Receivd: \(.received)  \(.received/100000000) BTC  \(.received_usd|round) USD",
			"Spent__: \(.spent)  \(.spent/100000000) BTC  \(.spent_usd|round) USD",
			"Balance: \(.balance)  \(.balance/100000000) BTC  \(.balance_usd|round) USD"
		)' <<< "$CHAIRADD"
}

#-p unspent outputs
utxaddf() {
	#multiple addresses?
	#get raw multi addr data
	set -- ${@//|/ }
	addrs=( ${@/%/|} )
	add="${addrs[*]}"
	add="${add// }"
	add="${add%|}"

	UTXADD="$( "${YOURAPP2[@]}" "https://blockchain.info/unspent${key1}&active=${add}&limit=1000" )"
	echo >&2

	#print json?
	if [[ -n  "$PJSON" ]]; then
		printf 'JSON from the address function.\n' 1>&2
		echo "$UTXADD"
		return 
	fi

	#check for error, try blockchair
	#if grep -iq -e 'err:' -e 'illegal' -e 'invalid' -e 'Checksum does not validate' <<< "$RAWADD"; then
	if ! jq -e '.unspent_outputs' <<< "$UTXADD" &>/dev/null; then
		printf 'Err: <blockchain.com> -- %s\n' "$( grep -F '<p>' <<<"$UTXADD" | sed 's/<[^>]*>//g ; s/^\s*//' )" >&2
		return  1
	fi

	#print unspent txs
	jq -r '.unspent_outputs[]|
		"",
		"--------",
		"Tx_Hash: \(.tx_hash)",
		"BEndian: \(.tx_hash_big_endian)",
		"Script_: \(.script)",
		"Value__: \(.value)\tValueHx: \(.value_hex)",
		"Confirm: \(.confirmations)\tTxIndex: \(.tx_index)",
		"TxOutpt: \(.tx_output_n)" ' <<< "$UTXADD"

}

#-t raw tx info
rtxf() {
	#unset FMT if user did not request it
	[[ -n "$HEXOPT" ]] || unset FMT2 FMT2b

	#check if there is a rawtx from another function already
	if [[ -z "$RAWTX" ]]; then
		RAWTX="$( "${YOURAPP2[@]}" "https://blockchain.info/rawtx/${1}${key1}${FMT2b}" )"
		echo >&2
	fi

	#print json?
	if [[ -n  "$PJSON" ]]; then
		#only if from tx opts explicitly
		echo 'JSON from the tx function' >&2
		echo "$RAWTX"

		unset RAWTX
		return 0
	#print hex opt
	elif [[ -n "$HEXOPT" ]]; then
		echo "$RAWTX"

		unset RAWTX
		return 0
	#test for no tx info received, maybe there is no tx done at an address
	elif ! jq -e '.hash' <<<"$RAWTX" 1>/dev/null 2>&1; then
		echo "Err: transaction not found -- $1" >&2
		
		unset RAWTX
		return 1
	fi

	#process
	jq -r '"                                 ",
		"--------",
		"Transaction Details",
		"Transaction vectors",
		"  From_:",
		(.inputs[].prev_out|"    \(.addr)  \(if .value == null then "??" else (.value/100000000) end) BTC  \(if .spent == true then "SPENT" else "UNSPENT" end)  \(.addr_tag // "")"),
		"  To___:",
		(.out[]|"    \(.addr)  \(if .value == null then "??" else (.value/100000000) end) BTC  \(if .spent == true then "SPENT" else "UNSPENT" end)  \(.addr_tag // "")"),
		"",
		"",
		"Transaction information",
		"TxHash_: \(.hash)",
		"BlkHgt_: \(if .block_height == null then "mempool" else .block_height end)\t\t\tVersion: \(.ver)",
		"Tx_Size: \(.size) bytes\t\tWeight_: \(.weight)",
		"LockTime: \(.lock_time)",
		"Time___: \(.time | strftime("%Y-%m-%dT%H:%M:%SZ"))",
		"LocalTi: \(.time |strflocaltime("%Y-%m-%dT%H:%M:%S%Z"))",
		"Relayed: \(if .relayed_by == "0.0.0.0" then empty else .relayed_by end)"' <<< "$RAWTX"

	unset RAWTX
}

#-tt transaction info from <blockchair.com>
chairrtxf() {
	TXCHAIR="$( "${YOURAPP[@]}" "https://api.blockchair.com/bitcoin/dashboards/transaction/$1" )"
	#print json?
	if [[ -n  "$PJSON" ]]; then
		printf 'JSON from the chair tx function.\n' 1>&2
		echo "$TXCHAIR"
		return
	fi
	#test response from server
	if grep -iq 'DOCTYPE html' <<< "$TXCHAIR"; then
		echo "Err: <blockchair.com> -- transaction not found -- $1" >&2
		return 1
	fi

	#process
	jq -r '"",
		"--------",
		"Transaction Details (Blockchair)        ",
		"Transaction vectors",
		"  From:",
		(.data[].inputs[]|
			"    \(.recipient)  \(.value/100000000)  \(if .is_spent == true then "SPENT" else "UNSPENT" end)"
		),
		"  To__:",
		(.data[].outputs[]|
			"    \(.recipient)  \(.value/100000000) \(if .is_spent == true then "SPENT" else "UNSPENT" end)  ToTxID: \(.spending_transaction_id)"
		),
		(.data[].transaction|
			"",
			"",
			"Transaction information",
			"Hash____: \(.hash)",
			"TxIndex_: \(.id)\tVersion: \(.version)",
			"Block_ID: \(.block_id)\tCDD____: \(.cdd_total) \(if .is_coinbase == true then "(Coinbase)" else "" end)",
			"Size____: \(.size) bytes\tWeight_: \(.weight) WU",
			"Inputs__: \(.input_count)\t\tOutputs: \(.output_count)",
			"TotalIn_: \(.input_total)  \(.input_total_usd) USD",
			"TotalOut: \(.output_total)  \(.output_total_usd) USD",
			"Fee_Rate: \(.fee // "??") sat  \(.fee_per_kb // "??") sat/KB",
			"Fee_rate: \(.fee_usd // "??") USD  \(.fee_per_kb_usd // "??") USD/KB",
			"LockTime: \(.lock_time)",
			"Time____: \(.time)Z",
			"LocalTim: \(.time | strptime("%Y-%m-%d %H:%M:%S")|mktime|strflocaltime("%Y-%m-%dT%H:%M:%S%Z"))"
		)' <<< "$TXCHAIR"
}

#bitcoin hash rate hist
hashratef()
{
	DATA="$( "${YOURAPP[@]}" --header "$UAG" 'https://api.blockchain.info/charts/hash-rate?timespan=all&sampled=true&metadata=false&cors=true&format=json' )"
	#print json?
	if [[ -n  "$PJSON" ]]; then
		echo "$DATA"
		return
	fi

	jq -r '"stat: \(.status)",
		"name: \(.name)",
		"unit: \(.unit)",
		"perd: \(.period)",
		"desc: \(.description)",
		(.values[]|
			"time: \(.x|strflocaltime("%Y-%m-%dT%H:%M:%S%Z"))\trate(TH/s): \(.y)      \trate(H/s): \(.y*1000000000000)"
		)' <<<"$DATA"

}
#https://www.blockchain.com/charts/hash-rate

#-u | -m memory pool unconfirmed txs ( mempool )
#only 48 last transaction, prefer <blockchair.com> api
#utxf() {
#	printf "Unconfirmed transactions (Mempool).\n" 1>&2
#	RAWTX="$( "${YOURAPP[@]}" "https://blockchain.info/unconfirmed-transactions${key1}&format=json" | jq -r '.txs[]' )"
#	rtxf
#	return
#}

#-u | -m memory pool unconfirmed txs (mempool) from blockchair
#uses blockchain.info and blockchair.com
utxf() {
	printf 'Addresses and balance deltas:\n'
	#printf 'Waiting server response..\r' 1>&2
	MEMPOOL="$( "${YOURAPP2[@]}" "https://api.blockchair.com/bitcoin/state/changes/mempool" )"

	#print json?
	if [[ -n  "$PJSON" ]]; then
		printf 'JSON from the mempool function.\n' 1>&2
		echo "$MEMPOOL"
		return
	fi

	#check for error response
	chairerrf "$MEMPOOL"

	#print addresses and balance delta (in satoshi and btc)
	#addresses and balance deltas
	jq -r '.data | keys_unsorted[] as $k | "\($k)  \(.[$k])  \(.[$k]/100000000) BTC"' <<< "$MEMPOOL"

	#some more info
	printf '\nUnconfirmed txs (Mempool)\n'
	jq -r '(.context.cache|"TStamp_: \(.since)  Duration: \(.duration)")' <<< "$MEMPOOL"
	printf 'Addrs__: %s\n' "$(jq -r '.context.results' <<<"$MEMPOOL")"
	printf 'TxCount: %s\n' "$( "${YOURAPP[@]}" "https://blockchain.info/q/unconfirmedcount"  2>/dev/null )"

	#calc total value of mempool
	TOTALDELTA=($(jq -r '.data[]|tostring|match("^[1-9][0-9]+")|.string' <<<"$MEMPOOL"))
	printf 'TtValue: %.8f  BTC\n' "$(bc -l <<<"(${TOTALDELTA[*]/%/+}0)/100000000")"
}

#parse options
while getopts ':abehijlmnprsutvx' opt
do
	case $opt in
		( a ) #address info
			[[ -z "$ADDOPT" ]] && ADDOPT=info || ADDOPT=chair
			;;
		( b ) #raw block info
			RAWOPT=1
			;;
		( e ) #soket mode for new btc blocks
			STREAMOPT=1
			;;
		( h ) #help
			echo "$HELP"
			exit 0
			;;
		( i ) #24-h blockchain ticker
			[[ -z "$BLKCHAINOPT" ]] && BLKCHAINOPT=info || BLKCHAINOPT=chair
			;;
		( j ) #print json
			PJSON=1
			;;
		( l ) #latest block info
			LATESTOPT=1
			;;
		( m|u ) #memory pool unconfirmed txs
			MEMOPT=1
			;;
		( n ) #block height info
			HOPT=1
			;;
		( p ) #unspent tx
			UTXOPT=1
			;;
		( r ) #bitcoin hash rate hist
			ROPT=1
			;;
		( s ) #summary  address info
			SUMMARYOPT=1
			[[ -z "$ADDOPT" ]] && ADDOPT=info || ADDOPT=chair
			;;
		( t ) #transaction info
			[[ -z "$TXOPT" ]] && TXOPT=info || TXOPT=chair
			;;
		( v ) #version of script
			grep -m1 '# v' "$0"
			exit
			;;
		( x ) #hex opt
			HEXOPT=1
			#FMTb="$FMT2b"
			;;
		( \? )
			echo "Invalid option: -$OPTARG" >&2
			exit 1
			;;
	 esac
done
shift $((OPTIND -1))
unset opt

#must have packages
if ! command -v jq &>/dev/null
then echo 'JQ is required' >&2 ;exit 1
fi
if command -v curl &>/dev/null
then YOURAPP=( curl -\# -L --compressed )    YOURAPP2=( curl -L --compressed )
elif command -v wget &>/dev/null
then YOURAPP=( wget -q -O- --show-progress ) YOURAPP2=( wget -O- --show-progress )
else echo 'cURL or Wget is required' >&2 ;exit 1
fi

#api key for this programme
#usage:?key=${key}
key=b31ba37b-2506-46a9-a4a0-54c276c68884
key1="?${key}"
export key
#https://www.blockchain.com/api/api_receive

#check function args
if [[ -n "$ADDOPT" || -n "$TXOPT" ]] && [[ -z "$1" ]]
then echo 'Err -- hash is needed' >&2 ;exit 1
fi

#call opts
#new block stream
if [[ -n "$STREAMOPT" ]]
then sstreamf
#blockchain information / stats
elif [[ -n "$ROPT" ]]
then hashratef
elif [[ "$BLKCHAINOPT" = info ]]
then blkinfof
elif [[ "$BLKCHAINOPT" = chair ]]
then chairblkinfof
#blocks
elif [[ -n "$LATESTOPT" ]]
then latestf
#addresses
elif [[ "$ADDOPT" = info ]]
then raddf "$@"
#addresses -- unspent tx
elif [[ -n "$UTXOPT" ]]
then utxaddf "$@"
#mempool (blockchair)
elif [[ -n "$MEMOPT" ]]
then utxf
#call opt functions
else
	for arg in "$@"
	do
		#block by height
		if [[ -n "$HOPT" ]]
		then hblockf "$arg"
		#block by hash
		elif [[ -n "$RAWOPT" ]]
		then rblockf "$arg"
		elif [[ "$ADDOPT" = chair ]]
		then chairaddf "$arg"
		#transactions
		elif [[ "$TXOPT" = info ]]
		then rtxf "$arg"
		elif [[ "$TXOPT" = chair ]]
		then chairrtxf "$arg"
		else notok=1
		fi
		#get exit code
		RET+=($?)

		#try not to flood the server
		sleep 0.8
	done

	#automatic opt selection
	if ((notok))
	then
		#other functions
		#loop through arguments
		for arg in "$@"
		do
			unset notok

			#is legacy addr?
			if [[ "$arg" =~ ^[13][a-km-zA-HJ-NP-Z1-9]{25,34}$ ]]
			then raddf "$arg"      #addr from blockchain.com
			#is bech32 addr?
			elif [[ "$arg" =~ ^bc(0([ac-hj-np-z02-9]{39}|[ac-hj-np-z02-9]{59})|1[ac-hj-np-z02-9]{8,87})$ ]]
			then chairaddf "$arg"  #addr from blockchair
			#is tx or block?
			elif [[ "$arg"  =~ ^[a-fA-F0-9]{64}$ ]]
			then
				#is block?
				if [[ "$arg" =~ ^[0]{8}[a-fA-F0-9]{56}$ ]]
				then rblockf "$arg"  #block by hash
				else rtxf "$arg"     #tx hash
				fi
			#block by height
			elif [[ "$arg" =~ ^[0-9]+$ ]] && ((arg<1000000)) 2>/dev/null
			then hblockf "$arg"
			else notok=1
			fi
			#get exit code
			RET+=($?)

			#try not to flood the server
			sleep 0.8
		done
	fi

	#if no option or argument given
	#default function
	#summary information of latest block
	if (($#==0)) || ((notok))
	then latestf
	fi
fi
#get exit code
RET+=($?)

#sum exit codes
exit $(( ${RET[@]/%/+} 0 ))

