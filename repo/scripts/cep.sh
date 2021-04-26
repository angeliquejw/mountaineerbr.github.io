#!/bin/bash
# cep.sh  --  cep por nome de rua e vice-versa
# v0.3.5  feb/2021  by mountaineerbr
# https://github.com/mountaineerbr

#defaults

#script name
SN="${0##*/}"
#script filepath
SCRIPT_PATH="$0"

#help page
HELP="NAME
	$SN - CEP por Nome de Rua e Vice-Versa


SYNOPSIS
	$SN [NOME DO LOGRADOURO|CEP] [ESTADO|BAIRRO]
	$SN [-hv]


DESCRIPTION
	Puxa o CEP de um logradouro pelo seu nome ou puxa o nome
	do logradouro pelo número de CEP.

	Não utilize acentos, número de casa/apto/lote/prédio ou
	abreviações.


SEE ALSO
	Site de CEP dos Correios
	<https://buscacepinter.correios.com.br/app/endereco/index.php?t>

	Tópico de fórum onde idea do script apareceu pela primeira vez
	<https://www.vivaolinux.com.br/topico/Sed-Awk-ER-Manipulacao-de-Textos-Strings/CEP-pela-Shell>


WARRANTY
	Licensed under the GNU Public License v3 or better and
	is distributed without support or bug corrections.
   	
	This script requires ?? and ?? to work properly.

	If you found this useful, please consider sending me a
	nickle!  =)

		bc1qlxm5dfjl58whg6tvtszg5pfna9mn2cr2nulnjr


BUGS
	No máximo 1000 resultados pela API dos Correios.


USAGE EXAMPLES
	$SN Rua Higienopolis Guarulhos
	$SN 07140-190


OPTIONS
	-d 	Debug, print raw json.
	-h 	Help page.
	-v 	Script version."


#functions

#convert latin chars to ascii
convf()
{
	local input set1 set2 set3 set4
	input="$*"

	#ISO Latin 1 character 
	set1='ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿ'
	set2='aaaaaaaceeeeiiiienoooooouuuuypsaaaaaaaceeeeiiiienoooooouuuuypy'
	#ISO Latin 1 Extended A character 
	set3='ĀāĂăĄąĆćĈĉĊċČčĎďĐđĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĦħĨĩĪīĬĭĮįİıĲĳĴĵĶķĸĹĺĻļĽľĿŀŁłŃńŅņŇňŉŊŋŌōŎŏŐőŒœŔŕŖŗŘřŚśŜŝŞşŠšŢţŤťŦŧŨũŪūŬŭŮůŰűŲųŴŵŶŷŸŹźŻżŽžſ'
	set4='aaaaaaccccccccddddeeeeeeeeeegggggggghhhhiiiiiiiiiiiijjkkkllllllllllnnnnnnnnnoooooooorrrrrrssssssssttttttuuuuuuuuuuuuwwyyyzzzzzzs'

	<<<"$input" sed -e "y/${set1}/${set2}/" -e "y/${set3}/${set4}/"
}
#https://docs.oracle.com/cd/E29584_01/webhelp/mdex_basicDev/src/rbdv_chars_mapping.html
#https://stackoverflow.com/questions/10207354/how-to-remove-all-of-the-diacritics-from-a-file
#iconv -f utf-8 -t ascii//translit

#main
mainf()
{
	local input pvar pini pfim url data t

	#retirar espaços em branco e acentos do input
	input="$(convf "$@" | tr \  +)"
	
	#bucar resultados
	pvar=50  pini=1  pfim="$pvar"
	while
		url="https://buscacepinter.correios.com.br/app/endereco/carrega-cep-endereco.php?pagina=%2Fapp%2Fendereco%2Findex.php&cepaux=&mensagem_alerta=&endereco=${input}&tipoCEP=ALL&inicio=${pini}&final=${pfim}"
		data="$( curl -L -\# "$url" | jq -er . 2>/dev/null )"
	do
		#dump data?
		if (( OPTDEBUG ))
		then
			echo "$data"
			continue
		fi

		#error message in json?
		if jq -e .erro <<<"$data" &>/dev/null
		then
			jq .mensagem <<<"$data" >&2
			return 1
		fi

		t="$(jq -r .total <<<"$data")"
		(( pini = pini + pvar ))
		(( pfim = pfim + pvar ))

		#format data in tables
		<<<"$data" jq -r '.dados[] | "\(.cep)\t\(.uf)\t\(.localidade)\t\(.bairro)\t\(.logradouroDNEC)\t\(.numeroLocalidade)\t\(.logradouroTextoAdicional)\t\(.nomeUnidade)\t\(.situacao)"' |
			column -dts$'\t' -N1,2,3,4,5,6,7,8,9 -T4,7,8,9 |
 			sed 's/\s*$//'
		
		if (( pfim > t ))
		then
			jq -r .mensagem <<<"$data" | grep -vi sucesso && return 1
			return 0
		fi

		#tente evitar throttle
		sleep 0.6
	done
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

