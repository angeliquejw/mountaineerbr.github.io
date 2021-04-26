#!/bin/bash
# hgbrasil.sh -- Dados financeiros do HG Brasil Finance
# v0.4.6  aug/2020  by mountaineer_br

#sua chave de api grátis do hg brasil
#HGBAPIKEY=
export HGBAPIKEY

#make sure locale is set correctly
export LC_NUMERIC=C

HELP="NOME
	hgbrasil.sh -- Dados financeiros do HG Brasil Finance


SINOPSE
	hgbrasil.sh 
	hgbrasil.sh SÍMBOLO
	hgbrasil.sh [-lhv]
	

	Este script puxa dados das principais cotações de moedas, ações da Bo-
	vespa e taxas CDI e SELIC das APIs do <hgbrasil.com/>.

	A opção padrão é uma visão geral do mercado e não requer uma chave de
	API e nenhum argumento para o script.

	Para puxar preços de ações específicas e das taxas de CDI e Selic, é
	necessária a criação de uma chave de API grátis em
	<console.hgbrasil.com/keys>.


AMBIENTE E CHAVE DE API
	Defina a variável de ambiente \$HGBAPIKEY com sua chave de api.

	Foi incluida uma chave de acesso do desenvolvedor para fins de de-
	monstrações. Ela poderá ser limitada ou bloquada a qualquer momento.


GARANTIA
	Este programa/script é software livre e está licenciado sob a Licença
	Geral Pública v3 ou superior do GNU. Sua distribuição não oferece 
	suporte nem correção de bugs.
	
	O script precisa do cURL/Wget, JQ, Gzip e Bash.

	If this programme was useful, consider sending me a nickle! =)
  
	Se este programa foi útil, considere me lançar um trocado!

		bc1qlxm5dfjl58whg6tvtszg5pfna9mn2cr2nulnjr


EXONERAÇÃO DE RESPONSABILIDADE
	Extraído do website <console.hgbrasil.com/documentation/finance>:
	
		\"API para fins informativos. Não garantimos a precisão dos
		dados fornecidos pela API ou contidos nesta página, uma vez
		que devem ser utilizados apenas para efeitos informativos.
		Trabalhamos pela estabilidade e precisão dos dados, porém, os
		dados podem estar atrasados ou errados 'no estado em que se
		encontram', confirme todos os dados antes de efetuar qualquer
		ação que possa ser afetada por estes valores, assim como de-
		mais endpoints da API.\"


	Termos de uso em: <console.hgbrasil.com/terms>


OPÇÕES
	-h 	Mostra esta ajuda.
	-j 	Debug, imprime json.
	-l 	Lista de ações.
	-v 	versão do script."

#visão geral do mercado
hgb() {
	#api público
	# Puxar JSON
	local HQRES="$(curl -s "https://api.hgbrasil.com/finance")"
	
	#print json?
	if [[ -n  "${PJSON}" ]]; then
		printf "%s\n" "${HQRES}" 
		exit 0
	fi

	printf "HG Brasil -- Visão Geral\n"
	
	#moedas
	#printf '\nMoedas\n'
	printf '\n'
	jq -r '.results.currencies[]' <<<"${HQRES}"| sed 1d | jq -r '"\(.name)=\(.variation//"??")=\(.sell//"??")=\(.buy//"??")"' | column -et -s= -N'MOEDA,VAR%,VENDA,COMPRA' 
	
	#indexes
	#printf '\nÍndices\n'
	printf '\n'
	jq -r '(.results.stocks[] | "\(.name)=\(.variation//"??")=\(.points//"??")")'<<<"${HQRES}" | sed 's/Stock Market//g' | column -et -s= -N'ÍNDICE,VAR%,PONTOS' 
	
	#tax rates
	if [[ -z "${HGBAPIKEY}" ]]; then
		printf '\nCDI, SELIC e fator diário requer uma chave de API.\n' 1>&2
	else
		printf '\nTAXAS\n'
		curl -s "https://api.hgbrasil.com/finance/taxes?key=${HGBAPIKEY}" |
			jq -r '.results[]|
				"CDI__: \(.cdi)",
				"SELIC: \(.selic)",
				"F_DIA: \(.daily_factor)",
				"DATA_: \(.date)"'
	fi
}

# -a cotações - uma ação/ativo específico
hga() {
	#get data
	local HQRES="$(curl -s "https://api.hgbrasil.com/finance/stock_price?key=${HGBAPIKEY}&symbol=${1,,}")"
	
	#print json?
	if [[ -n  "${PJSON}" ]]; then
		printf "%s\n" "${HQRES}"
		exit 0
	fi

	#more checking
	if jq -er ".results[].error" <<<"${HQRES}" >/dev/null; then
		jq -r ".results[].message" <<<"${HQRES}"
		exit 1
	fi

	#process data and print
	jq -r '.from_cache as $i|
		.results[] |
			"\(.symbol)  \(.name)",
			.region,
			"Atualiza: \(.updated_at)",
			"UsaCache: \(if $i == true then "Sim" else "Não" end)",
			"MktCapit: \(.market_cap)",
			"Abertura: \(.market_time.open)",
			"Fechamen: \(.market_time.close)",
			"Variação: \(.change_percent)%",
			"Preço___: \(.price)"'<<<"${HQRES}"
}

#lista de títulos
listf() {
	#get data
	DATA="$(curl -s "https://console.hgbrasil.com/documentation/finance/symbols")"
	
	#print json?
	if [[ -n  "${PJSON}" ]]; then
		printf "%s\n" "${DATA}" 1>&2
		exit
	fi

	#make sumbol list
	LIST="$(sed 's/<[^>]*>//g' <<<"${DATA}" | grep --color=auto -- '-\s[A-Z0-9][A-Z0-9]*$')"
	
	#process and print data
	sed 's/^\(.*[ -].*\)\s\-\s\(.*\)$/\2=\1/g' <<<"${LIST}" | sort | column -ets= -NTÍTULO,NOME
	printf "Títulos: %s\n" "$(wc -l <<<"${LIST}")"
	printf "<console.hgbrasil.com/documentation/finance/symbols>\n"
 }

#parse options
while getopts ":hjlv" opt; do
	case ${opt} in
		( h ) # Help
			printf '%s\n' "${HELP}"
			exit 0
			;;
		( j ) #print json
			PJSON=1
			;;
		( l ) # List symbols
			LOPT=1
			;;
		( v ) # Version of Script
			grep -m1 '\# v' "${0}"
			exit 0
			;;
		( \? )
			printf "Invalid option: -%s\n" "${OPTARG}" 1>&2
			exit 1
			;;
	esac
done
shift $((OPTIND -1))

#test for some must have packages
if command -v curl &>/dev/null; then
	YOURAPP='curl -sL --compressed'
elif command -v wget &>/dev/null; then
	YOURAPP="wget -qO-"
else
	printf "cURL ou Wget é requerido.\n" 1>&2
	exit 1
fi

#request compressed response
if ! command -v gzip &>/dev/null; then
	printf 'warning: gzip may be required\n' 1>&2
fi


#call opt func
#list stock symbols
if [[ -n "${LOPT}" ]]; then
	listf
#test for jq
elif ! command -v jq &>/dev/null; then
	printf "JQ is required.\n" 1>&2
	exit 1
#default func, market overview
elif [[ -z "${1}" ]]; then
	hgb
#test for API key
elif [[ -z "${HGBAPIKEY}" ]]; then
	#printf 'Cotação de ações requer uma chave de API.\n' 1>&2
	#exit 1
	
	#dev demo key
	HGBAPIKEY=f2e2b379
#stock price
else
	hga "${1}"
fi

