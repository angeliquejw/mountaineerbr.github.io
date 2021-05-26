#!/bin/bash
# v0.7.5  may/2021  by mountaineerbr
# bitcoin block information and functions

#script name
SN="${0##*/}"

#print simple
#feedback to stderr
OPTVERBOSE=0

#separator for option -n
#defaults='\t'
SEP='\t'

#mininum length to print sequences
#of characters, opt -y
#defaults=20
STRMIN="${STRMIN:-20}"

#maximum simultaneous asynchronous jobs
#defaults=1
JOBSDEF=1

#timezone
#defaults=UTC0
TZ="${TZ:-UTC0}"
export TZ

#set locale
#LC_NUMERIC=C
LANG=C LC_ALL=C

#printf clear line
CLR='\033[2K'

#genesis block hash (same as coinbase tx hash)
#requesting this may throw errors in some funcs
GENBLK_HASH=000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f
#get tx with `bitcoin-cli getblock $GENBLK_HASH 2`

#help
HELP="NAME
	$SN - Bitcoin block information and functions


SYNOPSIS
	$SN [-.,] [BLOCK_HASH..|BLOCK_HEIGHT..]
	$SN [-dd] [-luv] [-jNUM] [DATESTRING|@UNIXTIME]
	$SN [-Iiiyy] [-lv] [-jNUM] [BLOCK_HASH..|BLOCK_HEIGHT..]
	$SN -tt [-lnuv] [-jNUM] [BLOCK_HASH..|BLOCK_HEIGHT..]
	$SN -mmm [-lv] [-jNUM] [TRANSACTION_ID..]
	$SN [-bhV]


DESCRIPTION
	The default function is to print block information of BLOCK_HASH
	or BLOCK_HEIGHT. If option -i is set, prints the block header
	information and transaction hases. If option -ii is set, prints
	only transaction hashes from block. If option -I is set, prints
	json of all the block transactions. Multiple block hashes or
	height numbers are allowed. If empty, fetches hash of best (last)
	block. Negative integers refer to a block from the tip, i.e. -10,
	see note on example (1.2). Setting a . (dot) as positional param-
	eter is understood as best block.

	Option -. (dot) prints block height and -, (comma) prints block
	hash. Multiple block heights and hashes may be set as positional
	parameters. Negative index from the tip is accepted. If no pos-
	itional parameter is given, fetches best block. Options -,. may
	be combined.

	Option -m prints mempool transaction ids and -mm prints mempool
	transactions with more information. Optionally, transaction ids
	from the mempool are accepted as positional parameters. Option
	-mmm prints the number of transactions, their fees and some stats.

	Option -t generates a list of block timestamps, one timestamp per
	line. Set option -n to print block height hash besides block time
	separated by <TAB> control character. The defaults behaviour is
	to print \`mediantime' of blocks. Set -tt to print \`time' of blocks
	instead. Check reference at SEE ALSO for the distinction between
	both.

	To speed up processing of some options, setting maximum number of
	asynchronous jobs with option -jNUM is allowed, in which case NUM
	must be an integer or \`max'; asynchronous jobs may print in dif-
	ferent order from input request; consider manually sorting output
	afterwards, if needed; increasing NUM may only return modest speed
	gains; defaults jobs=$JOBSDEF .

	Option -d DATESTRING finds the block height immediately before or
	at a date, in which DATESTRING is a string describing a date that
	is understandable by the GNU date programme. Note that option -l
	changes interpretation of input time as local time; set option -v
	to check target and matched times. If input date string is UNIX
	time, attach an \`\`at'' (@) sign to it, see usage example (3).

	Option -d takes user input and tries to autocorrect it to a format
	GNU date programme can understand. Check date interpretation ver-
	bosely with option -v. In case of a wrong modification or inter-
	pretation of user input, set -d multiple times to disable auto
	correction.

	Option -u prints time in human-readable format.

	Option -l sets local time instead of UTC time.

	Option -v enables verbose, set twice to more verbose.

	Option -y will convert hex from a coinbase transaction to ascii
	text.  The output will be filtered to print sequences that are at
	least $STRMIN characters long, unless that returns empty, in which
	case there is decrement of one character until nought.  If nought
	is reached, the raw byte output will be printed.  You may set
	-yy to print raw byte output at once, see example (4).


ENVIRONMENT
	BITCOINCONF
		Path to bitcoin.conf or equivalent file with configs
		such as RPC user and password, is overwritten by script
		option -c, defaults=\"\$HOME/.bitcoin/bitcoin.conf\".

	STRMIN  Sets mininum length to print sequences of characters
		for options opt -y; alternatively, see usage example (4.3).

	TZ 	Sets timezone; if none set, defaults to UTC0 (GMT).


SEE ALSO
	A bitcoin-cli script to try and find approximate block height
	at a date. This was the inspiration of what became option -d
	in this script. Specifically, the usage of the bisection technique.

	<github.com/kristapsk/bitcoin-scripts/blob/master/blockheightat.sh>


	Median Time vs. Time of a Block
	<https://github.com/bitcoin/bips/blob/master/bip-0113.mediawiki>
	

WARRANTY
	Licensed under the gnu general public license 3 or better and
	is distributed without support or bug corrections.

	Bitcoin-cli v0.21+, jq, xxd, GNU date v5.3+ and bash are required.
	
	If you found this programme interesting, please consider
	sending me a nickle!  =)
  
		bc1qlxm5dfjl58whg6tvtszg5pfna9mn2cr2nulnjr


BUGS
	Not a real bug but note that some maths are performed with package
	\`jq', which uses double float values, thus for e.g. 0.999999 may
	actually be 1.


BLOCK REFERENCES
	BLOCK 		UNIX TIME 	HUMAN-READABLE TIME (UTC)
	#0 Genesis 	1231006505 	2009-01-03T18:15:05+00:00
	#1 Height 1	1231469665 	2009-01-09T02:54:25+00:00


USAGE EXAMPLES
	1) Get block information by block hash or height

	1.1) Information of 3 blocks, input is mixed with block heights
	     and hashes:

	$ $SN 200000 00000000000000000007316856900e76b4f7a9139cfbfba89842c8d196cd5f91


	1.2) Negative index, the 10th, 11th and 12th block before best
	     block (tip). Note that -- signals the end of script options,
	     if any:

	$ $SN -- -10 -11 -12


	2.1) Generate a list of timestamps from block 0 to 1000,
	     defaults to one job at most, output is ordered.

	$ $SN -t {0..1000}
	

	2.2) Generate a list of timestamps from block 0 to 1000, set
	     max jobs to 4; faster but prints asynchronously, so we
	     will sort output numerically.

	$ $SN -t -j4 {0..1000} | tee | sort -n


	3) Find a block at or immediately before a date and time.
	   Note that date format must be understood by GNU \`date\`

	3.1) UNIX time format

	$ $SN -d  @1584007200


	3.2) Verbose with human-readable time formats
	
	$ $SN -duv '12-mar-2020 10:00'
	
	
	3.3) Local time instead of UTC0 (GMT)
	
	$ $SN -dvl '12 mar 2020 10:00:00'

	
	3.4) Local time, relative
	
	$ $SN -dl 'yesterday 9:00pm'


	4.1) Decode hex code from coinbase transaction of a block to
	     ascii text:
	
	$ $SN -y 0000000000000000000080324fdf044b64f0661b3562a5729a51722d007d90b8


	4.2) Decode hex code from coinbase of the last 10 blocks (note
	     usage of brace expansion and negative relative block height):
	
	$ $SN -y -- -{0..9}


	4.3) Some other usage examples with package \`strings':

	$ $SN -yy 666076 | strings -n 20

	$ strings -n 20 blk00003.dat  #decode the whole block file


OPTIONS
	Miscellaneous
	-b 	General blockchain, mempool, mining, network and rpc info.
	-c  CONFIGFILE
		Path to bitcoin.conf or equivalent configuration file,
		defaults=\"\$HOME/.bitcoin/bitcoin.conf\".
	-e 	Print raw data when possible, debugging.
	-h 	Print this help page.
	-j  NUM	Maximum simultaneos jobs, may print asynchronously,
		defaults=$JOBSDEF .
	-l 	Set local time instead of UTC time.
	-u 	Print time in human-readable format.
	-v	Enables verbose feedback, may set multiple time.
	-V 	Print script version.

	Find block height at date
	-d  DATESTRING
		Find block height before or at time/date, check target
		and matched time with -v .
	-dd DATESTRING
		Same as -d, but disables autocorrection of user input
		date format.

	Timestamp list
	-n 	Print block hash besides block timestamp.
	-t  [HASH|HEIGHT]
		Generate a list of block mediantime timestamps.
	-tt [HASH|HEIGHT]
		Same as -t but uses block time instead.

	Memory pool
	-m 	Print mempool transaction ids.
	-mm [TXID]
		Print mempool transactions with more info, if empty,
		process the whole mempool.
	-mmm 	Print the number of transactions, their fees and some
		stats, same as -M .

	Block information
	Options below accept [HASH|HEIGHT] as arguments.
	-. 	Print block height.
	-, 	Print block hash.
	-i 	Block header information and transaction hases.
	-ii 	Block transaction hashes only.
	-I 	Prints raw json of all the block transactions. 
	-y 	Decode coinbase hex to ascii text, print sequences
		longer than $STRMIN chars only.
	-yy 	Same as -y but prints all bytes, same as -Y ."


#functions

#err signal
errsigf()
{
	local sig="${1:-1}"
	{ echo "$sig" >>"$TMPERR" ;} 2>/dev/null
}

#clean temp files
cleanf() {
	#disable trap
	trap \  EXIT

	#check for err signals in err temp file
	if [[ -e "$TMPERR" ]]
	then
		RET+=( $(<"$TMPERR") )
		rm "$TMPERR"
	fi
	#verbose feedback
	(( OPTVERBOSE )) && 
		printf '>>>took %s seconds  (%s minutes)\n' "$SECONDS" "$(( SECONDS / 60 ))" >&2
	
	#sum exit codes from other funcs
	exit $(( ${RET[@]/%/+} 0 ))
}

#get unix time from user input
#print error msg only if DATE is not human or unix time
dateunixfhelper()
{
	local str str2 seprm fmt

	#out-time format
	fmt=+%s
	#chars to remove
	seprm='[ /._-]*'

	#set string
	str="$*"
	#try this new separator
	sep="$sep"

	#defaults
	if date -d"$str" "$fmt"
	then
		return 0
	#some unusual date input formats
	elif
		str2="$( sed -En "s:([0-9]{1,4})(${seprm})([a-zA-Z]{3,}|[0-9]{1,2})(${seprm})([0-9]{1,4}):\1${sep}\3${sep}\5:p" <<<"$str" )" &&
		[[ -n "$str2" ]] && date -d"$str2" "$fmt"
	then
		return 0
	elif
		str2="$( sed -En "s:([0-9]{1,4})(${seprm})([a-zA-Z]{3,}|[0-9]{1,2})(${seprm})([0-9]{1,4}):\5${sep}\3${sep}\1:p" <<<"$str" )" &&
		[[ -n "$str2" ]] && date -d"$str2" "$fmt"
	then
		return 0
	fi
	
	return 1
}
#check DATE format validity
checkdatef() { 
	local unix sepout sep unix unixmin unixmax ok 

	#disable date checking?
	(( OPTDATE > 1 )) && return 1

	#rm extra chars froma rgs
	set -- "${@#[./]}"
	set -- "${@%[./]}"

	#only one letter is not date
	#not a date format
	if [[ "$*" = [a-z] ]] || (( ( ${#1} + ${#2} ) < 3 ))
	then return 1
	fi

	#try these separators
	for sep in \  \/ \-
	do  unix="$( dateunixfhelper "$@" )" && break
	done

	(( unix )) || return 1
	
	echo "$unix"
	return 0
}


#decode coinbase HEX
deccoinbf()
{
	local ascii coinb num rawtx strs txhex ret
	typeset -a ret

	#get coinbase tx hash
	coinb="$( jq -r '.tx[0]' <<< "$BLK" )"
	ret+=( $? )

	#get coinbase raw tx data and its hex
	#is target other block than genesis block?
	if [[ "$BLK_HASH" = "$GENBLK_HASH" ]]
	then
		#genesis block tx
		rawtx="$coinb"
	else
		rawtx="$(bwrapper getrawtransaction "$coinb" true)"
		ret+=( $? )
	fi
	
	#get coinbase hex
	txhex="$(jq -r '.hex' <<<"$rawtx" )"
	ret+=( $? )
	#or: .vin[].hex
	
	#debug? print raw data
	if (( DEBUGOPT ))
	then
		echo "$BLK"
		echo "$BLKSTAT"
		echo "$rawtx"
		echo "$txhex"
		echo "$coinb"
		return
	fi

	#verbose?
	(( OPTVERBOSE )) &&
		echo -ne "--------\nBLK_: $BLK_HASH\nTXID: $coinb\nHEX_: $txhex\nASCI: "

	#print ascii text
	if ((OPTASCII>1))
	then
		echo -n "$txhex" | xxd -p -r
	else
		#decode hex to ascii (ignore null byte warning)
		{ ascii="$(echo -n "$txhex" | xxd -p -r)" ;} 2>/dev/null

		for ((num=STRMIN ;num>=0 ;--num))
		do
			((num)) || break

			strs="$( strings -n "$num" <<<"$ascii" )"
			#-n Print sequences of characters that are
			#at least min-len characters long, instead of the default 4

			[[ -n "${strs// /}" ]] && break
		done

		#decide how to print
		if ((num))
		then
			#there was some output from `strings`
			echo "$strs"
		else
			#otherwise print the raw ascii
			echo -n "$txhex" | xxd -p -r
		fi
	fi
	ret+=( $? )

	#sum exit codes
	return $(( ${ret[@]/%/+} 0 ))
}

#is block hash or height?
ishashf()
{
	local hx
	hx="$1"

	#grep -qEx '[0]{8}[a-fA-F0-9]{56}' <<<"$hx"
	[[ "$hx" =~ ^0{8}[a-fA-F0-9]{56}$ ]]
}

#blockchain general information
#mempool, network information
blockchainf()
{
	local chain_info forknames key mining_info mempool_info

	#rpc info
	#print simple feedback to stderr?
	((OPTVERBOSE)) && printf "\r${CLR}%s " "Getting RPC info.." >&2
	rpc_info="$(bwrapper getrpcinfo)" || return

	#network info
	((OPTVERBOSE)) && printf "\r${CLR}%s " "Getting Network info.." >&2
	net_info="$(bwrapper getnetworkinfo)" || return

	#net totals
	((OPTVERBOSE)) && printf "\r${CLR}%s " "Getting Net Totals info.." >&2
	nettotals_info="$(bwrapper getnettotals)" || return

	#get mining stats
	((OPTVERBOSE)) && printf "\r${CLR}%s " "Getting Mining info.." >&2
	mining_info="$(bwrapper getmininginfo)" || return

	#get mempool data
	((OPTVERBOSE)) && printf "\r${CLR}%s " "Getting Mempool info.." >&2
	mempool_info="$(bwrapper getmempoolinfo)" || return

	#blockchain info
	((OPTVERBOSE)) && printf "\r${CLR}%s " "Getting Blockchain info.." >&2
	chain_info="$(bwrapper getblockchaininfo)" || return
	#fork information
	((OPTVERBOSE)) && printf "\r${CLR}%s " "Getting Fork info.." >&2
	forknames=( $(jq -r '.softforks // empty | keys_unsorted[]' <<< "$chain_info" 2>/dev/null) )

	#sanity newline
	((OPTVERBOSE)) && printf "%s\n" "" >&2

	#debug? print raw data
	if (( DEBUGOPT ))
	then
		echo "$rpc_info"
		echo "$nettotals_info"
		echo "$net_info"
		echo "$mining_info"
		echo "$mempool_info"
		echo "$chain_info"
		return 0
	fi

	#ignore error messages?
	{

	<<< "$rpc_info" jq -r '"",
		"--------",
		"RPC-call information",
		"Commands:",
		( .active_commands[]|"  Method: \(.method)\t Duration: \(.duration) µs" ),
		"Logpath_: \(.logpath)"'
	ret+=( $? )

	<<< "$net_info" jq -r '"",
		"--------",
		"Network information",
		"Version_: \(.version)",
		"SubVersi: \(.subversion)",
		"ProtVers: \(.protocolversion)",
		"LService: \(.localservices)",
		"LSerName: \(.localservicesnames|@sh)",
		"LocRelay: \(.localrelay)",
		"TiOffset: \(.timeoffset)",
		"NetwActv: \(.networkactive)",
		"Connects: \(.connections)",
		"ConnecIn: \(.connections_in)",
		"ConneOut: \(.connections_out)",
		"Networks:",
		( .networks[]|
			"  Name__: \(.name)\t Limitd: \(.limited)\t Reachb: \(.reachable)\t PxRand: \(.proxy_randomize_credentials)\t Proxy_: \(.proxy//"-")"
		),
		"RelayFee: \(.relayfee) BTC/kB",
		"IncreFee: \(.incrementalfee) BTC/kB",
		"LocalAddresses:",
		(.localaddresses[]|
			"  Addres: \(.address)\t Port__: \(.port)\t Score_: \(.score)"
		),
		"Warnings: \(if .warnings == "" then empty else .warnings end)"'
	ret+=( $? )

	#human readable table with inbound and outbound peers
	#bitcoin-cli -netinfo
	#ret+=( $? )

	<<< "$nettotals_info" jq -r '"",
		"--------",
		"Net totals information",
		"TotBRecv: \(.totalbytesrecv) B\t \(if (.totalbytesrecv/1000000) < 2000 then "\(.totalbytesrecv/1000000) MB" else "\(.totalbytesrecv/1000000000) GB" end)",
		"TotBSent: \(.totalbytessent) B\t \(if (.totalbytessent/1000000) < 2000 then "\(.totalbytessent/1000000) MB" else "\(.totalbytessent/1000000000) GB" end)",
		"UNIXEpoc: \(.timemillis) [ms]",
		"UplodTgt:",
		(.uploadtarget |
		"  TimeFram: \(.timeframe) s",
		"  Target__: \(.target) B",
		"  TgtReach: \(.target_reached)",
		"  SHistBlk: \(.serve_historical_blocks)",
		"  BLeftCyc: \(.bytes_left_in_cycle) B",
		"  TLeftCyc: \(.time_left_in_cycle) s"
		)'
	ret+=( $? )

	<<< "$mining_info" jq -r '"",
		"--------",
		"Mining information",
		"Chain___: \(.chain)",
		"Blocks__: \(.blocks)",
		"Difficul: \(.difficulty)",
		"HashRate: \(.networkhashps) H/s\t \(.networkhashps/1000000000000000000 | tostring | .[0:6]) EH/s",
		"PooledTx: \(.pooledtx) txs",
		"Warnings: \(if .warnings == "" then empty else .warnings end)"'
	ret+=( $? )

	<<< "$mempool_info" jq -r '"",
		"--------",
		"Mempool information",
		"Loaded__: \(.loaded)",
		"Min_Fee_: \( .mempoolminfee ) sat/KB\t \(.mempoolminfee/1000) sat/B",
		"MinRlyFe: \( .minrelaytxfee ) sat/KB\t \(.minrelaytxfee/1000) sat/B",
		"MaxMempo: \(.maxmempool)\t \(.maxmempool / 1000000 | tostring | .[0:6] ) MB",
		"UsageTot: \(.usage)\t \(.usage / 1000000 | tostring | .[0:6] ) MB",
		"vTxSize_: \(.bytes)\t \(.bytes / 1000000 | tostring | .[0:6] ) MvB",
		"UnbroadC: \(if .unbroadcastcount == 0 then empty else .unbroadcastcount end)",
		"Tx_Count: \(.size) txs"'
	ret+=( $? )

	#fork names
	if [[ -n "${forknames[*]}" ]]
	then
		echo -e "\n--------\nBlockchain forks"
		for key in "${forknames[@]}"
		do
			<<< "$chain_info" jq -r --arg key "$key" '.softforks | .[$key] |
				"    Name: \($key)\t Type: \(.type)\t Active: \(.active)\t Height: \(.height)"'
		done
	fi
	#general info
	<<< "$chain_info" jq -r '"--------",
		"Blockchain status",
  		"Warnings: \(.warnings // empty)",
  		"Chain___: \(.chain)",
  		"Blocks__: \(.blocks)",
  		"Headers_: \(.headers)",
  		"IniBlkDl: \(.initialblockdownload)",
  		"Pruned?_: \(.pruned)",
  		"SizeDisc: \(.size_on_disk) B\t \(.size_on_disk / 1000000000 | tostring | .[0:6] ) GB",
		"Verifica: \(.verificationprogress)\t \(.verificationprogress * 100 | tostring | .[0:6] ) %",
  		"BestBlk_: \(.bestblockhash)",
  		"ChainWrk: \(.chainwork)",
  		"Difficul: \(.difficulty)",
  		"MedianTi: \(.mediantime)\t \(.mediantime | '$HH' )"'
	ret+=( $? )

	} #2>/dev/null

	#sum exit codes
	return $(( ${ret[@]/%/+} 0 ))
}

#general block information and block transactions
defaultf()
{
	local blk_stat ret
	typeset -a ret

	#get block stats, too
	if (( OPTI < 2 )) && [[ "$BLK_HASH" != "$GENBLK_HASH" ]]
	then blk_stat="$( bwrapper getblockstats \""$BLK_HASH"\" )"
	fi

	#debug? print raw data
	if (( DEBUGOPT ))
	then
		echo "$BLK"
		echo "$blk_stat"
		echo "$BLK_HASH"
		echo "$BLK_HEIGHT"
		return
	fi

	#header?
	(( OPTI == 1 )) &&
		printf '\n\n%s\n%s\n' '--------' Transactions
	#print transaction hashes
	if (( OPTI ))
	then jq -r '.tx[]' <<<"$BLK" || return
	fi

	#print block information
	if (( OPTI < 2 ))
	then
		#is target other block than genesis block?
		if [[ "$BLK_HASH" != "$GENBLK_HASH" ]]
		then
			<<< "$blk_stat" jq -r '"",
				"--------",
				"Block status",
				"Height__: \(.height)",
				"Avg_Fee_: \(.avgfee) sat/KB \t \(.avgfee/1000) sat/B",
				"Med_Fee_: \(.medianfee) sat/KB\t \(.medianfee/1000) sat/B",
				"Min_Fee_: \(.minfee) sat/KB\t \(.minfee/1000) sat/B",
				"Max_Fee_: \(.maxfee) sat/KB\t \(.maxfee/1000) sat/B",
				"--------",
				"Transaction Fee Rates",
				"AvgFeeRt: \(.avgfeerate) sat/vB",
				"MinFeeRt: \(.minfeerate) sat/vB",
				"MaxFeeRt: \(.maxfeerate) sat/vB",
				"FeeRtPct: \(.feerate_percentiles | tostring ) sat/vB",
				"--------",
				"Segwit transactions",
				"Segw_Txs: \(.swtxs)",
				"SwTotWgt: \(.swtotal_weight) WU",
				"SwTotSiz: \(.swtotal_size) B\t \(.swtotal_size/1000) KB",
				"--------",
				"Transaction status",
				"AvgTxSiz: \(.avgtxsize) B\t \(.avgtxsize/1000) KB",
				"MedTxSiz: \(.mediantxsize) B\t \(.mediantxsize/1000) KB",
				"MinTxSiz: \(.mintxsize) B\t \(.mintxsize/1000) KB",
				"MaxTxSiz: \(.maxtxsize) B\t \(.maxtxsize/1000) KB",
				"--------",
				"Txs_In__: \(.ins)",
				"Txs_Out_: \(.outs)",
				"Utxo_Inc: \(.utxo_increase)",
				"UtxoSizI: \(.utxo_size_inc)",
				"--------",
				"TotalWgt: \(.total_weight) WU",
				"TotalSiz: \(.total_size) B\t \(.total_size/1000) KB",
				"TotalOut: \(.total_out)\t \(.total_out/100000000) BTC",
				"Subsidy_: \(.subsidy)\t \(.subsidy/100000000) BTC",
				"TotalFee: \(.totalfee)\t \(.totalfee/100000000) BTC"'
			ret+=( $? )
		fi

		<<< "$BLK" jq -r '"--------",
			"Block information",
			"Hash____: \(.hash)",
			"MrklRoot: \(.merkleroot)",
			"PrevBlkH: \(.previousblockhash)",
			"NextBlkH: \(.nextblockhash // empty)",
			"Chainwrk: \(.chainwork)",
			"Difficul: \(.difficulty)",
			"Version_: \(.version)",
			"Vers_Hex: \(.versionHex)",
			"Bits____: \(.bits)",
			"Nonce___: \(.nonce)",
			"Txs_____: \(.nTx)",
			"Confirma: \(.confirmations)",
			"Size____: \(.size) B\t \(.size/1000) KB",
			"Stripped: \(.strippedsize) B\t \(.strippedsize/1000) KB",
			"Weight__: \(.weight) WU\t \(.weight/4000) vKB",
			"Height__: \(.height)",
			"MedianTi: \(.mediantime)\t \(.mediantime | '$HH' )",
			"Time____: \(.time)\t \(.time | '$HH')"'
		ret+=( $? )
	fi

	#sum exit codes
	return $(( ${ret[@]/%/+} 0 ))
}

#find a block at timestamp
heightatf()
{
	local HEIGHTDELTA HEIGHTLAST HEIGHTMAX HEIGHTMIN HEIGHTMINLAST HEIGHTSTART HEIGHTTIMELAST TARGETTIME INPUT

	INPUT="$*"

	#check if there is any user input
	if [[ -z "$INPUT" ]]
	then
		echo "$SN: err -- DATE string required" >&2
		return 1
	#user input $INPUT
	#find block at TARGET time
	elif
		! TARGETTIME="$( date -d"$INPUT" +%s 2>/dev/null || checkdatef "$INPUT" 2>/dev/null )"
	then
 		#print error message
		date -d"$INPUT" +%s
		echo "$SN: err: invalid date format -- $INPUT" >&2
		return 1
	fi

	#current blockchain height
	#user input or get the latest block height
	HEIGHTMAX="$( bwrapper getblockchaininfo )" || return
	HEIGHTMAX="$( jq -r .blocks <<< "$HEIGHTMAX" )"
	HEIGHTSTART=1

	HEIGHTLAST="$HEIGHTMAX"
	HEIGHTMIN="$HEIGHTSTART"
	
	#check times
	#genesis: 1231006505
	#block 1: 1231469665
	if (( TARGETTIME > $( date +%s ) )) || (( TARGETTIME < 1231469665 ))
	then echo "$SN: DATE seems out of range -- $TARGETTIME" >&2 ;return 1
	fi
	
	#loop
	while true
	do
		HEIGHTMINLAST="$HEIGHTLAST"
		HEIGHTTIMELAST="$HEIGHTTIME"
	
		(( HEIGHTDELTA = ( HEIGHTLAST - HEIGHTMIN ) / 2 ))
		(( HEIGHTMIN = HEIGHTLAST - HEIGHTDELTA ))
		
		BLK_INFO_LAST=( "${BLK_INFO[@]}" )
		BLK_INFO=( $( bwrapper getblockheader "$( bwrapper getblockhash "$HEIGHTMIN" )" | jq -r .time,.hash ) )
		HEIGHTTIME="${BLK_INFO[0]}"
		HEIGHTDELTA="${HEIGHTDELTA#-}"
	
		#verbose
		if (( OPTVERBOSE ))
		then
			TIME="$HEIGHTTIME"
			(( OPTHUMAN )) && TIME="$( date -Iseconds -d@"$HEIGHTTIME" )"
			printf '%s: %*d  %s: %s\n' height 6 $HEIGHTMIN date $TIME >&2
		fi
	
		if (( HEIGHTTIME == TARGETTIME ))
		then
			HEIGHTTIMELAST="$HEIGHTTIME"
			HEIGHTMINLAST="$HEIGHTMIN"
			break
		elif (( HEIGHTDELTA == 1 ))
		then
			if (( HEIGHTTIMELAST < TARGETTIME )) && (( HEIGHTTIME > TARGETTIME ))
			then
				break
			elif (( HEIGHTMAX == HEIGHTMIN ))
			then 
				HEIGHTTIMELAST="$HEIGHTTIME"
				HEIGHTMINLAST="$HEIGHTMIN"
				break
			else
				HEIGHTDELTA=2
			fi
		fi
	
		if (( HEIGHTTIME > TARGETTIME ))
		then
			HEIGHTLAST="$HEIGHTMIN"
			(( HEIGHTMIN = HEIGHTMIN - HEIGHTDELTA ))
		elif (( HEIGHTTIME < TARGETTIME ))
		then
			HEIGHTLAST="$HEIGHTMIN"
			(( HEIGHTMIN = HEIGHTMIN + HEIGHTDELTA ))
		fi
	done
	
	#print result
	
	#verbose?
	if (( OPTVERBOSE ))
	then
		cat <<-!

		Target_Time: $TARGETTIME  $( date -Iseconds -d@"$TARGETTIME" )
		Match__Time: $HEIGHTTIMELAST  $( date -Iseconds -d@"$HEIGHTTIMELAST" )
		Block__Hash: ${BLK_INFO_LAST[1]}
		BlockHeight: $HEIGHTMINLAST
		!
	else
		echo "$HEIGHTMINLAST"
	fi
}

#print block hash and height
gethashheightf()
{
	local arg blk_height blk_hash bestblk ret
	typeset -a bestblk ret

	#expand braces, ex '{1..10}'
	for arg in $@
	do
		#is negative index?
		if [[ "$arg" = -+([0-9]) ]]
		then
			#get best block hash and height, set [bestblock - index]
			(( ${#bestblk[@]} )) || bestblk=( $( bestblkfun ) )
			arg=$((bestblk[1] - ${arg#-}))
		fi

		#is block hash or height?
		if ishashf $arg
		then
			blk_hash=$arg
			if ((OPTDOT))
			then
				blk_height=$(bwrapper getblock $arg | jq -r '.height') || {
					echo "invalid block hash/height -- $arg" >&2
					ret+=(1) ;continue
				}
			fi
		else
			if ((OPTCOMMA))
			then
				blk_hash="$( bwrapper getblockhash $arg )" || {
					echo "invalid block hash/height -- $arg" >&2
					ret+=(1) ;continue
				}
			fi
			blk_height=$arg
		fi

		#how to print?
		((OPTDOT)) && printf '%s' $blk_height
		((OPTCOMMA)) && printf "${OPTDOT+\t}%s" $blk_hash
		printf \\n
	done
	
	#get best block hash and height
	(($#)) || { 
		bestblk=( $( bestblkfun ) )
		#how to print?
		((OPTDOT)) && printf '%s' ${bestblk[1]}
		((OPTCOMMA)) && printf "${OPTDOT+\t}%s" ${bestblk[0]}
		printf \\n
	}


	#sum exit codes
	return $(( ${ret[@]/%/+} 0 ))
}

#get best block hash and height
bestblkfun()
{
	bwrapper getblockchaininfo | jq -er .bestblockhash,.blocks
}

#block information, transaction hashes or decode coinbase hex
mainf()
{
	local TOTAL JOBS N
	local arg bestblk blocks ret
	typeset -a blocks bestblk ret JOBS

	#total number of arguments
	TOTAL="$#"

	#is there positional args from user?
	if ((TOTAL))
	then
		#expand braces, ex '{1..10}'
		for arg in $@
		do
			if [[ "$arg" = +(.|,|)@(.|,|) ]]
			then
				#get bets block hash from ., operators
				(( ${#bestblk[@]} )) || bestblk=( $( bestblkfun ) ) || return
				blocks+=( ${bestblk[0]} )
			elif [[ "$arg" = -+([0-9]) ]]
			then
				#negative integers
				#get best block hash and height
				(( ${#bestblk[@]} )) || bestblk=( $( bestblkfun ) ) || return
				blocks+=( $((bestblk[1] - ${arg#-})) )
			else
				#positive integers
				#block hashes
				blocks+=( $arg )
			fi
		done
		set -- "${blocks[@]}"
	else
		#get best block hash
		bestblk=( $( bestblkfun ) ) || return

		echo "Best block height: ${bestblk[1]}" >&2
		set -- "${bestblk[0]}"
	fi

	#multiple jobs?
	if ((JOBSMAX>1))
	then
		#get block info
		for arg in "$@"
		do
			#counter
			((++N))

			#job control
			while JOBS=( $( jobs -p ) ) ;((${#JOBS[@]} > JOBSMAX))
			do sleep 0.1 ;done

			{ mainenginef || errsigf $? ;} &
		done
		wait
	else
		#get block info
		for arg in "$@"
		do ((++N)) ;mainenginef ;ret+=( $? )
		done
	fi

	#sum exit codes
	return $(( ${ret[@]/%/+} 0 ))
}
mainenginef()
{
	local BLK BLK_HASH BLK_HEIGHT ret
	typeset -a ret

	#is block hash or height?
	if ishashf "$arg"
	then
		BLK_HASH="$arg"
		BLK_HEIGHT=
	else
		if ! BLK_HASH="$( bwrapper getblockhash "$arg" )"
		then
			echo "invalid block hash/height -- $arg" >&2
			errsigf ;return 1
		fi
		BLK_HEIGHT="$arg"
	fi

	#get block info
	#is target other block than genesis block?
	if [[ "$BLK_HASH" = "$GENBLK_HASH" ]] || ((OPTI==1000))
	then
		#all block transaction json
		#genesis block with tx info
		BLK="$( bwrapper getblock "$BLK_HASH" 2 )"
	else
		#common block tx info
		BLK="$( bwrapper getblock "$BLK_HASH" true )"
	fi
	ret+=( $? )
	
	#call opt functions
	if (( OPTTIMESTAMP ))
	then
		#-t generate timestamp list
		timestamplistf
	elif (( OPTASCII ))
	then
		#decode coinbase HEX
		deccoinbf
		#https://bitcoin.stackexchange.com/questions/90684/how-to-decode-a-coinbase-transaction
		#you can just print every string in the blockchain database directly
		#{ strings -n 20 blk0000.dat ;}
		#https://bitcoin.stackexchange.com/questions/18/how-can-one-embed-custom-data-in-block-headers
	else
		#default option
		#general block information and block transactions
		defaultf
	fi
	#record exit codes
	ret+=( $? )
	
	#feedback
	#try to clear last feedback line
	((OPTVERBOSE==1)) && printf "${CLR}blk[%s/%s]: %s \r" "$N" "${TOTAL:-$N}" "${BLK_HEIGHT:-$BLK_HASH}" >&2
	((OPTVERBOSE>1)) && printf "${CLR}blk[%s/%s]: %s  %s \r" "$N" "${TOTAL:-$N}" "$BLK_HEIGHT" "$BLK_HASH" >&2
	
	#sum exit codes
	return $(( ${ret[@]/%/+} 0 ))
}

#-m mempool funcs
mempoolf()
{
	local cols width mempool_raw jqselect maxfee ret tx wc i c tt
	typeset -a ret
	
	#-m print transaction hashes only
	if (( OPTMEMPOOL == 1 && $# == 0 ))
	then
		mempool_raw="$( bwrapper getrawmempool false )" || return
		jq -er '.[]' <<< "$mempool_raw"
		ret+=( $? )
	#-mm print transaction ids and some more info
	elif (( OPTMEMPOOL == 2 || $# ))
	then
		#get data
		mempool_raw="$( bwrapper getrawmempool true )" || return

		#debug? print raw data
		if (( DEBUGOPT ))
		then
			echo "$mempool_raw"
			return 0
		fi

		#process only certain tx or print all of them
		for tx in ${@:-empty}
		do
			jqselect="select(.wtxid==\"${tx}\")"
			[[ "$tx" == empty ]] && jqselect='.'
			
			#process transaction data one by one
			<<< "$mempool_raw" jq -er '.[] | '${jqselect}' |
				"",
				"--------",
				"TxId+Wit: \(.wtxid)",
				"DependOn: \(.depends[] // empty)",
				"SpentBy_: \(.spentby[] // empty)",
				"Time____: \(.time)\t \(.time | '$HH' )",
				"UnbroadC: \(if .unbroadcast == true then "unbroadcasted" else empty end)",
				"BIP125Rp: \(.["bip125-replaceable"] | if . == true then "replaceable" else "not-replaceable" end)",
				"Height__: \(.height)",
				"Ance_Cnt: \(.ancestorcount) tx(s)",
				"AnceSize: \(.ancestorsize) B",
				"Desc_Cnt: \(.descendantcount) tx(s)",
				"DescSize: \(.descendantsize) B",
				( .fees |
					"Fees",
					"  Ancest: \(.ancestor) sat",
					"  Descen: \(.descendant) sat",
					"  Base__: \(.base) sat",
					"  Modifd: \(if .modified == .base then empty else .modified end) sat"
				),
				"VirtSize: \(.vsize) vB",
				"Weight__: \(.weight) WU"'
			ret+=( $? )
		done

	#-mmm Print the number of transactions, their fees and some stats
	else
		#feedback?
		(( OPTVERBOSE )) && printf '%s \r' "Fetching mempool transactions.." >&2
		mempool_raw="$( bwrapper getrawmempool true | jq -r '[.[]|(.fee*100000000)/.vsize] | sort | .[]' )" || return

		(( OPTVERBOSE )) && printf "${CLR}\r%s\n" "Processing mempool transactions.." >&2
		wc=$(wc -l <<<"$mempool_raw")

		#columns
		width=${COLUMNS:-$(tput cols)}
		cols=$((width/22))
		((width>24)) || width=72 cols=1

		#print mempool tx fees
		#echo "Mempool Transaction Fees (sat/vB)"
		#((OPTV)) && echo "(columns are printed across rather than down)"
		#<<<"$mempool_raw" pr -aT$cols -w$width
		#echo

		#tx number by fee
		echo "Fee and Transaction Number (transactions per sat/vB)"
		maxfee=100
		{
		for i in $(seq 1 $maxfee)
		do
			c=$(grep -c "^$i\." <<<"$mempool_raw") tt="$((tt+c))"
			printf "%+*d/vB: %5d\n" "$((${#maxfee}+1))" "$i" "$c"
		done
		printf ">%*d/vB: %5d\n" "${#maxfee}" "$maxfee" "$((wc-tt))"
		} | pr -T$cols -w$width

		echo -e "\nStatistics (sat/vB)"
		<<<"$mempool_raw" jq -s -r '"Minimum: \(min)","Maximum: \(max)","Average: \(add/length)","Median_: \(sort|if length%2==1 then.[length/2|floor]else[.[length/2-1,length/2]]|add/2 end)","TxTotal: \(length)"'
		#jq -s '{minimum:min,maximum:max,average:(add/length),median:(sort|if length%2==1 then.[length/2|floor]else[.[length/2-1,length/2]]|add/2 end)}'
		#perl -M'List::Util qw(sum max min)' -MPOSIX -0777 -a -ne 'printf "%-7s : %.2f\n"x4, "Min", min(@F), "Max", max(@F), "Average", sum(@F)/@F,  "Median", sum( (sort {$a<=>$b} @F)[ int( $#F/2 ), ceil( $#F/2 ) ] )/2;'
		#https://unix.stackexchange.com/questions/13731/is-there-a-way-to-get-the-min-max-median-and-average-of-a-list-of-numbers-in

		#number of txs (lines)
		#echo "Txs: $wc"
	fi

	#sum exit codes
	return $(( ${ret[@]/%/+} 0 ))
}

#-t generate timestamp list
timestamplistf()
{
	local HEADER NN ret
	typeset -a ret

	#print in human-readable format?
	(( OPTHUMAN )) || unset HH
	
	#get json data
	HEADER="$( bwrapper getblockheader "$BLK_HASH" )"
	ret+=( $? )

	#debug? print raw data
	if (( DEBUGOPT ))
	then
		echo "$HEADER"
		echo "$BLK_HASH"
		exit 0
	fi

	#print block hash, too?
	(( OPTN )) && NN="${SEP}${BLK_HASH}"

	if ((OPTTIMESTAMP>1))
	then jq -er "\"\( .time | ${HH:-.})${NN}\"" <<<"$HEADER"
	else jq -er "\"\( .mediantime | ${HH:-.})${NN}\"" <<<"$HEADER"
	fi
	ret+=( $? )
	
	#print simple feedback to stderr?
	(( OPTVERBOSE )) &&
		printf '>>>blk: %4d/%4d \r' "$N" "$TOTAL" >&2

	#sum exit codes
	return $(( ${ret[@]/%/+} 0 ))
}


#start

#parse script options
while getopts .,bc:dehiIj:lMmntuvVyY opt
do
	case $opt in
		\.)
			#print best block height
			OPTDOT=1
			;;
		\,)
			#print best block hash
			OPTCOMMA=1
			;;
		b)
			#blockchain information
			#mining information
			#mempool information
			#network information
			#rpc information
			OPTCHAIN=1
			;;
		c)
			#bitcoin.conf filepath
			BITCOINCONF="$OPTARG"
			;;
		d)
			#block height by date/time
			((++OPTDATE))
			;;
		e)
			#debug? print raw data
			DEBUGOPT=1
			;;
		h)
			#help page
			echo "$HELP"
			exit 0
			;;
		I)
			#all block transaction json
			OPTI=1000
			;;
		i)
			#block information option
			(( ++OPTI ))
			;;
		j)
			#maximum number of jobs
			JOBSMAX="$OPTARG"
			;;
		l)
			#local time for humans
			unset TZ
			;;
		M)
			#full information of mempool yxs
			#same as -mm
			OPTMEMPOOL=3
			;;
		m)
			#mempool
			(( ++OPTMEMPOOL ))
			;;
		n)
			#print block height number, too
			OPTN=1
			;;
		t)
			#timestamp lists
			((++OPTTIMESTAMP))
			;;
		u)
			#convert unix->human time
			OPTHUMAN=1
			;;
		v)
			#feedback
			(( ++OPTVERBOSE ))
			;;
		V)
			#print script version
			while IFS=  read -r
			do [[ "$REPLY" = \#\ v[0-9]* ]] && break
			done < "$0"
			echo "$REPLY"
			exit 0
			;;
		Y)
			#same as -yy, shortcut
			#block information option
			unset OPTI
			OPTASCII=2
			;;
		y)
			#block information option
			unset OPTI
			((++OPTASCII))
			;;
		\?)
			#illegal option
			exit 1
			;;
	esac
done
shift $(( OPTIND - 1 ))
unset opt


#required packages
for PKG in bitcoin-cli jq tee
do
	if ! command -v "$PKG" &>/dev/null
	then printf '%s: err  -- %s is required\n' "$SN" "$PKG" >&2 ;exit 1
	fi
done
unset PKG

#set alternative bitcoin.conf path?
if [[ -e "$BITCOINCONF" ]]
then
	#warp bitcoin-cli
	bwrapper() { bitcoin-cli -conf="$BITCOINCONF" "$@" ;}
	((OPTVERBOSE>1)) && echo "$SN: -conf=\"${BITCOINCONF}\"" >&2
else
	#warp bitcoin-cli
	bwrapper() { bitcoin-cli "$@" ;}
fi

#local time?
#human-readable time formats
#set jq arguments for time format printing
if [[ "${TZ^^}" = +(UTC0|UTC-0|UTC|GMT) ]]
then HH='strftime("%Y-%m-%dT%H:%M:%SZ")'
else HH='strflocaltime("%Y-%m-%dT%H:%M:%S%Z")'
fi

#consolidate $JOBSMAX
JOBSMAX="${JOBSMAX:-$JOBSDEF}"
[[ "$JOBSMAX" = [Mm][Aa][Xx] ]] && JOBSMAX=$(nproc)
#check minimum jobs
if ((JOBSMAX < 1))
then echo "$SN: err  -- at least one job required" >&2 ;exit 1
else ((OPTVERBOSE>1)) && echo "$SN: jobs -- $JOBSMAX" >&2
fi
	
#error signal temp file
TMPERR="/tmp/$$.errsignal.txt"

#traps
trap cleanf EXIT

#call option func
#-,. print block hash and height
if ((OPTDOT+OPTCOMMA))
then
	gethashheightf "$@"
#-b blockchain information
elif (( OPTCHAIN ))
then
	blockchainf
#-mm mempool
elif (( OPTMEMPOOL ))
then
	mempoolf "$@"
#-d  block height by date string
elif (( OPTDATE ))
then
	heightatf "$@"
#default function
else
	mainf "$@"
fi
RET+=( $? )

