#!/bin/bash
# download satellite images from
# Brazilian National Institute of Meteorology
# <https://satelite.inmet.gov.br/>
# by mountaineerbr  jul/2021
# requires curl and jq
# usage: $  inmet.sh  2020-12-15


#choose which image sets to download
URLS=(
	https://apisat.inmet.gov.br/GOES/AS/IV 		#GOES
	#https://apisat.inmet.gov.br/GOESIM/BR/CH 	#GOES+SIMSAT
	#https://apisat.inmet.gov.br/MSG/GL/PHPA 	#GOES+MSG
	#https://apisat.inmet.gov.br/SATELITE/AS/P 	#SATELITE+COSMOS
)

#date
DATE="${1:-$(date -I)}"
#DATE=2020-12-15

#results directory
RESULTDIR=INMET
RESULTDIR="${PWD%/$RESULTDIR}/$RESULTDIR"

#maximum async jobs
JOBMAX=10

#temp buffers
TMPD="$( mktemp -d )" || exit


#clean func
cleanf()
{
	trap \  INT HUP EXIT

	pkill -P $$

	wait
	[[ -d "$TMPD" ]] && rm -rf "$TMPD"

	echo -e "\nresults at -- $RESULTDIR"
	exit 0
}


#trap cleaning
trap cleanf INT HUP EXIT

#ckeck/make results dir
[[ -d "$RESULTDIR" ]] || mkdir "$RESULTDIR" || exit

for url in "${URLS[@]}"
do
	((m++))
	data="$TMPD/data.$m.json"
	
	echo
	#dl json+base64  data
	curl -L -o "$data" --compressed "$url/$DATE" || exit

	#get ids
	IDS=( $(jq -r '.[].id' "$data" ) )

	n=0
	for i in "${IDS[@]}"
	do
		((n++))

		#asynchronous
		{
			#buffer file
			buf="$TMPD/$m.$n.buffer.json"

			jq -r ".[]|select(.id==$i)" "$data" > "$buf"

			nome="$(jq -r '"\(.nome)_\(.satelite // "sat")"' "$buf")"
			#ext="$( jq -r '.base64' "$buf" | cut -f1 -d\; | cut -f2 -d/ )"
			ext=jpg
			tgt="$RESULTDIR/$nome.$ext"

			[[ -e "$tgt" ]] ||
				jq -r '.base64' "$buf" | cut -f2 -d, | base64 -di > "$tgt"
		} &

		echo -ne "url: $m/${#URLS[@]}  file: $n/${#IDS[@]}  \r"

		#job control (bash)
		while jobs=( $(jobs -p) ) ;((${#jobs[@]} > JOBMAX))
		do sleep 0.04
		done
	done

	wait
done

