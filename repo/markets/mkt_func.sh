##################################################
################ MARKET FUNCTIONS ################
# 2021  by mountaineerbr

#compatible with bash and z-shell
 
#make sure locale is set correctly
#export LC_NUMERIC=C

#request compressed response from server
#alias curl='curl --compressed'
#alias wget="wget --header='Accept-Encoding: gzip'" # .. |gzip -dc

#lista de ações da bovespa b3
blist()
{
	local i

	#user input
	if [[ -n "$*" ]]
	then
		set -- $( tr '[:lower:]' '[:upper:]' <<< "$*" )
	#or defaults
	else
		printf 'uso: blist [LETRA|NUM]\n\n' >&2
		set -- {A..Z} {0..9}
		sleep 1
	fi
	
	#laço para puxar os dados
	for i in "$@"
	do
		printf 'Puxando %s..\r' "$i" 1>&2
	
		curl -s "https://br.advfn.com/bolsa-de-valores/bovespa/$i" |
			sed 's/<[^>]*>//g' | sed -n '/Ação/,/var ZD_USER/p' |
			sed -e '1d' -e '$d' -e '/^\s*$/d' -Ee 's/[a-z ]([A-Z0-9]+)$/\t\1/' |
			column -et -s$'\t' -NNOME,SIMBOLO -TNOME
	done
}


#tesouro direto -- precos e taxas dos titulos
#requer o pacote 'xmlstarlet'
#'wget -qO-' ou 'curl -sL'
tesouro()
{
	local url data

	#https://www.tesourodireto.com.br/titulos/precos-e-taxas.htm
	#http://www.tesouro.fazenda.gov.br/tesouro-direto-precos-e-taxas-dos-titulos
	url=https://www.tesourodireto.com.br/json/br/com/b3/tesourodireto/service/api/treasurybondsinfo.json
	
	data="$(curl -L --compressed --insecure "$url" )"

	#print status
	jq '.response.TrsrBondMkt' <<<"$data"

	jq -r '.response.TrsrBdTradgList[].TrsrBd |
		"\(.nm)\t\(.FinIndxs| if .nm == "PREFIXADO" then "" else .nm end)+\(if .anulInvstmtRate == 0 then empty else .anulInvstmtRate end)%\t\(.minInvstmtAmt)\t\(.untrInvstmtVal)\t\(.mtrtyDt|.[:10])"' <<<"$data" |
		sort |
		column -s$'\t' -et -NTÍTULO,RENT/ANO,INVEST/MIN,PREÇO,VENCIMENTO -RRENT/ANO,INVEST/MIN,PREÇO

	echo "<https://www.tesourodireto.com.br/titulos/precos-e-taxas.htm>"

}
#https://stackoverflow.com/questions/47593807/how-to-scrape-a-html-table-and-print-it-on-terminal-using-bash


#ibge inflação brasileira IPCA - Variação mensal
ipcab()
{
	local val tval tvalp line data 
	(($#)) ||  printf 'uso: ipcab  ANO/MES  #ANO/MES >= 1980/01\n\n' >&2

	#testar input do usuário, ano maior que 1980
	set -- "$(tr -d '/.-' <<<"$*")"
	[[ -n "$2" ]] && set -- "$1$2"
	
	if [[ "$1" =~ ^[0-9]{4}$ ]] &&
		(( $1 >= 1980 )) 2>/dev/null
	then
		set -- "${1}01"
	fi

	#user arg must be a six-digit integer and before 1980/jan
	if [[ ! "$1" =~ ^[0-9]{6}$ ]] || (( $1 < 198001 )) 2>/dev/null
	then
		#199407 começo do plano real
		set -- 199501
	fi

	data="$( curl --compressed -s "https://servicodados.ibge.gov.br/api/v1/conjunturais?&d=s&user=ibge&t=1737&v=63&p=${1}-203701&ng=1(1)&c=" )"

	#inflação variação mensal #cod:63
	jq -er '.[0].var' <<< "$data" || return 1

	jq -r '.[]|"\(.p) \(.v)"' <<< "$data" |
	while read line
	do
		val="$( cut -d' ' -f3 <<< "$line" )"
		tval="$( bc <<< "scale=16; (1+ ( $val /100) ) * ${tval:-1}" )"
		tvalp="$( bc <<< "scale=16; ( $tval -1) * 100" )"

		printf "%s%% %'.2f%% %.6f\n" "$line" "$tvalp" "$tval"
	done |
		#make table
		column -ets' ' -NMes,Ano,Var%Mes,Acu%Total,Fator -OAno,Mes,Var%Mes,Acu%Total,Fator -RVar%Mes,Acu%Total,Fator

}
#calculadora: https://www3.bcb.gov.br/CALCIDADAO/publico/corrigirPorIndice.do?method=corrigirPorIndice


#ibge inflação brasileira IPCA - Variação acumulada no ano
#uso: %s [ANO]  #ANO>=1980 e calcula de jan/ANO a DEZ/ANO_ATUAL-1 
ipcab2()
{
	local data year yearend line val tval tvalp
	#print usage if user did not supply any argument
	[[ -z "$*" ]] && printf 'uso: ipcab2 ANO  #ANO >= 1980\n\n' >&2

	#testar input do usuário, ano maior que 1980
	if [[ "$1" =~ ^[0-9]{4}$ ]] &&
		(( $1 >= 1980 )) 2>/dev/null
	then
		set -- "${1}01"
	fi

	#user arg must be a six-digit integer and before 1980
	if [[ ! "$1" =~ ^[0-9]{6}$ ]] || (( $1 < 1980 )) 2>/dev/null
	then
		#199407 começo do plano real
		set -- 199501
	fi
	
	#inflação acumulada por ano #cod:69
	data="$( curl -sLb non-existing "https://servicodados.ibge.gov.br/api/v1/conjunturais?&d=s&user=ibge&t=1737&v=69&p=${1}-203012&ng=1(1)&c=" )"

	jq -er '.[0].var' <<< "$data" || return 1
	jq -r '.[]|"\(.p) \(.v)"' <<< "$data" | column -ets' ' -NMes,Ano,Acu%Ano -OAno,Mes,Acu%Ano
	
	#inflação acumulada a partir de um ano específicado pelo usuário
	yearend="$(( $( date +%Y ) - 1 ))"
	year="${1:0:4}"

	printf '\nPeríodo %s/jan - %s/dez\n' "$year" "$yearend"
	
	while read line
	do
		val="$( jq -r ".[]|select( .p == \"${line}\")|.v" <<< "$data" )"
		tval="$( bc <<< "scale=16; (1+ ( $val /100) ) * ${tval:-1}" )"
		tvalp="$( bc <<< "scale=16; ( $tval -1) * 100" )"
		
		printf "%s dez %s%% %'.2f%% %.6f\n" "$year" "$val" "$tvalp" "$tval"
		((year++))
	done <<< "$( eval printf 'dezembro\ %s\\n' \{$year..$yearend\} )" |
		#make table
		column -ets' ' -NAno,Mes,Ac%Ano,Acu%Total,Fator -RAc%Ano,Acu%Total,Fator 
}
#orig:199512,199612,199712,199812,199912,200012,200112,200212,200312,200412,200512,200612,200712,200812,200912,201012,201112,201212,201312,201412,201512,201612,201712,201812,201912,202012,202112,202212,202312,202412,202512,202612,202712,202812,202912,203012,202001
#https://www.ibge.gov.br/estatisticas/economicas/precos-e-custos/9256-indice-nacional-de-precos-ao-consumidor-amplo.html?t=series-historicas&utm_source=landing&utm_medium=explica&utm_campaign=inflacao#plano-real-mes


#american inflation
ipca()
{
	#if user supplied no args
	if [[ -z "${*}" ]]
	then
		printf 'usage: ipca [series_id]\n' >&2
		printf 'usage: ipca  .           #all series\n\n' >&2
		set -- CUUR0000SA0
	fi

	#get data and grep a series
	curl 'https://download.bls.gov/pub/time.series/cu/cu.data.1.AllItems' | grep "$1" | column -t
}
#??Daily query limit Version 1.0 (Unregistered) 25
#https://www.bls.gov/
#also good:https://download.bls.gov/pub/time.series/cu/cu.data.0.Current


#american inflation
ipca2()
{
	curl -sL 'https://www.usinflationcalculator.com/inflation/consumer-price-index-and-annual-percent-changes-from-1913-to-2008/' | 
		sed -n '/<tbody>/,/<\/tbody>/p' | sed -e 's/<[^>]*>//g' -e 's/&.*;//g' -e 's/^\s*//g' |
		sed -n '/Year/,$p' | sed ':a;N;s/\n\(.\)/ \1/;ta' | sed 's/^\s//g' | column -ts' ' -o' '
}
#https://www.usinflationcalculator.com


#richard heart's hex rate in usd
hex() {
	local DATA HEXETH ETHUSD

	#header, date
	date

	DATA="$(curl -s "https://api.exchange.bitcoin.com/api/2/public/ticker")"
	HEXETH="$(jq -r '.[]|select(.symbol == "HEXETH")|.last' <<<"$DATA")"
	ETHUSD="$(jq -r '.[]|select(.symbol == "ETHUSD")|.last' <<<"$DATA")"
	
	echo "Bitcoin.com Ticker"
 	column -et -s' ' <<-!
		$( jq -r '.[]|select(.symbol == "HEXETH")' <<< "$DATA" | tr -d '",}{' | sed 's/^\s\s*//g' | tac )
		!
	echo "HEXETH:       $HEXETH"
	echo "ETHUSD:       $ETHUSD"
	echo
	echo 'HEX/USD:'

	bc <<< "scale=16; ( $HEXETH*$ETHUSD ) / 1" | xargs printf 'Bitcoin.com:  %.10f\n'
	
	command -v cgk.sh &>/dev/null && cgk.sh hex usd | xargs printf 'CoinGecko__:  %.10f\n'
	command -v cmc.sh &>/dev/null && cmc.sh hex usd | xargs printf 'CoinMktCap_:  %.10f\n'
}

#stats from <xe.com>
#30 and 60-day hig, low and avg
#{ curl -sL 'https://www.xe.com/api/stats.php?fromCurrency=GBP&toCurrency=USD';}

#metal rates from kitco
kitco()
{
	local kitcohelp colconf nopt c
	#help
	kitcohelp='usage: kitco [CURRENCY] [UNIT]   #convert opts
usage: kitco -n NUM              #kitco news
usage: kitco -h                  #help page
currs: USD, AUD, CAD, EUR, GBP, JPY, CHF, CNY,
       HKD, BRL, INR, MXN, RUB and ZAR
units: ounce, gram, kilo or tola
defts: USD ounce'

	#parse options
	while getopts hn: c
	do
		case $c in
			h )
				#help
				echo "$kitcohelp"
				return 0
				;;
			n )
				#news
				local nopt=${OPTARG:-11}
				;;
			\?)
				#illegal opt
				return 1
		esac
	done
	shift $(( OPTIND - 1 ))

	#kitco news
	if [[ -n "$nopt" ]]; then
		curl -s "https://proxy.kitco.com/getvnews?type=json&df=2&max=$nopt" -H 'Origin: https://www.kitco.com' |
			jq  -r '.News.videoNews|reverse[]|.fullHeadline,.publishDate,.description,""' | sed 's/<br\/>//g'
		return
	fi
	
	#arrange parameters
	set -- $( tr A-Z a-z <<< "$*" )
	[[ "$1" =~ ^(ounce|gram|kilo|tola)$ ]] && set -- "$2" "$1"
	[[ ! "$2" =~ ^(ounce|gram|kilo|tola)$ ]] && set -- "$1" ounce
	
	#check if $1 is empty
	if [[ -z "$1" ]]
	then
		#set default currency
		set -- USD "$2"
	else
		#set all uppercase
		set -- "$( tr a-z A-Z <<< "$1" )" "$2"
	fi
	
	#check for possible error in $1
	if (( ${#1} - 3 ))
	then
		echo 'Err: invalid currency symbol' >&2
		return 1
	fi

	#set columns
	(( COLUMNS < 102 )) && colconf=( -TTIME -HUNIT,CUR )
	
	#ny spot
	printf 'New York Spot Price\n'
	#mkt status
	curl -Ls 'https://proxy.kitco.com/getMarketStatus?market=1' -H 'Origin: https://www.kitco.com'
	#table
	curl -Ls "https://proxy.kitco.com/getPM?symbol=AU,AG,PT,PD,RH&currency=${1}&unit=${2}&market=1" -H 'Origin: https://www.kitco.com' | sed -e 's/\s/T/' -e 's/\r//g' | column -ts, -NX,CUR,UNIT,TIME,BID,MID,ASK,CHG,CHG%,LOW,HIGH -RCUR,UNIT,BID,MID,ASK,CHG,CHG%,LOW,HIGH -OX,BID,MID,ASK,CHG,CHG%,LOW,HIGH,CUR,UNIT,TIME ${colconf[@]}

	#world prices
	printf '\nThe World Spot Price - Asia/Europe/NY markets\n'
	#mkt status
	curl -Ls 'https://proxy.kitco.com/getMarketStatus?market=4' -H 'Origin: https://www.kitco.com'
	#table
	curl -Ls "https://proxy.kitco.com/getPM?symbol=AU,AG,PT,PD,RH&currency=${1}&unit=${2}&market=4" -H 'Origin: https://www.kitco.com' | sed -e 's/\s/T/' -e 's/\r//g' | column -ts, -NX,CUR,UNIT,TIME,BID,MID,ASK,CHG,CHG%,LOW,HIGH -RCUR,UNIT,BID,MID,ASK,CHG,CHG%,LOW,HIGH -OX,BID,MID,ASK,CHG,CHG%,LOW,HIGH,CUR,UNIT,TIME ${colconf[@]}
	
	printf '<https://www.kitco.com/market/>\n'
}
#<<Exchange rates displayed are the middle point between bid and ask.>>


#metal rates from infomine
metals()
{
	curl -sL https://www.mining.com/markets/ |
		grep "class='commodity-name'" |
		sed 's/<div/\n&/g ;s/<[^>]*>//g'

	echo '<https://www.mining.com/markets/>'
}
#Metals and Commodities
#Spot - Gold, silver, palladium and platinum are updated every two minutes. Trading time is London, UK time. Spot data is 23 ½ hours
#per day 6 days per week. The market is closed for 30 minutes every day and is also closed on Saturdays, North America timezone.
#Data Provider: Xignite
#Closing – LME data, such as copper, nickel and aluminum, is updated in the early evening hours, PST.
#Data Provider: theFinancials
#Uranium data tracks Ux U308 spot.
#Data Provider: UX Consulting Company
#Oil data tracks Brent crude oil.
#Data Provider: ICE
#Chromite: Ferro-Chrome (High Carbon) 65% min., Europe;
#Cobalt: Cobalt 99.8% min.;
#Iron Ore: CVRD;
#Iron Ore: Hamersley;
#Magnesium: Ingots 99.9%, Europe;
#Manganese: Electrolytic flakes 99.7%, Europe;
#Molybdenum: Molybdenum oxide (Western) 57% min;
#Phosphates: Phosphate rock, 70% BPL, Morocco;
#Potash: Potassium chloride, standard grade, Vancouver;
#Titanium: Ferro-Titanium 68-72% min., Europe;
#Tungsten: Ferro-Tungsten 75% min., Europe;
#Vanadium: Ferro-Vanadium 78% min., Europe
#Specialty/Minor and Bulk Metals prices are derived from various sources including but not limited to International Monetary Fund,
#The World Bank, German Geoscience Institutes, Energy Information Administration and others. 
#http://www.infomine.com/chartsdata/infominechartsdatareadme.pdf


#google finance hack
gfin()
{
	printf 'Google Finance\n'
	{
	#get rates by 'mids'; max 100 mids per request
	curl -s 'https://www.google.com/async/finance_wholepage_price_updates?ei=99InXuDmDNHY5OUPv-CguA0&yv=3&async=mids:%2Fg%2F11c319bxp1%7C%2Fg%2F11c6qr7_zl%7C%2Fg%2F11cjk7msnp%7C%2Fg%2F11f_p2h7tk%7C%2Fg%2F11fqt81yyy%7C%2Fg%2F11h06gmwhk%7C%2Fg%2F11h5q0hb4g%7C%2Fg%2F12fh0nz9c%7C%2Fg%2F12fh0nzb0%7C%2Fg%2F12fh0nzb3%7C%2Fg%2F12fh0p2yj%7C%2Fg%2F12fh0p2ys%7C%2Fg%2F12fh0p2zf%7C%2Fg%2F12fh0p73t%7C%2Fg%2F12fh0p75f%7C%2Fg%2F12fh0p75n%7C%2Fg%2F12fh0pcbj%7C%2Fg%2F12fh0ph_m%7C%2Fg%2F12fh0ph_n%7C%2Fg%2F12fh0ph_w%7C%2Fg%2F12fh0pj0n%7C%2Fg%2F12fh0pj11%7C%2Fg%2F12fh0pmvf%7C%2Fg%2F12fh0q03j%7C%2Fg%2F12fh0q03k%7C%2Fg%2F12fh0q40l%7C%2Fg%2F12fh0q40p%7C%2Fg%2F12fh0q417%7C%2Fg%2F12fh0q41w%7C%2Fg%2F12fh0q889%7C%2Fg%2F12fh0q89p%7C%2Fg%2F12fh0qdmr%7C%2Fg%2F12fh0qdp7%7C%2Fg%2F12fh0qdq2%7C%2Fg%2F12fh0qdq7%7C%2Fg%2F12hdlm_nd%7C%2Fg%2F12hdlm_nx%7C%2Fg%2F12hdlm_pq%7C%2Fg%2F12hdlr38s%7C%2Fg%2F12hdlrw86%7C%2Fg%2F12hdlsn8t%7C%2Fg%2F12hdlsn8x%7C%2Fg%2F12hdltfqt%7C%2Fg%2F12hdltfr0%7C%2Fg%2F12hdltfrc%7C%2Fg%2F12hdltfsh%7C%2Fg%2F1dtsbwq8%7C%2Fg%2F1hg1hklbg%7C%2Fg%2F1q4t94b6p%7C%2Fg%2F1q52g9wfq%7C%2Fg%2F1q52gbb7v%7C%2Fg%2F1q6b4f1pf%7C%2Fg%2F1yg5879fd%7C%2Fg%2F1yghbvnlq%7C%2Fg%2F1ylhlbf1j%7C%2Fm%2F016j14%7C%2Fm%2F016yss%7C%2Fm%2F02853rl%7C%2Fm%2F02hl6w%7C%2Fm%2F02xl7xj%7C%2Fm%2F034673%7C%2Fm%2F046k_p%7C%2Fm%2F04j8v0t%7C%2Fm%2F04t5sp%7C%2Fm%2F04ww1p%7C%2Fm%2F04xjcr%7C%2Fm%2F04xk2h%7C%2Fm%2F04zvfw%7C%2Fm%2F07zkq3x%7C%2Fm%2F07zkrds%7C%2Fm%2F07zk_ym%7C%2Fm%2F07zk_zc%7C%2Fm%2F07zkzv8%7C%2Fm%2F07zl90k%7C%2Fm%2F07zllzd%7C%2Fm%2F07zln7n%7C%2Fm%2F07zln_9%7C%2Fm%2F07zlw9w%7C%2Fm%2F07zm1ts%7C%2Fm%2F07zm2vb%7C%2Fm%2F07zm7zs%7C%2Fm%2F07zmbvf,currencies:,_fmt:json' | sed 1d
	curl -s 'https://www.google.com/async/finance_wholepage_price_updates?ei=ywprXZHwMcCy5OUPqeK3qAw&yv=3&async=mids:%2Fm%2F0877z%7C%2Fm%2F09fld6%7C%2Fm%2F0b18t%7C%2Fm%2F0ckbkv_%7C%2Fm%2F0ckbnyv%7C%2Fm%2F0ckcq21%7C%2Fm%2F0ckcrh7%7C%2Fm%2F0ckcxmp%7C%2Fm%2F0ckd7nm%7C%2Fm%2F0ckd8tr%7C%2Fm%2F0ckdqsq%7C%2Fm%2F0ckf36v%7C%2Fm%2F0ckf8kv%7C%2Fm%2F0ckgsgx%7C%2Fm%2F0ckh859%7C%2Fm%2F0ckhqlx%7C%2Fm%2F0ck_hz6%7C%2Fm%2F0ckj0b3%7C%2Fm%2F0ckj76w%7C%2Fm%2F0ckjvmb%7C%2Fm%2F0ckk41t%7C%2Fm%2F0ckk6tq%7C%2Fm%2F0ckl1vg%7C%2Fm%2F0ckl258%7C%2Fm%2F0ckp030%7C%2Fm%2F0ckplt3%7C%2Fm%2F0ckpv1f%7C%2Fm%2F0ckpwbx%7C%2Fm%2F0ckq0pv%7C%2Fm%2F0ckq1xd%7C%2Fm%2F0ckq1yk%7C%2Fm%2F0ckqp37%7C%2Fm%2F0ckr0kx%7C%2Fm%2F0ckrjm4%7C%2Fm%2F0cks31m%7C%2Fm%2F0cks_60%7C%2Fm%2F0cksgss%7C%2Fm%2F0ckspft%7C%2Fm%2F0cksrc4%7C%2Fm%2F0cksx47%7C%2Fm%2F0ckt6ld%7C%2Fm%2F0cktgpy%7C%2Fm%2F0ckwf21%7C%2Fm%2F0ckxj89%7C%2Fm%2F0ckxkz6%7C%2Fm%2F0ckxpc8%7C%2Fm%2F0ckxrhc%7C%2Fm%2F0ckxvl0%7C%2Fm%2F0ckxvm7%7C%2Fm%2F0cky1hw%7C%2Fm%2F0ckynjl%7C%2Fm%2F0ckyv15%7C%2Fm%2F0ckzfjy%7C%2Fm%2F0cl015q%7C%2Fm%2F0cl0x5j%7C%2Fm%2F0cl19mp%7C%2Fm%2F0cl1_nd%7C%2Fm%2F0cl20h_%7C%2Fm%2F0cl20hl%7C%2Fm%2F0cl26k8%7C%2Fm%2F0cl3bt3%7C%2Fm%2F0cl3pfz%7C%2Fm%2F0clbbbp%7C%2Fm%2F0cqyw%7C%2Fm%2F0rz9htl,currencies:%2Fm%2F02l6h%2B%2Fm%2F09nqf%7C%2Fm%2F09nqf%2B%2Fm%2F088n7%7C%2Fm%2F01nv4h%2B%2Fm%2F09nqf%7C%2Fm%2F09nqf%2B%2Fm%2F0ptk_%7C%2Fm%2F09nqf%2B%2Fm%2F02nb4kq%7C%2Fm%2F09nqf%2B%2Fm%2F0hn4_%7C%2Fm%2F0kz1h%2B%2Fm%2F09nqf,_fmt:json' | sed 1d
	} |
		jq -r '.PriceUpdate.entities[]|
			( .financial_entity // .currency_entity |
				"\((.common_entity_data|"\(.symbol//.name)$\(.name)$\(.change)$\(.value_change)$\(if .change == "POSITIVE" then "+" else "-" end)\(.percent_change)$\(.last_value)$\(.last_updated_time)"))$\(.last_close_price//null|.value//"")$\(.exchange//"")"
			)' |
		sed 's/\s\/\s/\//g' | sort -u -k1 -t'$' |
		column -et -s'$' -NSYMBOL,NAME,DIRECTION,CHANGE,CHANGE%,VALUE,UPDATE,LASTCLOSE,EXCHANGE -TNAME,UPDATE -HDIRECTION,EXCHANGE -OSYMBOL,VALUE,NAME,DIRECTION,CHANGE,CHANGE%,LASTCLOSE,UPDATE,EXCHANGE

}
#for jspb: .. | sed 's/<[^>]*>//g' | grep -E "\"*[[:digit:]]+.[[:digit:]]+\"" | grep -oP '"\K[^"]+' | grep -Ev -e '^,$' -e 'newwindow' -e 'search' -e '[[:digit:]]+]' -e '^]$' -e 'null' -e '/m/' -e '/g/' | sed -e 's/,.,/\n/g' -e 's/,$//g' -e 's/^,//g' -e 's/\\u0026/\&/g'  #| grep --color=never -i -e "$1" -A6 -B3
#<<quotes are not sourced from all markets and may be delayed by up to 20 minutes.
#information is provided 'as is' and solely for informational purposes, not for
#trading purposes or advice.>>
#get a personalised list by visiting <https://www.google.com/finance>,
#expand watchlists and set up your symbols. then, open the 'developer tools' 
#of your browser, go to the 'network' tab, reload the page and check for the 
#'finance_wholepage_price_updates' link and get your 'mids'


#yahoo finance hack -- long ticker
yfin()
{
	#subshell
	(
	#parse some opts
	if [[ "$1" = -h ]]
	then
		printf 'usage: yfin [-jh] SYMBOL\n'
		printf 'option -j to print raw json data\n'
		return
	elif [[ "$1" = -j ]]
	then
		PJSON=1
		shift
	fi
	
	#set symbol to uppercase (POSIX-compatible)
	SYMBOL="$( tr '[:lower:]' '[:upper:]' <<< "${1:-TSLA}" )"

	#get data
	YJSON="$( curl -sL "https://query1.finance.yahoo.com/v7/finance/quote?symbols=${SYMBOL:-TSLA}&range=1d&interval=5m&indicators=close&includeTimestamps=false&includePrePost=false&corsDomain=finance.yahoo.com&.tsrc=finance" )"

	#print json?
	if [[ -n "$PJSON" ]]
	then
		printf '%s\n' "$YJSON"
		return
	#check for error response
	elif jq -e '.quoteResponse.error' <<< "$YJSON" &>/dev/null
	then
		jq -r '.quoteResponse.error' <<< "$YJSON"
		return 1
	#empty response?
	elif ! jq -e '.quoteResponse.result[]' <<<"$YJSON" &>/dev/null
	then
		return 1
	fi

	#set timezone for displaying times
	#export TZ="GMT"
	#set timezone according to info from yahoo
	export TZ="$( jq -r '.quoteResponse.result[]|.exchangeTimezoneName//.exchangeTimezoneShortName' <<< "$YJSON" )"

	#format ticker
	jq -r '.quoteResponse.result[]|
		"Exchang: \(.fullExchangeName)",
		"Timezon: \(.exchangeTimezoneName)  \(.exchangeTimezoneShortName)",
		"Source_: \(.quoteSourceName)",
		"Delayed: \(.exchangeDataDelayedBy)",
		"Intervl: \(.sourceInterval)",
		"",
		"50-day",
		"Average: \(.fiftyDayAverage)",
		"Change_: \(.fiftyDayAverageChange)",
		"Change%: \(.fiftyDayAverageChangePercent)",
		"",
		"200-day",
		"Average: \(.twoHundredDayAverage)",
		"Change_: \(.twoHundredDayAverageChange)",
		"Change%: \(.twoHundredDayAverageChangePercent)",
		"",
		"52-week",
		"Range__: \(.fiftyTwoWeekRange)",
		"HChange: \(.fiftyTwoWeekHighChange)",
		"HChang%: \(.fiftyTwoWeekHighChangePercent)",
		"LChange: \(.fiftyTwoWeekLowChange)",
		"LChang%: \(.fiftyTwoWeekLowChangePercent)",
		"High___: \(.fiftyTwoWeekHigh)",
		"Low____: \(.fiftyTwoWeekLow)",
		"",
		"Average daily volume",
		"Last3Mo: \(.averageDailyVolume3Month)",
		"Last10d: \(.averageDailyVolume10Day)",
		"",
		"Earnings",
		"T_Stamp: \(.earningsTimestamp//empty|strflocaltime("%Y-%m-%dT%H:%M:%S%Z"))",
		"Start__: \(.earningsTimestampStart//empty|strflocaltime("%Y-%m-%dT%H:%M:%S%Z"))",
		"End____: \(.earningsTimestampEnd//empty|strflocaltime("%Y-%m-%dT%H:%M:%S%Z"))",
		"",
		"BookVal: \(.bookValue)",
		"ForwdPE: \(.forwardPE)",
		"PToBook: \(.priceToBook)",
		"",
		"Earnings per share",
		"12mTrai: \(.epsTrailingTwelveMonths)",
		"Forward: \(.epsForward)",
		"Populat: \(.esgPopulated)",
		"",
		"Post market",
		"Time___: \(.postMarketTime//empty|strflocaltime("%Y-%m-%dT%H:%M:%S%Z"))",
		"Change%: \(.postMarketChangePercent)",
		"Price__: \(.postMarketPrice)",
		"Change_: \(.postMarketChange)",
		"",
		"Exchang: \(.exchange)",
		"Market_: \(.market)",
		"Name___: \(.longName)",
		"Type___: \(.quoteType)",
		"Symbol_: \(.symbol)",
		"Currenc: \(.financialCurrency)",
		"1stTrad: \(((.firstTradeDateMilliseconds//empty)/1000)|strflocaltime("%Y-%m-%dT%H:%M:%S%Z"))",
		"MktStat: \(.marketState)",
		"ShrOuts: \(.sharesOutstanding)",
		"Mkt_Cap: \(.marketCap)",
		"BidSize: \(.bidSize)",
		"AskSize: \(.askSize)",
		"Bid____: \(.bid)",
		"Ask____: \(.ask)",
		"",
		"Regular market",
		"Time___: \(.regularMarketTime//empty|strflocaltime("%Y-%m-%dT%H:%M:%S%Z"))",
		"DayRang: \(.regularMarketDayRange)",
		"Change_: \(.regularMarketChange)",
		"Change%: \(.regularMarketChangePercent)",
		"DayHigh: \(.regularMarketDayHigh)",
		"DayLow_: \(.regularMarketDayLow)",
		"Volume_: \(.regularMarketVolume)",
		"PrevClo: \(.regularMarketPreviousClose)",
		"Open___: \(.regularMarketOpen)",
		"Price__: \(.regularMarketPrice)"
		' <<<"$YJSON" | grep -Fv 'null' | cat -s
	)
}
#currency
#language
#triggerable
#region
#tradeable
#priceHint
#messageBoardId
#shortName -- symbol short name
#gmtOffSetMilliseconds
#https://query1.finance.yahoo.com/v7/finance/quote?symbols=DANSKE.CO,ERIC-B.ST,FPKPEN.CO,SSO.OL,VWS.CO&range=1d&interval=5m&indicators=close&includeTimestamps=false&includePrePost=false&corsDomain=finance.yahoo.com&.tsrc=finance


#yahoo finance hack -- data from chart api
#usage: yfin2 [-jh] 'symbol' [range] [granularity]
yfin2()
{
	#subshell
	(
	#parse some opts
	if [[ "$1" = -h ]]
	then
		printf 'usage: yfin2 [-jh] SYMBOL [RANGE] [GRANULARITY]\n'
		return
	elif [[ "$1" = -j ]]
	then
		PJSON=1
		set -- "${@:2:4}"
	fi
	
	#set symbol to uppercase (POSIX-compatible)
	SYMBOL="$( tr '[:lower:]' '[:upper:]' <<< "${1:-TSLA}" )"

	#get json
	YJSON="$( curl -s "https://query1.finance.yahoo.com/v8/finance/chart/${SYMBOL}?region=US&lang=en-US&includePrePost=true&interval=${2:-1d}&range=${3:-1d}&corsDomain=finance.yahoo.com&.tsrc=finance" --compressed )"

	#print json?
	if [[ -n "$PJSON" ]]
	then
		printf '%s\n' "$YJSON"
		return
	#check for error response
	elif jq -er '.chart.error' <<< "$YJSON" &>/dev/null
	then
		jq -r '.chart.error.description' <<< "$YJSON"
		return 1
	fi

	#set timezone for displaying times
	#export TZ="GMT"
	#set timezone according to info from yahoo
	export TZ="$( jq -r '.chart.result[].meta.exchangeTimezoneName//.timezone' <<< "$YJSON" )"
	
	#print ticker config
	jq -r '.chart.result[]|
	 		(.meta|
				"Ticker configuration",
				"Granularity and range",
				"Available ranges:",
				(.validRanges| @sh),
				"Range___: \(.range)  Grain___: \(.dataGranularity)",
				"",
				"Current trading period",
				(.currentTradingPeriod|
					(.pre|
					"PreMkt_T: \(.start//empty|tonumber|strflocaltime("%Y-%m-%dT%H:%M:%S%Z"))  \(.end//empty|strflocaltime("%Y-%m-%dT%H:%M:%S%Z"))"
					),
					(.regular|
					"RegMkt_T: \(.start//empty|strflocaltime("%Y-%m-%dT%H:%M:%S%Z"))  \(.end//empty|strflocaltime("%Y-%m-%dT%H:%M:%S%Z"))"
					),
					(.post|
					"PostMktT: \(.start//empty|strflocaltime("%Y-%m-%dT%H:%M:%S%Z"))  \(.end//empty|strflocaltime("%Y-%m-%dT%H:%M:%S%Z"))"
					)
				),
				""
			)' <<< "$YJSON"

	#tickers and indicators
	jq -r '.chart.result[]|
		"Symbol information",
		"StartTim: \(.timestamp[0]//empty|strflocaltime("%Y-%m-%dT%H:%M:%S%Z"))",
		"EndTime_: \(.timestamp[1]//empty|strflocaltime("%Y-%m-%dT%H:%M:%S%Z"))",
		(.meta|
			"Symbol__: \(.symbol)  Currency: \(.currency//empty)",
			"InstType: \(.instrumentType//empty)  Exchange: \(.exchangeName//empty)",
			"Timezone: \(.exchangeTimezoneName//empty)  \(.timezone)",
			"1stTrade: \(.firstTradeDate//empty|strflocaltime("%Y-%m-%dT%H:%M:%S%Z"))"
		),
		"",
		"Indicators",
		(.indicators.quote[]|
			"Volume__: \(if .volume[1] != null and .volume[1] != 0 then .volume[1] else .volume[0]//"??" end)",
			"High____: \(.high[0]//empty)",
			"Low_____: \(.low[0]//empty)",
			"Open ___: \(.open[0]//empty)",
			"Close __: \(.close[0]//empty)"
		),
		"",
		"Ticker",
		(.meta|
			"Mkt_Time: \(.regularMarketTime|strflocaltime("%Y-%m-%dT%H:%M:%S%Z"))",
			"MktT_UTC: \(.regularMarketTime//empty|strftime("%Y-%m-%dT%H:%M:%SZ"))",
			"PrevClse: \(.chartPreviousClose//empty)",
			"MktPrice: \(.regularMarketPrice//empty)"
			#"PriceHnt: \(.priceHint//empty)"
		)
		' <<< "$YJSON"
	)
}


#yahoo finance symbol list
ylist()
{
	#assign local vars
	local LISTF TMPF

	#local file?
	LISTF="$HOME/arq/docs/yahooFinanceSymbols/yahooFinanceSymbols.txt" 

	#temp file for download
	TMPF='/tmp/yahooFinanceSymbols.txt'

	#if there is no local copy, try to download it
	if [[ ! -f "$LISTF" ]]
	then
		#check for downloaded temp file
		if [[ ! -f "$TMPF" ]]
		then
			curl -L -o "$TMPF" 'https://github.com/mountaineerbr/extra/raw/master/yahooFinanceSymbols/yahooFinanceSymbols.txt' || return 1
			printf 'File at %s\n' "$TMPF" >&2
		fi
		
		#set new path
		LISTF="$TMPF"
	fi

	#make table
	column -et -s $'\t' -N'TICKER,NAME,EXCHANGE,CATEGORY,COUNTRY' -T'CATEGORY,NAME' "$LISTF"
}

#nasdaq stock symbols
nlist()
{
	local line

	#get data
	curl --compressed 'ftp://ftp.nasdaqtrader.com/symboldirectory/'|
		sed 's/<[^>]*>//g' | sort -nk3 | awk '$4{print $4}' |
		while read line
		do
			#for line in nasdaqlisted.txt otherlisted.txt
			printf 'Fetching %s\r' "$line" >&2
			curl --compressed "ftp://ftp.nasdaqtrader.com/symboldirectory/$line"
		done
}
#https://quant.stackexchange.com/questions/1640/where-to-download-list-of-all-common-stocks-traded-on-nyse-nasdaq-and-amex

#slightly ugly bash one-liner for a sorted json array
#of nasdaq stock symbols
nlistjson()
{
	echo "[\"$(echo -n "$(echo -en "$(curl -s --compressed 'ftp://ftp.nasdaqtrader.com/SymbolDirectory/nasdaqlisted.txt' | tail -n+2 | head -n-1 | perl -pe 's/ //g' | tr '|' ' ' | awk '{printf $1" "} {print $4}')\n$(curl -s --compressed 'ftp://ftp.nasdaqtrader.com/SymbolDirectory/otherlisted.txt' | tail -n+2 | head -n-1 | perl -pe 's/ //g' | tr '|' ' ' | awk '{printf $1" "} {print $7}')" | grep -v 'Y$' | awk '{print $1}' | grep -v '[^a-zA-Z]' | sort)" | perl -pe 's/\n/","/g')\"]"
}
#ref:?

#curl cryptocurrencies exchange rates
#follow igor_chbin at <twitter.com/igor_chubin>
#multiple symbols table
rates()
{
	if [[ ${*} =~ (-h|:?help) ]]
	then
		curl -s 'rate.sx/:help'
		return
	fi
 	
	curl -s 'rate.sx/?TFq' | sed -e '1,6d' -e '$d'
}

#single symbol graph
rate()
{
	#usage: rate [from_currency] [to_currency] [@date|?T|..]
	if [[ -z "$2" ]] || [[ "$2" =~ [0-9]+ ]]
	then
		set -- "$1" usd "$2"
	elif [[ ${*} =~ (-h|:?help) ]]
	then
		curl -s 'rate.sx/:help'
		printf '\nusage: rate [from_currency] [to_currency] [@date|?T|..]\n' 
		return
	fi		
	
	curl -s "${2:-usd}.rate.sx/${1:-btc}${3}" | awk NF
}


#
#loss/gain reciprocal or symetrical ratio
#usage: loss [+-]NUM[%] [SCALE]
#usage: NUM is an integer and if negative reads as gain
#loss()
#{
#	local u g
#	u=${1%\%} u="${u#+}"
#
#	#check for invalid notations
#	if [[ "$u" = *[a-zA-Z]* || "$u" != *[0-9]* || ! "${u/[,.-]*}" =~ ^.?.?$ ]]
#	then echo -e 'err\nusage: loss [+-]NUM[%] [SCALE]' >&2 ;return 1 
#	fi
#
#	#use zshell maths or bash bc?
#	if ((ZSH_VERSION))
#	then float u ;g=$(( ( (1 / (1 - (u / 100) ) ) - 1) * 100))
#	else g=$( bc <<<"scale=16; ( (1 / (1 - ($u / 100) ) ) - 1) * 100" )
#	fi
#
#	if [[ "$u" = -* ]]
#	then printf "%4s: %6.${2:-4}f %%\n" gain ${u#-} loss ${g#-}
#	else printf "%4s: %6.${2:-4}f %%\n" loss $u gain $g
#	fi
#}
#fausto botelho: https://www.youtube.com/watch?v=yY7d6gOIynU
#formula: 100/(100-loss)


#fun with <datahub.io>
#time series

#gold monthly
gold()
{
	curl -sL 'https://datahub.io/core/gold-prices/r/1.json' | jq -r '.[]|"\(.Date)\t\(.Price)"'
}
#gold annual
golda()
{
	curl -sL 'https://datahub.io/core/gold-prices/r/0.json' | jq -r '.[]|"\(.Date)\t\(.Price)"'
}

#oil daily brent 
brent()
{
	curl -sL 'https://datahub.io/core/oil-prices/r/0.json' | jq -r '.[]|"\(.Date)\t\(.Price)"'
}
#oil weekly brent 
brentw()
{
	curl -sL 'https://datahub.io/core/oil-prices/r/1.json' | jq -r '.[]|"\(.Date)\t\(.Price)"'
}
#oil monthly brent 
brentm()
{
	curl -sL 'https://datahub.io/core/oil-prices/r/2.json' | jq -r '.[]|"\(.Date)\t\(.Price)"'
}
#oil annual brent 
brenta()
{
	curl -sL 'https://datahub.io/core/oil-prices/r/3.json' | jq -r '.[]|"\(.Date)\t\(.Price)"'
}
alias brenty=brenta

#oil daily wti 
wti()
{
	curl -sL 'https://datahub.io/core/oil-prices/r/4.json' | jq -r '.[]|"\(.Date)\t\(.Price)"'
}
#oil weekly wti 
wtiw()
{
	curl -sL 'https://datahub.io/core/oil-prices/r/5.json' | jq -r '.[]|"\(.Date)\t\(.Price)"'
}
#oil monthly wti 
wtim()
{
	curl -sL 'https://datahub.io/core/oil-prices/r/6.json' | jq -r '.[]|"\(.Date)\t\(.Price)"'
}
#oil annual wti 
wtia()
{
	curl -sL 'https://datahub.io/core/oil-prices/r/7.json' | jq -r '.[]|"\(.Date)\t\(.Price)"'
}
alias wtiy=wtia

#gas monthly
gas()
{
	curl -sL 'https://datahub.io/core/natural-gas/r/1.json' | jq -r '.[]|"\(.Month)\t\(.Price)"'
}
#gas daily
gasd()
{
	curl -sL 'https://datahub.io/core/natural-gas/r/0.json' | jq -r '.[]|"\(.Date)\t\(.Price)"'
}

#consumer price index
cpi()
{ 
	curl -sLb non-existing 'https://datahub.io/core/cpi/r/0.json' |
		jq -r '.[]|"\(.Year)=\(.CPI)=\(.["Country Name"])"' | 
		column -ets= -NYEAR,CPI,COUNTRY
}

#corruption perception
corruption()
{ 
	curl -sL 'https://datahub.io/core/corruption-perceptions-index/r/0.json' |
		jq -r '.[]|keys[] as $k | "\($k) \(.[$k])"' | sed 's/^Jurisdiction.*/&\n/'
}

#world population
wpop2()
{ 
	curl -sL 'https://pkgstore.datahub.io/core/population-growth-estimates-and-projections/population-estimates_json/data/1d29be418daf875533c4bd4b5d0a5963/population-estimates_json.json' |
		jq -r '.[]|"\(.Year)\t\(.Population)\t\(.Region)"' |
		sort -t$'\t' -k3 |column -ets$'\t' -NYEAR,POPULATION,REGION
}


#btc halving/supply tables
btcsupply()
{
	w3m -dump https://en.bitcoin.it/wiki/Controlled_supply | sed -En '/^Projected/,/^(\*|Note)/p'
}

#coin market cap stats
cmcstats()
{
	{
		curl -sL "https://web-api.coinmarketcap.com/v1/cryptocurrency/listings/latest?limit=10&start=1"
		curl -sL "https://web-api.coinmarketcap.com/v1/global-metrics/quotes/latest"
	} | jq

}

#btc historical prices
#usage: cmcbtchist VS_CURRENCY CRYPTO_SLUG START_TIME END_TIME
cmcbtchist()
{
	local vscur slug start end
	vscur="${1:-USD}"
	slug="${2:-bitcoin}"
	start="${3:-1367020800}"  #Sat 27 Apr 00:00:00 UTC 2013
	end="${4:-$( date -udtomorrow0 +%s )}"

	curl -sL "https://web-api.coinmarketcap.com/v1/cryptocurrency/ohlcv/historical?convert=${vscur}&slug=${slug}&time_end=${end}&time_start=${start}" | jq


	#if no positional argument, print usage
	if [[ -z "$1" ]]
	then
		echo 'usage: cmcbtchist VS_CURRENCY CRYPTO_SLUG START_TIME END_TIME' >&2
		echo 'usage: cmcbtchist USD bitcoin' >&2
	fi
}


#sochain api
sochain()
{
	local uri
	case "$1" in
		balance | bal* | a*)
			#balance
			uri="get_address_balance/${3:-bitcoin}/${2:?address required}/${4:-1}"
			;;
		received | rec*)
			uri="get_address_received/${3:-bitcoin}/${2:?address required}"
			;;
		spent | sp*)
			uri="get_address_spent/${3:-bitcoin}/${2:?address required}"
			;;
		valid | val*)
			uri="is_address_valid/${3:-bitcoin}/${2:?address required}"
			;;
		txin | in)
			uri="get_tx_inputs/${3:-bitcoin}/${2:?transaction required}"
			;;
		txout | out)
			uri="get_tx_outputs/${3:-bitcoin}/${2:?transaction required}"
			;;
		txconfirmed | t*c*)
			uri="is_tx_confirmed/${3:-bitcoin}/${2:?transaction required}"
			;;
		txspent | t*s*)
			uri="is_tx_spent/${3:-bitcoin}/${2:?transaction required}"
			;;
		tx | t*)
			uri="get_tx/${3:-bitcoin}/${2:?transaction required}"
			;;
		blkhash | b*h*)
			uri="get_blockhash/${3:-bitcoin}/${2:?block required}"
			;;
		blk | b*)
			uri="get_block/${3:-bitcoin}/${2:?block required}"
			;;
		price | p*)
			uri="get_price/${2:?coin required}/${3:-USD}"
			;;
		info | i*)
			uri="get_info/${2:-bitcoin}"
			;;
		help | h*)
			printf '%s\n' options: balance addrreceived addrspent isvalid txin txout txconfirmed txspent blkhash blk price info
			return 0
			;;
	esac
	[[ -z "$uri" ]] && echo "option required" >&2 && return 1
	curl -s "https://sochain.com/api/v2/$uri"
	echo
}
#https://sochain.com/api
#SoChain allows 300 requests/minute free-of-charge


##################################################
############## END MARKET FUNCTIONS ##############
##################################################

# magic vim modeline
# vim:filetype=bash

