#!/bin/bash
# v0.8.38  jul/2021  by mountaineerbr
# parse transactions by hash or transaction json data
# requires bitcoin-cli and jq 1.6+

#script name
SN="${0##*/}"

#set simple verbose
#feedback to stderr
OPTVERBOSE=0

#cache dir for results copy
#eg. ~/.cache/bitcoin.tx
CACHEDIR="$HOME/.cache/bitcoin.tx"

#check user cache disk usage
#(prints warning when exceeded)
MAXCACHESIZE=150000000  #150MB

#maximum jobs (subprocesses)
JOBSDEF=3   #hard defaults
#this depends mainly on the number of threads to service rpc calls of
#bitcoin daemo (rpcthreads=<n> ,defaults: 4)
#is the number of independent api requests that can be processed in parallel.
#in reality however there are many locks inside the product that means you 
#won't see much performance benefit with a value above 2.

#semaphore sleep time
SEMAPHORESLEEP=0.1

#set calculation scale (mainf fun)
SCL=8

#white paper
#out file
WPOUTFILE=bitcoinWP.pdf
#whitepaper transaction hash and block hash
WPTXID=54e48e5f5c656b26c3bca14a8c95aa583d07ebe84dde3b7dd4a78f4e4186e713
WPBLKHX=00000000000000ecbbff6bafb7efa2f7df05b227d5c73dca8f2635af32a2e949

#timezone
#defaults=UTC0
TZ="${TZ:-UTC0}"
export TZ

#temporary directory path
#$TMPDIR has higher precedence
#try to keep temp files in shared memory (ramdisc)
TMPDIR1=/dev/shm

#make sure locale is set correctly
#LC_NUMERIC=C
LANG=C  LC_ALL=C

#printf clear line
CLR='\033[2K'

#genesis block hash (same as coinbase tx hash)
#requesting this may throw errors in some funcs
#GENBLK_HASH=000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f
#get tx with `bitcoin-cli getblock $GENBLK_HASH 2`

#help
HELP="NAME
	$SN - Parse transactions by hash or transaction json data


SYNOPSIS
	$SN  [-afklouvyy] [-j[NUM]] [-bBLOCK_HASH|HEIGHT] TRANSACTION_HASH..
	$SN  [-afklouvyy] [-j[NUM]] \"TRANSACTION_HASH [BLOCK_HASH|HEIGHT]\"..
	$SN  [-s|-S[VOUT]] [-j[NUM]] \"TRANSACTION_HASH [BLOCK_HASH|HEIGHT]\"..
	$SN  -hVww


DESCRIPTION
	Given a TRANSACTION_HASH, the script will make an RPC call to
	bitcoin-cli and parse the returning JSON data. Parsed transact-
	ions are concatenated as per input order to a single file at
	${CACHEDIR/$HOME/\~} and printed to stdout.

	Transaction ids/hashes may be sent through stdin or set as posi-
	tional parameters to the script.

	An argument or line from stdin may have two words separated by
	a blank space: the first one is the TRANSACTION_HASH and the
	second word must be BLOCK_HASH or HEIGHT of that transaction.
	Setting a BLOCK_HASH or HEIGHT is required if bitcoin-daemon is
	not set with txindex=1 option.

	Option -f prints only general transaction information and does
	not retrieve vins and vouts but is very fast. Pass multiple times
	to dump more data. If used with multiple jobs, transaction output
	order may differ from input; note that this option does not save
	a copy of output.


	General Options
	Option -c CONFIGFILE sets the configuration file path (bitcoin.conf)
	if that is in a custom location other than defaults, see also
	section ENVIRONMENT.
	
	Option -l sets local time instead of UTC time.

	Option -u prints time in human-readable format RFC 5322 instead
	of the defaults ISO 8601.

	Option -v enables verbose, set -vv to print more feedback for
	some functions.


	Job Control
	Set option -o to print to stdout while processing; beware trans-
	actions may not be printed in the input order; this option dis-
	ables writing results to cache at ${CACHEDIR/$HOME/\~} .
	
	Set option -jNUM in which NUM is an integer and sets the maximum
	number of simultaneous background jobs, in which case NUM must be
	an integer or \`auto'. Environment variable \$JOBSMAX is read,
	defaults=${JOBSDEF} .

	Beware that, with the exception of the defaults functions, all
	other functions may print asynchronously and mix output. To avoid
	that, set -j1 .


	Other Functions
	Option -y will convert plain hex dump from a transaction to ASCII
	text. The output will be filtered to print sequences that are at
	least 20 characters long, unless that returns empty, in which case
	there is decrement of one character until a match is found. If
	nought is reached, the raw byte output will be printed. Setting
	-yy prints all raw byte sequences, see example (4).

	Option -s checks if TXID VOUTS are all unspent, otherwise exits
	with one error per TXID. To check only one VOUT number of TXIDS,
	set -S VOUT instead, in which VOUT is a positive integer. Printed
	fields: Txid, Vout_n, Check, [Value], [Coinbase] and [Addresses].


	Extra Functions
	Option -w will regenerate bitcoin white paper. Two methods are
	available, either from the transaction itself (fast, -w) or from
	the UTXO set (slow, -ww). An output PDF file will be created at
	\$PWD, defaults=$WPOUTFILE. See section SEE ALSO for more
	information.

	If -b is set with a BLOCK_HASH or BLOCK_HEIGHT, no positional
	argument is set and stdin is free, parse all transactions from
	that block, see also option -f; e.g. \`$SN -ff -b100000\`.


ENVIRONMENT VARIABLES
	BITCOINCONF
		Path to bitcoin.conf or equivalent file with configs
		such as RPC user and password, is overwritten by script
		option -c, defaults=\"\$HOME/.bitcoin/bitcoin.conf\".
	TMPDIR  Sets user custom temporary directory, if unset defaults
		to $TMPDIR1 or /tmp .

	TZ 	Sets timezone, defaults to UTC0 (GMT).


SEE ALSO
	bitcoin.blk.sh -- Bitcoin block information and functions;
	from the same suite of this present script
	<https://github.com/mountaineerbr/scripts>


	bitcoin.sh -- Grondilu's Bitcoin bash functions
	<https://github.com/grondilu/bitcoin-bash-tools>


	blockchain-parser -- Ragestack's blockchain binary data parser
	<https://github.com/ragestack/blockchain-parser>

	Bitcoin whitepaper in the blockchain
	<https://bitcoinhackers.org/@jb55/105595146491662406>
	<https://bitcoin.stackexchange.com/questions/35959/how-is-the-whitepaper-decoded-from-the-blockchain-tx-with-1000x-m-of-n-multisi/35970#35970>


	Q. What's the difference between \`txid' and \`hash'?
	A. when tx is segwit, calculation of \`hash' does not include
	witness data, whereas the \`txid' does.
	<https://bitcoin.stackexchange.com/questions/77699/whats-the-difference-between-txid-and-hash-getrawtransaction-bitcoind>


WARRANTY
	Licensed under the gnu general public license 3 or better and
	is distributed without support or bug corrections.
	
	Grondilu's bitcoin-bash-tools functions are embedded in this
	script, see <https://github.com/grondilu/bitcoin-bash-tools>.
	
	Packages bitcoin-cli v0.21+, jq 1.6+, openssl, xxd, sha256sum
	and bash v4+ are required.

	If you found this programme interesting or useful, please
	consider sending me a nickle!  =)
  
		bc1qlxm5dfjl58whg6tvtszg5pfna9mn2cr2nulnjr


USAGE EXAMPLES
	1) Get transaction information; commands below should be equiv-
	alent; setting block hash is only necessary if bitcoin daemon is
	not set with txindex :

	$ $SN -b0000000000000000000fb6a4d6f5dc7438f91a1bc3988c4f32b4bb8284eed0ec \\
		a8bb9571a0667d63eaaaa36f9de87675f0d430e13c916248ded1d13093a77561

	$ $SN -b 638200 a8bb9571a0667d63eaaaa36f9de87675f0d430e13c916248ded1d13093a77561

	$ $SN 'a8bb9571a0667d63eaaaa36f9de87675f0d430e13c916248ded1d13093a77561 0000000000000000000fb6a4d6f5dc7438f91a1bc3988c4f32b4bb8284eed0ec'

	$ echo 'a8bb9571a0667d63eaaaa36f9de87675f0d430e13c916248ded1d13093a77561 638200' | $SN


	2) Process transaction JSON from bitcoin daemon:

	$ TRANSACTION_HASH=a8bb9571a0667d63eaaaa36f9de87675f0d430e13c916248ded1d13093a77561

	$ BLOCK_HEIGHT=638200

	$ BLOCK_HASH=\$( bitcoin-cli getblockhash \$BLOCK_HEIGHT )

	$ bitcoin-cli getrawtransaction \"\$TRANSACTION_HASH\" true \"\$BLOCK_HASH\" | $SN


	3) Examples (1) and (2) are equivalent to:

	$ $SN -b\"\$BLOCK_HASH\" \"\$TRANSACTION_HASH\"


	4) Decode hex code to ASCII text using \`strings\`:
	
	$ $SN -y 930a2114cdaa86e1fac46d15c74e81c09eee1d4150ff9d48e76cb0697d8e1d72

	$ $SN -yy 930a2114cdaa86e1fac46d15c74e81c09eee1d4150ff9d48e76cb0697d8e1d72 | strings -n 20

	$ strings -n 20 blk00003.dat  #decode the whole block file


	5) Get the genesis block coinbase transaction and parse it:

	$ bitcoin-cli getblock \$(bitcoin-cli getblockhash 0) 2 | $SN

	$ bitcoin.blk.sh -ii 0 | $SN


	6) Parse all transactions from best block; note that bitcoin.blk.sh
	   is a companion suite script from the same author:

	$ bitcoin.blk.sh -g | $SN -ff    #fast, less tx info
	
	$ bitcoin.blk.sh -ii | $SN       #slow, detailed tx info 


OPTIONS
	Extra Functions
	-w 	Regenerate bitcoin whitepaper, may set twice; outfile=$WPOUTFILE.

	Miscellaneous
	-h 	Print this help page.
	-V 	Print script version.
	-v 	Verbose, may set multiple times.

	General
	-a 	Do not try to compress addresses (print assembly).
	-b BLOCK_HASH
	   	Set block hash containing transactions.
	-c 	CONFIGFILE
		Path to bitcoin.conf or equivalent configuration file,
		defaults=\"\$HOME/.bitcoin/bitcoin.conf\".

	Job control
	-j NUM	Maximum number of simultaneous jobs, defaults=${JOBSDEF} .

	Output and format control
	-l 	Sets local time instead of UTC time.
	-o 	Send to stdout while processing, inhibits creation of
		results file at ${CACHEDIR/$HOME/\~} .
	-u 	Print time in RFC5322 instead of ISO8601.

	Functions
	-f 	General transaction information only (fast), set multiple
		times to dump more data.
	-s 	Check if TXID VOUTS are all unspent.
	-S VOUT
		Same as -s, but check only a specific VOUT number.
	-y 	Decode transaction hex to ASCII (auto select string length).
	-yy, -Y	Same as -y but prints all bytes."


#!#bitcoin.sh snapshot with custom modifications
#!#commit: 95860e1567e2def6f95fb77212ea53015016ab6a
#!#date: 24/jan/2021
#
# Various bash bitcoin tools
#
# requires dc, the unix desktop calculator (which should be included in the
# 'bc' package)
#
# This script requires bash version 4 or above.
#
# This script uses GNU tools.  It is therefore not guaranted to work on a POSIX
# system.
#
# Copyright (C) 2013 Lucien Grondin (grondilu@yahoo.fr)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

pack() {
    echo -n "$1" |
    xxd -r -p
}

unpack() {
    xxd -p | tr -d '\n'
}

declare -a base58=(
      1 2 3 4 5 6 7 8 9
    A B C D E F G H   J K L M N   P Q R S T U V W X Y Z
    a b c d e f g h i j k   m n o p q r s t u v w x y z
)
unset dcr; for i in {0..57}; do dcr+="${i}s${base58[i]}"; done

decodeBase58() {
  echo -n "$1" | sed -e's/^\(1*\).*/\1/' -e's/1/00/g' | tr -d '\n'
  echo "$1" |
  {
    echo "$dcr 0"
    sed 's/./ 58*l&+/g'
    echo "[256 ~r d0<x]dsxx +f"
  } | dc |
  while read n
  do printf "%02X" "$n"
  done
}

encodeBase58() {
    local n
    echo -n "$1" | sed -e's/^\(\(00\)*\).*/\1/' -e's/00/1/g' | tr -d '\n'
    dc -e "16i ${1^^} [3A ~r d0<x]dsxx +f" |
    while read -r n; do echo -n "${base58[n]}"; done
}

checksum() {
    pack "$1" |
    openssl dgst -sha256 -binary |
    openssl dgst -sha256 -binary |
    unpack |
    head -c 8
}

hash160() {
    openssl dgst -sha256 -binary |
    openssl dgst -rmd160 -binary |
    unpack
}

hexToAddress() {
    local x="$(printf "%2s%${3:-40}s" ${2:-00} $1 | sed 's/ /0/g')"
    encodeBase58 "$x$(checksum "$x")"
    echo
}


#original script funcs

#get a bitcoin whitepaper pdf copy
whitepaperf()
{
	#From the UTXO set (slow)
	#bare multisig outputs that will never be spent
	if ((OPTW>1))
	then
		for ((n=0;n<948;++n))
		do
			((OPTVERBOSE)) && printf 'utxo: %3d/%3d \r' $((n+1)) 948 >&2
			bwrapper gettxout $WPTXID $n |
				jq -r '.scriptPubKey.asm' |
				awk '{ print $2 $3 $4 }'
		done \
		| tr -d '\n' \
		| cut -c 17-368600 \
		| xxd -r -p >"$WPOUTFILE"

	#From blockchain transaction (defaults, fast)
	else
		bwrapper getrawtransaction $WPTXID 0 $WPBLKHX \
		| sed 's/0100000000000000/\n/g' \
		| tail -n +2 \
		| cut -c7-136,139-268,271-400 \
		| tr -d '\n' \
		| cut -c17-368600 \
		| xxd -p -r >"$WPOUTFILE"
	fi

	((OPTVERBOSE)) && echo >&2
	echo "$SN: file generated -- $WPOUTFILE" >&2
}
#https://bitcoin.stackexchange.com/questions/35959/how-is-the-whitepaper-decoded-from-the-blockchain-tx-with-1000x-m-of-n-multisi/35970#35970
#https://bitcoinhackers.org/@jb55/105595146491662406

#err signal
errsigf()
{
	local sig="${1:-1}"
	echo "$sig" >>"$TMPERR"
}

#is transaction hash?
#ishashf() { [[ "$1" =~ ^[a-fA-F0-9]{64}$ ]] ;}

#tx hex to ascii
hexasciif()
{
	local ascii hex num  #BLOCK_HASH_LOOP 

	if 
		#read file $TMP3 or get json from bitcoin-cli
		if [[ -e "$TMP3" ]]
		then hex="$(jq -r '.hex // empty' "$TMP3")"
		else hex="$(bwrapper getrawtransaction "$TXID" true ${BLOCK_HASH_LOOP:-${BLK_HASH}} | jq -r '.hex // empty')"
		fi
		[[ -n "$hex" ]]
	then
		#verbose?
		#clear last feedback line in stderr
		((OPTVERBOSE)) && printf "$CLR" >&2
		if ((OPTVERBOSE > 1))
		then
			#<<<"$txdata" jq -r '.vin[0] | if .coinbase then "(coinbase transaction)\\n" else empty end'
			echo -ne "--------\nTXID: ${TXID:-${COUNTER:-(json)}}\nHEX_: $hex\nASCI: "
		fi

		#print ascii text
		if ((OPTASCII>1))
		then
			<<<"$hex" xxd -r -p 
		else
			#if strings result is not empty
			#decode hex to ascii (ignore null byte warning)
			{ ascii="$(<<<"$hex" xxd -r -p)"  ;} 2>/dev/null
			for ((num=20 ;num>=0 ;--num))
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
				<<<"$hex" xxd -r -p 
			fi
		fi

		#print simple feedback
		((OPTVERBOSE)) &&
			printf "tx: %*d/%*d  \r" "$K" "$((COUNTER+1))" "$K" "$L" >&2
	else
		return 1
	fi

	return 0
}
#nelson mandela transaction
#hash:8881a937a437ff6ce83be3a89d77ea88ee12315f37f7ef0dd3742c30eef92dba 
#hex:334E656C736F6E2D4D616E64656C612E6A70673F
#Len Sassaman Tribute
#txid:930a2114cdaa86e1fac46d15c74e81c09eee1d4150ff9d48e76cb0697d8e1d72
#Satoshi Nakamoto email
#txid:77822fd6663c665104119cb7635352756dfc50da76a92d417ec1a12c518fad69
#very good (there is a how to)
#http://www.righto.com/2014/02/ascii-bernanke-wikileaks-photographs.html

#json parsing func
mainf()
{
	local catvin catvout header index tmp10 tmp10sum tmp11 tmp11sum TMP
	typeset -a vinsum voutsum catvin catvout
	TMP="$1"

	#one transaction json at a time!

	#vins
	echo -e "\n--------\nInput and output vectors\nVins"

	#temp file for sum of vins
	index=0  tmp10sum="$TMP.vin.sum"
	#loop through indexes
	while
		header="$( jq -re --arg index "$index" '.vin[($index|tonumber)] // empty |
			"  TxIndex: \(.txid // empty)",
			"  Sequenc: \(.sequence)",
			"  VoutNum: \(.vout // empty)"' "$TMP" 2>/dev/null )"
	do
		#temp file for vin
		tmp10="$TMP.$index.vin"  catvin+=( "$tmp10" )

		#manage jobs
		jobsemaphoref

		#async loop
		{
			#get addrs
			#also sets $tmp10sum
			echo -e "$header\n  Addresses"
			if ! vinf "$TMP"
			then
				echo '    skipping address..'
				#set err signal
				errsigf 1
			fi 2>/dev/null
			echo
		
			#print simple feedback
			(( OPTVERBOSE )) &&
				printf "${CLR}tx: %*d/%*d  in : %3d  \r" "$K" "$((COUNTER+1))"  "$K" "$L" "$((index+1))" >&2
		} >"$tmp10" &
		
		(( ++index ))
	done
	wait
	cat -- "${catvin[@]}"
	
	#vouts
	echo -e "\nVouts"
	
	#temp file for sum of vouts
	index=0  tmp11sum="$TMP.vout.sum"
	#loop through indexes
	while
		header="$( jq -re --arg index "$index" '.vout[($index|tonumber)] // empty |
			"  Number_: \(.n )\tValue__: \(.value )"' "$TMP" 2>/dev/null )"
	do
		#temp file for vout
		tmp11="$TMP.$index.vout"  catvout+=( "$tmp11" )

		#manage jobs
		jobsemaphoref
	
		#async loop
		{
			#avoid shell errors being printed
			{

			echo -e "$header\n  Addresses"
			#get addrs
			if ! voutf "$TMP"
			then
				echo '    skip..'
				errsigf 1
			fi
			echo
		
			#save for sum later
			jq -r --arg index "$index" '.vout[($index|tonumber)] // "0" | .value' "$TMP" >>"$tmp11sum"
			
			} 2>/dev/null
			
			#print simple feedback
			(( OPTVERBOSE )) &&
				printf "${CLR}tx: %*d/%*d  out: %3d  \r" "$K" "$((COUNTER+1))"  "$K" "$L" "$((index+1))" >&2
		} >"$tmp11" &
		
		(( ++index ))
	done
	wait
	cat -- "${catvout[@]}"

	#avoid shell errors being printed
	{

	#general info
	jq -r "\"\",$JQTXINFO" "$TMP"
	
	#sum vouts
	#load values from file
	#change "e" to "*10^", may use GLOBIGNORE=\* and sed
	voutsum=( $(<"$tmp11sum") )  voutsum=( "${voutsum[@]//e/*10^}" )
	#calc sums
	out="$( bc <<<"scale=$SCL ;( ${voutsum[@]/%/+} 0 ) /1" )"

	#sum vins
	#load values from file
	vinsum=( $(<"$tmp10sum") )
	if [[ "${vinsum[*]}" = *coinbase* ]]
	then
		in=coinbase  fee=0
	else
		#change e to *10^
		vinsum=( "${vinsum[@]//e/*10^}" )
		#calc sums
		in="$( bc <<<"scale=$SCL ;( ${vinsum[@]/%/+} 0 ) /1" )"  fee="$( bc <<<"scale=$SCL ;( $in-$out ) /1" )"
	fi

	#format results
	#count longest number characters
	for c in "$in" "$out" "$fee"
	do ((${#c}>cc)) && cc="${#c}"
	done
	
	#is coinbase?
	[[ "$in" != *coinbase* ]] && in="$(printf '%+*.*f\n' "$cc" "$SCL" "$in")"
	out="$( printf '%+*.*f\n' "$cc" "$SCL" "$out" )"  fee="$( printf '%+*.*f\n' "$cc" "$SCL" "$fee" )"
	#calc transaction fee per vByte and total fee
	feerates=( 
		$(jq -r "((${fee//[.+-]/} / .size  )|if . < 1000 and . > 0.01 then tostring|.[0:5] else . end),
			 ((${fee//[.+-]/} / .vsize )|if . < 1000 and . > 0.01 then tostring|.[0:5] else . end),
			 ((${fee//[.+-]/} / .weight)|if . < 1000 and . > 0.01 then tostring|.[0:5] else . end)" "$TMP")
	)
	##feerates=( "${feerates[@]%.*}" )
	#tere are many units for calculating transaction fee
	#per byte, per virtual bye and per weight unit
	#one virtual byte = 4 weight units
	#the defaults should be `sats/vB'
	#https://bitcointalk.org/index.php?topic=5250569.0
	#https://bitcointalk.org/index.php?topic=5251213.0
	#https://btc.network/estimate

	echo "Vin__Sum: ${in:-?}
Vout_Sum: ${out:-?}
Tx___Fee: ${fee:-?}
FeeRates: ${feerates[0]:-?} sat/B  ${feerates[1]:-?} sat/vB  ${feerates[2]:-?} sat/WU"

	#remove buffer files
	rm -- "$tmp10sum" "$tmp11sum" "${catvout[@]}" "${catvin[@]}"

	}  2>/dev/null

	unset vinsum voutsum in out fee feerates c cc
}
#faster method (process less info)
mainfastf()
{
	#print simple feedback
	(( OPTVERBOSE )) &&
		printf "${CLR}tx: %*d/%*d  \r" "$K" "$((COUNTER+1))"  "$K" "$L" >&2

	#vins and vouts and general info
	if ((OPTFAST>1))
	then
		#dumps more data
		jq -r --arg optf "$OPTFAST" '"",
			"--------",
			"Input and output vectors",
			"",
			"Vins",
			(
				.vin[] // empty |
				(
					"  TxIndex_: \(.txid // "coinbase")",
					"  Sequence: \(.sequence)\tVoutNum: \(.vout // "")",
					(
						.scriptSig |
							"  ScSigTyp: \(.type // empty)",
							"  ScSigAsm: \( if ($optf | tonumber) > 2 then (.asm // empty) else empty end)",
							""
					),
					""
				)
			),
			"Vouts",
			(
				.vout[] |
					"  Number__: \(.n )\tValue__: \(.value )",
					(
					.scriptPubKey |
						"  PKeyType: \(.type // empty)\(if .reqSigs then "\tReqSigs: \(.reqSigs)" else "" end)",
						"  PKeyAddr: \(.addresses? | .[]? // empty)",
						"  PKeyAsm_: \( if ($optf | tonumber) > 2 then (.asm // empty) else empty end )",
						""
					)
			),
			'"$JQTXINFO" "$@"

	else
		#dumps only basic info
		jq -r '"",
			"--------",
			'"$JQTXINFO" "$@"

	fi

}

#parse engine
parsef()
{
	#set to concatenate results
	CONCAT=1
	#processed transaction temp file
	TMP4="${TMPD}/${COUNTER}.tx"
	#raw transaction (json) temp file
	TMP3="$TMP4.json"
	#!#must be the same as in other functions

	#manage jobs
	jobsemaphoref
	
	#make sure file exists for later concatenation
	#(even if empty)
	: >"$TMP4"
	#make an array with processed transaction files
	TXFILES+=( "$TMP4" )
	
	#processing pipeline (to bg)
	{
		#is tx json already? Else, get tx json
		if ((JSON)) || {
			#consolidate $BLK_HASH (if set)
			BLK_HASH="${BLK_HASH_LOOP:-${BLK_HASH}}"
			
			#do some basic checking
			#is $BLK_HASH set?
			if [[ -n "${BLK_HASH// }" ]]
			then
				#is "block hash" set as "block height"?
				if [[ "$BLK_HASH" =~ ^[0-9]{,7}$ ]]
				then
					BLK_HASH="$( bwrapper getblockhash "$BLK_HASH" )" || { errsigf $?; exit 1;}
				#is it really NOT "block hash"?
				elif [[ ! "$BLK_HASH" =~ ^[0]{8}[a-fA-F0-9]{56}$ ]]
				then
					#print error msg
					echo ">>>error: block hash -- $BLK_HASH" >&2
					errsigf 1
					exit 1
				fi
			fi
			#check that $TXID is a transaction hash
			if [[ ! "$TXID" =~ ^[a-fA-F0-9]{64}$ ]]  #is $TXID a tx hash?
			then
				#print error msg
				echo ">>>error: transaction id -- $TXID" >&2
				errsigf 1
				exit 1
			fi

			#get raw transaction json
			bwrapper getrawtransaction "$TXID" true $BLK_HASH >"$TMP3"
		}
		then
	
			mainf "$TMP3" > "$TMP4"

			#write to stdout while processing?
			if (( OPTOUT ))
			then
				#clear last feedback line
				(( OPTVERBOSE )) && printf "$CLR" >&2
				cat -- "$TMP4"
			fi
		else
			#print error
			echo ">>>error: transaction id -- $TXID" >&2
			errsigf
		fi
		
		#clean up on the fly
		rm -- "$TMP3"  2>/dev/null
	} &
}
#note: use bitcoin.tx.sh with option '-bBLOCK_HASH' 
#if bitcoind option txindex is not set
#jq slurp tip:https://stackoverflow.com/questions/41216894/jq-create-empty-array-and-add-objects-to-it
parsefastf()
{
	#manage jobs
	jobsemaphoref
	
	#processing pipeline (to bg)
	{
		#consolidate $BLK_HASH (if set)
		BLK_HASH="${BLK_HASH_LOOP:-${BLK_HASH}}"
		
		#do some basic checking
		#is $BLK_HASH set?
		if [[ -n "${BLK_HASH// }" ]]
		then
			#is "block hash" set as "block height"?
			if [[ "$BLK_HASH" =~ ^[0-9]{,7}$ ]]
			then
				BLK_HASH="$( bwrapper getblockhash "$BLK_HASH" )" || { errsigf $?; exit 1;}
			#is it really NOT "block hash"?
			elif [[ ! "$BLK_HASH" =~ ^[0]{8}[a-fA-F0-9]{56}$ ]]
			then
				#print error msg
				echo ">>>error: block hash -- $BLK_HASH" >&2
				errsigf 1
				exit 1
			fi
		fi
		#check that $TXID is a transaction hash
		if [[ ! "$TXID" =~ ^[a-fA-F0-9]{64}$ ]]  #is $TXID a tx hash?
		then
			#print error msg
			echo ">>>error: transaction id -- $TXID" >&2
			errsigf 1
			exit 1
		fi

		#get raw transaction json
		bwrapper getrawtransaction "$TXID" true $BLK_HASH | mainfastf
	} &
}

#break asm and remove some script strings - helper func
#it would be useful to have a script code library with byte translations
#so we could process asm (assembly) better or even the hex code directly
#https://en.bitcoin.it/wiki/Script#Constants
asmbf()
{
	local string
	for string in "$@"
	do
		#remove strings with chars '_][' or jq null output
		if [[ "$string" = *[\[\]_]* || "$string" = null ]]
		then continue
		else echo "$string"
		fi
	done
}
#do not activate this now, may need eventually, 
#break asm (string[EXAMPLE]) -> (string [EXAMPLE])
#A=( ${ASM[@]//\[/ [} ) ;A=( ${A[@]//\]/] } )

#check addresses -- helper func
#used in vinbakf only
seladdrf()
{
	local TADDR
	TADDR=( ${ADDR[@]//null} )
	[[ -n "${TADDR[*]}" ]] || return 1
}

#select correct asm ( experimental! ) -- helper func
#used in vinbakf only
selasmf()
{
	ASM=( $( asmbf "$@" ) )
	[[ -n "${ASM[*]}" ]] || return 1
}

#vouts
#defaults voutf function
#this function has many fallbacks if bitcoind is not set with txindex
#and it will try and decode an address from asm/hex
#old code, tested a lot, avoid changing it, cannot retest all fallbacks again
voutf()
{
	local ADDR ASM TYPE pubKeyAddr pubKeyAsm pubKeyType TMP
	TMP="$1"

	#set variables for address processing
	#that is risky to set them all at once, but faster
	#the following shell arrays or variables will be set:
	#$pubKeyAddr, $pubKeyAsm and $pubKeyType
	eval "$( 
		jq -r --arg index "$index" '.vout[($index | tonumber)].scriptPubKey |
			(
				"pubKeyAddr=( \( .addresses? | .[]? // empty ) )",
				"pubKeyAsm=( \( .asm? // empty ) )",
				"pubKeyType=\"\( .type? // empty )\""
			)' "$TMP"
	)"

	#try to hash uncompressed addresses
	if (( ${#pubKeyAddr[@]} ))
	then
		#1#
		TYPE="$pubKeyType"
		echo   "    type: $TYPE"
		printf '    %s\n' "${pubKeyAddr[@]}"

	elif ASM=( $( asmbf "${pubKeyAsm[@]}" ) )
		(( ${#ASM[@]} ))
	then
		TYPE="$pubKeyType"
		echo "    type: $TYPE"

		#if nulldata
		#or if option -a (don't try to compress address) is set, print raw
		if [[ "$TYPE" = nulldata || "$OPTADDR" -gt 0 ]]
		then
		#2#
			echo "    ${ASM[-1]}"

		#if string is hashed
		elif [[ "$TYPE" = *hash* ]]
		then
		#3#
			echo "    $( hexToAddress "${ASM[-1]}" 05 )"
		else
		#4#
			echo "    $( hexToAddress "$( pack "${ASM[-1]}" | hash160 )" 00 )"
		fi
	
	else
		#10#
		#exit with error signal
		return 1
	fi

	return 0
}
#analysis# it seems that only the following conditionals
#are being met by txs from various blocks:
# #1#, #2# and #4#
#however, there are many fallbacks..
#debug: voutf count usage: echo "#$n# ${TXID}" >&2

#vins
#defaults vinf function
#this function has some fallbacks
#for when bitcoind is not set with txind=1
vinf()
{
	local TMP TMP2 txid ret retsum
	typeset -a txid ret
	TMP="$1"
	
	#go back to previous transaction to get some data..
	txid=( $( 
		jq -er --arg index "$index" \
		'.vin[($index | tonumber)] |
			.txid,
			.vout,
			(if .coinbase then "coinbase" else empty end)' \
			"$TMP"
	) ) || return 1
	
	#temp file
	TMP2="$TMP.${txid[0]:0:20}.$index"

	#is coinbase?
	if [[ "${txid[-1]}" = coinbase ]]
	then
		vinsum+=(coinbase)
		echo "    coinbase"
	#get previous transaction
	elif bwrapper getrawtransaction "${txid[0]}" true >"$TMP2"
	then
		jq -r --arg index "${txid[-1]}" '.vout[($index | tonumber)] // empty | "  Number_: \(.n )\tValue__: \(.value )"' "$TMP2"
		index="${txid[-1]}" voutf "$TMP2" 
	else
		#backup func
		#if bitcoind txindex is not set,
		#this func may still parse some addresses..
		vinbakf "$TMP" && return
	fi
	#get exit code
	ret+=( $? )
	
	#save result for sum later if no error exit code
	if retsum="$(( ${ret[@]/%/+} 0 ))"
		(( retsum == 0 ))
	then
		if [[ "${vinsum[0]}" = coinbase ]]
		then
			echo coinbase
		else
			jq -r  --arg index "${txid[-1]}" '.vout[( $index | tonumber)] // "0" | .value' "$TMP2"

			#clean up on the fly
			rm -- "$TMP2"  2>/dev/null
		fi
	fi >>"$tmp10sum"

	#sum exit codes
	return $(( ${ret[@]/%/+} 0 ))
}

#backup vinf function
#if bitcoind txindex is not set,
#this func may still process some addresses..
vinbakf()
{
	local TMP="$1"
	if ADDR=( $( jq -er --arg index "$index" '.vin[($index | tonumber)].scriptPubKey.addresses? | .[]?' "$TMP" ) ) &&
		seladdrf
	then
		#1#
		printf '    %s\n' "${ADDR[@]}"

	elif ASM=( $( jq -er --arg index "$index" '.vin[($index | tonumber)].scriptPubKey.asm? // empty' "$TMP" ) ) &&
		selasmf "${ASM[@]}"
	then
		#if option -a (don't try to compress address) is set, print raw
		if (( OPTADDR ))
		then
		#2#
			echo   "    ${ASM[-1]}"
		else
		#3#
			printf '    %s\n' "$( hexToAddress "${ASM[-1]}" 00 )"
		fi
	
	#others
	elif ASM=( $( jq -er --arg index "$index" '.vin[($index | tonumber)].scriptSig.asm? // empty' "$TMP" ) ) &&
		ASMSSIG=( ${ASM[@]} ) && selasmf "${ASM[@]}"
	then
		#note: there must be a more realiable way checking if first asm string is 0
		#check .scriptSig object keys for clues?
		#if option -a (don't try to compress address) is set, print raw
		if (( OPTADDR ))
		then
		#4#
			echo   "    ${ASM[-1]}"
		#or if first assembly element is a 0
		#or asm starts with 0014 or 0020
		elif [[ "${ASM[0]}" = 0 ]] || [[ "${ASM[0]}" = 0014* ]] || [[ "${ASM[0]}" = 0020* ]]
		then
		#5#
			printf '    %s\n' "$( hexToAddress "$( pack "${ASM[-1]}" | hash160 )" 05 )"
		else
		#6#
			#
			printf '    %s\n' "$( hexToAddress "$( pack "${ASM[-1]}" | hash160 )" 00 )"
		fi

	else
		#7#
		#
		#scriptSig.asm arrives here
		#ex tx: 718b13d041b1db8058390df6b33b77c261a06ca27a00d0b4d3a10bbdfb37d743 
		#how to hash this asm?
		[[ -n "${ASMSSIG[*]}" ]] &&
			echo   "    scriptSig: ${ASMSSIG[*]}"
		
		#cannot do anything with scriptSig asm
		return 1
	fi

	return 0
}

#manage job launch in loops
#this is not optimal but works
jobsemaphoref()
{
	local JOBS 
	while JOBS=( $( jobs -p ) )
		(( ${#JOBS[@]} > JOBSMAX ))
	do sleep $SEMAPHORESLEEP
	done
}
#semaphore: { (1/.1)*3 = max 30 calls/sec }
#bitcoin-cli rpc call: 88-160 calls/sec

#check if tx is unspent
checkspentf()
{
	local TMP index info addr ret
	TMP="${TMPD}/${TXID}.tx"

	bwrapper getrawtransaction $TXID 1 ${BLOCK_HASH_LOOP:-${BLK_HASH}} >"$TMP"

	for index in ${OPTSPENTVOUT:-$(jq -r '.vout[].n' "$TMP")}
	do
		info=( $(bwrapper gettxout $TXID $index | jq -r '.value //empty,if .coinbase == true then "coinbase" else empty end') )
		addr=( $(voutf "$TMP") )
		if [[ -n "${info[*]}" ]]
		then echo "$TXID $index unspent ${info[*]} ${addr[@]:1}"
		else echo "$TXID $index spent ${addr[@]:1}" ;ret=1
		fi
	done

	#return error if ANY vout is SPENT
	return ${ret:-0}
}

#clean temp files
cleanf() {
	#disable trap
	trap \  EXIT

	#user cache dir
	#if that does not exist, create
	if [[ -d "$CACHEDIR" ]] || mkdir -pv "$CACHEDIR"
	then
		#tasks
		#concatenate result?
		((CONCAT == 0)) || concatf || RET+=( $? )

		#check cache disk usage
		MAXCACHESIZE=150000000  #150MB
		cachesize=( $(du -bs "$CACHEDIR") )
		if (( cachesize[0] > MAXCACHESIZE ))
		then echo -e "$SN: warning -- user cache is $((cachesize[0] /1000000)) MB\n$SN: check -- ${cachesize[1]}" >&2
		fi
	else
		echo "$SN: err: cannot create user cache -- $CACHEDIR" >&2
	fi

	#check for err signals in err temp file
	[[ -e "$TMPERR" ]] && RET+=( $(<"$TMPERR") )

	#remove temp data?
	[[ -d "$TMPD" ]] && rm -rf "$TMPD"

	#verbose feedback
	((OPTVERBOSE)) && 
		printf '\n>>>took %s seconds  (%s min)\n' "$SECONDS" "$(( SECONDS / 60 ))" >&2
	
	#sum exit codes from other funcs
	exit $(( ${RET[@]/%/+} 0 ))
}

#concatenate result files in the input order
concatf()
{
	#return here if option -f or -o is set
	((OPTFAST + OPTOUT)) && return 0
	
	#concatenate buffer files in the correct order
	#get a unique name
	while RESULT="$CACHEDIR/txs-$(date +%Y-%m-%dT%T)-${L}.txt"
		[[ -e "$RESULT" ]]
	do sleep 1
	done
	#reserve the results file asap
	: >"$RESULT"

	#concatenate results in order
	if (( ${#TXFILES[@]} )) \
		&& cat -- "${TXFILES[@]}" >"$RESULT" \
		&& [[ -s "$RESULT" ]]
	then
		#write final result to stdout (feedback)?
		#only if option -o is not set!
		(( OPTOUT )) || cat -- "$RESULT" || return
	
		printf '>>>final transaction parsing -- %s\n' "$RESULT" >&2
	else
		##printf '%s: err  -- could not concatenate transaction files\n' "$SN" >&2
		rm -- "$RESULT"  2>/dev/null
		return 1
	fi
}

#kill subprocesses
trapf()
{
	#disable trap
	trap \  TERM INT HUP
	
	#kill sub processes
	pkill -P $$

	exit
}


#start

#parse script options
while getopts ab:c:fhj:losS:uvVwyY opt
do
	case $opt in
		a)
			#dont try to hash uncompressed addresses
			OPTADDR=1
			;;
		b)
			#get txs from a block hash or height
			BLK_HASH="$OPTARG"
			;;
		c)
			#bitcoin.conf filepath
			BITCOINCONF="$OPTARG"
			;;
		f)
			#fast tx processing (less info)
			((++OPTFAST))
			;;
		h)
			#help page
			echo "$HELP"
			exit 0
			;;
		j)
			#max jobs in background
			if [[ "$OPTARG" = [Aa][Uu][Tt][Oo]* ]]
			then JOBSMAX=$(nproc)
			else JOBSMAX="$OPTARG"
			fi
			;;
		l)
			#local time for humans
			unset TZ
			;;
		o)
			#send to stdout only
			OPTOUT=1
			;;
		s)
			#check if transaction is spent or not
			OPTSPENT=1
			;;
		S)
			#check if transaction is spent or not
			#get vout number
			OPTSPENT=1
			OPTSPENTVOUT="$OPTARG"
			;;
		u)
			#human-readable time formats
			((++OPTHUMAN))
			;;
		v)
			#feedback
			(( ++OPTVERBOSE ))
			;;
		V)
			#print script version
			while read
			do [[ "$REPLY" = \#\ v[0-9]* ]] && break
			done < "$0"
			echo "$REPLY"
			exit 0
			;;
		w)
			#white paper copy
			((++OPTW))
			;;
		Y)
			#same as -yy, shortcut
			#tx hex to ascii
			OPTASCII=2
			;;
		y)
			#tx hex to ascii
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

#typeset vars
typeset -a RET TXFILES

#consolidate user-set max jobs
JOBSMAX="${JOBSMAX:-$JOBSDEF}"
#check minimum jobs
if ((JOBSMAX < 1))
then echo "$SN: err  -- at least one job required" >&2 ;exit 1
else ((OPTVERBOSE>1)) && echo "$SN: jobs -- $JOBSMAX" >&2
fi

#required packages
for PKG in bitcoin-cli jq openssl xxd
do
	if ! command -v "$PKG" &>/dev/null
	then echo "$SN: err  -- $PKG is required" >&2 ;exit 1
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


#call some opt functions
#fast processing txs (less info)?
if ((OPTFAST))
then parsef() { parsefastf "$@" ;}
#retrieve bitcoin whitepaper from blockchain?
elif ((OPTW))
then whitepaperf ;exit
fi

#traps
trap cleanf EXIT
trap trapf TERM INT HUP

#choose and create temp dir
#eg. /dev/shm/bitcoin.tx.sh.[PROCID].[RANDOM]
for dir in "${TMPDIR:-$TMPDIR1}" "$TMPDIR1" /tmp
do
	[[ -d "$dir" ]] \
		&& TMPD="$(mktemp -d "${dir%/}/${SN:-bitcoin.tx}.$$.XXXXXXXX")" \
		&& break
done
unset dir

#check if var was set correctly
if [[ ! -d "$TMPD" ]] && TMPD="$( ! mktemp -d )"
then
	echo "$SN: err  -- no temporary directory available" >&2
	echo "$SN: err  -- check script help page and source code settings" >&2
	exit 1
#feedback?
elif ((OPTVERBOSE>1))
then echo ">>>temporary directory -- $TMPD" >&2
fi

#error signal temp file
TMPERR="$TMPD/errsig.txt"

#local time?
#human-readable time formats
#set jq arguments for time format printing
if [[ "${TZ^^}" = +(UTC0|UTC-0|UTC|GMT) ]]
then HH='strftime("%Y-%m-%dT%H:%M:%SZ")' ;((OPTHUMAN)) && HH='strftime("%a, %d %b %Y %T +00")'
else HH='strflocaltime("%Y-%m-%dT%H:%M:%S%Z")' ;((OPTHUMAN)) && HH='strflocaltime("%a, %d %b %Y %T %Z")'
fi

#jq script block for parsing txs
((OPTFAST > 2)) && JQTXHEX='"Hex_____: \(if ($optf | tonumber) > 2 then (.hex // empty) else empty end)",'
JQTXINFO='"Transaction information",
			'"$JQTXHEX"'
			"Tx_Id___: \(.txid)",
			"Hash____: \(.hash // empty)",
			"Blk_Hash: \(.blockhash // empty)",
			"Time____: \(.time // empty)\t \((.time // empty) | '"$HH"' )",
			"Blk_Time: \(.blocktime // empty)\t \((.blocktime // empty)| '"$HH"' )",
			"InActCha: \( if .in_active_chain then .in_active_chain else empty end)",
			"LockTime: \(.locktime)",
			"Version_: \(.version)",
			"Confirma: \(.confirmations // empty)",
			"Weight__: \(.weight) WU",
			"VirtSize: \(.vsize) vB",
			"Size____: \(.size // empty) B",
			"Vout_Sum: \([.vout[]|.value] | add)"'

#do some basic checking
#at this point, did user set option -b $BLK_HASH ?
if [[ -n "${BLK_HASH// }" ]]
then
	#is "block hash" set as "block height"?
	if [[ "$BLK_HASH" =~ ^[0-9]{,7}$ ]]
	then
		BLK_HASH="$( bwrapper getblockhash "$BLK_HASH" )"
		RET+=( $? )
	#is it really NOT "block hash"?
	elif [[ ! "$BLK_HASH" =~ ^[0]{8}[a-fA-F0-9]{56}$ ]]
	then
		#print error msg
		echo ">>>error: block hash -- $BLK_HASH" >&2
		RET+=( 1 )
		exit 1
	fi
fi

#(experimental)
#all txs from one block; tx hashes from block to stdin
#if -b , no pos args and stdin is free
if [[ -n "$BLK_HASH" && "$#" -eq 0 && -t 0 ]]
then
	if ((OPTFAST))
	then bwrapper getblock "$BLK_HASH" 2 | jq -r '.tx[]' | mainfastf ; RET+=($?) ;exit 1
	else
		if ((OPTASCII))
		then exec 0< <(bwrapper getblock "$BLK_HASH" 2) || { RET+=($?) ;exit 1 ;}
		else exec 0< <(bwrapper getblock "$BLK_HASH" 1 | jq -r '.tx[]') || { RET+=($?) ;exit 1 ;}
		fi
	fi
fi

#functions and loops
#if there are positional args
if (( $# ))
then
	#get number of arguments
	#"number" length for printing feedback
	L="$#"  K="${#L}"

	#loop through arguments
	for ARG in "$@"
	do
		read TXID BLK_HASH_LOOP OTHER <<<"$ARG"
		TXID="${TXID// }"
		[[ -n "$TXID" ]] || continue

		#-y transaction hex to ascii
		if (( OPTASCII ))
		then hexasciif
		#-u check if transaction is unspent
		elif (( OPTSPENT ))
		then checkspentf
		#parse tx info
		else parsef
		fi
		RET+=( $? )
		#get exit code

		#counter
		(( ++COUNTER ))
	done

#stdin not free and no arg
elif [[ ! -t 0 ]]
then
	#read until first newline
	#line must not be empty
	while read TXID BLK_HASH_LOOP OTHER || [[ -n "$TXID" ]]
	do [[ -n "${TXID// }" ]] && break
	done
			
	#select funtions
	#deal with stdin input types
	case "${TXID// }" in

		#json data, auto detect
		*[][{}]*)
			JSON=1
			#set temp filename for stdin buffer
			TMPSTDIN="${TMPD}/data.$$.json"
				
			#copy first line to our custom stdin buffer
			echo "${TXID} ${BLK_HASH_LOOP} ${OTHER}" >"$TMPSTDIN"
			unset TXID BLK_HASH_LOOP OTHER
	
			#copy remaining stdin
			cat >>"$TMPSTDIN"
	
			#test if stdin is json really
			if ! jq empty "$TMPSTDIN"
			then
				unset JSON
				echo "$SN: err  -- stdin does not seem to be json data" >&2
				exit 1
			#is there a tx array .tx[] (from `getrawblock HASH 2`) ? 
			elif jq -e '.tx[]' "$TMPSTDIN" &>/dev/null
			then
				TXAR=tx  #for jq cmd later
			#is there an array .[] ?
			elif jq -e '.[0]' "$TMPSTDIN" &>/dev/null
			then
				TXAR=
			else
				#may be unarrayed tx data, let's try and slurp it
				TXAR=    #for jq cmd later
				TMP5="$TMPSTDIN.txarray.json"
	
				jq -esr . "$TMPSTDIN" >"$TMP5" || exit 
				TMPSTDIN="$TMP5"
			fi
			unset TMP5
			
			#-y transaction hex to ascii
			if (( OPTASCII ))
			then
				TMP3="${TMPD}/${RANDOM}${RANDOM}.tx"
				jq -er ".${TXAR}[] // empty" "$TMPSTDIN" >"$TMP3" \
				&& hexasciif
				RET+=( $? )
			#-f fast processing (only general tx info)?
			elif ((OPTFAST))
			then
				jq -er ".${TXAR}[] // empty" "$TMPSTDIN" | mainfastf
				RET+=( $? )
			else
				#ids in array
				TXIDARRAY=( $(jq -r ".${TXAR}[]|.txid // empty" "$TMPSTDIN" ) )
				#get number of txs in array
				L="${#TXIDARRAY[@]}"
				#"number" length for printing feedback
				K="${#L}"
				
				## loop through tx ids
				for ((COUNTER=0 ;COUNTER<=$((${#TXIDARRAY[@]} - 1)) ;COUNTER++))
				do
					#processed transaction temp file
					TMP4="${TMPD}/${COUNTER}.tx"
					#raw transaction (json) temp file
					TMP3="$TMP4.json"
					#!#must be the same as in other functions
	
					#get transaction by json array index
					if jq -er ".${TXAR}[${COUNTER}] // empty" "$TMPSTDIN" >"$TMP3"  #&& [[ -s "$TMP3" ]]
					then
						#parse tx info
						parsef
					fi
					RET+=( $? )
				done
			fi
			;;

		#transaction hashes [:xdigit:], hopefully
		*[A-Fa-f0-9]*)
			#tx counter
			COUNTER=0

			#first $TXID was already set before
			while
				[[ -n "$TXID" ]] || read TXID BLK_HASH_LOOP OTHER
				TXID="${TXID// }"
				[[ -n "$TXID" ]]
			do
				#input from stdin
				#cannot know the number of lines in advance
				L="$((COUNTER+1))"
				#"number" length for printing feedback
				((${#L}<3)) && K=3 || K="${#L}"
				
				#-y transaction hex to ascii
				if (( OPTASCII ))
				then hexasciif
				#-u check if transaction is unspent
				elif (( OPTSPENT ))
				then checkspentf
				#parse tx info
				else parsef
				fi
				#get exit code
				RET+=( $? )

				#counter
				(( ++COUNTER ))

				#make sure to unset $TXID
				unset TXID
			done
			;;

		#empty
		'')
			echo "$SN: err  -- stdin empty" >&2
			RET+=(1)
			;;

		#invalid
		*)
			echo "$SN: err  -- invalid input" >&2
			RET+=(1)
			;;

	esac
else
	
	#requires argument
	echo "$SN: err  -- transaction id or json required" >&2
	RET+=(1)
fi

#wait for
#subprocesses
wait

#sanity newline
((OPTVERBOSE)) && echo >&2

