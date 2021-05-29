#!/bin/zsh
#walletexplorer.com wrapper
# v0.2.1  by mountaineerbr

HELP="walletexplorer.com wrapper
usage: wexplorer a [address|walletid] [csv]
usage: wexplorer w [address|walletid]
usage: wexplorer t txid
options:
	a - all transactions from an address
	w - all addresses from a wallet
	t - check a transaction
very slow api. w3m and gunzip are required.
<https://www.walletexplorer.com>"

SLEEP=1.6

sedwidf()
{
	sed -En 's/<title>([^ ]+).*/\1/p'
}

widf()
{
	w3m -dump_source "https://www.walletexplorer.com/?q=$1" | gunzip -c | sedwidf
}

#help page
if [[ "$1" = help ]] || [[ "$1" = -h* ]]
then
	echo "$HELP"
	exit 0
#more than 2 arguments required
elif [[ -z "$2" ]]
then
	echo "$HELP"
	echo "more arguments required" >&2
	exit 1
#is requesting csv with the right option?
elif [[ "$3" = csv ]] && [[ "$1" != *[tw]* ]] 
then
	comp2='?format=csv'
fi

#select options
#set option url
case "$1" in
	#transactions from an address
	address | addr | a)
		if (( ${#2} > 30 ))
		then
			if [[ -n "$comp2" ]]
			then
				#get wallet id
				wid="$( widf "$2" )"
				set -- "$1" "$wid"
				uri="wallet/$2"
			else
				uri="?q=$2"
			fi
		else
			uri="wallet/$2"
		fi
		;;
	#wallet addresses by wallet id
	wallet | wal | w)
		if (( ${#2} > 30 ))
		then
			#get wallet id
			wid="$( widf "$2" )"
			set -- "$1" "$wid"
		fi
		uri="wallet/$2/addresses"
		;;
	#look up a transaction by id
	transaction | txid | tx | t)
		uri="txid/$2"
		;;
	*)
		echo "bad option" >&2
		exit 1
		;;
esac

uri="$uri$comp$comp2"
page="$( w3m -dump_source "https://www.walletexplorer.com/$uri" )"

if grep -ai "too many requests" <<< "$page"
then
	exit 1
elif [[ -n "$comp2" ]]
then
	echo "$page"
	
	pagen="$( head -n 1 <<< "$page" | sed -r 's/^.*page 1 from ([0-9]+),.*$/\1/' )"
	
	#loop
	for n in $( seq 2 "$pagen" )
	do
		w3m -dump_source "https://www.walletexplorer.com/wallet/$wid${comp2}&page=${n}"
		sleep $SLEEP
	done

	exit 0
else
	#bash has some problems here with zipped content in the variable
	page="$( gunzip -c <<< "$page" 2>/dev/null )"
fi

#how many result pages?
[[ -z "$pagen" ]] && pagen="$( sed -En 's/.*Page [0-9]+ \/ ([0-9]+).*/\1/p' <<< "$page" | head -1 )"
#get wallet id
[[ -z "$wid" ]] && wid="$( sedwidf <<< "$page" )"

#process data
w3m -dump -cols 160 -T text/html <<< "$page" | sed '1,3d ; /^©/,$d'
echo "wallet id: $wid"
echo "https://www.walletexplorer.com/$uri"
echo

#request multiple result pages
if (( pagen > 1 )) && [[ "$1" != *t* ]]
then
	#set wallet id
	set -- "$1" "$wid"

	#loop
	for n in $( seq 2 "$pagen" )
	do
		pagen=1
		if [[ "$1" = *w* ]]
		then
			comp="/wallet/?page=$n"
		else
			comp="?page=$n"
		fi
	
		export comp pagen

		"$0" "$1" "$2" #|| break
		sleep $SLEEP
	done
fi
		
