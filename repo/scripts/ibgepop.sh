#!/bin/bash
# ibgepop.sh - população nacional/regional do Brasil
# v0.2 feb/2021  by mountaineerbr
# https://github.com/mountaineerbr

#defaults

#script name
SN="${0##*/}"
#script filepath
SCRIPT_PATH="$0"

#help page
HELP="NAME
	$SN - População nacional/regional do Brasil


SYNOPSIS
	$SN [ID|REGIÃO|ESTADO]
	$SN [-hv]


DESCRIPTION
	Puxa dados do IBGE com relação a população brasileira por
	estado, região ou nacional.

ETIQUETAS
	id 			número de identificação interno do ibge
	incrementoPopulacional 	período médio em millisegundos
				para a população aumentar em uma unidade
	nascimento 		período médio entre nascimentos
	obito 			período médio entre óbitos


SEE ALSO
	Site original do IBGE
	<https://servicodados.ibge.gov.br/api/docs/projecoes>


WARRANTY
	Licensed under the GNU Public License v3 or better and
	is distributed without support or bug corrections.
   	
	This script requires ?? and ?? to work properly.

	If you found this useful, please consider sending me a
	nickle!  =)

		bc1qlxm5dfjl58whg6tvtszg5pfna9mn2cr2nulnjr


BUGS


USAGE EXAMPLES
	$SN são paulo
	$SN brasil


OPTIONS
	-d 	Debug, print raw json.
	-h 	Help page.
	-v 	Script version."


#functions

mainf()
{
	local id input

	input="$*"
	id="$( sed 'y:aáãíô:aaaio:; s: ::g' <<< "$input" | tr A-Z a-z )"
	
	case "$id" in
		n|norte)	id=1;;		ne|nordeste)	id=2;;
		se|sudeste)	id=3;;		s|sul)	id=4;;
		co|centrooeste)	id=5;;		ro|rondonia)	id=11;;
		ac|acre)	id=12;;		am|amazonas)	id=13;;
		ro|roraima)	id=14;;		pa|para)	id=15;;
		ap|amapa)	id=16;;		to|tocantins)	id=17;;
		ma|maranhão)	id=21;;		pi|piaui)	id=22;;
		ce|ceara)	id=23;;		rn|riograndedonorte) id=24;;
		pb|paraiba)	id=25;;		pe|pernambuco)	id=26;;
		al|alagoas)	id=27;;		se|sergipe)	id=28;;
		bh|bahia)	id=29;;		mg|minasgerais)	id=31;;
		as|espiritosanto) id=32;;	rj|riodejaneiro) id=33;;
		sp|saopaulo)	id=35;;		pr|parana)	id=41;;
		sc|santacatarina) id=42;;	mt|matogrosso)	id=51;;
		rs|riograndedosul) id=43;;	ms|matogrossodosul) id=50;;
		go|goias)	id=52;;		df|distritofederal) id=53;;
		br|brasil) 	unset id;;
	esac
	[[ ! "$id" =~ ^[0-9]+$ ]] && [[ -n "$id" ]] && return 1

	#puxar dados
	json="$(curl --compressed "https://servicodados.ibge.gov.br/api/v1/projecoes/populacao/$id")"
	
	#dump data?
	if (( OPTDEBUG ))
	then
		echo "$json"
		return 0
	fi

	#processa dados
	<<<"$json" jq -r '"",
			"Projeção",
			"LocalID: \(.localidade)",
			"Horário: \(.horario)",
			(.projecao|
				"Populaç: \(.populacao)",
				(.periodoMedio|
				(.incrementoPopulacional | if . != null then  "IncrPop: \(.)ms  \(. /1000)s" else empty end),
				(.nascimento | if . != null then "Nascmts: \(.)ms  \(. /1000)s" else empty end),
				(.obito | if . != null then "Obitos_: \(.)ms  \(. /1000)s" else empty end)
				)
			)'

	echo "Input__: $input"
}


#parse options
while getopts :dhv c
do case $c in
	d) OPTDEBUG=1 ;;
	h) echo "$HELP"; exit 0	;;
	v) grep -m1 '^# v[0-9]' "$0" ;exit ;;
   esac
done
shift $(( OPTIND - 1 ))
unset c

#check arguments
if [[ -z "${*// }" ]]
then echo "$HELP" ;exit 1
fi

#required packages
for pkg in curl jq
do if ! command -v "$pkg" &>/dev/null
   then echo "$SN: err  -- $pkg is required" >&2 ;exit 1
   fi
done
unset pkg

#call opt functions
#main function
mainf "$@"

