#!/bin/bash
# Brasilbtc.sh -- Puxa Taxas de Bitcoin de Exchanges do Brasil
# v0.6.9  dec/2020  by mountaineerbr

#defaults

#retries in case of temporary failures
RETRIES=2

#timeout to estabilish connection
TIMEOUT=8

#user agent
UAG='user-agent: Mozilla/5.0 Gecko'
#UAG='User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.106 Safari/537.36'

#make sure locale is set correctly
export LC_NUMERIC=C

## Manual and help
# Uso: brasilbtc.sh [MOEDA] #Ex: btc, eth ltc
HELP_LINES="NOME
 	Brasilbtc.sh -- Puxa Taxas de Bitcoin/Criptos de Exchanges do Brasil


SINOPSE
	brasilbtc.sh [-mm] [CÓDIGO_CRIPTO]

	brasilbtc.sh [-bbchjv]


DESCRIÇÃO
	O script puxa as cotações de algumas agências de câmbio brasileiras.
	Por padrão, puxará as taxas para o Bitcoin. Quando fornecido o código
	de outra cripto, os resultados serão exibidos somente caso ela seja
	suportada em cada uma das agências de câmbio. Alguns APIs só oferecem
	cotações para o Bitcoin e somente algumas agências de câmbio são
	suportadas.

	Caso não seja fornecido nenhum argumento algum para o script, serão
	puxados tickeres do BitValor, BitVerse e CoinTrader, que comtemplam
	várias agências de câmbio. Pode-se puxar as cotações de somente um dos
	APIs, veja opções.
	
	Somente os valores dos tickeres diretamente das APIs da agências de
	câmbio são usado para produzir a média e estatísticas básicas da
	opção '-m'.

	No ticker do CoinTrader, a coluna 'RNK' (rank) é o ranque por volume
	de mercado 'MS' (market size) de cada agência.

	O nome do script em Bash (Brasilbtc.sh) não tem relação com qualquer
	agência de câmbio com nome eventualmente parecido!

	Veja também:
		<cointradermonitor.com/preco-bitcoin-brasil>
		<guiadoinvestidor.com.br/melhores-exchanges-de-bitcoin-do-brasil-2019-2020>

	
GARANTIA
	Licenciado sob a GPLv3 e superior. Este programa é distribuído sem
	suporte ou correções de bugs.

	Se este script foi útil, por favor considere me dar um trocado!
		=)

		 bc1qlxm5dfjl58whg6tvtszg5pfna9mn2cr2nulnjr

	
	São necessários os pacotes Curl (preferível) ou Wget, Jq e Bash.


IMPORTANTE
	Cuidado com agências de câmbio golpistas! Faça seus estudos! Não reco-
	mendamos nenhuma em particular. São suspeitas no momento e de meu co-
	nhecimento: 3xBit, AltasQuantum, HitBtc, NanuExchange, NegocieCoins, 
	NoxBitcoin Nanu Exchange e TemBTC. Provavelmente muitas outras
	também.

	Nas estatísticas do <coingecko.com>, somente as agências 3xBit,
	Brasiliex, NanuExchange, Mercado Bitcoin e Novadax estão listadas.
	Porém, somente três delas receberam uma nota (score): Braziliex rece-
	beu '2', Mercado Bitcoin '6' e Novadax recebeu '7'. É uma pista de
	quais agências de câmbio brasileiras devem ser as mais confiáveis..


OPÇÕES
		-b 	Somente API do BitValor (bitcoin).
		
		-bb 	Somente API do Bitverso (bitcoin).
		
		-c 	Somente API do CoinTrader (bitcoin).

		-h 	Mostra esta página de ajuda.

		-j 	Debug.

		-m 	Média e estatísticas básicas das cotações puxadas
			diretamente das apis.

		-mm 	Como opção '-m', porém somente o valor da média.

		-v 	Mostra versão deste programa."

#test if $RATE is non-zero
testratef()
{
	((${RATE//[0.]}>0)) &&
		[[ "$RATE" != null ]]
}

apiratesf() {
	# Exchanges e Valores

	## 3xBIT
	#RATE="$("${YOURAPP[@]}" "https://api.exchange.3xbit.com.br/ticker/" | jq -r ".BRL_${1^^}.ask")"
	#testratef && printf "%'.2f\t3xBIT\n" "${RATE}"
	#https://github.com/3xbit/docs/blob/master/exchange/public-rest-api-en_us.md
	
	## AtlasQuantum -- api returns Forbidden message
	#[[ "${1^^}" = "BTC" ]] && printf "%'.2f\tAtlasQuantum\n" "$("${YOURAPP[@]}" 'https://19py4colq0.execute-api.us-west-2.amazonaws.com/prod/price' | jq -r '.last')"
	#https://atlasquantum.com/
	
	## BitBlue
	[[ "${1^^}" =~ ^(BTC|ETH|DASH)$ ]] && {
		RATE="$("${YOURAPP[@]}" "https://bitblue.com/api/transactions?market=${1,,}&currency=brl" | jq -r '.[].data[0].price')"
		testratef && printf "%'.2f\tBitBlue\n" "$RATE"
	}
	#https://bitblue.com/api-docs.php
	unset RATE

	## BitCambio
	[[ "${1^^}" = BTC ]] && {
		RATE="$("${YOURAPP[@]}" "https://bitcambio_api.blinktrade.com/api/v1/BRL/ticker" | jq -r '.last')"
		testratef && printf "%'.2f\tBitCambio\n" "$RATE"
	}
	#https://bitcambiohelp.zendesk.com/hc/pt-br/articles/360006575172-Documenta%C3%A7%C3%A3o-para-API
	#https://blinktrade.com/docs/?shell#ticker
	unset RATE
	
	## BitcoinToYou -- litecoin does not work anymore
	#[[ "${1,,}" = "ltc" ]] && BTYN="_litecoin"
	#if [[ "${1,,}" = "btc" ]]; then
	#	RATE="$("${YOURAPP[@]}" "https://api_v1.bitcointoyou.com/ticker${BTYN}.aspx" | jq -r '((.buy|tonumber)+(.sell|tonumber))/2')"
	#	testratef && printf "%'.2f\tBitcoinToYou\n" "${RATE}"
	#fi
	#https://www.bitcointoyou.com/blog/api-b2u/
	#unset RATE
	
	## BitcoinTrade
	RATE="$("${YOURAPP[@]}" "https://api.bitcointrade.com.br/v2/public/BRL${1^^}/ticker" | jq -r '.data.last')"
	testratef && printf "%'.2f\tBitcoinTrade\n" "${RATE}"
	#https://apidocs.bitcointrade.com.br/?version=latest#e3302798-a406-4150-8061-e774b2e5eed5
	unset RATE
	
	#bit nuvem
	[[ "${1^^}" = BTC ]] && {
		RATE="$("${YOURAPP[@]}" "https://bitnuvem.com/api/BTC/ticker" | jq -r '.ticker.last')"
		testratef && printf "%'.2f\tBitNuvem\n" "$RATE"
	}
	#https://bitnuvem.com/api
	unset RATE

	## bitPreço
	RATE="$("${YOURAPP[@]}" "https://api.bitpreco.com/${1,,}-brl/ticker" | jq -r '.last')"
	testratef && printf "%'.2f\tBitPreço\n" "${RATE}"
	#https://bitpreco.com/api.html
	unset RATE

	#BitRecife
	RATE="$("${YOURAPP[@]}" "https://exchange.bitrecife.com.br/api/v3/public/getticker?market=${1^^}_BRL" | jq -r '.result[].Last')"
	testratef && printf "%'.2f\tBitRecife\n" "${RATE}"
	#https://app.swaggerhub.com/apis-docs/bleu/white-label/3.0.0#/Public%20functions/getMarkets
	unset RATE

	## BrasilBitcoin
	RATE="$("${YOURAPP[@]}" "https://brasilbitcoin.com.br/API/prices/${1^^}" | jq -r '.last')"
	testratef && printf "%'.2f\tBrasilBitcoin\n" "${RATE}"
	#
	unset RATE
	
	## Braziliex
	RATE="$("${YOURAPP[@]}" "https://braziliex.com/api/v1/public/ticker/${1,,}_brl" | jq -r '.last')"
	testratef && printf "%'.2f\tBraziliex\n" "${RATE}"
	#https://braziliex.com/exchange/api.php
	unset RATE

	## Citicoin
	RATE="$("${YOURAPP[@]}" "https://api.citcoin.com.br/v1/${1,,}/ticker/" | jq -r '.close')"
	testratef && printf "%'.2f\tCitiCoin\n" "${RATE}"
	#https://www.citcoin.com.br/api/
	unset RATE

	## CoinNext
	case "${1^^}" in
		BTC ) CN=1;;
		LTC ) CN=2;;
		ETH ) CN=4;;
		XRP ) CN=6;;
	esac
	# Get rate functions
	RATE="$(
		post='{"OMSId": 1, "InstrumentId": '"${CN}"', "Depth": 1}'
		url='https://api.coinext.com.br:8443/AP/GetL2Snapshot'
		if [[ "$YOURAPP" =~ curl ]]; then
			curl -s -X POST -d "$post" "$url"
		else
			wget -qO- --post-data="$post" "$url"
		fi |
			jq '.[0]|.[4]'
	)"
	testratef && printf "%'.2f\tCoinNext\n" "${RATE}"
	#https://coinext.com.br/api.html
	unset CN RATE
	
	#coin trader cx
	RATE="$("${YOURAPP[@]}" "https://api.cointradecx.com/public/ticker?market=${1^^}_BRL" | jq -r '.result[].last')"
	testratef && printf "%'.2f\tCoinTraderCX\n" "$RATE"
	#https://docs.cointradecx.com/
	unset RATE

	## FlowBTC -- ONLY WEBSOCKET SEEMS TO BE WORKING! jan/2020
	#RATE="$("${YOURAPP[@]}" "https://publicapi.flowbtc.com.br/v1/ticker/${1^^}BRL" | jq -r '.data.LastTradedPx')"
	#[[ -n "${RATE}" ]] && [[ "${RATE}" != "0" ]] &&
	#	[[ "${RATE}" != "null" ]] &&
	#	printf "%'.2f\tFlowBTC\n" "${RATE}"
	#https://www.flowbtc.com.br/api.html
	
	## Foxbit
	RATE="$("${YOURAPP[@]}" "https://watcher.foxbit.com.br/api/Ticker/" | jq -r '.[]|"\(.createdDate) \(.currency) \(.sellPrice)"' | sort -rn | grep -im1 "BRLX${1^^}" | cut -d' ' -f3)"
	testratef && printf "%'.2f\tFoxBit\n" "${RATE}"
	#https://foxbit.com.br/grafico-bitcoin/
	unset RATE
	
	## MercadoBitcoin
	RATE="$("${YOURAPP[@]}" "https://www.mercadobitcoin.net/api/${1^^}/ticker/" | jq -r '.ticker.last')"
	testratef && printf "%'.2f\tMercadoBitcoin\n" "${RATE}"
	#https://www.mercadobitcoin.com.br/api-doc/
	unset RATE
	
	## NegocieCoins -- Provavelmente é Golpe!
	#printf "%'.2f\tNegocieCoins\n" "$("${YOURAPP[@]}" "https://broker.negociecoins.com.br/api/v3/${1,,}brl/ticker" | jq -r '.last')"
	#https://www.negociecoins.com.br/documentacao-api

	#Nanu Exchange
	#if RATE="$("${YOURAPP[@]}" "https://nanu.exchange/public?command=returnTicker&currencyPair=BRL_BTC" | jq -er 'select(.currencyPair == "BRL_'${1^^}'")|.last')"; then
	#	printf "%'.2f\tNanu\n" "${RATE}"
	#fi
	#https://nanu.exchange/documentation
	#unset RATE

	## NovaDAX
	RATE="$("${YOURAPP[@]}" "https://api.novadax.com/v1/market/ticker?symbol=${1^^}_BRL" | jq -r '.data.lastPrice')"
	testratef && printf "%'.2f\tNovaDAX\n" "${RATE}"
	#https://doc.novadax.com/pt-BR/#get-latest-tickers-for-all-trading-pairs
	unset RATE

	## NoxBitcoin
	[[ "${1^^}" = BTC ]] && {
		RATE="$("${YOURAPP[@]}" 'https://charlie.noxbitcoin.com.br/public/api/v1/prices' | jq -r '.last_price')"
		testratef && printf "%'.2f\tNoxBitcoin\n" "$RATE"
	}
	#https://www.noxbitcoin.com.br/
	unset RATE
	
	## TEMBTC --> Em processo judicial
	#RATE="$("${YOURAPP[@]}" "https://broker.tembtc.com.br/api/v3/${1,,}brl/ticker" | jq -r '.buy')"
	#testratef && printf "%'.2f\tTEMBTC\n" "${RATE}"
	#https://www.tembtc.com.br/api
	
	## OmniTrade -- closed
	#RATE="$("${YOURAPP[@]}" "https://omnitrade.io/api/v2/tickers/${1,,}brl" | jq -r '.ticker.last')"
	#testratef && printf "%'.2f\tOmniTrade\n" "${RATE}"
	#https://help.omnitrade.io/pt-BR/articles/1572451-apis-como-integrar-seu-sistema

	## Pagcripto  ##POR ENQUANTO SÓ RETORNA VALOR DE BTC MESMO NA APIv2!!
	[[ "${1^^}" = BTC ]] && {
		RATE="$("${YOURAPP[@]}" "https://api.pagcripto.com.br/v2/public/ticker/${1^^}BRL" | jq -r '.data.last')"
		testratef && printf "%'.2f\tPagCripto\n" "${RATE}"
	#https://docs.pagcripto.com.br/?version=latest
	}
	unset RATE

	## Profitfy  #PASSOU A PEDIR CHAVE DE API 
	#RATE="$("${YOURAPP[@]}" "https://profitfy.trade/api/v1/public/ticker/${1,,}/brl" | jq -r '.[].last')"
	#testratef && printf "%'.2f\tProfitfy\n" "${RATE}"
	#https://profitfy.trade/Home/Api
	#unset RATE


	#youbtrade
	RATE="$("${YOURAPP[@]}" "https://youbtrade.com.br/datafeed/history?symbol=TICKER${1^^}%2FBRL&resolution=60&from=${unix}&to=${unix}" | jq -r '.l[-1]')"
	testratef && printf "%'.2f\tYouBTrade\n" "${RATE}"
	#https://youbtrade.com.br/market/pair/BTC-BRL
	unset RATE

	## Walltime
	[[ "${1^^}" = BTC ]] && {
		RATE="$("${YOURAPP[@]}" "https://s3.amazonaws.com/data-production-walltime-info/production/dynamic/walltime-info.json" | jq -r '(.BRL_XBT.last_inexact)')"
		testratef && printf "%'.2f\tWalltime\n" "$RATE"
	}
	#https://walltime.info/api.html#orgaa3116b
	unset RATE
}

bitvalorf() {
	## BitValor (Análise de Agências de Câmbio do Brasil)
	
	# Nome das exchanges analisadas pelo BitValor
	ARN="Arena Bitcoin"
	B2U="BitcoinToYou"
	BAS="Basebit"
	BIV="Bitinvest"
	BSQ="Bitsquare"
	BTD="BitcoinTrade"
	CAM="BitCambio"
	FLW="flowBTC"
	FOX="FoxBit"
	LOC="LocalBitcoins"
	MBT="Mercado Bitcoin"
	NEG="Negocie Coins"
	PAX="Paxful"
	WAL="Walltime"
	BZX="Bitcoin Zero"
	PFY="Payfair"
	
	# Pegar o JSON uma única vez ( limit: 1 request/min )
	BVJSON=$("${YOURAPP[@]}" "https://api.bitvalor.com/v1/ticker.json")
	
	# Extrair a montar Array com nomes das exchanges
	ENAMES="$(jq -r '.ticker_24h.exchanges | keys[]' <<< "${BVJSON}")"
	
	# Print nomes e valores das exchanges
	while read -r i; do
		NAME="$(eval echo "\${$i}")"
		printf "%'.2f  %s\t%s\n" "$(jq -r ".ticker_24h.exchanges.${i}.last" <<< "${BVJSON}")" "${i}" "${NAME}"
	done <<< "${ENAMES}"
	#https://bitvalor.com/api
	#https://unix.stackexchange.com/questions/41406/use-a-variable-reference-inside-another-variable
}

# Pegar somente média
getmediaf() {
	#função de limpeza dos dados
	getnf() { sed -E -e "s/^([0-9\.]+)\s.*/\1/" -e '/^[a-zA-Z]/d';}
	
	# Get API rates
	RESULTS="$(apiratesf "${1}" 2>/dev/null | tr -d ',')"
	N="$(grep -cE "^[0-9]+" <<< "${RESULTS}")"

	if [[ "$N" -eq 0 ]]; then
		echo "Nenhum resultado para ${1^^}" 1>&2
		exit 1
	fi
	
	printf "Maiores:    \n"
	grep -E "^[0-9]+" <<< "${RESULTS}" | sort -nr | head -n3
	
	printf "Média(n=%s):\n" "${N}"
	printf "%.2f\n" "$(bc -l <<< "($(getnf <<< "${RESULTS}" | paste -sd+))/${N}")"
	
	printf "Delta(maior/menor):\n"
	MIN="$(getnf <<< "${RESULTS}" | sort -n | head -1)" 
	MAX="$(getnf <<< "${RESULTS}" | sort -n | tail -1)" 
	printf "%.2f %%\n" "$(bc -l <<< "((${MAX}/${MIN})-1)*100")"

	if [[ "$N" -gt 3 ]]; then
		printf "Menores:\n"
		grep -E "^[0-9]+" <<< "${RESULTS}" | sort -nr | tail -n3
	fi
}

#ticker bitverso
bitversof() {
	"${YOURAPP[@]}" 'https://members.bitverso.com/ticker.json' | jq -r '(.coins.btc.exchanges[]|"\(.current_price)   \t\(.name)")' | grep -v '^0' | sort -k2

}
#https://guiadoinvestidor.com.br/melhores-exchanges-de-bitcoin-do-brasil-2019-2020/

#coin trader monitor
cointf() {
	#check which app
	[[ "${YOURAPP[0]}" = curl ]] && HEADER=(-H) || HEADER=(--header=)
	"${YOURAPP[@]}" "${HEADER[@]}${UAG}" 'https://www.cointradermonitor.com/preco-bitcoin-brasil' | 
		sed -e 's/[><]/ & /g' -e 's/<[^>]*>//g' -ne '/Exchange\s*Preço/,+35p' | sed -Ee 's/([a-zA-Z]+)\s*([A-Z])/\1\2/' -e 1d | column -et -NRNK,AGÊNCIA,PREÇO,VOL,MS
}
#https://www.cointradermonitor.com/preco-bitcoin-brasil


# Parse options
# If the very first character of the option string is a colon (:) then getopts 
# will not report errors and instead will provide a means of handling the errors yourself.
while getopts ":bcjhvm" opt; do
  case ${opt} in
	b ) #somente API do BitValor ou BitVerso
		[[ -z "${BITVALOROPT}" ]] && BITVALOROPT=1 || BITVERSOOPT=1
		;;
	c ) #somente API do CoinTrader
		COINTOPT=1
		;;
	h ) # Show Help
		echo -e "${HELP_LINES}"
		exit 0
		;;
    	j ) # DEBUG
		DEBUGOPT=1
      		;;
	m ) # Média somente
		[[ -z "${MOPT}" ]] && MOPT=1 || MOPT=2
		;;
    	v ) # Version of Script
      		grep -m1 '\# v' "${0}"
      		exit
      		;;
	\? )
		printf "Opção inválida: -%s\n" "$OPTARG" 1>&2
		exit 1
		;;
  esac
done
shift $((OPTIND -1))

# Test if cURL or Wget is available
if command -v curl &>/dev/null; then
	YOURAPP=(curl -sL --retry "${RETRIES}" --connect-timeout "${TIMEOUT}" --compressed)
elif command -v wget &>/dev/null; then
	YOURAPP=(wget -qO- -t"${RETRIES}" -T"${TIMEOUT}")
else
	printf "cURL ou Wget é necessário.\n" 1>&2
	exit 1
fi

#request compressed response
if ! command -v gzip &>/dev/null; then
	printf 'aviso: gzip pode ser necessário\n' 1>&2
fi

# Veja se há algum argumento
if [[ -z "${1}" ]]; then
	noarg=1
	set -- btc
else
	case "${*,,}" in
		(bitcoin|bitcorn) set -- btc;;
		(ethereum|ether|shitcoin) set -- eth;;
		(litecoin) set -- ltc;;
		(monero) set -- xmr;;
		(bitcoin\ cash) set -- bch;;
		(tether) set -- usdt;;
		(binance|binance\ coin) set -- bnb;;
	esac
fi

# Debug option
if [[ -n "${DEBUGOPT}" ]]; then
	printf "Abaixo, as linhas que puxam dados brutos JSON\n" 1>&2
	grep -Ei -e "http" < "${0}" | sed -e 's/^[ \t]*//' | sort
	printf "Executando \"apiratesf\" sem redireção do STDERR..\n" 1>&2
	apiratesf ${@}
	exit
fi

#chamar funcoes de opt
#api do bitverso?
if [[ -n "${BITVERSOOPT}" ]]; then
	date
	printf "API do BitVerso\n"
	bitversof
#api do bitvalor?
elif [[ -n "${BITVALOROPT}" ]]; then
	date
	printf "API do BitValor\n"
	bitvalorf
#api do cointrader?
elif [[ -n "${COINTOPT}" ]]; then
	date
	printf "API do CoinTrader\n"
	cointf
#estatisticas basicas
elif [[ -n "${MOPT}" ]]; then
	printf "Aguarde\r"
	#somente a média?
	if [[ "${MOPT}" = "2" ]]; then
		getmediaf "${1}" | sed -Ee 's/\s+/  /' -e 's/\./,/' | grep -A1 "^Média" | tail -n1
	#estatisticas basicas e média?
	else
		getmediaf "${1}" | sed -Ee 's/\s+/  /' -e 's/^[0-9]/ &/' -e 's/\./,/'
	fi
# Função padrão
else
	# Imprimir referência de hora
	date
	# Pegar cotações disponíveis
	{
	if [[ -n "$noarg" ]]; then
		printf "\nAPI do CoinTrader\n"
		cointf
		printf "\nAPI do BitVerso\n"
		bitversof
		printf "\nAPI do BitValor\n"
		bitvalorf
	fi
	printf "\nAPIs das agências\n"
	apiratesf "${1}"
	} 2>/dev/null | tr ',.' '.,'
fi

