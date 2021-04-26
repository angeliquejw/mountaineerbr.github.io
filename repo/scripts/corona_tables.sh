#!/bin/zsh

#target dir
TDIR="${1:-${PWD}}"

#table folder name
DIR="$TDIR/reutersTables"

#modified from corona_func.sh
corona() {
	local flag=-n flag2=-r flag3=-c150
	local opt sort data update keys stats

	#opts
	getopts r opt && unset flag2 && shift

	#is output being redirected?
	[[ -t 1 ]] && unset flag3
	
	#sort order
	[[ "$1" = [1-7] ]] || set -- 1
	case "$1" in
		1) sort=CASES;;
		2) sort=DEATHS;;
		3) sort=RECOVERED;;
		4) sort=POPULATION;;
		5) sort=LETALITY%;;
		6) sort=LETALITY/100K;;
		7) sort=LOCATION; unset flag;;
	esac
		
	#get data if empty
	if [[ -z "$data" ]]
	then
		data="$( curl -sL 'https://graphics.thomsonreuters.com/data/2020/coronavirus/tracking/global/data.json' )" 
	fi

	#set vars
	update="$( jq -r '.lastUpdated' <<< "$data" )"

	keys="$( jq -r '.countries|keys_unsorted[]' <<< "$data" )"

	stats="$( jq -r '.countries[] | "\(.cases[-1])\t\(.deaths[-1])\t\(.recovered[-1])\t\(.population)\t\(((.deaths[-1]/.cases[-1])*100) | tostring | .[0:6] )%\t\(((.deaths[-1]/.population)*100000) | tostring | .[0:7] )" ' <<<"$data" )"

	echo "updated__: $update"
	echo "sorted_by: $sort"
	echo 'source___: reuters news agency'

	paste <( echo "$stats") <( echo "$keys" ) |
		sort ${flag} ${flag2} -t$'\t' -k"$1" | nl -s$'\t' -w1 |   #tac | 
		column ${flag3} -ets$'\t' -N'RNK,CASES(1),DEATH(2),REC(3),POP(4),LET%(5),LET/100K(6),LOC(7)' -T'LOC(7)'
}

#check target dir
if [[ -d "$DIR" ]]
then
	\mv "$DIR" "${DIR}.$( date +%s )" 
fi

#make parent dirs
mkdir -p "$DIR"

#update timestamp
data="$( curl -L 'https://graphics.thomsonreuters.com/data/2020/coronavirus/tracking/global/data.json' )" 
export data

echo "$data" > "$DIR/data.json"

#make tables
for SORT in cases deaths recovered population letalityPerCent letality100KInhabitants location
do
	(( ++COUNTER ))
	echo "sorting by ${SORT}.." >&2

	corona "$COUNTER" > "$DIR/corona.${COUNTER}.${SORT}.txt"
done
wait

echo ''
echo "$DIR"

