#!/bin/bash
# Foxbit.sh -- Pegar taxas de criptos pelo API da FoxBit
# v0.3.4  aug/2020  by mountaineer_br

## Defaults
#Mercado padrão 
ID=1 ;IDNAME=BTC

#Intervalo de estatísticas do ticker
INTVDEF=24h

#Manter-se conectado?
ROLAR=1

#make sure locale is set correctly
export LC_NUMERIC=C

HELP="SINOPSE
	foxbit.sh [-pq] [-iINT] [CRIPTOMOEDA]	
	foxbit.sh [-hv]


 	Puxa as cotações de criptomoedas diretamente da API da FoxBit.

	A opção padrão gera um ticker com estatísticas. O ticker é ro-
	lante, ou seja, é sempre gerado com as estatísticas de uma janela
	de tempo e pode ser configurado com a opção -iINT, em que INT
	é uma opção de intervalo de tempo descrita em uma seção abaixo,
	padrão=$INTVDEF .

	Como o acesso é através de um Websocket, a conexão fica aberta
	e quando houver alguma atualização por parte do servidor, ele
	nos mandará pelo canal de comunicação aberto.

	Se nenhum parâmetro for especificado, BTC é usado. Para ver o
	ticket de outras moedas, especificar o nome da moeda no primeiro
	argumento.

	Os tickeres que a FoxBit oferece são:
	
		BTC 		LTC
		ETH		TUSD
		XRP
	

	O intervalo de tempo dos tickeres pode ser mudado. O padrão é
	de $INTVDEF . Os intervalos de tempo suportados são os seguintes:

		Intervalos 	Equivalente em segundos
		 1m		   60 	
		30m		 1800 	
	 	 1h  		 3600 	
	 	 6h  		21600 	
		12h  		43200 	
		24h  		86400 	

	
	O spread (Spd) e a variação (Var) são calculados a partir das
	seguintes fórmulas:

		[ Alta - Baixa ]
		[ Venda - Compra ]
		[ Fechamento - Abertura ]


LIMITES
	Segundo a documentação da API:

		<<rate limit: 500 requisições à cada 5 min>>

		<https://foxbit.com.br/api/>


GARANTIA
	Este programa/script é software livre e está sob a Licença 
	Geral Pública v3 ou superior do GNU. Sua distribuição não
	oferece suporte nem correção de bugs.

	O script requer os pacotes Bash, JQ e Websocat.

	Se achou este script útil, por favor considere me mandar
	um trocado!
		=)

		bc1qlxm5dfjl58whg6tvtszg5pfna9mn2cr2nulnjr


BUGS
	Percebi nos testes que algumas vezes o API da FoxBit não responde. 
	Neste caso, basta reiniciar o script.


EXEMPLOS DE USO

		Ticker rolante do Ethereum:

		$ foxbit.sh ETH


		Ticker rolante da Litecoin das últimas 6 horas:

		$ foxbit.sh -i 6h LTC

		
		Somente as atualizações de preço do Bitcoin:

		$ foxbit.sh -p
		
		$ foxbit.sh -p BTC


OPÇÕES
	-i 	Intervalo de tempo do ticker (1m, 30m, 1h,
		6h, 12h, 24h); padrão=24h.
	-h 	Mostra esta Ajuda.
	-p 	Preço somente.
	-q 	Puxar dados uma vez e sair.
	-v 	Mostra a versão deste script."


# Test if JQ and Websocat are available
if ! command -v websocat &>/dev/null
then
	echo "Websocat é requerido" >&2
	exit 1
elif ! command -v jq &>/dev/null
then
	echo "JQ é requerido" >&2
	exit 1
fi

# Functions
## Price of Instrument
statsf () {
	echo '{"m":0,"i":4,"n":"SubscribeTicker","o":"{\"OMSId\":1,\"InstrumentId\":'${ID}',\"Interval\":'${INTV}',\"IncludeLastCount\":1}"}' |
		websocat ${ROLAR} -t --ping-interval 20 "wss://apifoxbitprodlb.alphapoint.com/WSGateway" |
		jq --unbuffered -r '.o' |
		jq --unbuffered -r --arg IDNA "${IDNAME}" '.[] |
			"",
			"## Foxbit Ticker Rolante",
			"Intervl: \((.[0]-.[9])/1000) secs (\((.[0]-.[9])/3600000) h)",
			"Inicial: \((.[9]/1000) | strflocaltime("%Y-%m-%dT%H:%M:%S%Z"))",
			"Final__: \((.[0]/1000) | strflocaltime("%Y-%m-%dT%H:%M:%S%Z"))",
			"InstrID: \(.[8]) (\($IDNA))",
			"Volume_: \(.[5])",
			"Alta___: \(.[1])",
			"Baixa__: \(.[2])   \tVar: \((.[1]-.[2])|round)",
			"Venda__: \(.[7])",
			"Compra_: \(.[6])   \tSpd: \((.[7]-.[6])|round)",
			"#Abert_: \(.[3])",
			"*Fecham: \(.[4])   \tVar: \((.[4]-.[3])|round)"'
}
#https://www.fool.com/knowledge-center/how-to-calculate-the-bid-ask-spread-percentage.aspx
#https://www.fool.com/knowledge-center/how-to-calculate-spread.aspx
#https://www.calculatorsoup.com/calculators/financial/bid-ask-calculator.php

## Only Price of Instrument
pricef () {
	echo '{"m":0,"i":4,"n":"SubscribeTicker","o":"{\"OMSId\":1,\"InstrumentId\":'${ID}',\"Interval\":60,\"IncludeLastCount\":1}"}' |
		websocat ${ROLAR} -t --ping-interval 20 "wss://apifoxbitprodlb.alphapoint.com/WSGateway" |
		jq --unbuffered -r '.o' |
		jq --unbuffered -r '.[]|.[4]' |
		while read
		do
			printf '\n%.2f' "$REPLY"
		done
}

#trap
trapf()
{
	trap \  INT TERM HUP
	pkill -P $$
	echo
}

# Parse options
while getopts :hvi:pq opt
do
	case $opt in
		( i ) # Interval
			INTVOPT="$OPTARG"
			;;
		( h ) # Help
			echo "${HELP}"
			exit 0
			;;
		( q ) # Puxar dados uma vez e sair
			unset ROLAR
			;;
		( p ) # Preço somente
			POPT=1
			;;
		( v ) # Version of Script
			grep -m1 '# v' "$0"
			exit 0
			;;
		( \? )
			echo "Opção inválida -- -$OPTARG" >&2
			exit 1
			;;
	esac
done
shift $((OPTIND -1))

#select interval
case "${INTVOPT:-$INTVDEF}" in
	( 1m* )
		INTV=60
		;;
	( 30m* )
		INTV=1800
		;;
	( 1h* )
		INTV=3600
		;;
	( 6h* )
		INTV=21600
		;;
	( 12h* )
		INTV=43200
		;;
	( 24h* )
		INTV=86400
		;;
	( * )
		echo "Intervalo não suportado -- $INTVOPT" >&2
		INTV="$INTVDEF"
		;;
esac

# Get Product ID
if [[ -n "${1}" ]]
then
	case "${1^^}" in
		( BTC|BITCOIN )
			ID=1
			IDNAME=BTC
			;;
		( LTC|LITECOIN )
			ID=2
			IDNAME=LTC
			;;
		( ETH|ETHER|ETHEREUM )
			ID=4
			IDNAME=ETH
			;;
		( TUSD|TRUEUSD )
			ID=6
			IDNAME=TUSD
			;;
		( XRP|RIPPLE )
			ID=10
			IDNAME=XRP
			;;
		( * )
			echo "Shitcoin indisponível -- ${1^^}" >&2
			exit 1
			;;
	esac
fi

#manter-se contactado?
(( ROLAR )) && ROLAR=-n || unset ROLAR

# Set trap
trap trapf INT TERM HUP

# Call opt functions
if (( POPT))
then
	pricef
	exit
# Defaul opt
else
	# Ticker rolante, cortar colunas
	statsf
fi


exit
# Dead code
# Annotations
#\t %\(((.[1]-.[2])/.[1])*100)",
#\t %\(((.[7]-.[6])/.[7])*100)",
#\t %\(((.[4]-.[3])/.[3])*100)"'
#| cut -c-${CUTAT}
#[
#    {
#        "EndDateTime": 0, // POSIX format
#        "HighPX": 0,
#        "LowPX": 0,
#        "OpenPX": 0,
#        "ClosePX": 0,
#        "Volume": 0,
#        "Bid": 0,
#        "Ask": 0,
#        "InstrumentId": 1,
#        "BeginDateTime": 0 // POSIX format
#    }
#]
#
### Products
#productsf() {
#websocat "wss://apifoxbitprodlb.alphapoint.com/WSGateway" <<<'{"m":0,"i":10,"n":"GetProducts","o":"{\"OMSId\":1}"}' | jq -r '.o' | jq -r '.'
#}
##productsf
#
#Product ID 	Product
#1 		BTC
#2 		BRL
#3 		LTC
#4 		ETH
#5 		TUSD
#6 		XRP
### ?
##websocat "wss://apifoxbitprodlb.alphapoint.com/WSGateway" <<< '{"m":0,"i":12,"n":"GetInstruments","o":"{"OMSId":1}"}' | jq -r '.'

