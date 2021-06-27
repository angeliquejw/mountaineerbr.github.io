#!/bin/bash
# v0.6.28  jun/2021  by castaway
# create base-58 address types from public key
# create WIF from private keys

#defaults
#user-side, set $VER
#public address version byte (prefix)
VERDEF=00
#private address version byte (prefix)
VERPRIDEF=80
#compressed public key (suffix)
VERCOMP=01

#script name
SN="${0##*/}"

#make sure locale is set correctly
export LC_NUMERIC=C
#export LC_NUMERIC=en_US.UTF-8

#base58 character set
B58='1-9A-HJ-NP-Za-km-z'
#bech32 character set, including uppercase
B32='AC-HJ-NP-Zac-hj-np-z02-9'

#ASCII chars
#literal newline and blank space
ASCIISET="

 !\"#$%&'()*+,./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_\`abcdefghijklmnopqrstuvwxyz{|}~-"
ASCIISET='\x00-\x7F'

#todo
#really check prefixes in wif checksum check?

#help
HELP="$SN - create base-58 address types from public key
		and WIF from private keys


DESCRIPTION
	$SN [-ace] [-vNUM] [STRING|HASH160]..
	$SN [-ep] [-vNUM] [STRING|FILE]..
	$SN [-eppwwx] [-vNUM] STRING..
	$SN [-1e] STRING..
	$SN [-26be] [STRING|FILE|HEX]..
	$SN [-beyYt] [STRING|FILE|HEX]..
	$SN -h


	Create public and private addresses from HEX STRINGS. If no
	option is given, defaults to converting HEX STRING to public
	address

	Set multiple STRINGS as positional parameters or send them via
	stdin (pipe) one per line.

	If STRING is a filename and any option -26pyY is set, it reads
	the entire file, otherwise process each line from stdin or
	positional argument separately. Other options will read input
	as literal STRINGS.

	Final newline literals in input strings are removed before further
	processing. However, some functions require that output end with
	a newline, so that may be added automatically.

	Only legacy addresses (P2PKH) are supported (addresses starting
	with 1). Segwit addresses (P2SH, starting with 3) may not be
	checked with option -c. Native segwit (bech32, starting with bc1)
	addresses will throw errors.

	This script warps around \`\`some'' functions from Grondilu's
	bitcoin-bash-tools. The script has got some original functions,
	too.


	WARNING: SCRIPT IS EXPERIMENTAL


	Public keys (defaults)

	Option -1 prints HASH160 of public address, this converts a
	bitcoin address to the HASH160 format used internally by bitcoin
	(decodes BASE58 address and removes version byte).

	Option -a skips making HASH160 of STRING when creating a base-58
	address from it.

	Option -c check checksum of public keys.


	Private keys

	Option -p generates a wallet import format address from a private
	key (seed); private key may be SHA256 of an image file, audio
	file, text, etc. The SHA256 sum will be set as private key.

	Option -x check checksum of Wallet Import Format (WIF) key.

	Option -w convert WIF to private key. Pass twice to set compres-
	sion flag.


	Decode and encode BASE58

	Encoding works well with text files.

	Option -Y encodes STRING or FILE to BASE58; text may be UTF-8,
	optionally set -t to transliterate UTF-8 characters to ASCII
	(requires package iconv); set -b if input is BYTE HEX.
	
	Option -y decodes BASE58 encoded STRING or FILE to text; may set
	option -b to print BYTE HEX instead of text.


	Miscellaneous

	Option -2 generates the double SHA256 sum of STRING, FILE or
	BYTE HEX; if input is BYTE HEX, set -b.
	
	Option -6 generates HASH160 from STRING, FILE or BYTE HEX, that
	is the RIPEMD160 of SHA256 sum of input; see also option -b.

	Option -b sets input is BYTE HEX instead of text (with -26y) or
	prints output as BYTE HEX (with -Y).

	Option -e for some verbose and option -h for this help page.

	Option -vNUM sets version byte, in which NUM is a byte version
	number such as 00, 05, ef and others.


ENVIRONMENT
	VER 	Public keys, defaults=${VERDEF}
		Private keys, defaults=${VERPRIDEF}


SEE ALSO
	List of address prefixes
	<https://en.bitcoin.it/wiki/List_of_address_prefixes>

	For basic information on making addresses
	<https://en.bitcoin.it/wiki/Technical_background_of_version_1_Bitcoin_addresses>

	Graphical address generator
	<https://royalforkblog.github.io/2014/08/11/graphical-address-generator/>

	BIP39 tool
	<https://github.com/iancoleman/bip39>

	Private key generation and WIF
	<https://en.bitcoin.it/wiki/Wallet_import_format>
	<https://gist.github.com/t4sk/ac6f2d607c96156ca15f577290716fcc>
	<http://gobittest.appspot.com/PrivateKey>
	<https://royalforkblog.github.io/2014/08/11/graphical-address-generator>

	BASE58 conversion specs and examples
	<https://tools.ietf.org/id/draft-msporny-base58-01.html>
	<https://www.appdevtools.com/base58-encoder-decoder>
	<https://www.dcode.fr/base-58-cipher>
	<https://incoherency.co.uk/base58/>
	<https://en.bitcoin.it/wiki/Base58Check_encoding>
	<https://github.com/keis/base58>

	Grondilu's bitcoin-bash-tools
	<https://github.com/grondilu/bitcoin-bash-tools>

	Validating bitcoin address (see older and newer comments)
	<https://bitcointalk.org/index.php?topic=1026.0>

	Bech32 patterns and names
	<https://www.reddit.com/r/Bitcoin/comments/6xrl60/so_bech32_address_formats_are_already_live_on/dmilfor>


BUGS
	Be aware this script is for studying purposes so there is no
	guarantee this is working properly. DYOR and check output.


WARRANTY
	Packages GNU dc (GNU coreutils), openssl, xxd and bash 4+ are
	required.

	Package iconv is required to transliterate UTF-8 to ASCII text
	with option -t (optional).

	Licensed under the gnu general public license 3 or better and is
	distributed without support or bug corrections. Grondilu's bit-
	coin-bash-tools functions are embedded in this script.
	
	If you found this programme interesting, please consider sending
	me a nickle!  =)
  
		bc1qlxm5dfjl58whg6tvtszg5pfna9mn2cr2nulnjr


USAGE EXAMPLES
	1) Make public address from HEX:

		$ $SN 0496b538e853519c726a2c91e61ec11600ae1390813a627c66fb8be7947be63c52da7589379515d4e0a604f8141781e62294721166bf621e73a82cbf2342c858ee

		12c6DSiU4Rq3P4ZxziKxzrL5LmMBrzjrJX


	2) Make public address, version byte 05 (P2SH, pay to script hash):
	
		$ $SN -v05 00142b2296c588ec413cebd19c3cbc04ea830ead6e78
		or
		$ VER=05 $SN 00142b2296c588ec413cebd19c3cbc04ea830ead6e78
			
		3FfQGY7jqsADC7uTVqF3vKQzeNPiBPTqt4


	3) Make public address, set input as HASH160, ver byte 05 (P2SH):

		$SN -av05 354937d51cf40b4c442f8a97988b9be588367ba1

		36YmSzZVaPbv9EyG8sNGSLHTKD3PkBAAmQ


	4) Get HASH160 of address:

		$ $SN -1 12c6DSiU4Rq3P4ZxziKxzrL5LmMBrzjrJX

		0119b098e2e980a229e139a9ed01a469e518e6f26


	5) Encode text to BASE58:

		$ $SN -Y \"The quick brown fox jumps over the lazy dog.\" 
		
		USm3fpXnKG5EUBx2ndxBDMPVciP5hGey2Jh4NDv6gmeo1LkMeiKrLJUUBk6Z


	6) Encode a whole text file to BASE58; converts to ASCII automatically:

		$ $SN -Y file.txt


	7) Decode binary HEX to text:

		$ $SN -yb 0x48656c6c6f20576f726c6421
	
		Hello World!	


OPTIONS
	Public keys (defaults)
	Generate public address from HEX
	-1 	Print HASH160 from public address (decode BASE58 and
		remove version byte).
	-a 	Avoid making HASH160 from input (set input as HASH160).
	-c 	Check public address checksum.

	Private keys
	-p	Generate Wallet import Format (WIF) key from private key.
	-pp 	Generate compressed WIF from private key.
	-x 	Check Wallet Import Format checksum.
	-w	Generate private key from WIF.
	-ww	Generate private key from compressed WIF.
	
	Decode and encode BASE58
	-b 	Flag input STRING is BYTE HEX instead of text (with -26y),
		or print output as BYTE HEX (with -Y).
	-t 	Transliterate non-ASCII characters to ASCII (with -Y).
	-y	Decode BASE58-encoded STRING or FILE to text (see -b).
	-Y	Encode STRING or text FILE to BASE58 (see also -bt).

	Misc
	-2 	Generate double SHA256 sum from STRING, FILE or BYTE HEX
		(see also -b).
	-6 	Generate double HASH160 from STRING, FILE or BYTE HEX
		(see also -b).
	-e 	Verbose mode.
	-h 	Print this help page.
	-v NUM 	Set version byte, defaults=${VERDEF} (public keys)
		and defaults=${VERPRIDEF} (private keys)."


#even more refs
#generate bech32 addresses in zsh
#i am _not_ sure his scripts are right though
#https://blog.iuliancostan.com/post/2020-02-10-bitcoin-bech32-segwit-address/


#functions

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

#custom, use -c instead of `tr`'ing newlines
unpack() {
    #xxd -p | tr -d '\n'
    xxd -p -c 100000000
}
#xxd -p | tr -d '\n'
#custom, may use -c instead of `tr`'ing newlines
#xxd -p -c 100000000

declare -a base58=(
      1 2 3 4 5 6 7 8 9
    A B C D E F G H   J K L M N   P Q R S T U V W X Y Z
    a b c d e f g h i j k   m n o p q r s t u v w x y z
)
unset dcr; for i in {0..57}; do dcr+="${i}s${base58[i]}"; done

#newest function for decoding base58 specific values
#https://github.com/grondilu/bitcoin-bash-tools/issues/19
#S2 S2 S2
decodeBase58() {
  echo -n "$1" | sed -e's/^\(1*\).*/\1/' -e's/1/00/g' | tr -d '\n'
  echo "$1" |
  {
    echo "$dcr 0"
    sed 's/./ 58*l&+/g'
    echo "[256 ~r d0<x]dsxx +f"
  } | dc |
  while read n
  do printf "%02x" "$n"
  done
}

#original
encodeBase58() {
    local n
    echo -n "$1" | sed -e's/^\(\(00\)*\).*/\1/' -e's/00/1/g' | tr -d '\n'
    dc -e "16i ${1^^} [3A ~r d0<x]dsxx +f" |
    while read -r n; do echo -n "${base58[n]}"; done
}
#custom (for option -Y)
#use echo to send large strings to dc
yencodeBase58f() {
    local n
    echo -n "$1" | sed -e's/^\(\(00\)*\).*/\1/' -e's/00/1/g' | tr -d '\n'
    echo "16i ${1^^} [3A ~r d0<x]dsxx +f" | dc |
    while read -r n; do echo -n "${base58[n]}"; done
}

checksum() {
    pack "$1" |
    openssl dgst -sha256 -binary |
    openssl dgst -sha256 -binary |
    unpack |
    head -c 8
}

checkBitcoinAddress() {
    if [[ "$1" =~ ^[$(IFS= ; echo "${base58[*]}")]+$ ]]
    then
        local h="$(decodeBase58 "$1")"
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
    local x="$(printf "%2s%${3:-40}s" ${2:-00} $1 | sed 's/ /0/g')"
    encodeBase58 "$x$(checksum "$x")"
    echo
}


#script original funcs

#-1 get hash160 from public address
#reverse direction
revf()
{
	local hx160 input

	input="$1"

	#validate base58 input string
	if [[ "$input" = *[^${B58}]* ]]
	then
		#segwit bech32 character set will throw errors
		echo "err: invalid base58 public key -- ${input:0:20}" >&2
		return 1
	else
		#get addr type
		type="$( ispubkeyf "$input" || isprivkeyf "$input" || echo string )"
	fi

	#decode base58
	hx160="$( decodeBase58 "$input" )"

	#remove byte number and checksum
	hx160="$( sed -E 's/^.?.(.{40}).{8}$/\1/' <<< "$hx160" )"

	#print result
	if (( OPTVERBOSE ))
	then
		#verbose
		cat <<-!
		--------
		TYPE___: $type
		INPUT__: $input
		HASH160: $hx160
		!
	else
		#simple
		echo "$hx160"
	fi
}

#Base58 Mapping Table
#func()
#{
#	local b char input
#	
#	input="$1"
#
#	while read -n1 char
#	do
#		case "$char" in
#			1) b=0;;   2) b=1;;   3) b=2;;
#			4) b=3;;   5) b=4;;   6) b=5;;
#			7) b=6;;   8) b=7;;   9) b=8;;
#			A) b=9;;   B) b=10;;  C) b=11;;
#			D) b=12;;  E) b=13;;  F) b=14;;
#			G) b=15;;  H) b=16;;  J) b=17;;
#			K) b=18;;  L) b=19;;  M) b=20;;
#			N) b=21;;  P) b=22;;  Q) b=23;;
#			R) b=24;;  S) b=25;;  T) b=26;;
#			U) b=27;;  V) b=28;;  W) b=29;;
#			X) b=30;;  Y) b=31;;  Z) b=32;;
#			a) b=33;;  b) b=34;;  c) b=35;;
#			d) b=36;;  e) b=37;;  f) b=38;;
#			g) b=39;;  h) b=40;;  i) b=41;;
#			j) b=42;;  k) b=43;;  m) b=44;;
#			n) b=45;;  o) b=46;;  p) b=47;;
#			q) b=48;;  r) b=49;;  s) b=50;;
#			t) b=51;;  u) b=52;;  v) b=53;;
#			w) b=54;;  x) b=55;;  y) b=56;;
#			z) b=57;;
#			*)
#				b=
#				echo "err: cannot convert base58 to hex -- \"$char\"" >&2
#				return 1
#				;;
#		esac
#
#		echo -n "$b"
#	done <<<"$input"
#
#	#add new line
#	echo
#}
#https://tools.ietf.org/id/draft-msporny-base58-01.html

#-Yy encode decode base58
base58f()
{
	local bytestr input type output VERB
	typeset -a VERB

	input="$1"

	#load file if input is a filename
	#ignore warning of no newline
	[[ -e "$input" ]] && input="$(<"$input")"

	#decode or encode?
	if ((ASCIIOPT==1))
	then
		#-Y encode base58

		#is input byte hex?
		if ((OPTBYTE))
		then
			#-b input is byte hex
			#drop 0x from start of string
			bytestr="${input#0x}"
			type=hex

			#output byte string
			output="$( echo -n "$bytestr" | unpack)"
		else
			#check if text is ascii
			if [[ "$input" = *[^${ASCIISET}]* ]]
			then
				VERB+=('warning -- string contains non-ascii characters')

				#check availability of iconv
				if ((OPTCONV))
				then
					VERB+=('warning -- utf-8 to ascii transliterated')

					#utf8 to ascii (transliteration of diacritics)
					input="$(iconv -f utf-8 -t ascii//translit <<<"$input")" || exit
				fi
			fi

			bytestr="$( echo -n "$input" | unpack )"
			type=text

			#convert hex to base58; get error msg
			output="$( yencodeBase58f "$bytestr" 2>&1 )"
			
			#empty newline is the same as : "true" for dc
			#so check output for err msg
			[[ "$output" = dc:* ]] && output=B 
		fi

		#print option
		if ((OPTVERBOSE))
		then
			#verbose
			cat <<-!
			--------
			TYPE___: $type
			INPUT__: $input
			HEXDUMP: $bytestr
			BASE58_: $output
			!

			#print verbose warnings
			((${#VERB[@]})) && printf '%s\n' "${VERB[@]}" >&2
		else
			#bas58 result
			#must print new line
			echo "$output"
		fi
	else
		#-y decode base58

		#-b output byte hex?
		if ((OPTBYTE))
		then
			#input is byte hex
			#drop 0x from start of string
			bytestr="${input#0x}"
			type=hex
		#validate base58 input string
		elif [[ "$input" = *[^${B58}]* ]]
		then
			echo "err: invalid base58 string -- ${input:0:20}" >&2
			return 1
		else
			#convert hex to text
			bytestr="$( decodeBase58 "$input" )"
			type=text
		fi
		
		#process output
		{ output=$(<<<"$bytestr" xxd -p -r) ;} 2>/dev/null
		#print option
		if ((OPTVERBOSE))
		then
			#verbose
			cat <<-!
			--------
			TYPE___: $type
			INPUT__: $input
			HEXDUMP: $bytestr
			TEXTOUT: $output
			!

			#print verbose warnings
			((${#VERB[@]})) && printf '%s\n' "${VERB[@]}"
		else
			#convert hex to text
			#must print new line
			echo "$output"
		fi
	fi

	#cannot get exit code from dc anyways
	return 0
}
#https://medium.com/concerning-pharo/understanding-base58-encoding-23e673e37ff6
#https://stackoverflow.com/questions/34076160/how-to-convert-a-string-into-hexadecimal-in-bash
#https://stackoverflow.com/questions/46990378/command-to-convert-hexdump-back-to-text

#convert hex to public address
addrf()
{
	local addr hx160 input

	input="$1"

	#make hash160 of input?
	if ((OPTHASH==0))
	then
		#make hash160
		hx160="$( pack "$input" | hash160 )"
	else
		hx160="$input"
	fi

	#generate address
	addr="$( hexToAddress "$hx160" "$VER" )"

	#verbose
	if (( OPTVERBOSE ))
	then
		#verbose
		cat <<-!
		---------
		INPUT___: $input
		HASH160_: $hx160
		VER_BYTE: $VER
		PUB_ADDR: $addr
		!
	else
		echo "$addr"
	fi

	[[ -n "$addr" ]] || return 1
}

#-2 generate double sha256 sum
#main func
gendsha256f()
{
	local input sha256

	#is input binary hex, a file or string?
	if ((OPTBYTE))
	then
		#input is byte hex
		type='byte hex'
		input="$( pack "$1" )"
	elif [[ -e "$1" ]]
	then
		#input a filename?
		type=file
		#read file
		input="$( pack "$(<"$1")" )"
	else
		type=string
		input="$1"
	fi 2>/dev/null

	sha256=( $(
		echo -n "$input" |
			openssl dgst -sha256 -binary |
			openssl dgst -sha256
	) )
	sha256=( "${sha256[@]^^}" )

	#print result
	if (( OPTVERBOSE ))
	then
		#verbose
		cat <<-!
		--------
		TYPE___: $type
		INPUT__: $input
		DSHA256: ${sha256[-1]}
		!
	else
		#simple 
		echo "${sha256[-1]}"
	fi
}
#may also use: `echo -n myfirstSHA | sha256sum | xxd -r -p | sha256sum`
#https://bitcoin.stackexchange.com/questions/5671/how-do-you-perform-double-sha-256-encoding
#https://en.bitcoin.it/wiki/Protocol_documentation#Hashes
#https://btcleak.com/2020/06/10/double-sha256-in-bash-and-python/

#-6 generate hash160
#main func
genhash160f()
{
	local dump input hx160

	#is input binary hex, a file or string?
	if ((OPTBYTE))
	then
		#input is byte hex
		type='byte hex'
		input="$1"
	elif [[ -e "$1" ]]
	then
		#input a filename?
		type=file
		#read file
		input="$1"
		dump="$( echo -n "$(<"$input")" | unpack )"
	else
		type=string
		input="$1"
		dump="$( echo -n "$input" | unpack )"
	fi 2>/dev/null

	#make hash160
	hx160="$( pack "${dump:-$input}" | hash160 )"

	#print result
	if (( OPTVERBOSE ))
	then
		#verbose
		cat <<-!
		--------
		TYPE___: $type
		INPUT__: $input
		HEXDUMP: ${dump:-$input}
		HASH160: $hx160
		!
	else
		#simple 
		echo "$hx160"
	fi
}

#-c check public key (address) checksum
checkf()
{
	local input ret
	
	input="$1"

	checkBitcoinAddress "$input"
	ret="$?"

	#verbose
	((OPTVERBOSE)) && echo 'Public key checksum check'

	#print validation result
	if ((ret==0))
	then
		echo "Validation pass -- $input"
	else
		echo "Validation fail -- $input" >&2
		return 1
	fi

	return 0
}

#-p generate a private address
privkeyf()
{
	local addr input sha256 step hx cksum

	input="$1"
	
	#is input SHA256SUM ?
	if [[ "$input" =~ ^[A-Fa-f0-9]{64}$ ]]
	then
		type=sha256
		#use SHA256SUM as is
		sha256=( "$input" )
	#is input a filename?
	elif [[ -e "$input" ]]
	then
		type=filename
		#read file without the last newline
		sha256=( $( echo -n "$(<"$input")" | openssl dgst -sha256 ) ) 
	else
		type=string
		#echo string without last newline
		sha256=( $( echo -n "$input" | openssl dgst -sha256 ) ) 
	fi
	
	#uppercase
	sha256=( "${sha256[@]^^}" )

	#is compressed?
	(( OPTP == 2 )) || unset VERCOMP

	step="$VER${sha256[-1]}$VERCOMP"

	hx="$(
		pack "$step" |
		openssl dgst -sha256 -binary |
		openssl dgst -sha256 -binary |
		unpack 
	)"
	
	#get the checksum
	cksum="$( head -c8 <<<"$hx" )"

	#generate address
	addr="$( encodeBase58 "$step$cksum" )"

	#verbose
	if (( OPTVERBOSE ))
	then
		#verbose
		cat <<-!
		--------
		TYPE____: $type
		INPUT___: $input
		SHA256__: ${sha256[-1]}
		COMPRESS: $( ((OPTP==2)) && echo true || echo false )
		VER_BYTE: $VER
		CHECKSUM: $cksum
		PRIVADDR: $addr
		!
	else
		echo "$addr"
	fi

	[[ -n "$addr" ]] || return 1
}
#https://en.bitcoin.it/wiki/Wallet_import_format
#https://gist.github.com/t4sk/ac6f2d607c96156ca15f577290716fcc
#http://gobittest.appspot.com/PrivateKey
#https://bitcoin.stackexchange.com/questions/8247/how-can-i-convert-a-sha256-hash-into-a-bitcoin-base58-private-key

#-w generate private key from wif
wifkeyf()
{
	local input pkey
	
	input="$1"

	#check private key prefix
	if [[ "$input" != [59KLc]* ]]
	then
		echo "err: WIF not recognised -- $input" >&2
		return 1
	fi
	
	#Convert it to a string using Base58Check encoding
	pkey="$( decodeBase58 "$input" )"

	#Drop the last 4 checksum bytes from the byte string
	pkey="${pkey%????????}"
	
	#Drop first bytes from the byte string
	pkey="${pkey#??}"

	#Also drop the last byte (it should be 0x01)
	#if it corresponded to a compressed public key
	((OPTW==1)) || pkey="${pkey%??}"

	#verbose
	if (( OPTVERBOSE ))
	then
		#verbose
		cat <<-!
		--------
		WIF_____: $input
		COMPRESS: $( ((OPTW==2)) && echo true || echo false )
		PRIV_KEY: $pkey
		!
	else
		#print private key
		echo "$pkey"
	fi

	[[ -n "$pkey" ]] || exit 1
}

#-x check wif key checksum
wcheckf()
{
	local a b c d cksum hx input

	input="$1"

	#check private key prefix
	if [[ "$input" != [59KLc]* ]]
	then
		echo "err: WIF not recognised -- $input" >&2
		return 1
	fi
	
	#Convert it to a string using Base58Check encoding
	a="$( decodeBase58 "$input" )"

	#Drop the last 4 checksum bytes from the byte string
	b="${a%????????}"
	
	#Drop first byte from the string
	c="${a/$b}"

	#check version byte?
	#does it start with 0x$VER (defaults=0x80) byte?
	d="$( cut -c1,2 <<<"$a" )"
	#if [[ "$d" != "$VER" ]]
	#then
	#	echo "err: version byte from key does not start with 0x$VER -- $1" >&2
	#	return 1
	#fi
	
	#Convert string to byte string and
	#perform SHA-256 hash on the shortened string 
	hx="$(
		pack "$b" |
		openssl dgst -sha256 -binary |
		openssl dgst -sha256 -binary |
		unpack 
	)"
	
	#Take the first 4 bytes of the second SHA-256 hash, this is the checksum 
	cksum="$( head -c8 <<<"$hx" )"

	#uppercase values
	c="${c^^}"
	cksum="${cksum^^}"

	#verbose
	if (( OPTVERBOSE ))
	then
		#verbose
		cat <<-!
		--------
		WIF key checksum check
		INPUT____: $input
		2NDSHA256: $c
		CHECKSUM_: $cksum
		CKVERBYTE: $d
		VER_BYTE_: $VER
		!
	fi

	#print validation result
	#Make sure $cksum matches $c
	#If they are the same, and the byte string from point 2 starts
	#with 0x80 (0xef for testnet addresses), then there is no error
	if [[ "$cksum" == "$c" ]]
	then
		echo "Validation pass -- $1"
	else
		echo "Validation fail -- $1" >&2
		return 1
	fi

	return 0
}

##is public address?
ispubkeyf()
{
	local input
	input="$1"

	#is legacy (P2PKH)?
	if [[ "$input" =~ ^[1][a-km-zA-HJ-NP-Z1-9]{25,34}$ ]]
	then
		echo 'Legacy (P2PKH)'
		return 0
	#is Segwit (P2SH)?
	elif [[ "$input" =~ ^[3][a-km-zA-HJ-NP-Z1-9]{25,34}$ ]]
	then
		echo 'Segwit (P2SH)'
		return 0
	#is native segwit (bech32)?
	elif [[ "$input" =~ ^bc(0([ac-hj-np-z02-9]{39}|[ac-hj-np-z02-9]{59})|1[ac-hj-np-z02-9]{8,87})$ ]]
	then
		echo 'Native segwit (bech32)'
		return 0
	fi

	return 1
}

##is private key?
isprivkeyf()
{
	if [[ "$input" =~ ^[5KL][1-9A-HJ-NP-Za-km-z]{50,51}$ ]]
	then
		echo 'Private address'
		return 0
	fi

	return 1
}


#parse opts
while getopts 126abcehv:ptxwyY c
do
	case $c in
		1)
			#reverse direction
			#print hash160 of string
			OPTREV=1
			;;
		2)
			#generate double sha256 sum
			OPTDSHA=1
			;;
		6)
			#generate hash160
			OPTHASH160=1
			;;
		a)
			#don't make hash160 of input
			OPTHASH=1
			;;
		b)
			#set input/output is byte hex
			OPTBYTE=1
			;;
		c)
			#check public key checksum
			OPTC=1
			;;
		e)
			#verbose
			OPTVERBOSE=1
			;;
		h)
			#print script version
			while read
			do
				[[ "$REPLY" = \#\ v[0-9]* ]] && break
			done < "$0"
			echo "$REPLY"

			#print help
			echo "$HELP"
			exit 0
			;;
		v)
			#byte version
			VER="${OPTARG:-${VERDEF}}"
			VEROPT=1
			;;
		p)
			#make a privy key from seed
			((OPTP++))
			VERDEF="$VERPRIDEF"
			;;
		t)
			#transliterate utf-8 to ascii, with -Y only
			OPTCONV=1
			;;
		x)
			#check wif key checksum
			OPTX=1
			VERDEF="$VERPRIDEF"
			;;
		w)
			#WIF to private key
			((OPTW++))
			;;
		y)
			#decode base58
			ASCIIOPT=2
			;;
		Y)
			#encode base58
			ASCIIOPT=1
			;;
		?)
			#illegal opt
			exit 1
			;;
	esac
done
shift $(( OPTIND - 1 ))
unset c


#required packages
for PKG in openssl xxd
do
	if ! command -v "$PKG" &>/dev/null
	then
		echo "$SN: err  -- $PKG is required" >&2
		exit 1
	fi
done
unset PKG

#check bash version
if (( BASH_VERSINFO[0] < 4 ))
then
    echo "$SN: err  -- bash version 4 or above required" >&2
    exit 1
fi

#set option function
if (( OPTREV ))
then
	#-1 get hash160 from public address
	mainf() { revf "$1" ;}
elif (( ASCIIOPT ))
then
	#-yY encode decode base58
	mainf() { base58f "$1" ;}
elif (( OPTC ))
then
	#-c check public key (address) checksum
	mainf() { checkf "$@" ;}
elif (( OPTP ))
then
	#-p create private key from seed
	mainf() { privkeyf "$@" ;}
elif (( OPTDSHA ))
then
	#-2 generate double sha256 sum
	mainf() { gendsha256f "$1" ;}
elif (( OPTHASH160 ))
then
	#-6 generate hash160
	mainf() { genhash160f "$1" ;}
elif (( OPTW ))
then
	#-w WIF to privy key
	mainf() { wifkeyf "$@" ;}
elif (( OPTX ))
then
	#-x check wif key checksum
	mainf() { wcheckf "$@" ;}
else
	#default option
	#convert hex to public address
	mainf()
	{
		addrf "$1"
	}
fi

#check $VER and incompatible options
if [[ "$VER" = *[a-zA-Z]* ]] ||
	(( ${#VER} > 2 ))
then
	echo "warning: user-set byte version -- $VER" >&2
elif (( VEROPT )) &&
	(( OPTREV || OPTDSHA || OPTHASH160 ))
then
	echo "$SN: err  -- incompatible options" >&2
	exit 1
fi

#consolidate version byte option
VER="${VER:-$VERDEF}"
#drop 0x from start of string
VER="${VER#0x}"

#default function
#loop through strings
#is there any postional argument?
if (( $# ))
then
	for ARG in "$@"
	do mainf "$ARG"
	done
#is stdin taken?
elif [[ ! -t 0 ]]
then
	#dont mangle lines at \\EOL
	#test for non-empty string terminated with null
	while IFS=  read -r || [[ -n "$REPLY" ]]
	do mainf "$REPLY"
	done
else
	#fail
	echo "$SN: user input required" >&2
	exit 1
fi

