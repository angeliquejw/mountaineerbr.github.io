#!/usr/local/bin/ksh
#!/bin/env ksh
# v0.7.29k-  apr/2021  by mountaineerbr
# parse transactions by hash or transaction json data
# requires bitcoin-cli and jq

#BASH TO KSH (~10% faster in some cases, in other cases is slower, i dont understand)
#CHECK agetopts and esac (simplify json input?)
#GLOBS
#ADD AST TOOLS TO $PATH ?
#change $( cmd ) to ${ cm }
#change fun() to function fun syntax
#change &> to 1>file 2>&1
#change $JOBSMAX to ksh $JOBMAX 
#introduced bug: `Vin__Sum: 0.00000000' should be `Vin__Sum: coinbase'

#AST (Advanced Software Technologies) tools
#build from <https://github.com/att/ast>
#export PATH="/usr/local/ast/arch/linux.i386-64/bin:$PATH"
#. /usr/local/ast/arch/linux.i386-64/bin/.paths
#may be up to 10-15% faster than bash..


#script name
SN="${0##*/}"

#cache dir for results copy
#eg. ~/.cache/bitcoin.tx
CACHEDIR="$HOME/.cache/bitcoin.tx"

#set simple verbose
#feedback to stderr
OPTVERBOSE=0

#maximum jobs (subprocesses)
JOBSDEF=3   #hard defaults
#this depends mainly on the number of threads to service rpc calls of
#bitcoin daemo (rpcthreads=<n> ,defaults: 4)
#is the number of independent api requests that can be processed in parallel.
#in reality however there are many locks inside the product that means you 
#won't see much performance benefit with a value above 2.

#timezone
#defaults=UTC0
TZ="${TZ:-UTC0}"
export TZ

#temporary directory path
#try to keep temp files in shared memory (ramdisc)
#TMPDIR="/tmp"  #user custom
TMPDIR1=/dev/shm
TMPDIR2=/tmp

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
	$SN  [-aklosvyy] [-jNUM] [-bBLOCK_HASH|HEIGHT] TRANSACTION_HASH..
	$SN  [-aklosvyy] [-jNUM] \"TRANSACTION_HASH [BLOCK_HASH|HEIGHT]\"..
	$SN  -hV


DESCRIPTION
	Given a TRANSACTION_HASH, the script will make an RPC call to
	bitcoin-cli and parse the returning json data. When parsing is
	complete, transactions are concatenated as per input order to a
	single file at ${CACHEDIR/$HOME/\~} and printed to stdout.

	Transaction ids/hashes may be sent through stdin or set as posi-
	tional parameters to the script.

	An argument or a line from stdin may have two words separated by
	a blank space: the first one is the TRANSACTION_HASH and the
	second word must be BLOCK_HASH or HEIGHT of that transaction.
	Setting a BLOCK_HASH or HEIGHT is required if bitcoin-daemon is
	not set with txindex=1 option.
	
	Set option -s to parse transaction json obtained from bitcoin-cli
	sent via stdin. The script will try to detect json data automat-
	ically.

	Set option -o to print to stdout while processing; beware trans-
	actions may not be printed in the input order; this option dis-
	ables writing results to cache at ${CACHEDIR/$HOME/\~} .
	
	Set option -jNUM in which NUM is an integer and sets the maximum
	number of simultaneous background jobs, in which case NUM must be
	an integer or \`max'. Environment variable \$JOBMAX is read,
	defaults=${JOBSDEF} .

	Beware of mixed job outputs with optoin -o if more than one trans-
	action id and -jNUM is greater than 1! In order to prevent mixed
	outputs from asynchronous jobs, use -oj1 .

	Option -l sets local time instead of UTC time.

	Option -v enables verbose, set -vv to print more feedback for
	some functions.

	Option -y will convert plain hex dump from a transaction to ASCII
	text. The output will be filtered to print sequences that are at
	least 20 characters long, unless that returns empty, in which case
	there is decrement of one character until a match is found. If
	nought is reached, the raw byte output will be printed. Setting
	-yy prints all raw byte sequences, see example (4).


SHELL INTERPETER
	ksh93u+ (Version AJM 93u+ 2012-08-01, from teh officla AT&T ast
	repo) is required because of its speed and features, such as
	float point arithmetics.


ENVIRONMENT VARIABLES
	BITCOINCONF
		Path to bitcoin.conf or equivalent file with configs
		such as RPC user and password, is overwritten by script
		option -c, defaults=\"\$HOME/.bitcoin/bitcoin.conf\".
	TMPDIR  Sets user custom temporary directory, defaults to
		$TMPDIR1 or $TMPDIR2 .

	TZ 	Sets timezone, defaults to UTC0 (GMT).


SEE ALSO
	bitcoin.blk.sh -- Bitcoin block information and functions;
	from the same suite of this present script
	<https://github.com/mountaineerbr/scripts>


	bitcoin.sh -- Grondilu's Bitcoin bash functions
	<https://github.com/grondilu/bitcoin-bash-tools>


	blockchain-parser -- Ragestack's blockchain binary data parser
	Our bash script is slower than his parser in Python for various
	reasons, however these scripts print different information about
	transactions
	<https://github.com/ragestack/blockchain-parser>


BUGS


WARRANTY
	Licensed under the gnu general public license 3 or better and
	is distributed without support or bug corrections.
	
	Grondilu's bitcoin-bash-tools functions are embedded in this
	script, see <https://github.com/grondilu/bitcoin-bash-tools>.
	
	Packages bitcoin-cli v0.21+, jq, openssl, xxd, sha256sum and
	bash v4+ are required.

	The script \`bitcoin.tx.sh\`  will deliver better summary data
	than <blockchain.com> or <blockchair>. This script can return
	addresses from segwit and multisig transactions. The average
	time for parsing transactions until block height 667803 is about
	2 seconds with my i7, however that depends on the number of vins
	and vouts of each transaction. Parsing a few thousand trans-
	actions seems quite feasible for personal use.

	If you found this programme interesting, please consider
	sending me a nickle!  =)
  
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


	2) Process transaction json from bitcoin daemon:

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


	5) Get the genesis block coinbase transaction:

	$ bitcoin-cli getblock \$(bitcoin-cli getblockhash 0) 2 | $SN


OPTIONS
	-a 	Do not try to compress addresses (print assembly).
	-b BLOCK_HASH
		Set block hash containing transactions.
	-c CONFIGFILE
		Path to bitcoin.conf or equivalent configuration file,
		defaults=\"\$HOME/.bitcoin/bitcoin.conf\".
	-e 	Print raw data when possible, debugging.
	-h 	Print this help page.
	-j NUM 	Maximum number of simultaneous jobs, defaults=${JOBSDEF} .
	-l 	Sets local time instead of UTC time.
	-o 	Send to stdout while processing, inhibits creation of
		results file at ${CACHEDIR/$HOME/\~} .
	-s 	Set stdin input is raw transaction json.
	-V 	Print script version.
	-v	Enables verbose feedback.
	-vv	More verbose feedback for some functions.
	-y 	Decode transaction hex to ASCII, decrease minimum length
		of sequences to print until match is found, otherwise
		print all bytes.
	-yy 	Same as -y but prints all bytes (shortcut: -Y)."


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
    print -n "$1" |
    xxd -r -p
}

#custom, use -c instead of `tr`'ing newlines
unpack() {
    #xxd -p | tr -d '\n'
    xxd -p -c 100000000
}

typeset -a base58=(
      1 2 3 4 5 6 7 8 9
    A B C D E F G H   J K L M N   P Q R S T U V W X Y Z
    a b c d e f g h i j k   m n o p q r s t u v w x y z
)
unset dcr; for i in {0..57}; do dcr+="${i}s${base58[i]}"; done

decodeBase58() {
  print -n "$1" | sed -e's/^\(1*\).*/\1/' -e's/1/00/g' | tr -d '\n'
  print "$1" |
  {
    print "$dcr 0"
    sed 's/./ 58*l&+/g'
    print "[256 ~r d0<x]dsxx +f"
  } | dc |
  while read n
  do printf "%02x" "$n"
  done
}

encodeBase58() {
    typeset n X
    typeset -u X
    print -n "$1" | sed -e's/^\(\(00\)*\).*/\1/' -e's/00/1/g' | tr -d '\n'
    dc -e "16i ${X} [3A ~r d0<x]dsxx +f" |
    while read -r n; do print -n "${base58[n]}"; done
}

checksum() {
    pack "$1" |
    openssl dgst -sha256 -binary |
    openssl dgst -sha256 -binary |
    unpack |
    head -c 8
}

checkBitcoinAddress() {
    if [[ "$1" =~ ^[${ IFS= ; print "${base58[*]}" ;}]+$ ]]
    then
        typeset h="${ decodeBase58 "$1" ;}"
        checksum "${h:0:-8}" | grep -qi "^${h:${#h}-8}$"
    else return 2
    fi
}

hash160() {
    openssl dgst -sha256 -binary |
    openssl dgst -rmd160 -binary |
    unpack
}

hexToAddress() {
    typeset x="${ printf "%2s%${3:-40}s" ${2:-00} $1 | sed 's/ /0/g' ;}"
    encodeBase58 "$x${ checksum "$x" ;}"
    print
}


#original script funcs

#sum arguments
sumf()
{
	typeset i sum
	for i in "$@"
	do ((sum = sum + r ))
	done
	print $sum
}

#err signal
errsigf()
{
	typeset sig="${1:-1}"
	{ print "$sig" >>"$TMPERR" ;} 2>/dev/null
}

#is transaction hash?
#ishashf() { [[ "$1" =~ ^[a-fA-F0-9]{64}$ ]] ;}

#tx hex to ascii
hexasciif()
{
	typeset ascii data hex iscoinb num  #BLOCK_HASH_LOOP 

	if 
		#read file $TMP3 or get json from bitcoin-cli
		{ [[ -e "$TMP3" ]] && data="${ <"$TMP3" ;}" ;} ||
			data="${  bwrapper getrawtransaction "$TXID" true ${BLOCK_HASH_LOOP:-${BLK_HASH}}  ;}"
		hex="${  jq -er '.hex? // empty' <<<"$data"  ;}" &&
		[[ -n "$hex" ]]
	then
		#verbose?
		if (( OPTVERBOSE ))
		then
			#is coinbase tx?
			iscoinb="${  jq -r '.vin[0] | (.coinbase | if . == null then empty else "(coinbase transaction)\\n" end)' <<<"$data"  ;}"
			print -ne "--------\n${iscoinb}TXID: ${TXID}\nHEX_: $hex\nASCI: "
		#debug? print raw data
		elif (( DEBUGOPT ))
		then
			print "$data"
			print "$hex"
			return
		fi

		#print ascii text
		if ((OPTASCII>1))
		then
			print -n "$hex" | xxd -r -p 
		else
			#if strings result is not empty
			#decode hex to ascii (ignore null byte warning)
			{ ascii="${ print -n "$hex" | xxd -r -p ;}"  ;} 2>/dev/null
			for ((num=20 ;num>=0 ;--num))
			do
				((num)) || break

				strs="${  strings -n "$num" <<<"$ascii"  ;}"
				#-n Print sequences of characters that are
				#at least min-len characters long, instead of the default 4

				[[ -n "${strs// /}" ]] && break
			done

			#decide how to print
			if ((num))
			then
				#there was some output from `strings`
				print "$strs"
			else
				#otherwise print the raw ascii
				print -n "$hex" | xxd -r -p 
			fi
		fi

		#print simple feedback
		(( OPTVERBOSE )) &&
			printf "${CLR}tx: %*d/%*d  \r" "$K" "$((COUNTER+1))" "$K" "$L" >&2
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
	typeset catvin catvout header index tmp10 tmp10sum tmp11 tmp11sum REPLY
	typeset -a catvin catvout

	#debug? print raw data
	if (( DEBUGOPT ))
	then
		cat "$TMP"
		print ">>>file -- $TMP"
		return 0
	fi
	
	#one transaction json at a time!

	#vins
	print -e "\n--------\nInput and output vectors\n"
	print "Vins"

	index=0
	#temp file for sum of vins
	tmp10sum="$TMP.vin.sum"
	#loop through indexes
	while
		header="${  jq -re --arg index "$index" '.vin[($index|tonumber )] // empty |
			"  TxIndex: \(.txid // empty)",
			"  Sequenc: \(.sequence)",
			"  VoutNum: \(.vout // empty)"' "$TMP" 2>/dev/null ;}"
	do
		#temp file for vin
		tmp10="$TMP.$index.vin"
		catvin+=( "$tmp10" )

		#manage jobs
		#jobsemaphoref

		#async loop
		{
			#get addrs
			#also sets $tmp10sum
			print -e "$header\n  Addresses"
			if ! vinf
			then
				print '    skipping address..'
				#set err signal
				errsigf 1
			fi 2>/dev/null
			print
		
			#print simple feedback
			(( OPTVERBOSE )) &&
				printf "${CLR}tx: %*d/%*d  in : %3d  \r" "$K" "$((COUNTER+1))"  "$K" "$L" "$((index+1))" >&2
		} >"$tmp10" &
		
		(( ++index ))
	done
	wait
	cat -- "${catvin[@]}"
	
	#vouts
	print -e "\nVouts"
	
	index=0
	#temp file for sum of vouts
	tmp11sum="$TMP.vout.sum"
	#loop through indexes
	while
		header="${ jq -re --arg index "$index" '.vout[($index|tonumber)] // empty |
			"  Number_: \(.n )\tValue__: \(.value )"' "$TMP" 2>/dev/null ;}"
	do
		#temp file for vout
		tmp11="$TMP.$index.vout"
		catvout+=( "$tmp11" )

		#manage jobs
		#jobsemaphoref
	
		#async loop
		{
			#avoid shell errors being printed
			{

			print -e "$header\n  Addresses"
			#get addrs
			if ! voutf
			then
				print '    skipping address..'
				#set err signal
				errsigf 1
			fi
			print
		
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
	jq -r '"",
		"Transaction information",
		"",
		"Tx_Id___: \(.txid)",
		"Hash____: \(.hash // empty)",
		"Blk_Hash: \(.blockhash // empty)",
		"Time____: \(.time // empty)\t \(.time | '$HH' )",
		"Blk_Time: \(.blocktime // empty)\t \(.blocktime | '$HH' )",
		"LockTime: \(.locktime)",
		"Version_: \(.version)",
		"Confirma: \(.confirmations // empty)",
		"Weight__: \(.weight) WU",
		"VirtSize: \(.vsize) vB",
		"Size____: \(.size // empty) B"' "$TMP"
	
	#set calculation scale
	scl=8
	#sum vouts
	#load values from file
	#calc sums
	typeset -F $scl out in fee
	while read
	do ((out = out+REPLY))
	done <"$tmp11sum"

	#sum vins
	if [[ "${ <"$tmp10sum" ;}" = *coinbase* ]]
	then
		in=coinbase
		fee=0
	else
		#load values from file
		while read
		do ((in = in+REPLY))
		done <"$tmp10sum"

		#calc sums
		((fee = in-out))
	fi

	#format results
	#count longest number characters
	for c in "$in" "$out" "$fee"
	do ((${#c}>cc)) && cc="${#c}"
	done
	
	#is coinbase?
	[[ "$in" != *coinbase* ]] && in="${ printf '%+*.*f\n' "$cc" "$scl" "$in" ;}"
	out="${  printf '%+*.*f\n' "$cc" "$scl" "$out"  ;}"
	fee="${  printf '%+*.*f\n' "$cc" "$scl" "$fee"  ;}"
	#calc transaction fee per vByte and total fee
	feerates=( 
		${ jq -r "((${fee//[.+-]/} / .size  )|if . < 1000 and . > 0.01 then tostring|.[0:5] else . end),
			 ((${fee//[.+-]/} / .vsize )|if . < 1000 and . > 0.01 then tostring|.[0:5] else . end),
			 ((${fee//[.+-]/} / .weight)|if . < 1000 and . > 0.01 then tostring|.[0:5] else . end)" "$TMP" ;}
	)
	##feerates=( "${feerates[@]%.*}" )
	#tere are many units for calculating transaction fee
	#per byte, per virtual bye and per weight unit
	#one virtual byte = 4 weight units
	#the defaults should be `sats/vB'
	#https://bitcointalk.org/index.php?topic=5250569.0
	#https://bitcointalk.org/index.php?topic=5251213.0
	#https://btc.network/estimate

	cat<<-!
	Vin__Sum: ${in:-?}
	Vout_Sum: ${out:-?}
	Tx___Fee: ${fee:-?}
	FeeRates: ${feerates[0]:-?} sat/B  ${feerates[1]:-?} sat/vB  ${feerates[2]:-?} sat/WU
	!

	#remove buffer files
	rm -- "$tmp10sum" "$tmp11sum" "${catvout[@]}" "${catvin[@]}"

	}  2>/dev/null

	unset voutsum in out fee feerates c cc
}

#parse engine
parsef()
{
	#processed transaction temp file
	TMP4="${TMPD}/${COUNTER}.tx"
	#raw transaction (json) temp file
	TMP3="$TMP4.json"
	#!#must be the same as in other functions

	#manage jobs
	#jobsemaphoref
	
	#make sure file exists for later concatenation
	#(even if empty)
	: >"$TMP4"
	#make an array with processed transaction files
	TXFILES+=( "$TMP4" )
	
	#processing pipeline (to bg)
	{
		#is json option -s set?
		if ((OPTS)) || {
			#consolidate $BLK_HASH (if set)
			BLK_HASH="${BLK_HASH_LOOP:-${BLK_HASH}}"
			
			#do some basic checking
			#is $BLK_HASH set?
			if [[ -n "${BLK_HASH// }" ]]
			then
				#is "block hash" set as "block height"?
				if <<<"$BLK_HASH" grep -Eq '^[0-9]{,7}$'
				then
					BLK_HASH="${  bwrapper getblockhash "$BLK_HASH"  ;}" || { errsigf $?; exit 1;}
				#is it really NOT "block hash"?
				elif ! <<<"$BLK_HASH" grep -Eq '^[0]{8}[a-fA-F0-9]{56}$'
				then
					#print error msg
					print ">>>error: block hash -- $BLK_HASH" >&2
					#set err signal
					errsigf 1
					exit 1
				fi
			fi
			#check that $TXID id a transaction hash
			if ! <<<"$TXID" grep -Eq '^[a-fA-F0-9]{64}$'  #is $TXID a tx hash?
			then
				#print error msg
				print ">>>error: transaction id -- $TXID" >&2
				#set err signal
				errsigf 1
				exit 1
			fi

			#get raw transaction json
			bwrapper getrawtransaction "$TXID" true $BLK_HASH >"$TMP3"
		}
		then
			#debug? print raw data
			if (( DEBUGOPT ))
			then
				cat "$TMP3"
				exit 0
			fi
	
			TMP="$TMP3" mainf > "$TMP4"

			#write to stdout while processing?
			if (( OPTOUT ))
			then
				#clear last feedback line
				(( OPTVERBOSE )) &&
					printf "$CLR" >&2
				
				cat -- "$TMP4"
			fi
		else
			#print error
			print ">>>error: transaction id -- $TXID" >&2
			#set err signal
			errsigf
		fi
		
		#try to clean up on the fly
		rm -- "$TMP3"
	} &
}
#note: use bitcoin.tx.sh with option '-bBLOCK_HASH' 
#if bitcoind option txindex is not set
#jq slurp tip:https://stackoverflow.com/questions/41216894/jq-create-empty-array-and-add-objects-to-it

#break asm and remove some script strings - helper func
#it would be useful to have a script code library with byte translations
#so we could process asm (assembly) better or even the hex code directly
#https://en.bitcoin.it/wiki/Script#Constants
asmbf()
{
	typeset string
	for string in "$@"
	do
		#remove strings with chars '_][' or jq null output
		if [[ "$string" = *[\[\]_]* || "$string" = null ]]
		then continue
		else print "$string"
		fi
	done
}
#do not activate this now, may need eventually, 
#break asm (string[EXAMPLE]) -> (string [EXAMPLE])
#A=( ${ASM[@]//\[/ [} ) ;A=( ${A[@]//\]/] ;} )

#check addresses -- helper func
#used in vinbakf only
seladdrf()
{
	typeset TADDR
	TADDR=( ${ADDR[@]//null} )
	[[ -n "${TADDR[*]}" ]] || return 1
}

#select correct asm ( experimental! ) -- helper func
#used in vinbakf only
selasmf()
{
	ASM=( ${ asmbf "$@" ;} )
	[[ -n "${ASM[*]}" ]] || return 1
}

#vouts
#defaults voutf function
#this function has many fallbacks if bitcoind is not set with txindex
#and it will try and decode an address from asm/hex
#old code, tested a lot, avoid changing it, cannot retest all fallbacks again
voutf()
{
	typeset ADDR ASM TYPE pubKeyAddr pubKeyAsm pubKeyType scriptSigAsm scriptSigType

	#set variables for address processing
	#that is risky to set them all at once, but faster
	#the following shell arrays or variables will be set:
	#$pubKeyAddr, $pubKeyAsm, $pubKeyType, $scriptSigAsm and $scriptSigType
	eval "$( 
		jq -r --arg index "$index" '(
			.vout[( $index | tonumber)] |
			(
				.scriptPubKey |
					"pubKeyAddr=( \( .addresses? | .[]? // empty ) )",
					"pubKeyAsm=( \( .asm? // empty ) )",
					"pubKeyType=\"\( .type? // empty )\""
			),
			(
				.scriptSig |
					"scriptSigAsm=( \( .asm? // empty ) )",
					"scriptSigType=\"\( .type? // empty )\""
			)
			)' "$TMP"
	)"

	#try to hash uncompressed addresses
	if (( ${#pubKeyAddr[@]} ))
	then
		#1#
		TYPE="$pubKeyType"
		print   "    type: $TYPE"
		printf '    %s\n' "${pubKeyAddr[@]}"

	elif ASM=( ${ asmbf "${pubKeyAsm[@]}" ;} )
		(( ${#ASM[@]} ))
	then
		TYPE="$pubKeyType"
		print "    type: $TYPE"

		#if nulldata
		#or if option -a (don't try to compress address) is set, print raw
		if [[ "$TYPE" = nulldata ]] || (( OPTADDR ))
		then
		#2#
			print "    ${ASM[-1]}"

		#if string is hashed
		elif [[ "$TYPE" = *hash* ]]
		then
		#3#
			print "    ${  hexToAddress "${ASM[-1]}" 05  ;}"
		else
		#4#
			print "    ${  hexToAddress "$( pack "${ASM[-1]}" | hash160 )" 00  ;}"
		fi
	
	#others
	elif ASM=( ${  asmbf "${scriptSigAsm[@]}" ;}  )
		(( ${#ASM[@]} ))
	then
		#5#
		TYPE="$scriptSigType"
		print "    type: $TYPE"

		#if nulldata
		#or if option -a (don't try to compress address) is set, print raw
		if [[ "$TYPE" = nulldata ]] || (( OPTADDR ))
		then
			#6#
			print "    ${ASM[-1]}"
		#if string is hashed
		elif [[ "$TYPE" = *hash* ]]
		then
			#7#
			print "    ${  hexToAddress "${ASM[-1]}" 00  ;}"
		elif [[ "${ASM[0]}" = 0 ]] || [[ "${ASM[0]}" = 0014* ]] || [[ "${ASM[0]}" = 0020* ]]
		then
			#8#
			print "    ${  hexToAddress "$( pack "${ASM[-1]}" | hash160 )" 05  ;}"
		else
			#9#
			print "    ${  hexToAddress "$( pack "${ASM[-1]}" | hash160 )" 00  ;}"
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
#debug: voutf count usage: print "#$n# ${TXID}" >&2

#vins
#defaults vinf function
#this function has some fallbacks
#for when bitcoind is not set with txind=1
vinf()
{
	typeset TMP2 txid ret
	typeset -a txid ret
	
	#go back to previous transaction to get some data..
	txid=( $( 
		jq -er --arg index "$index" \
		'.vin[( $index | tonumber)] |
			.txid,
			.vout,
			(.coinbase | if . == null then empty else "coinbase" end)' \
			"$TMP"
	) ) || return 1
	
	#temp file
	TMP2="$TMP.${txid[0]:0:20}.$index"

	#is coinbase?
	if [[ "${txid[-1]}" = coinbase ]]
	then
		print "    coinbase"
	#get previous transaction
	elif bwrapper getrawtransaction "${txid[0]}" true >"$TMP2"
	then
		jq -r  --arg index "${txid[-1]}" '.vout[( $index | tonumber)] // empty | "  Number_: \(.n )\tValue__: \(.value )"' "$TMP2"
		TMP="$TMP2" index="${txid[-1]}" voutf
	else
		#backup func
		#if bitcoind txindex is not set,
		#this func may still parse some addresses..
		vinbakf && return
	fi
	#get exit code
	ret+=( $? )
	
	#save result for sum later if no error exit code
	retsum="${  sumf "${ret[@]}"  ;}"
	if
		(( retsum == 0 ))
	then
		if [[ "${txid[-1]}" = coinbase ]]
		then
			print coinbase
		else
			jq -r  --arg index "${txid[-1]}" '.vout[( $index | tonumber)] // "0" | .value' "$TMP2"

			#clean up on the fly
			rm -- "$TMP2"
		fi
	fi >>"$tmp10sum"

	#sum exit codes
	return $retsum
}

#backup vinf function
#if bitcoind txindex is not set,
#this func may still process some addresses..
vinbakf()
{
	if ADDR=( ${ jq -er --arg index "$index" '.vin[( $index | tonumber)].scriptPubKey.addresses? | .[]?' "$TMP" ;} ) &&
		seladdrf
	then
		#1#
		printf '    %s\n' "${ADDR[@]}"

	elif ASM=( ${ jq -er --arg index "$index" '.vin[( $index | tonumber)].scriptPubKey.asm? // empty' "$TMP" ;} ) &&
		selasmf "${ASM[@]}"
	then
		#if option -a (don't try to compress address) is set, print raw
		if (( OPTADDR ))
		then
		#2#
			print   "    ${ASM[-1]}"
		else
		#3#
			printf '    %s\n' "${  hexToAddress "${ASM[-1]}" 00  ;}"
		fi
	
	#others
	elif ASM=( ${ jq -er --arg index "$index" '.vin[( $index | tonumber)].scriptSig.asm? // empty' "$TMP" ;} ) &&
		ASMSSIG=( ${ASM[@]} ) && selasmf "${ASM[@]}"
	then
		#note: there must be a more realiable way checking if first asm string is 0
		#check .scriptSig object keys for clues?
		#if option -a (don't try to compress address) is set, print raw
		if (( OPTADDR ))
		then
		#4#
			print   "    ${ASM[-1]}"
		#or if first assembly element is a 0
		#or asm starts with 0014 or 0020
		elif [[ "${ASM[0]}" = 0 ]] || [[ "${ASM[0]}" = 0014* ]] || [[ "${ASM[0]}" = 0020* ]]
		then
		#5#
			printf '    %s\n' "${  hexToAddress "$( pack "${ASM[-1]}" | hash160 )" 05  ;}"
		else
		#6#
			#
			printf '    %s\n' "${  hexToAddress "$( pack "${ASM[-1]}" | hash160 )" 00  ;}"
		fi

	else
		#7#
		#
		#scriptSig.asm arrives here
		#ex tx: 718b13d041b1db8058390df6b33b77c261a06ca27a00d0b4d3a10bbdfb37d743 
		#how to hash this asm?
		[[ -n "${ASMSSIG[*]}" ]] &&
			print   "    scriptSig: ${ASMSSIG[*]}"
		
		#cannot do anything with scriptSig asm
		return 1
	fi

	return 0
}

#manage job launch in loops
#this is not optimal but works
jobsemaphoref()
{
	typeset JOBS 
	while JOBS=( ${ jobs -p ;} )
		(( ${#JOBS[@]} > JOBSMAX ))
	do sleep 0.1
	done
}
#semaphore: { (1/.1)*3 = max 30 calls/sec }
#bitcoin-cli rpc call: 88-160 calls/sec

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
		(( CONCAT == 0 )) || concatf || RET+=( $? )

		#check cache disk usage
		max=150000000  #150MB
		cachesize=( ${ du -bs "$CACHEDIR" ;} )
		if (( cachesize[0] > max ))
		then print -e "$SN: warning -- user cache is $((cachesize[0] /1000000)) MB\n$SN: check -- ${cachesize[1]}" >&2
		fi
	else
		print "$SN: err: cannot create user cache -- $CACHEDIR" >&2
	fi

	#check for err signals in err temp file
	[[ -e "$TMPERR" ]] && RET+=( ${ <"$TMPERR" ;} )

	#remove temp data?
	if [[ -d "$TMPD" ]]
	then
		#remove with feedback?
		if (( OPTVERBOSE > 1 ))
		then rm -rfv "$TMPD"
		else rm -rf "$TMPD"
		fi
	fi

	#verbose feedback
	(( OPTVERBOSE )) && 
		printf '>>>took %s seconds  (%s minutes)\n' "$SECONDS" "$(( SECONDS / 60 ))" >&2
	
	#sum exit codes from other funcs
	exit ${ sumf ${RET[@]} ;}
}

#concatenate result files in the input order
concatf()
{
	#return here if option -o or -e is set
	(( OPTOUT )) && return 0
	(( DEBUGOPT )) && return 0
	
	#concatenate buffer files in the correct order
	#get a unique name
	while
		RESULTFNAME="txs-${ date +%Y-%m-%dT%T ;}-${L}.txt"
		RESULT="$CACHEDIR/$RESULTFNAME"
		[[ -f "$RESULT" ]]
	do sleep 0.6
	done
	#reserve the results file asap
	: >"$RESULT"

	#concatenate results in order
	if (( ${#TXFILES[@]} == 0 ))
	then
		#no transaction files were created
		true
	elif cat -- "${TXFILES[@]}" > "$RESULT" &&
		[[ -s "$RESULT" ]]
	then
		#write final result to stdout (feedback)?
		#only if option -o is not set!
		(( OPTOUT )) || cat -- "$RESULT" || return
	
		printf '>>>final transaction parsing -- %s\n' "$RESULT" >&2
	else
		[[ -e "$RESULT" ]] && rm -- "$RESULT"
		printf '%s: err  -- could not concatenate transaction files\n' "$SN" >&2
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
while getopts ab:c:ehj:losvVyY opt
do
	case $opt in
		a)
			#dont try to hash uncompressed addresses
			OPTADDR=1
			;;
		b)
			#get a block hash
			BLK_HASH="$OPTARG"
			;;
		c)
			#bitcoin.conf filepath
			BITCOINCONF="$OPTARG"
			;;
		e)
			#debug? print raw data
			DEBUGOPT=1
			;;
		h)
			#help page
			print "$HELP"
			exit 0
			;;
		j)
			#max jobs in background
			JOBMAX="$OPTARG"
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
			#set stdin is json data (user explict)
			OPTS=1
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
			print "$REPLY"
			exit 0
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

#consolidate user-set max jobs
#consolidate $JOBMAX
typeset JOBMAX
JOBMAX="${JOBMAX:-$JOBSDEF}"
[[ "$JOBMAX" = [Mm][Aa][Xx] ]] && JOBMAX=${ nproc ;}
#check minimum jobs
if ((JOBMAX < 1))
then print "$SN: err  -- at least one job required" >&2 ;exit 1
else ((OPTVERBOSE)) && print "$SN: jobs -- $JOBMAX" >&2
fi

#required packages
for PKG in bitcoin-cli jq openssl xxd
do
	if ! command -v "$PKG" >/dev/null 2>&1
	then print "$SN: err  -- $PKG is required" >&2 ;exit 1
	fi
done
unset PKG

#grondilu's bitcoin-bash-tools requirement
#if (( BASH_VERSINFO[0] < 4 ))
#then print "$SN: this script requires bash version 4 or above" >&2 ;exit 1
#fi

#set alternative bitcoin.conf path?
if [[ -e "$BITCOINCONF" ]]
then
	#warp bitcoin-cli
	bwrapper() { bitcoin-cli -conf="$BITCOINCONF" "$@" ;}
	((OPTVERBOSE)) && print "$SN: -conf=\"${BITCOINCONF}\"" >&2
else
	#warp bitcoin-cli
	bwrapper() { bitcoin-cli "$@" ;}
fi

#error signal temp file
TMPERR="$TMPD/errsignal.txt"

#$RET is an array with exit codes
typeset -a RET TXFILES

#traps
trap cleanf EXIT
trap trapf TERM INT HUP

#set temp dir
for D in "$TMPDIR" "$TMPDIR1" "$TMPDIR2" /tmp
do
	#remove ending /
	D="${D%\/}"

	#create temp dir
	#eg. /dev/shm/bitcoin.tx.sh.[PROCID].[RANDOM]
	if [[ -d "$D" ]] && TMPD="${ mktemp -d "$D/${SN:-bitcoin.tx}.$$.XXXXXXXX" ;}"
	then break
	else continue
	fi
done
unset D

#check if var was set correctly
if [[ ! -d "$TMPD" ]] && TMPD="${ ! mktemp -d ;}"
then
	print "$SN: err  -- no temporary directory available" >&2
	print "$SN: err  -- check script help page and source code settings" >&2
	exit 1
fi

#feedback?
(( OPTVERBOSE > 1)) &&
	print ">>>temporary directory -- $TMPD" >&2

#local time?
#human-readable time formats
#set jq arguments for time format printing
typeset -u TZ
if [[ "${TZ}" =~ ^(UTC0?|GMT)$ ]]
then HH='strftime("%Y-%m-%dT%H:%M:%SZ")'
else HH='strflocaltime("%Y-%m-%dT%H:%M:%S%Z")'
fi

#do some basic checking
#at this point, did user set option -b $BLK_HASH ?
if [[ -n "${BLK_HASH// }" ]]
then
	#is "block hash" set as "block height"?
	if <<<"$BLK_HASH" grep -Eq '^[0-9]{,7}$'
	then
		BLK_HASH="${ bwrapper getblockhash "$BLK_HASH" ;}"
		RET+=( $? )
	#is it really NOT "block hash"?
	elif ! <<<"$BLK_HASH" grep -Eq '^[0]{8}[a-fA-F0-9]{56}$'
	then
		#print error msg
		print ">>>error: block hash -- $BLK_HASH" >&2
		RET+=( 1 )
		exit 1
	fi
fi

#functions and loops

#process arguments
#if there are positional args
if (( $# ))
then
	#get number of arguments
	L="$#"
	#"number" length for printing feedback
	K="${#L}"

	#loop through arguments
	for ARG in "$@"
	do
		read TXID BLK_HASH_LOOP BAD <<<"$ARG"
		TXID="${TXID// }"
		[[ -n "$TXID" ]] || continue

		#select option
		if (( OPTASCII ))
		then
			#-y transaction hex to ascii
			hexasciif
		else
			#parse tx info
			#set to concatenate results
			CONCAT=1

			#parse tx
			parsef
		fi
		#get exit code
		RET+=( $? )

		#counter
		(( ++COUNTER ))
	done
#stdin
#if no arg given and stdin is not free
elif [[ ! -t 0 ]]
then
	#if -s is not set
	if ((OPTS==0))
	then
		#read until first newline
		#line must not be empty
		while read TXID BLK_HASH_LOOP BAD
			TXID="${TXID// }" ;[[ -z "$TXID" ]]
		do continue
		done
	fi
			
	#if -s is not set
	#check stdin is not empty
	if ((OPTS==0)) && [[ -z "$TXID" ]]
	then
		unset CONCAT
		print "$SN: err  -- stdin appears empty or is not json" >&2
		exit 1
	fi

	#select funtions
	#deal with stdin input types
	query="${TXID}${OPTS+OPTSSET}"
	case "$query" in

	#json data or -s json option
	*[{}]*|*OPTSSET)
		#set temp filename for stdin buffer
		TMPSTDIN="${TMPD}/data.$$.json"
			
		#set to concatenate results
		CONCAT=1

		#json detect automatically
		#copy first line to our custom stdin buffer
		[[ "$query" =  *[{}]* ]] &&
			print "${TXID} ${BLK_HASH_LOOP} ${BAD}" >"$TMPSTDIN"	

		#-s is set explicitly
		if [[ "$query" = *OPTSSET ]]
		then
			OPTS=1
			unset TXID BLK_HASH_LOOP

			#copy remaining stdin
			print "${ </dev/stdin ;}" >>"$TMPSTDIN"

			#test if stdin is json
			if ! jq empty "$TMPSTDIN"
			then
				unset CONCAT
				print "$SN: err  -- stdin does not seem to be json data" >&2
				exit 1
			#is there a tx arrau .tx[] (from `getrawblock HASH 2`) ? 
			elif jq -er '.tx[]' "$TMPSTDIN" >/dev/null 2>&1
			then
				TXAR=tx  #for jq cmd later
			else
				#may be unarrayed tx data, let's try and slurp it
				TXAR=    #for jq cmd later
				TMP5="$TMPSTDIN.txarray.json"

				jq -esr . "$TMPSTDIN" >"$TMP5" || exit 
				TMPSTDIN="$TMP5"
			fi
			unset TMP5
			
			#ids in array
			TXIDARRAY=( ${ jq -r ".${TXAR}[]|.txid? // empty" "$TMPSTDIN" ;} )
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
				if jq -er ".${TXAR}[${COUNTER}] // empty" "$TMPSTDIN" >"$TMP3" &&
					[[ -s "$TMP3" ]]
				then
					#select option
					if (( OPTASCII ))
					then
						#-y transaction hex to ascii
						hexasciif
					else
						#parse tx info
						#set to concatenate results
						CONCAT=1

						#parse tx
						parsef
					fi
				fi
				RET+=( $? )
			done
		fi

		;;
	#transaction hashes
	*)
		#tx counter
		COUNTER=0

		#first $TXID was already set before
		while
			[[ -n "$TXID" ]] || read TXID BLK_HASH_LOOP BAD
			TXID="${TXID// }"
			[[ -n "$TXID" ]]
		do
			#input from stdin
			#cannot know the number of lines in advance
			L="$((COUNTER+1))"
			#"number" length for printing feedback
			((${#L}<3)) && K=3 || K="${#L}"
			
			#select option
			if (( OPTASCII ))
			then
				#-y transaction hex to ascii
				hexasciif
			else
				#parse tx info

				#set to concatenate results
				CONCAT=1

				#parse tx
				parsef
			fi
			#get exit code
			RET+=( $? )

			#counter
			(( ++COUNTER ))

			#make sure to unset $TXID
			unset TXID
		done
		;;
	esac
else
	unset CONCAT
	
	#requires argument
	print "$SN: err  -- transaction id or json required" >&2
	exit 1
fi

#wait for
#subprocesses
wait

#sanity newline
(( OPTVERBOSE )) && print >&2

