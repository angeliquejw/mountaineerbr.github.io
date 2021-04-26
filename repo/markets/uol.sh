#!/bin/bash
# Uol.sh -- Puxa cotações do portal do UOL
# v0.2.25  jan/2021  by mountaineer_br

#defaults
#column separator for the -a opt
#USRSEP=','  #defaults='\t'

#não mude o seguinte:
SCRIPT="${BASH_SOURCE[0]}"
LASTLINES=2004
RED='\e[1;31;40m'
ENDC='\e[0m'

#make sure locale is set correctly
export LC_NUMERIC=C

AJUDA="Uol.sh -- Puxa dados do UOL Economia


SINOPSE
	uol.sh [ID|SÍMBOLO|NOME]

	uol.sh [-bdi]
	
	uol.sh [-ahllmv]

	
	O script puxa as cotações de páginas de economia do UOL.
	A opção padrão puxa as cotações do dólar turismo e comercial.

	Para uma liste simples com símbolos para algumas ações e seus
	nomes, use a opção -l . Para imprimir uma lista com os números
	de identificação internos, nomes, símbolos e descrição, use
	a opção -ll. Porém, observe que esta listagem é fixa e não
	puxa dados ao vivo.
	
	Para puxar o valor de todos os ativos disponíveis (scrape),
	utilize a opção -a . É uma lista grande e demorada para ser
	impressa. Copie os dados e faça uma tabela com as informações
	de formatação oferecidas no cabeçalho.

	O número de identificação ID (interno do UOL) pode ser usado
	para puxar um ticker resumido do ativo correspondente. Veja a
	seção seguinte sobre tickers.

	A opção -a tenta puxar todas as cotações de moedas, ações e
	índices suportados pelo UOL. O scrape de dados é uma operação
	demorada.

	Os pacotes Bash, cURL ou Wget e gzip são necessários.


TICKER RESUMIDO
	Há um hack para puxar o ticker resumido de um ativo disponível
	do UOL. Tente digitar o nome da ação, moeda ou índice como
	argumentos para o programa:

		$ uol.sh PETR4.SA


	Se não funcionar, será necessário que se utilize o número de
	ID do ativo para este fim. Para pegar o número de ID de uma
	ação, moeda ou índice, utilize a opção -ll (esta lista não é
	atualizada em tempo real) para pegar o número de ID da ação
	ou moeda de interesse. Por exemplo, com o comando:

		$ uol.sh -ll  |  grep -i petrobras
	

	Verificamos que as ações PETR4.SA e PETR3.SA possuem o número
	de ID 484 e 485, respectivamente. Para puxar um ticker resumido:
	
		$ uol.sh 484
	

	Em caso de colisão de números de identificação entre moedas,
	ações e índices, será puxado ambos (números 1-170). Por exemplo,
	a cotação do Euro em reais tem ID número 5. Porém, o índice
	'Special Governance Corporate Governance Stock Index', IGCX,
	também tem seu número de ID 5. Neste caso, será impresso
	tickeres de ambos.
	

GARANTIA
	Este programa/script é software livre e está licenciado sob
	a Licença Geral Pública v3 ou superior do GNU. Sua distribuição
	não oferece suporte nem correção de bugs.
	
	O script precisa do cURL ou Wget, JQ e Bash.

	If this programme was useful, consider sending me a nickle!
  
	Se este programa foi útil, por favor considere me lançar
	um trocado!
		=)

		bc1qlxm5dfjl58whg6tvtszg5pfna9mn2cr2nulnjr


OPÇÕES
	-a 	Minera dados de moedas, ações e índices (scrape).
	-b 	Índice da B3.
	-bb 	Série B3 intraday.
	-bbb 	Série B3 histórica.
	-d 	Cotação do dólar turismo e comercial, ticker simples.
	-dd 	Séries dólar turismo e comercial intraday.
	-ddd 	Séries dólar turismo e comercial históricas.
	-h 	Mostra esta ajuda.
	-j 	Debug, imprime json.
	-l 	Lista ações da B3 pela infomoney (dados ao vivo).
	-ll 	Lista longa de ações, moedas e seus números de id (list fixa).
	-m 	Cotação dos metais preciosos.
	-v 	Mostra versão do script." 

## Funções
# Filtro HTML
hf() {  sed 's/<[^>]*>//g';}

#helper func opt -a
procf() {
	printf '\033[2K' >&2
	sed 's/\r//g' |
		jq -r '.docs|reverse[]|"\(.abbreviation//.name)'$SEP'\(.price//.askvalue)'$SEP'\(.high//.maxbid//"-")'$SEP'\(.low//.minbid//"-")'$SEP'\(.open//"-")'$SEP'\(.close//"-")'$SEP'\(.change//.variationbid//"-")'$SEP'\(.pctChange//.variationpercentbid//"-")%'$SEP'\(.date)'$SEP'\(.exchangeasset//"")"' |
		sed -E 's/([0-9]{4})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})/\1-\2-\3T\4:\5:\6/'
}
#helper func opt -a
loopf() {
	#i=start at position
	#f=items per page
	#inc=increment (same as $f)
	#max=max items
	while (( f <= max )); do
		#g=is a string containing numbers separated by a comma
		g="$( eval printf '%s,' "{$i..$f}" )"
		#get rid of last comma
		g="${g%,}"

		#change incremental value
		i=$(( i + inc )); f=$(( f + inc ))

		#try not to miss any one page of results
		MAX=4
		SLEEP=20
		while ! cf ; do
			(( ++COUNTER ))
			(( COUNTER < MAX )) || break

			printf "${RED}Erro. Retentativa %s  ${ENDC}\n" "$COUNTER" 1>&2
			printf 'Aguardando %s segundos..  \n' "$SLEEP" 1>&2
			
			sleep "$SLEEP"
			SLEEP="$(( SLEEP * 2 ))"

		done

		#exited on error?
		(( COUNTER - MAX )) || {
				printf '\nErros de conexão  \n'
				printf 'Pulando uma página de resultados..  \n\n'
				} 1>&2

		unset COUNTER
		
		#loading bar sent to stderr, align to rightmost
		printf "${RED}>>>%s/%s [+%s]${ENDC} \r" "$(( f - inc ))" "${max}" "${inc}" 1>&2
		
		#don't be naughty to the server
		sleep 0.8
	done
}
##printf '\033[2K\r' 1>&2  #clear stderr?

#-a scrape de cotações
scrapef() {
	#check for user-set separator
	[[ -n "$USRSEP" ]] && SEP="$USRSEP" || SEP='\t'
	
	#cabeçalho
	cat <<-!
	UOL - Economia
	$(date)
	
	COLUNAS
	Separador____: ${USRSEP:-<TAB>}
	Moedas_______: Nome,Preço,Max,Min,Var,Var%,Data
	Índices/Ações: Símbolo,Pontos,Alta,Baixa,Abertura,Fechamento,Var,Var%,Data,Nome

	!

	#exit pipeline with err code
	set -o pipefail
	
	#currency rates
	#define subfunction cf and loop variables
	#i=start at position, f=items per page, inc=increment (same as $f), max=max items
	i=1; f=25; inc=$f; max=175
	cf() { ${YOURAPP} "https://api.cotacoes.uol.com/mixed/summary?&currencies=${g}&fields=name,openbidvalue,askvalue,variationpercentbid,price,exchangeasset,open,pctChange,date,abbreviation&json=json" | procf;}
	printf 'Taxas de Moedas\n'
	loopf

	#stocks and indexes
	#redefine subfunction cf and loop variables
	i=1; f=9; inc=$f; max=2010
	cf() { ${YOURAPP} "https://api.cotacoes.uol.com/mixed/summary?&itens=${g}&fields=name,openbidvalue,askvalue,variationpercentbid,price,exchangeasset,open,pctChange,date,abbreviation&json=json" | procf;}
	printf '\n\nTaxas de Índices e Ações\n'
	loopf

}
#curl --compressed -s "https://api.cotacoes.uol.com/mixed/summary?&currencies=${c}&itens=${i}&fields=name,openbidvalue,askvalue,variationpercentbid,price,exchangeasset,open,pctChange,date,abbreviation&json=json" |

# Cotação da BOVESPA B3 Hack
b3f() {
	if ((B3OPT<=2)); then
		#get data
		UOLB3="$(${YOURAPP} 'https://api.cotacoes.uol.com/asset/intraday/list/?format=JSON&fields=price,high,low,open,volume,close,change,pctChange,date&item=1&')"
		#bid,ask,

		#Debug?
		if [[ -n "${PJSON}" ]]; then
			printf "%s\n" "${UOLB3}"
			exit
		fi
		
		#simple tickers
		if ((B3OPT==1)); then
			printf 'UOL - Bovespa B3\n'
			jq -r '.docs[0]|
				"Data   : \(.date)",
				"Alta   : \(.high)",
				"Baixa  : \(.low)",
				"Abertur: \(.open)",
				"Fechame: \(.close)",
				"Var    : \(.change)",
				"Var%   : \(.pctChange)%",
				"Pontos : \(.price)"'<<<"${UOLB3}" | sed -E 's/([0-9]{4})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})/\1-\2-\3T\4:\5:\6/'
		#série intraday
		else
			[[ ! -t 1 ]] && printf 'UOL - Bovespa B3\n' 1>&2
			printf 'UOL - Bovespa B3\n'
			jq -r '.docs|reverse[]|"\(.price)\t\(.high)\t\(.low)\t\(.open)\t\(.close)\t\(.change)\t\(.pctChange)%\t\(.date)"'<<<"${UOLB3}" | sed -E 's/([0-9]{4})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})/\1-\2-\3T\4:\5:\6/' | column -ets$'\t' -NPONTOS,ALTA,BAIXA,ABERT,FECHA,VAR,VAR%,DATA
		fi
	#serie histórica ano
	else
		UOLB3="$(${YOURAPP} 'https://api.cotacoes.uol.com/asset/interday/list/years/?format=JSON&fields=price,high,low,open,volume,close,bid,ask,change,pctChange,date&item=1&')"
		#Debug?
		if [[ -n "${PJSON}" ]]; then
			printf "%s\n" "${UOLB3}"
			exit
		fi
		
		[[ ! -t 1 ]] && printf 'UOL - Bovespa B3\n' 1>&2
		printf 'UOL - Bovespa B3\n'
		jq -r '.docs|reverse[]|"\(.price)\t\(.high)\t\(.low)\t\(.open)\t\(.close)\t\(.change)\t\(.pctChange)%\t\(.date)"'<<<"${UOLB3}" | sed -E 's/([0-9]{4})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})/\1-\2-\3T\4:\5:\6/' | column -ets$'\t' -NPONTOS,ALTA,BAIXA,ABERT,FECHA,VAR,VAR%,DATA
	fi
}

#Cotação dólar
dolarf() {
	#subfunction
	tablef() { jq -r '.docs|reverse[]|"\(.bidvalue)\t\(.askvalue)\t\(.maxbid)\t\(.minbid)\t\(.variationbid)\t\(.variationpercentbid)%\t\(.date)"' | sed -E 's/([0-9]{4})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})/\1-\2-\3T\4:\5:\6/' | column -ets$'\t' -NCOMPRA,VENDA,MAX,MIN,VAR,VAR%,DATA -TDATA;}

	if ((DOLAROPT<=2)); then
		#get data
		DT="$(${YOURAPP} 'https://api.cotacoes.uol.com/currency/intraday/list/?format=JSON&fields=bidvalue,askvalue,maxbid,minbid,variationbid,variationpercentbid,date&currency=3&')"
		DC="$(${YOURAPP} 'https://api.cotacoes.uol.com/currency/intraday/list/?format=JSON&fields=bidvalue,askvalue,maxbid,minbid,variationbid,variationpercentbid,date&currency=1&')"
		#DC="$(${YOURAPP} 'http://cotacoes.economia.uol.com.br/cambioJSONChart.html')"

		#Debug?
		if [[ -n "${PJSON}" ]]; then
			#printf "%s\n" "${DT}"
			printf "%s\n" "${DC}"
			exit
		fi

		#simple tickers
		if ((DOLAROPT==1)); then
			{
			#turismo
			jq -r '.docs[0]|
				"UOL - Dólar Turismo",
				"Data____: \(.date)",
				"VarCompr: \(.variationbid)",
				"Var%Comp: \(.variationpercentbid)%",
				"MaxCompr: \(.maxbid)",
				"MinCompr: \(.minbid)",
				"Venda___: \(.askvalue)",
				"Compra__: \(.bidvalue)"' <<< "${DT}"

			#comercial
			jq -r '.docs[0]|
				"",
				"UOL - Dólar Comercial",
				"Data____: \(.date)",
				"VarCompr: \(.variationbid)",
				"Var%Comp: \(.variationpercentbid)%",
				"MaxCompr: \(.maxbid)",
				"MinCompr: \(.minbid)",
				"Venda___: \(.askvalue)",
				"Compra__: \(.bidvalue)"' <<< "${DC}"
			#formata datas
			} | sed -E 's/([0-9]{4})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})/\1-\2-\3T\4:\5:\6/'

		#intraday
		else
			[[ ! -t 1 ]] && printf 'UOL - Dólar Turismo\n' 1>&2
			printf 'UOL - Dólar Turismo\n'
				tablef <<< "${DT}"

			[[ ! -t 1 ]] && printf '\nUOL - Dólar Comercial\n' 1>&2
			printf '\nUOL - Dólar Comercial\n'
				tablef <<< "${DC}"
		fi
	#historical prices
	else
		#get data	
		DT="$(${YOURAPP} 'https://api.cotacoes.uol.com/currency/interday/list/years/?format=JSON&fields=bidvalue,askvalue,maxbid,minbid,variationbid,variationpercentbid,date&currency=3&')"
		DC="$(${YOURAPP} 'https://api.cotacoes.uol.com/currency/interday/list/years/?format=JSON&fields=bidvalue,askvalue,maxbid,minbid,variationbid,variationpercentbid,date&currency=1&')"

		#Debug?
		if [[ -n "${PJSON}" ]]; then
			printf "%s\n" "${DT}"
			printf "%s\n" "${DC}"
			exit
		fi
		[[ ! -t 1 ]] && printf 'UOL - Dólar Turismo\n' 1>&2
		printf 'UOL - Dólar Turismo\n'
		tablef <<< "${DT}"

		[[ ! -t 1 ]] && printf '\nUOL - Dólar Comercial\n' 1>&2
		printf '\nUOL - Dólar Comercial\n'
		tablef <<< "${DC}"
	fi
}


# Lista de ações
lstocksf() {
	if ((LSTOCKSOPT==1)); then
		echo 'Ações da Bovespa'

		#not working anymore#
		#PRELIST="$(${YOURAPP} "http://cotacoes.economia.uol.com.br/acoes-bovespa.html?exchangeCode=.BVSP&page=1&size=2000" | hf | sed -n "/Nome Código/,/Páginas/p" | sed -e 's/^[ \t]*//' -e '1,2d' -e '/^[[:space:]]*$/d' -e '$d' | sed '$!N;s/\n/=/')"

		#from infomoney
		URL=https://www.infomoney.com.br/cotacoes/empresas-b3/
		PRELIST="$($YOURAPP "$URL" | sed -n '/<table*/,/<\/table/p')"

		#Debug?
		if [[ -n "${PJSON}" ]]; then
			printf "%s\n" "${PRELIST}"
			exit
		fi

		#choose a browser to process html
		if command -v w3m &>/dev/null
		then
			w3m -dump -T text/html
		elif command -v links &>/dev/null
		then
			tmp="$(mktemp)"
			cat >"$tmp"
			links -force-html -dump "$tmp"
			rm "$tmp"
		elif command -v lynx &>/dev/null
		then
			lynx -force_html -dump -nolist -stdin
		elif command -v elinks &>/dev/null
		then
			elinks -force-html -dump -no-references
		else
			sed 's/<[^>]*>//g'
			echo 'não foi possível usar um navegador de linha de comando para processar html' >&2
			echo 'considere instalar um entre w3m, links, lynx ou elinks' >&2
		fi <<<"$PRELIST"
		echo "<${URL}>"
	else
		#list from script offline database
		tail -"$LASTLINES" "$SCRIPT"
		printf 'Items: %s\n' "$(tail -"$LASTLINES" "$SCRIPT" | grep -c '^[0-9]')"
	fi
}

# Cotação dos metais
metf() {
	#get data
	COT="$(${YOURAPP} "https://economia.uol.com.br/cotacoes/")"
	
	#Debug?
	if [[ -n "${PJSON}" ]]; then
		printf "%s\n" "${COT}"
		exit
	fi

	printf "UOL - Metais Preciosos\n"
	
	hf <<<"${COT}" |
		grep -Eo 'Ouro.{117}' |
		grep -e 'US$' -e '%' |
		sed -e 's/[0-9]\s/&\n/g' -e 's/^\s\s*//' -e 's/US\$//g' |
		grep -Evi '(desce|sobre|d.lar|bolsa|melhor|pior|setor|tem|p.blico|privado|V)' |
		column -et -N'METAL,VAR,VENDA(US$/OZ)'
	
	grep -o "Câmbio\s*Atualizado em..............." <<<"${COT}" |
		sed -e 's/\s\s*/ /g' -e 's/Atualizado/atualizado/'
}

# Test for must have packages 
if command -v curl &>/dev/null; then
	YOURAPP='curl -s --compressed'
elif command -v wget &>/dev/null; then
	YOURAPP='wget -qO-'
else
	printf 'cURL ou Wget é necessário.\n' 1>&2
	exit 1
fi

#request compressed response
if ! command -v gzip &>/dev/null; then
	printf 'warning: gzip may be required\n' 1>&2
fi

#default option if no user input
(( $# )) ||  set -- -d

# Parse options
while getopts :abdjlmhv opt; do
	case ${opt} in
		a ) #scrape data
			SCRAPEOPT=1
			;;
		b ) #b3 
			((B3OPT++))
	      		;;
		d ) #dolar 
			((DOLAROPT++))
	      		;;
		j ) #debug, print json
			PJSON=1
			;;
		l ) #lista de ações
			((LSTOCKSOPT++))
	      		;;
		m ) #cotações metais
			METAISOPT=1
	      		;;
		h ) # Help
	      		echo -e "${AJUDA}"
	      		exit 0
	      		;;
		v ) # Version of Script
	      		grep -m1 '# v' "${0}"
	      		exit 0
	      		;;
		\? )
	     		echo "Opção inválida: -$OPTARG" >&2
	     		exit 1
	     		;;
  	esac
done
shift $((OPTIND -1))

# Check for no arguments or options in input
#printf 'Rode com -h para ajuda.\n' 1>&2
#exit 1

#Call opts
if ((B3OPT)); then
	b3f 
elif ((DOLAROPT)); then
	dolarf 
elif ((METAISOPT)); then
	metf
elif ((LSTOCKSOPT)); then
	lstocksf
elif ((SCRAPEOPT)); then
	scrapef
else
	#tickeres resumidos
	#is that a name?
	if [[ "$*" = *[a-zA-Z]* ]]; then
		arg=( $(tail -"$LASTLINES" "$SCRIPT" | awk -F$'\t' "/$*/ {print \$1}") )
		if [[ -z "${arg[0]}" ]]; then
			set -- $(tr 'a-z' 'A-Z' <<<"$*")
			arg=( $(tail -"$LASTLINES" "$SCRIPT" | awk -F$'\t' "toupper(\$0) ~ /$*/ {print \$1}") )
			[[ -z "${arg[0]}" ]] && exit 1
		fi
		set  -- "${arg[0]}"
	fi

	#is that an ID number?
	if [[ "$*" =~ ^[0-9]+$ ]]; then
		{
		printf 'NUM_ID_: %s\n\n' "$1"
		#ticker de ações/indexes
		#ticker de uma ação, por número de id do uol
		JSON="$(${YOURAPP} "https://api.cotacoes.uol.com/stocks/summary?&item=${1}&fields=openbidvalue,askvalue,variationpercentbid,price,exchangeasset,open,pctChange,date,abbreviation&json=json")"

		jq -r '.docs[]|
			"Data___: \(.date)",
			"Nome___: \(.exchangeasset)",
			"Abbrvia: \(.abbreviation)",
			"Abertur: \(.open)",
			"Variaç%: \(.pctChange)",
			"Preço__: \(.price)"' <<<"${JSON}"

		#ticker de moedas
		if ((${1}<170)); then
			#ticker de uma moeda, por número de id do uol
			JSON="$(${YOURAPP} "https://api.cotacoes.uol.com/currency/summary?&currency=${1}&fields=name,openbidvalue,askvalue,variationpercentbid,price,exchangeasset,open,pctChange,date&json=json")"

			jq -r '.docs[]|
				"",
				"Data___: \(.date)",
				"Nome___: \(.name)",
				"Varia%_: \(.variationpercentbid)",
				"Venda__: \(.askvalue)",
				"Compra_: \(.openbidvalue)"' <<<"${JSON}"
		fi
		#formata data
		} | sed -E 's/([0-9]{4})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})/\1-\2-\3T\4:\5:\6/'
	else
		exit 1
	fi
fi

exit 0
#next section is printed when option -ll is run






UOL - Economia
Lista de moedas, ações e indexes
Puxado em 13/Fevereiro/2020

Moedas
Número,Nome

1	Dólar Comercial
2	Dólar Paralelo
3	Dólar Turismo
4	Euro
5	Euro (R$)
6	Libra Esterlina
7	Libra Esterlina (R$)
8	Iene
9	Iene (R$)
10	Peso Argentino
11	Peso Argentino (R$)
12	Rand
13	Rand (R$)
14	Dinar
15	Dinar (R$)
16	Rial Saldita
17	Rial Saldita (R$)
18	Dólar Australiano
19	Dólar Australiano (R$)
20	Teca
21	Teca (R$)
22	Rublo Bielo-Russo
23	Rublo Bielo-Russo (R$)
24	Lev
25	Lev (R$)
26	Dólar Canadense
27	Dólar Canadense (R$)
28	Tenge
29	Tenge (R$)
30	Dólar de Cingapura
31	Dólar de Cingapura (R$)
32	Peso Chileno
33	Peso Chileno (R$)
34	Yuan
35	Yuan (R$)
36	Peso Colombiano
37	Peso Colombiano (R$)
38	Won sul-coreano
39	Won sul-coreano (R$)
40	Kuna
41	Kuna (R$)
42	Coroa dinamarquesa
43	Coroa (R$)
44	Libra Egípcia
45	Libra Egípcia (R$)
46	Coroa Eslovaca
47	Coroa Eslovaca (R$)
48	Coroa Estoniana
49	Coroa Estoniana (R$)
50	Peso Filipino
51	Peso Filipino (R$)
52	Dólar de Hong Kong
53	Dólar de Hong Kong (R$)
54	Forinte
55	Forinte (R$)
56	Rupia Indiana
57	Rupia Indiana (R$)
58	Rupia Indonésia
59	Rupia Indonésia (R$)
60	Rial Iraniano
61	Rial Iraniano (R$)
62	Shekel Novo
63	Shekel Novo (R$)
64	Dinar Jordaniano
65	Dinar Jordaniano (R$)
66	Dinar Kuaitiano
67	Dinar Kuaitiano (R$)
68	Lat
69	Lat (R$)
70	Kip Laosiano
71	Kip Laosiano (R$)
72	Libra Libanesa
73	Libra Libanesa (R$)
74	Dinar Líbio
75	Dinar Líbio (R$)
76	Litas
77	Litas (R$)
78	Ringgit
79	Ringgit (R$)
80	Dirham Marroquino
81	Dirham Marroquino (R$)
82	Peso Novo Mexicano
83	Peso Novo Mexicano (R$)
84	Leu
85	Leu (R$)
86	Dólar Namibiano
87	Dólar Namibiano (R$)
88	Coroa Norueguesa
89	Coroa Norueguesa (R$)
90	Dólar da Nova Zelândia
91	Dólar da Nova Zelândia (R$)
92	Rupia Paquistanesa
93	Rupia Paquistanesa (R$)
94	Guarani
95	Guarani (R$)
96	Sol Novo
97	Sol Novo (R$)
98	Zloty
99	Zloty (R$)
100	Rial de Qatar
101	Rial de Qatar (R$)
102	Xelim Queniano
103	Xelim Queniano (R$)
104	Coroa Tcheca
105	Coroa Tcheca (R$)
106	Novo leu romeno (R$)
107	Novo leu romeno (R$)
108	Rublo
109	Rublo (R$)
110	Libra Síria
111	Libra Síria (R$)
112	Rupia Cingalesa
113	Rupia Cingalesa (R$)
114	Coroa Sueca
115	Coroa Sueca (R$)
116	Franco Suíço
117	Franco Suíço (R$)
118	Baht
119	Baht (R$)
120	Dólar Taiwanês
121	Dólar Taiwanês (R$)
122	Dinar Tunisiano
123	Dinar Tunisiano (R$)
124	Lira
125	Lira (R$)
126	Hrivna
127	Hrivna (R$)
128	Peso Uruguaio
129	Peso Uruguaio (R$)
130	Dólar do Zimbábue
131	Dólar do Zimbábue (R$)
132	Kwanza (R$)
133	Lek (R$)
134	Peso Cubano
135	Peso Cubano (R$)
136	Dinar
137	Dinar (R$)
138	Coroa Islandesa
139	Coroa Islandesa (R$)
140	Metical
141	Metical (R$)
142	Balboa
143	Balboa (R$)
144	Bolívar
145	Bolívar (R$)
146	Boliviano
147	Boliviano (R$)
148	Lek
149	Lek (R$)
150	Dólar Fechamento do Dia
151	Dirham
152	Dirham (R$)
153	Rublo Bielo-Russo
154	Rublo Bielo-Russo (R$)
155	Bolívar Soberano
156	Bolívar Soberano (R$)
157	Dólar Fechamento do Dia

Ações e Índices
Número,Nome,Código

1	BVSP BOVESPA IND	.BVSP
2	IBX IND	.IBX
3	IBX50 INDEX	.IBX50
4	IEE IND	.IEE
5	IGCX IND	.IGCX
6	ITEL IND	.ITEL
7	IVBX IND	.IVBX
8	ITAG IND	.ITAG
9	ISE IND	.ISE
10	INDX IND	.INDX
11	Lima General Inx	.IGRA
12	PX-PRAGUE SE IND	.PX
13	SASE Gral Index	.IGPA
14	TA-100 INDEX	.TA100
15	ISE National-100	.XU100
16	IBC INDEX	.IBC
17	CAC 40	.FCHI
18	ABC BRASIL PN	ABCB4.SA	ABC Brasil Banco 
20	ABNOTE ON	ABNB3.SA	ABNB3.SA (ABNOTE ON)
21	ABYARA ON	ABYA3.SA	Construtora Tenda Empresa 
22	ACUCAR GUAR ON	ACGU3.SA	ACGU3.SA (ACUCAR GUAR ON)
23	ANHANGUERA UNT	AEDU11.SA	AEDU11.SA (ANHANGUERA UNT)
24	ANHANGUERA ON	AEDU3.SA	AEDU3.SA (ANHANGUERA ON)
26	AES ELPA ON	AELP3.SA	AES ELPA S.A. 
27	AES SUL ON	AESL3.SA	AESL3.SA (AES SUL ON)
28	AES SUL PN	AESL4.SA	AESL4.SA (AES SUL PN)
30	AGRENCO BDR	AGEN11.SA	AGEN11.SA (AGRENCO BDR)
31	AGRA INCORP ON	AGIN3.SA	AGIN3.SA (AGRA INCORP ON)
32	BRASILAGRO ON	AGRO3.SA	BrasilAgro Empresa 
33	SPTURIS ON	AHEB3.SA	São Paulo Turismo S/A Empresa 
34	SPTURIS PNA	AHEB5.SA	SAO PAULO TURISMO S.A. 
35	SPTURIS PNB	AHEB6.SA	Bovespa
36	ALL AMER LAT PN	ALLL4.SA	ALLL4.SA (ALL AMER LAT PN)
37	ALL AMER LAT ON	ALLL3.SA	ALLL3.SA (ALL AMER LAT ON)
38	ALL AMER LAT UNT	ALLL11.SA	ALLL11.SA (ALL AMER LAT UNT)
39	ALPARGATAS PN	ALPA4.SA	Alpargatas S.A. 
40	ALPARGATAS ON	ALPA3.SA	Alpargatas S.A. 
43	AMBEV ON	AMBV3.SA	AMBEV ON
44	AMBEV PN	AMBV4.SA	AMBV4.SA (AMBEV PN)
45	AMERICEL ON	AMCE3.SA	AMCE3.SA (AMERICEL ON)
47	AMIL ON	AMIL3.SA	AMIL3.SA (AMIL ON)
48	AMPLA INVEST ON	AMPI3.SA	AMPI3.SA (AMPLA INVEST ON)
49	ALIPERTI ON	APTI3.SA	SIDERURGICA J. L. ALIPERTI S.A. 
50	ALIPERTI PN	APTI4.SA	APTI4 (ALIPERTI PN) 
51	ARACRUZ PNA	ARCZ5.SA	ARCZ5.SA (ARACRUZ PNA)
52	ARACRUZ PNB	ARCZ6.SA	ARCZ6.SA (ARACRUZ PNB)
53	ARACRUZ ON	ARCZ3.SA	ARCZ3.SA (ARACRUZ ON)
54	ARTHUR LANGE PN	ARLA4.SA	ARLA4.SA (ARTHUR LANGE PN)
55	ARTHUR LANGE ON	ARLA3.SA	ARLA3.SA (ARTHUR LANGE ON)
57	ACOS VILL ON	AVIL3.SA	AVIL3.SA (ACOS VILL ON)
58	AZEVEDO PN	AZEV4.SA	Azevedo E Travassos SA Empresa 
59	AZEVEDO ON	AZEV3.SA	Azevedo E Travassos SA Empresa 
60	BAHEMA PNA	BAHI4.SA	BAHI4.SA (BAHEMA PNA)
61	BAHEMA ON	BAHI3.SA	Bahema Educacao SA Empresa
62	BAUMER ON	BALM3.SA	Baumer SA Empresa
63	BAUMER PN	BALM4.SA	Baumer SA Empresa
64	EXCELSIOR PN	BAUH4.SA	Excelsior Empresa
66	AMAZONIA ON	BAZA3.SA	BCO Amazonia S.A. Banco
67	BRASIL ON	BBAS3.SA	Banco do Brasil 
68	BRADESCO ON	BBDC3.SA	Bradesco Banco 
69	BRADESCO PN	BBDC4.SA	Bradesco Banco 
70	BRASIL BROK ON	BBRK3.SA	Brasil Brokers Participacoes S.A. Empresa
71	BARDELLA PN	BDLL4.SA	Bardella S.A. Indústrias Mecânicas Empresa 
72	BARDELLA ON	BDLL3.SA	Bardella S.A. Indústrias Mecânicas Empresa 
73	MINERVA ON	BEEF3.SA	Minerva Foods Empresa 
74	BANESTES ON	BEES3.SA	Banco do Estado do Espírito Santo 
75	BEMATECH ON	BEMA3.SA	Banco do Brasil 
76	BANESE ON	BGIP3.SA	Banco do Estado de Sergipe S.A. Banco
77	BANESE PN	BGIP4.SA	Banco do Estado de Sergipe S.A. Banco
78	BICBANCO ON	BICB3.SA	BICB3.SA (BICBANCO ON)
79	BICBANCO PN	BICB4.SA	BICB4.SA (BICBANCO PN)
80	BIOMM PN	BIOM4.SA	BIOM4.SA (BIOMM PN)
81	BIOMM ON	BIOM3.SA	Biomm S.A. Empresa 
82	BROOKFIELD ON	BISA3.SA	BISA3.SA (BROOKFIELD ON)
83	MERC BRASIL PN	BMEB4.SA	Banco Mercantil do Brasil 
84	MERC BRASIL ON	BMEB3.SA	Banco Mercantil do Brasil 
85	MERC INVEST ON	BMIN3.SA	Banco Mercantil de Investimentos Empresa
86	MERC INVEST PN	BMIN4.SA	Banco Mercantil de Investimentos Empresa
87	BIC MONARK ON	BMKS3.SA	Monark Empresa 
88	BRASMOTOR ON	BMTO3.SA	BMTO3.SA (BRASMOTOR ON)
89	BRASMOTOR PN	BMTO4.SA	BMTO4.SA (BRASMOTOR PN)
90	NORD BRASIL PN	BNBR4.SA	BNBR4.SA (NORD BRASIL PN)
91	NORD BRASIL ON	BNBR3.SA	Banco do Nordeste 
92	NOSSA CAIXA ON	BNCA3.SA	BNCA3.SA (NOSSA CAIXA ON)
93	BOMBRIL ON	BOBR3.SA	BOMBRIL ON 
94	BOMBRIL PN	BOBR4.SA	Bombril Empresa 
95	BANPARA ON	BPAR3.SA	BCO ESTADO DO PARA S.A. 
96	PATAGONIA BDR	BPAT11.SA	BPAT11.SA (PATAGONIA BDR)
97	EST PIAUI ON	BPIA3.SA	BPIA3.SA (EST PIAUI ON)
99	PANAMERICANO PR	BPNM4.SA	BPNM4.SA (PANAMERICANO PR)
100	BRADESPAR PN	BRAP4.SA	Bradespar SA Empresa
101	BRADESPAR ON	BRAP3.SA	Bradespar SA Empresa
102	ALFA CONSORC ON	BRGE3.SA	Consorcio Alfa De Administracao SA Empresa
103	ALFA CONSORC PNE	BRGE11.SA	Consorcio Alfa De Administracao SA Empresa
104	ALFA CONSORC PNB	BRGE6.SA	CONSORCIO ALFA DE ADMINISTRACAO S.A. 
105	ALFA CONSORC PNC	BRGE7.SA	CONSORCIO ALFA DE ADMINISTRACAO S.A. 
106	ALFA CONSORC PNA	BRGE5.SA	CONSORCIO ALFA DE ADMINISTRACAO S.A. 
107	ALFA CONSORC PND	BRGE8.SA	Consorcio Alfa De Administracao SA Empresa
108	ALFA CONSORC PNF	BRGE12.SA	Consorcio Alfa De Administracao SA Empresa
109	ALFA INVEST PN	BRIV4.SA	Banco Alfa de Investimento SA
110	ALFA INVEST ON	BRIV3.SA	Banco Alfa de Investimento SA
111	BRASKEM PNA	BRKM5.SA	Braskem Empresa 
112	BRASKEM ON	BRKM3.SA	Braskem Empresa 
113	BRASKEM PNB	BRKM6.SA	BRASKEM S.A. 
114	BR MALLS PAR ON	BRML3.SA	brMalls Empresa 
115	BANRISUL PNB	BRSR6.SA	Banrisul Banco 
116	BANRISUL PNA	BRSR5.SA	Banrisul Banco 
117	BANRISUL ON	BRSR3.SA	Banrisul Banco 
118	BRASIL TELEC ON	BRTO3.SA	BRTO3.SA (BRASIL TELEC ON)
119	BRASIL TELEC PN	BRTO4.SA	BRTO4.SA (BRASIL TELEC PN)
120	BRASIL T PAR PN	BRTP4.SA	BRTP4.SA (BRASIL T PAR PN)
121	BRASIL T PAR ON	BRTP3.SA	BRTP3.SA (BRASIL T PAR ON)
122	BESC ON	BSCT3.SA	BSCT3.SA (BESC ON)
124	BESC PNA	BSCT5.SA	BSCT5.SA (BESC PNA)
125	BESC PNB	BSCT6.SA	BSCT6.SA (BESC PNB)
131	BRB BANCO PN	BSLI4.SA	BRB BCO DE BRASILIA S.A. 
132	BRB BANCO ON	BSLI3.SA	BRB BCO DE BRASILIA S.A. 
133	B2W GLOBAL ON	BTOW3.SA	B2W Digital Empresa 
134	BATTISTELLA PN	BTTL4.SA	BTTL4.SA (BATTISTELLA PN)
135	BATTISTELLA ON	BTTL3.SA	Battistella ADM Participacoes SA Empresa
136	BUETTNER ON	BUET3.SA	BUET3.SA (BUETTNER ON)
137	BUETTNER PN	BUET4.SA	BUET4.SA (BUETTNER PN)
138	CAF BRASILIA PN	CAFE4.SA	CAFE4.SA (CAF BRASILIA PN)
139	CAF BRASILIA ON	CAFE3.SA	CAFE3.SA (CAF BRASILIA ON)
140	CONST A LIND PN	CALI4.SA	CONSTRUTORA ADOLPHO LINDENBERG S.A. 
141	CONST A LIND ON	CALI3.SA	CONSTRUTORA ADOLFO L ON 
142	CAMBUCI ON	CAMB3.SA	Cambuci SA Empresa 
143	CAMBUCI PN	CAMB4.SA	CAMBUCI S.A. 
144	CSU CARDSYST ON	CARD3.SA	CSU Cardsystem SA Empresa
145	CASAN ON	CASN3.SA	Companhia Catarinense de Águas e Saneamento Empresa 
148	CASAN PN	CASN4.SA	Companhia de Saneamento do Paraná Empresa 
151	BAN ARMAZENS ON	CBAG3.SA	CBAG3.SA (BAN ARMAZENS ON)
152	AMPLA ENERG ON	CBEE3.SA	Ampla Energia E Servicos SA Empresa
153	COBRASMA PN	CBMA4.SA	CBMA4.SA (COBRASMA PN)
154	COBRASMA ON	CBMA3.SA	CBMA3.SA (COBRASMA ON)
155	CHIARELLI ON	CCHI3.SA	CCHI3.SA (CHIARELLI ON)
156	CHIARELLI PN	CCHI4.SA	Recrusul SA Empresa 
157	CC DES IMOB ON	CCIM3.SA	CCIM3.SA (CC DES IMOB ON)
158	CYRE COM-CCP ON	CCPR3.SA	Cyrela Commercial Propertes SA Emp Partp
159	CCR RODOVIAS ON	CCRO3.SA	Grupo CCR Empresa 
160	CEB PNA	CEBR5.SA	Companhia Energetica de Brasilia 
161	CEB PNB	CEBR6.SA	Companhia Energetica de Brasilia 
162	CEB ON	CEBR3.SA	Companhia Energetica de Brasilia 
163	CEDRO PN	CEDO4.SA	Cedro Textil Empresa 
164	CEDRO ON	CEDO3.SA	Cedro Textil Empresa 
166	COELBA PNA	CEEB5.SA	Companhia de Eletricidade do Estado da Bahia 
167	COELBA ON	CEEB3.SA	Companhia de Eletricidade do Estado da Bahia 
168	CEG ON	CEGR3.SA	CIA DISTRIB DE GAS DO RIO DE JANEIRO
169	CELM ON	CELM3.SA	CELM3.SA (CELM ON)
170	CELPA PNB	CELP6.SA	CELPA PNB
171	CELPA PNC	CELP7.SA	CELPA PNC
172	CELPA PNA	CELP5.SA	CELPA PNA
173	CELPA ON	CELP3.SA	Equatorial Energia Pará Empresa 
174	CELPE ON	CEPE3.SA	Companhia Energética de Pernambuco Empresa 
175	CELPE PNB	CEPE6.SA	Companhia Energética de Pernambuco Empresa 
176	CELPE PNA	CEPE5.SA	CIA ENERGETICA DE PERNAMBUCO 
177	CESP ON	CESP3.SA	Companhia Energética de São Paulo 
178	CESP PNA	CESP5.SA	Companhia Energética de São Paulo 
179	CESP PNB	CESP6.SA	Companhia Energética de São Paulo 
180	COMGAS PNA	CGAS5.SA	Comgás Empresa 
181	COMGAS ON	CGAS3.SA	Comgás Empresa 
182	GRAZZIOTIN ON	CGRA3.SA	Grazziotin S.A. Empresa
183	GRAZZIOTIN PN	CGRA4.SA	Grazziotin S.A. Empresa
184	CACIQUE PN	CIQU4.SA	CIQU4.SA (CACIQUE PN)
185	CACIQUE ON	CIQU3.SA	CIQU3.SA (CACIQUE ON)
186	CELESC ON	CLSC3.SA	Centrais Elétricas de Santa Catarina Empresa 
187	CELESC PNA	CLSC5.SA	CLSC5.SA (CELESC PNA)
188	CELESC PNB	CLSC6.SA	CLSC6.SA (CELESC PNB)
189	CEMAT ON	CMGR3.SA	CMGR3.SA (CEMAT ON)
190	CEMAT PN	CMGR4.SA	CMGR4.SA (CEMAT PN)
191	CEMIG ON	CMIG3.SA	Companhia Energética de Minas Gerais 
192	CEMIG PN	CMIG4.SA	Companhia Energética de Minas Gerais 
195	CONFAB ON	CNFB3.SA	CNFB3.SA (CONFAB ON)
196	CONFAB PN	CNFB4.SA	CNFB4.SA (CONFAB PN)
197	COELCE PNB	COCE6.SA	COCE6 (COELCE PNB) 
198	COELCE ON	COCE3.SA	Enel Distribuição Ceará Companhia 
199	COELCE PNA	COCE5.SA	Enel Distribuição Ceará Companhia 
200	COR RIBEIRO PN	CORR4.SA	CORREA RIBEIRO S.A. COMERCIO E INDUSTRIA 
201	COR RIBEIRO ON	CORR3.SA	CORREA RIBEIRO S.A. COMERCIO E INDUSTRIA 
202	CPFL ENERGIA ON	CPFE3.SA	CPFL Energia 
203	COPEL PNA	CPLE5.SA	COPEL PNA 
204	COPEL ON	CPLE3.SA	Companhia Paranaense de Energia Empresa 
205	COPEL PNB	CPLE6.SA	Companhia Paranaense de Energia Empresa 
206	COMPANY ON	CPNY3.SA	CPNY3.SA (COMPANY ON)
207	CARAIBA MET PNA	CRBM5.SA	CRBM5.SA (CARAIBA MET PNA)
208	CARAIBA MET ON	CRBM3.SA	CRBM3.SA (CARAIBA MET ON)
210	CARAIBA MET PNC	CRBM7.SA	CRBM7.SA (CARAIBA MET PNC)
211	CARAIBA MET PNE	CRBM11.SA	CRBM11.SA (CARAIBA MET PNE)
212	CR2 ON	CRDE3.SA	CR2 Empreendimentos Imobiliarios SA Empresa
213	CREMER ON	CREM3.SA	CREM3.SA (CREMER ON)
214	ALFA FINANC PN	CRIV4.SA	Financeira Alfa SA 
215	ALFA FINANC ON	CRIV3.SA	Financeira Alfa SA 
216	SOUZA CRUZ ON	CRUZ3.SA	CRUZ3.SA (SOUZA CRUZ ON)
217	SEG AL BAHIA PN	CSAB4.SA	CSAB4.SA (SEG AL BAHIA PN)
218	SEG AL BAHIA ON	CSAB3.SA	CIA Seguros Alianca Da Bahia Empresa
219	COSAN ON	CSAN3.SA	Cosan S.A. 
220	SEG MIN BRAS ON	CSMB3.SA	CSMB3.SA (SEG MIN BRAS ON)
221	COPASA MG ON	CSMG3.SA	Companhia de Saneamento de Minas Gerais 
222	SID NACIONAL ON	CSNA3.SA	Companhia Siderúrgica Nacional 
223	COSERN PNB	CSRN6.SA	CSRN6.SA (COSERN PNB)
224	COSERN PNA	CSRN5.SA	Companhia Energética do Rio Grande do Norte Empresa 
225	COSERN ON	CSRN3.SA	Companhia Energética do Rio Grande do Norte Empresa 
226	CONTAX ON	CTAX3.SA	CTAX3.SA (CONTAX ON)
227	CONTAX PN	CTAX4.SA	CTAX4.SA (CONTAX PN)
228	KARSTEN PN	CTKA4.SA	Karsten Companhia 
229	KARSTEN ON	CTKA3.SA	Karsten Companhia 
232	COTEMINAS PN	CTNM4.SA	CIA Tecidos Norte De Minas COTEMINAS Empresa
233	COTEMINAS ON	CTNM3.SA	CIA Tecidos Norte De Minas COTEMINAS Empresa
234	MARAMBAIA ON	CTPC3.SA	CTPC3.SA (MARAMBAIA ON)
235	SANTANENSE ON	CTSA3.SA	Santanense Empresa
236	SANTANENSE PN	CTSA4.SA	Santanense Empresa
237	SANTANENSE PND	CTSA8.SA	CIA TECIDOS SANTANENSE 
238	CYRELA REALT ON	CYRE3.SA	Cyrela Incorporador de imóveis 
239	COSAN LTD BDR	CZLT11.SA	CZLT11.SA (COSAN LTD BDR)
241	CRUZEIRO SUL PN	CZRS4.SA	CZRS4.SA (CRUZEIRO SUL PN)
243	DASA ON	DASA3.SA	DASA Empresa 
244	DAYCOVAL PN	DAYC4.SA	DAYC4.SA (DAYCOVAL PN)
246	D H B PN	DHBI4.SA	DHBI4.SA (D H B PN)
247	D H B ON	DHBI3.SA	DHBI3.SA (D H B ON)
248	DOCAS PN	DOCA4.SA	DOCA4.SA (DOCAS PN)
249	DOCAS ON	DOCA3.SA	DOCA3.SA (DOCAS ON)
250	DOHLER ON	DOHL3.SA	Döhler Empresa 
251	DOHLER PN	DOHL4.SA	Döhler Empresa 
252	DROGASIL ON	DROG3.SA	DROG3.SA (DROGASIL ON)
254	DTCOM-DIRECT ON	DTCY3.SA	Dtcom Empresa 
255	DUFRY BDR	DUFB11.SA	DUFB11.SA (DUFRY BDR)
256	MET DUQUE PN	DUQE4.SA	DUQE4.SA (MET DUQUE PN)
257	MET DUQUE ON	DUQE3.SA	DUQE3.SA (MET DUQUE ON)
258	SEE DTEX3.SA	DURA4.SA	DURA4.SA (SEE DTEX3.SA)
259	SEE DTEX3.SA	DURA3.SA	DURA3.SA (SEE DTEX3.SA)
261	DIXIE TOGA PN	DXTG4.SA	DXTG4.SA (DIXIE TOGA PN)
262	ACO ALTONA PN	EALT4.SA	Electro Aço Altona S.A. Empresa 
263	ACO ALTONA ON	EALT3.SA	Electro Aço Altona S.A. Empresa 
264	EMBRATEL PAR ON	EBTP3.SA	EBTP3.SA (EMBRATEL PAR ON)
265	EMBRATEL PAR PN	EBTP4.SA	Petrobras Empresa 
266	ECODIESEL ON	ECOD3.SA	ECOD3.SA (ECODIESEL ON)
267	ENCORPAR PN	ECPR4.SA	Empresa Nacional de Comercio Redito e Participacoes S.A. 
268	ENCORPAR ON	ECPR3.SA	EMPRESA NAC COM REDITO PART S.A.ENCORPAR 
269	ELEKTRO ON	EKTR3.SA	Elektro Empresa 
270	ELEKTRO PN	EKTR4.SA	Elektro Empresa 
271	ELEKEIROZ ON	ELEK3.SA	ELEKEIROZ S.A. 
272	ELEKEIROZ PN	ELEK4.SA	ELEKEIROZ S.A. 
273	ELETROBRAS PNB	ELET6.SA	Eletrobras Holding 
274	ELETROBRAS ON	ELET3.SA	Eletrobras Holding 
275	ELETROBRAS PNA	ELET5.SA	CENTRAIS ELET BRAS S.A. 
276	ELETROPAULO ON	ELPL3.SA	ELETROPAULO METROP. ELET. SAO PAULO S.A. 
277	ELETROPAULO PNA	ELPL5.SA	ELPL5.SA (ELETROPAULO PNA)
278	ELETROPAULO PNB	ELPL6.SA	Eletrobras Holding 
279	ELUMA PN	ELUM4.SA	ELUM4.SA (ELUMA PN)
280	ELUMA ON	ELUM3.SA	ELUM3.SA (ELUMA ON)
281	EMAE PN	EMAE4.SA	Empresa Metropolitana de Águas e Energia 
282	EMAE ON	EMAE3.SA	EMPRESA METROP.AGUAS ENERGIA S.A.
283	EMBRAER ON	EMBR3.SA	Embraer SA Empresa
284	ENERGIAS BR ON	ENBR3.SA	EDP Brasil 
285	ENERGISA PN	ENGI4.SA	Grupo Energisa Empresa 
286	ENERGISA ON	ENGI3.SA	Grupo Energisa Empresa 
287	EQUATORIAL ON	EQTL3.SA	Equatorial Energia Empresa 
288	ESTACIO PART ON	ESTC3.SA	ESTC3.SA (ESTACIO PART ON)
289	ESTRELA ON	ESTR3.SA	MANUFATURA DE BRINQUEDOS ESTRELA S.A. 
290	ESTRELA PN	ESTR4.SA	Manufaturas de Brinquedos Estrela SA Empresa
291	ETERNIT ON	ETER3.SA	Eternit Empresa 
292	EUCATEX PN	EUCA4.SA	Eucatex Empresa 
293	EUCATEX ON	EUCA3.SA	Eucatex Empresa 
294	EVEN ON	EVEN3.SA	Even Empresa 
295	EZTEC ON	EZTC3.SA	EZ TEC Empreendimentos e Participacoes SA Empresa
296	FIBAM ON	FBMC3.SA	FBMC3.SA (FIBAM ON)
297	FIBAM PN	FBMC4.SA	FBMC4.SA (FIBAM PN)
298	SAM INDUSTR ON	FCAP3.SA	FCAP3.SA (SAM INDUSTR ON)
299	SAM INDUSTR PN	FCAP4.SA	SAM INDUSTRIAS S.A. 
300	FERBASA PN	FESA4.SA	CIA de Ferro Ligas da Bahia 
301	FERBASA ON	FESA3.SA	CIA de Ferro Ligas da Bahia 
302	FOSFERTIL ON	FFTL3.SA	FFTL3.SA (FOSFERTIL ON)
303	FOSFERTIL PN	FFTL4.SA	FFTL4.SA (FOSFERTIL PN)
304	F GUIMARAES PN	FGUI4.SA	FGUI4.SA (F GUIMARAES PN)
305	F GUIMARAES ON	FGUI3.SA	FGUI3.SA (F GUIMARAES ON)
306	FER HERINGER ON	FHER3.SA	Fertilizantes Heringer Empresa 
307	INVEST BEMGE ON	FIGE3.SA	FIGE3.SA (INVEST BEMGE ON)
308	INVEST BEMGE PN	FIGE4.SA	INVEST BEMGE PN 
309	FORJA TAURUS PN	FJTA4.SA	TAURUS ARMAS S.A. 
310	FORJA TAURUS ON	FJTA3.SA	FJTA3.SA (FORJA TAURUS ON)
312	FRAS-LE PN	FRAS4.SA	FRAS4.SA (FRAS
313	FRAS-LE ON	FRAS3.SA	Fras-le SA
314	METALFRIO ON	FRIO3.SA	FRIO3.SA (METALFRIO ON)
315	FAB C RENAUX ON	FTRX3.SA	FTRX3.SA (FAB C RENAUX ON)
316	FAB C RENAUX PN	FTRX4.SA	FTRX4.SA (FAB C RENAUX PN)
317	CIMOB PART ON	GAFP3.SA	GAFP3.SA (CIMOB PART ON)
318	CIMOB PART PN	GAFP4.SA	GAFP4.SA (CIMOB PART PN)
319	GAZOLA ON	GAZO3.SA	Histórico de Cotações da ação GAZO3.SA (GAZOLA ON ) 
320	GAZOLA PN	GAZO4.SA	GAZO4.SA (GAZOLA PN)
321	GER PARANAP PN	GEPA4.SA	Rio Paranapanema Energia SA Empresa
322	GER PARANAP ON	GEPA3.SA	Rio Paranapanema Energia SA Empresa
323	AES TIETE ON	GETI3.SA	Banco do Brasil 
324	AES TIETE PN	GETI4.SA	GETI4.SA (AES TIETE PN)
325	GAFISA ON	GFSA3.SA	Gafisa Empresa 
326	GERDAU ON	GGBR3.SA	Gerdau Empresa 
327	GERDAU PN	GGBR4.SA	Gerdau Empresa 
328	GLOBEX ON	GLOB3.SA	GLOB3.SA (GLOBEX ON)
329	GERDAU MET ON	GOAU3.SA	Metalúrgica Gerdau Empresa
330	GERDAU MET PN	GOAU4.SA	Metalúrgica Gerdau Empresa
332	GOL PN	GOLL4.SA	Gol Linhas Aéreas Companhia aérea 
333	GPC PART ON	GPCP3.SA	GPC Participacoes S.A. Empresa 
334	GP INVEST BDR	GPIV11.SA	GPIV11.SA (GP INVEST BDR)
335	GRENDENE ON	GRND3.SA	Grendene Empresa 
338	GENERALSHOPP ON	GSHP3.SA	General Shopping Empresa 
339	GUARARAPES ON	GUAR3.SA	Guararapes Confeccoes S.A. Empresa
340	GUARARAPES PN	GUAR4.SA	GUAR4.SA (GUARARAPES PN)
341	GVT HOLDING ON	GVTT3.SA	GVTT3.SA (GVT HOLDING ON)
342	HAGA S/A PN	HAGA4.SA	Haga S.A. Industria E Comercio Empresa
343	HAGA S/A ON	HAGA3.SA	Haga S.A. Industria E Comercio Empresa
344	HELBOR ON	HBOR3.SA	Helbor Empresa 
346	HABITASUL PNA	HBTS5.SA	COMPANHIIA HABITASUL DE PARTICIPAÇÕES Empresa 
348	HERCULES ON	HETA3.SA	HERCULES S.A. FABRICA DE TALHERES 
349	HERCULES PN	HETA4.SA	Hercules Empresa 
350	CIA HERING ON	HGTX3.SA	CIA Hering SA Empresa 
351	HOTEIS OTHON PN	HOOT4.SA	Hoteis Othon S.A. Empresa 
353	HYPERMARCAS ON	HYPE3.SA	Hypera Pharma Empresa 
354	IDEIASNET ON	IDNT3.SA	IDNT3 é o código de negociação na B3 (antiga BM	IDNT3.SAFBOVESPA ) das ações ordinárias
355	BCO INDUSVAL ON	IDVL3.SA	Banco Indusval SA 
356	BCO INDUSVAL PN	IDVL4.SA	Banco Indusval SA 
357	IENERGIA PNA	IENG5.SA	IENG5.SA (IENERGIA PNA)
358	IENERGIA ON	IENG3.SA	IENG3.SA (IENERGIA ON)
360	GRADIENTE ON	IGBR3.SA	Gradiente Empresa 
361	IGUATEMI ON	IGTA3.SA	Iguatemi Empresa de Shopping Centers 
362	IGUACU CAFE PNA	IGUA5.SA	IGUA5.SA (IGUACU CAFE PNA)
363	IGUACU CAFE PNB	IGUA6.SA	IGUA6.SA (IGUACU CAFE PNB)
364	IGUACU CAFE ON	IGUA3.SA	IGUA3.SA (IGUACU CAFE ON)
365	YARA BRASIL PN	ILMD4.SA	ILMD4.SA (YARA BRASIL PN)
366	YARA BRASIL ON	ILMD3.SA	ILMD3.SA (YARA BRASIL ON)
367	DOC IMBITUBA ON	IMBI3.SA	IMBI3.SA (DOC IMBITUBA ON)
368	DOC IMBITUBA PN	IMBI4.SA	IMBI4.SA (DOC IMBITUBA PN)
369	INEPAR PN	INEP4.SA	Grupo Inepar 
370	INEPAR ON	INEP3.SA	Grupo Inepar 
371	INEPAR TEL ON	INET3.SA	INET3.SA (INEPAR TEL ON)
372	INPAR ON	INPR3.SA	INPR3.SA (INPAR ON)
373	ITAUBANCO ON	ITAU3.SA	ITAU3.SA (ITAUBANCO ON)
374	ITAUBANCO PN	ITAU4.SA	ITAU4.SA (ITAUBANCO PN)
375	ITAUTEC ON	ITEC3.SA	ITEC3.SA (ITAUTEC ON)
376	ITAUSA PN	ITSA4.SA	Itaúsa Holding 
377	ITAUSA ON	ITSA3.SA	Itaúsa Holding 
378	INVEST TUR ON	IVTT3.SA	JHSF Empresa 
379	J B DUARTE PN	JBDU4.SA	Industrias J B Duarte SA Empresa
380	J B DUARTE ON	JBDU3.SA	Industrias J B Duarte SA Empresa
381	JBS ON	JBSS3.SA	JBS Empresa 
382	JOAO FORTES ON	JFEN3.SA	Joao Fortes Engenharia S.A. 
383	JHSF PART ON	JHSF3.SA	JHSF Empresa 
384	JOSAPAR PN	JOPA4.SA	JOSAPAR PN 
385	JOSAPAR ON	JOPA3.SA	JOSAPAR Joaquim Oliveira S.A. Participações Empresa
386	KEPLER WEBER ON	KEPL3.SA	Kepler Weber Empresa 
387	KLABIN S/A PN	KLBN4.SA	Klabin Empresa 
388	KLABIN S/A ON	KLBN3.SA	Klabin Empresa 
390	KROTON UNT	KROT11.SA	KROT11.SA (KROTON UNT)
391	KROTON ON	KROT3.SA	-
392	KLABINSEGALL ON	KSSA3.SA	KSSA3.SA (KLABINSEGALL ON)
393	LOJAS AMERIC ON	LAME3.SA	Lojas Americanas SA
394	LOJAS AMERIC PN	LAME4.SA	Lojas Americanas Empresa 
395	LARK MAQS ON	LARK3.SA	LARK3.SA (LARK MAQS ON)
396	LARK MAQS PN	LARK4.SA	LARK4.SA (LARK MAQS PN)
397	PARMALAT ON	LCSA3.SA	LCSA3.SA (PARMALAT ON)
398	PARMALAT PN	LCSA4.SA	LCSA4.SA (PARMALAT PN)
400	LECO PN	LECO4.SA	LECO4.SA (LECO PN)
401	METAL LEVE PN	LEVE4.SA	LEVE4.SA (METAL LEVE PN)
402	METAL LEVE ON	LEVE3.SA	Mahle Metal Leve SA
403	LA FONTE TEL ON	LFFE3.SA	JPSP INVESTIMENTOS E PARTICIPAÇÕES S.A. 
404	LA FONTE TEL PN	LFFE4.SA	JPSP INVESTIMENTOS E PARTICIPAÇÕES S.A. 
406	LIVR GLOBO PN	LGLO4.SA	LGLO4.SA (LIVR GLOBO PN)
407	LOJAS HERING ON	LHER3.SA	LHER3.SA (LOJAS HERING ON)
408	LOJAS HERING PN	LHER4.SA	LHER4.SA (LOJAS HERING PN)
409	LIGHT S/A ON	LIGT3.SA	Light S.A. Empresa 
410	ELETROPAR ON	LIPR3.SA	Eletrobras Eletropar
411	LIX DA CUNHA ON	LIXC3.SA	LIXC3.SA (LIX DA CUNHA ON)
412	LIX DA CUNHA PN	LIXC4.SA	LIXC4.SA (LIX DA CUNHA PN)
413	LE LIS BLANC ON	LLIS3.SA	Restoque Comércio e Confecções de Roupas SA Empresa
414	LOG-IN ON	LOGN3.SA	Log
415	LPS BRASIL ON	LPSB3.SA	LPS Brasil Empresa
416	LOJAS RENNER ON	LREN3.SA	Lojas Renner Empresa 
417	LUPATECH ON	LUPA3.SA	Lupatech SA Empresa 
418	TREVISA ON	LUXM3.SA	LUXM3.SA (TREVISA ON)
419	TREVISA PN	LUXM4.SA	Trevisa Investimentos S.A. Empresa 
420	MAGNESITA SA ON	MAGG3.SA	MAGNESITA SA ON
421	CEMEPE PN	MAPT4.SA	Cemepe Investimentos SA Empresa 
422	CEMEPE ON	MAPT3.SA	Cemepe Investimentos SA Empresa 
423	MARISA ON	MARI3.SA	MARI3.SA (MARISA ON)
424	M.DIASBRANCO ON	MDIA3.SA	M DIAS BRANCO SA IND E COM DE ALIMENTOS Empresa 
425	MEDIAL ON	MEDI3.SA	MEDI3.SA (MEDIAL ON)
426	MENDES JR PNA	MEND5.SA	MENDES JR PNA 
427	MENDES JR PNB	MEND6.SA	MENDES JR PNB 
428	MENDES JR ON	MEND3.SA	MEND3.SA (MENDES JR ON)
429	MERC FINANC PN	MERC4.SA	Mercantil do Brasil Financeira SA CFI Empresa
430	MERC FINANC ON	MERC3.SA	MERC3.SA (MERC FINANC ON)
431	MANGELS INDL PN	MGEL4.SA	Mangels Empresa 
432	MANGELS INDL ON	MGEL3.SA	MANGELS INDUSTRIAL S.A. 
433	LAEP INVEST BDR	MILK11.SA	A Laep Investments é uma empresa holding com sede principal em Bermudas,
434	JEREISSATI ON	MLFT3.SA	MLFT3.SA (JEREISSATI ON)
435	JEREISSATI PN	MLFT4.SA	MLFT4.SA (JEREISSATI PN)
437	MELPAPER PN	MLPA12.SA	MLPA12.SA (MELPAPER PN)
438	MELPAPER PN	MLPA4.SA	MLPA4.SA (MELPAPER PN)
440	MINASMAQUINA PN	MMAQ4.SA	MINASMAQUINAS S.A. 
441	MINASMAQUINA ON	MMAQ3.SA	Ações em Circulação no Mercado 
442	MMX MINER ON	MMXM3.SA	MMX Mineração e Metálicos Empresa 
443	MUNDIAL ON	MNDL3.SA	Mundial S.A. 
444	MUNDIAL PN	MNDL4.SA	MNDL4.SA (MUNDIAL PN)
445	MINUPAR ON	MNPR3.SA	MINUPAR PARTICIPAÇÕES S/A Empresa
446	MONT ARANHA ON	MOAR3.SA	Grupo Monteiro Aranha 
447	ENEVA ON	ENEV3.SA	Eneva Empresa 
448	MARFRIG ON	MRFG3.SA	Marfrig Companhia 
449	MARISOL PN	MRSL4.SA	MRSL4.SA (MARISOL PN)
450	MARISOL ON	MRSL3.SA	MRSL3.SA (MARISOL ON)
451	MRV ON	MRVE3.SA	MRV Engenharia e Participacoes SA
452	MELHOR SP ON	MSPA3.SA	CIA MELHORAMENTOS DE SAO PAULO 
453	MELHOR SP PN	MSPA4.SA	Melhoramentos Empresa 
454	METAL IGUACU PN	MTIG4.SA	Metalgráfica Iguaçu S.A. Empresa 
455	METAL IGUACU ON	MTIG3.SA	METALGRAFICA IGUACU S.A. 
456	METISA PN	MTSA4.SA	METISA Empresa 
457	METISA ON	MTSA3.SA	METISA METALURGICA TIMBOENSE S.A. 
458	MULTIPLAN ON	MULT3.SA	Multiplan Empresa 
459	WETZEL S/A ON	MWET3.SA	Wetzel SA Empresa 
460	WETZEL S/A PN	MWET4.SA	Wetzel SA Preference Shares
461	IOCHP-MAXION ON	MYPK3.SA	Iochpe Maxion SA
462	NADIR FIGUEI PN	NAFG4.SA	NADIR FIGUEIREDO PN 
463	NADIR FIGUEI ON	NAFG3.SA	NADIR FIGUEIREDO IND E COM S.A. 
464	NATURA ON	NATU3.SA	NATU3 é o código de negociação no Mercado Bovespa das ações ordinárias da
468	SUZANO HOLD PN	NEMO4.SA	NEMO4.SA (SUZANO HOLD PN)
469	NET ON	NETC3.SA	NETC3.SA (NET ON)
470	NET PN	NETC4.SA	NETC4.SA (NET PN)
471	NORDON MET ON	NORD3.SA	NORDON INDÚSTRIAS METALÚRGICAS S/A Empresa
472	ODERICH PN	ODER4.SA	ODER4.SA (ODERICH PN)
474	ODONTOPREV ON	ODPV3.SA	Odontoprev Empresa 
475	OGX PETROLEO ON	OGXP3.SA	OGXP3.SA (OGX PETROLEO ON)
476	OHL BRASIL ON	OHLB3.SA	Grupo CCR Empresa 
477	PANATLANTICA ON	PATI3.SA	Panatlântica SA Empresa
478	PANATLANTICA PN	PATI4.SA	Panatlântica SA Empresa
479	P.ACUCAR-CBD PN	PCAR4.SA	PCAR4.SA (P.ACUCAR
480	P.ACUCAR-CBD ON	PCAR3.SA	GPA Empresa 
481	PDG REALT ON	PDGR3.SA	PDG Empresa
482	PAR AL BAHIA PN	PEAB4.SA	CIA PARTICIPACOES ALIANCA DA BAHIA 
483	PAR AL BAHIA ON	PEAB3.SA	Companhia de Participacoes Alianca da Bahia
484	PETROBRAS	PETR4.SA	Petrobras Empresa 
485	PETROBRAS ON	PETR3.SA	Petrobras Empresa 
486	PROFARMA ON	PFRM3.SA	Profarma Distribuidora de Produtos Farmacêuticos S.A. Empresa
488	PINE PN	PINE4.SA	Banco Pine 
489	LF TEL ON	PITI3.SA	PITI3.SA (LF TEL ON)
490	LF TEL PN	PITI4.SA	PITI4.SA (LF TEL PN)
491	PLASCAR PART ON	PLAS3.SA	Plascar Participações Industriais S.A. Empresa 
492	PARANAPANEMA PN	PMAM4.SA	PMAM4.SA (PARANAPANEMA PN)
493	PARANAPANEMA ON	PMAM3.SA	Paranapanema S.A. Empresa 
494	PRONOR PNB	PNOR6.SA	PNOR6.SA (PRONOR PNB)
496	PRONOR PNA	PNOR5.SA	PNOR5.SA (PRONOR PNA)
497	DIMED ON	PNVL3.SA	Dimed Empresa
498	DIMED PN	PNVL4.SA	Dimed Empresa
499	MARCOPOLO ON	POMO3.SA	Marcopolo Empresa 
500	MARCOPOLO PN	POMO4.SA	Marcopolo Empresa 
501	POSITIVO INF ON	POSI3.SA	Positivo Tecnologia Empresa 
502	POLPAR ON	PPAR3.SA	POLPAR S.A. 
505	PETROQ UNIAO PN	PQUN4.SA	PQUN4.SA (PETROQ UNIAO PN)
506	PETROQ UNIAO ON	PQUN3.SA	PQUN3.SA (PETROQ UNIAO ON)
508	PARANA PN	PRBC4.SA	PRBC4.SA (PARANA PN)
509	PERDIGAO S/A ON	PRGA3.SA	PRGA3.SA (PERDIGAO S/A ON)
510	PROVIDENCIA ON	PRVI3.SA	PRVI3.SA (PROVIDENCIA ON)
513	PORTO SEGURO ON	PSSA3.SA	Porto Seguro Seguros 
514	PORTOBELLO ON	PTBL3.SA	Portobello S.A. Empresa 
515	PETTENATI ON	PTNT3.SA	Pettenati Empresa 
516	PETTENATI PN	PTNT4.SA	Pettenati Empresa 
517	PETROPAR ON	PTPA3.SA	PTPA3.SA (PETROPAR ON)
518	PETROPAR PN	PTPA4.SA	PTPA4.SA (PETROPAR PN)
519	CELUL IRANI ON	RANI3.SA	Celulose Irani Empresa 
520	CELUL IRANI PN	RANI4.SA	Celulose Irani Empresa 
521	RANDON PART ON	RAPT3.SA	Randon Companhia 
522	RANDON PART PN	RAPT4.SA	Randon Companhia 
523	RECRUSUL ON	RCSL3.SA	Recrusul SA Empresa 
524	RECRUSUL PN	RCSL4.SA	Recrusul SA Empresa 
525	REDECARD ON	RDCD3.SA	RDCD3.SA (REDECARD ON)
526	RODOBENS ON	RDNI3.SA	Rodobens Negócios Imobiliários Empresa
527	REDE ENERGIA PN	REDE4.SA	REDE4.SA (REDE ENERGIA PN)
528	REDE ENERGIA ON	REDE3.SA	Rede Energia S.A. Empresa
529	RIMET PN	REEM4.SA	REEM4.SA (RIMET PN)
531	LOCALIZA ON	RENT3.SA	Localiza Hertz Empresa 
532	M&G POLIEST ON	RHDS3.SA	RHDS3.SA (M	RHDS3.SAG POLIEST ON)
533	RENAR ON	RNAR3.SA	RNAR3.SA (RENAR ON)
534	RENNER PART ON	RNPT3.SA	RNPT3.SA (RENNER PART ON)
535	RENNER PART PN	RNPT4.SA	RNPT4.SA (RENNER PART PN)
536	INDS ROMI ON	ROMI3.SA	Industrias Romi SA Empresa 
537	ALFA HOLDING ON	RPAD3.SA	Alfa Holdings SA Empresa
538	ALFA HOLDING PNA	RPAD5.SA	Alfa Holdings SA Empresa
539	ALFA HOLDING PNB	RPAD6.SA	Alfa Holdings SA Empresa
540	PET MANGUINH ON	RPMG3.SA	Refinaria De Petroleos Manguinhos S.A. Empresa
541	PET MANGUINH PN	RPMG4.SA	RPMG4.SA (PET MANGUINH PN)
542	ROSSI RESID ON	RSID3.SA	Rossi Residencial Empresa 
543	RASIP AGRO PN	RSIP4.SA	RSIP4.SA (RASIP AGRO PN)
544	RASIP AGRO ON	RSIP3.SA	RSIP3.SA (RASIP AGRO ON)
545	RIOSULENSE PN	RSUL4.SA	Metalurgica Riosulense SA Empresa 
547	SANTANDER BR ON	SANB3.SA	Banco Santander Brasil Subsidiária 
548	SANTANDER BR PN	SANB4.SA	Banco Santander Brasil Subsidiária 
549	SANEPAR ON	SAPR3.SA	Companhia de Saneamento do Paraná Empresa 
550	SANEPAR PN	SAPR4.SA	Companhia de Saneamento do Paraná Empresa 
551	SEE DTEX3.SA	SATI3.SA	SATI3.SA (SEE DTEX3.SA)
552	SABESP ON	SBSP3.SA	Companhia de Saneamento Básico do Estado de São Paulo Empresa 
553	SAO CARLOS ON	SCAR3.SA	Sao Carlos Empreend E Participacoes SA Empresa 
554	SCHLOSSER PN	SCLO4.SA	SCLO4.SA (SCHLOSSER PN)
555	SCHLOSSER ON	SCLO3.SA	SCLO3.SA (SCHLOSSER ON)
556	SADIA S/A ON	SDIA3.SA	SDIA3.SA (SADIA S/A ON)
557	SADIA S/A PN	SDIA4.SA	SDIA4.SA (SADIA S/A PN)
559	SEB UNT	SEBB11.SA	SEBB11.SA (SEB UNT)
561	SEMP ON	SEMP3.SA	SEMP3.SA (SEMP ON)
563	SOFISA PN	SFSA4.SA	SFSA4.SA (SOFISA PN)
564	WLM IND COM ON	SGAS3.SA	SGAS3.SA (WLM IND COM ON)
565	WLM IND COM PN	SGAS4.SA	SGAS4.SA (WLM IND COM PN)
566	SERGEN PN	SGEN4.SA	SGEN4.SA (SERGEN PN)
567	SERGEN ON	SGEN3.SA	SGEN3.SA (SERGEN ON)
568	SPRINGS GLB ON	SGPS3.SA	Springs Global Participações S.A. Empresa 
569	SCHULZ ON	SHUL3.SA	SCHULZ S.A. 
570	SCHULZ PN	SHUL4.SA	Schulz SA Empresa 
571	TECEL S JOSE PN	SJOS4.SA	SJOS4.SA (TECEL S JOSE PN)
572	TECEL S JOSE ON	SJOS3.SA	SJOS3.SA (TECEL S JOSE ON)
573	SLC AGRICOLA ON	SLCE3.SA	SLC Agricola SA Empresa 
574	SARAIVA LIVR ON	SLED3.SA	Saraiva Livreiros SA EM Recuperacao Judicial Empresa
575	SARAIVA LIVR PN	SLED4.SA	Saraiva Livreiros SA EM Recuperacao Judicial Empresa
576	SAO MARTINHO ON	SMTO3.SA	São Martinho Companhia 
577	SANSUY PNA	SNSY5.SA	Sansuy SA Industria De Plasticos Empresa
578	SANSUY ON	SNSY3.SA	Sansuy SA Industria De Plasticos Empresa
579	SANSUY PNB	SNSY6.SA	SANSUY PNB 
580	SONDOTECNICA PNA	SOND5.SA	Sondotécnica Engenharia Empresa 
581	SONDOTECNICA PNB	SOND6.SA	Sondotécnica Engenharia Empresa 
582	SONDOTECNICA ON	SOND3.SA	SONDOTECNICA ENGENHARIA SOLOS S.A. 
583	SPRINGER ON	SPRI3.SA	Springer S.A. Empresa
584	SPRINGER PNB	SPRI6.SA	SPRI6.SA (SPRINGER PNB)
585	SPRINGER PNA	SPRI5.SA	SPRINGER S.A. 
589	SANTOS BRP ON	STBP3.SA	Santos Brasil Empresa 
590	SANTOS BRP UN	STBP11.SA	STBP11.SA (SANTOS BRP UN)
591	STAROUP PN	STRP4.SA	STRP4.SA (STAROUP PN)
593	SULAMERICA PN	SULA4.SA	Sul América SA Empresa 
594	SULAMERICA ON	SULA3.SA	Sul América SA Empresa 
595	SULAMERICA UNT	SULA11.SA	Sul América SA Empresa 
596	SULTEPA ON	SULT3.SA	CONSTRUTORA SULTEPA S.A. 
597	SULTEPA PN	SULT4.SA	SULT4.SA (SULTEPA PN)
598	SUZANO PAPEL PNA	SUZB5.SA	-
600	SUZANO PAPEL PNB	SUZB6.SA	SUZB6.SA (SUZANO PAPEL PNB)
601	SUZANO ON	SUZB3.SA	Suzano SA Empresa
604	SUZANO PETR PN	SZPQ4.SA	SZPQ4.SA (SUZANO PETR PN)
605	TAM SA ON	TAMM3.SA	TAMM3.SA (TAM SA ON)
606	TAM SA PN	TAMM4.SA	TAMM4.SA (TAM SA PN)
607	TARPON BDR	TARP11.SA	TARP11.SA (TARPON BDR)
608	TRACTEBEL ON	TBLE3.SA	WEG S.A. Empresa 
609	TECNOSOLO PN	TCNO4.SA	Tecnosolo Engenharia SA Empresa 
610	TECNOSOLO ON	TCNO3.SA	Tecnosolo Engenharia SA Empresa 
611	TECNISA ON	TCSA3.SA	Tecnisa Empresa
612	TIM PART S/A PN	TCSL4.SA	TCSL4.SA (TIM PART S/A PN)
613	TIM PART S/A ON	TCSL3.SA	TCSL3.SA (TIM PART S/A ON)
614	TELEFONICA BDR	TEFC11.SA	TEFC11.SA (TELEFONICA BDR)
615	TEKA ON	TEKA3.SA	Teka Empresa
616	TEKA PN	TEKA4.SA	Teka Empresa
617	TELEBRAS PN	TELB4.SA	Telecomunicações Brasileiras S.A. Empresa 
618	TELEBRAS ON	TELB3.SA	Telecomunicações Brasileiras S.A. Empresa 
619	TEMPO PART ON	TEMP3.SA	TEMP3.SA (TEMPO PART ON)
620	TENDA	TEND3.SA	Construtora Tenda Empresa 
621	TEC BLUMENAU PNC	TENE7.SA	TENE7.SA (TEC BLUMENAU PNC)
622	TEC BLUMENAU PNA	TENE5.SA	TENE5.SA (TEC BLUMENAU PNA)
623	TEC BLUMENAU PNB	TENE6.SA	TENE6.SA (TEC BLUMENAU PNB)
625	TEGMA ON	TGMA3.SA	Tegma Gestão Logística Empresa
626	MILLENNIUM PNA	TIBR5.SA	TIBR5.SA (MILLENNIUM PNA)
627	MILLENNIUM PNB	TIBR6.SA	TIBR6.SA (MILLENNIUM PNB)
628	MILLENNIUM ON	TIBR3.SA	TIBR3.SA (MILLENNIUM ON)
629	TEKNO PN	TKNO4.SA	Tekno S.A. Indústria e Comércio Empresa
630	TEKNO ON	TKNO3.SA	TEKNO S.A. 
631	TELESP PN	TLPP4.SA	TLPP4.SA (TELESP PN)
632	TELESP ON	TLPP3.SA	TLPP3.SA (TELESP ON)
633	TELEMAR N L ON	TMAR3.SA	TMAR3.SA (TELEMAR N L ON)
634	TELEMAR N L PNA	TMAR5.SA	TMAR5.SA (TELEMAR N L PNA)
635	TELEMAR N L PNB	TMAR6.SA	TMAR6.SA (TELEMAR N L PNB)
636	TELEMIG PART PN	TMCP4.SA	TMCP4.SA (TELEMIG PART PN)
637	TELEMIG PART ON	TMCP3.SA	TMCP3.SA (TELEMIG PART ON)
638	TELEMIG CL PNE	TMGC11.SA	TMGC11.SA (TELEMIG CL PNE)
639	TELEMIG CL PNC	TMGC7.SA	Imagens Ver tudo
641	TELEMIG CL PNF	TMGC12.SA	TMGC12.SA (TELEMIG CL PNF)
642	TELEMIG CL ON	TMGC3.SA	TMGC3.SA (TELEMIG CL ON)
643	TELEMIG CL PNB	TMGC6.SA	TMGC6.SA (TELEMIG CL PNB)
644	TELEMIG CL PNG	TMGC13.SA	TMGC13.SA (TELEMIG CL PNG)
645	TELE NORT CL PN	TNCP4.SA	TNCP4.SA (TELE NORT CL PN)
646	TELE NORT CL ON	TNCP3.SA	TNCP3.SA (TELE NORT CL ON)
647	TELEMAR ON	TNLP3.SA	TNLP3.SA (TELEMAR ON)
648	TELEMAR PN	TNLP4.SA	TNLP4.SA (TELEMAR PN)
649	TOTVS ON	TOTS3.SA	Totvs Empresa 
650	TECTOY ON	TOYB3.SA	TEC TOY S.A. 
651	TECTOY PN	TOYB4.SA	TEC TOY S.A. 
652	TRIUNFO PART ON	TPIS3.SA	Triunfo Empresa 
653	TRAFO ON	TRFO3.SA	TRFO3.SA (TRAFO ON)
654	TRAFO PN	TRFO4.SA	TRFO4.SA (TRAFO PN)
655	TRISUL ON	TRIS3.SA	Trisul SA Empresa 
656	TERNA PART ON	TRNA3.SA	TRNA3.SA (TERNA PART ON)
657	TERNA PART UNT	TRNA11.SA	TRNA11.SA (TERNA PART UNT)
658	TERNA PART PN	TRNA4.SA	TRNA4.SA (TERNA PART PN)
659	TRORION PN	TROR4.SA	TROR4.SA (TRORION PN)
660	TRORION ON	TROR3.SA	TROR3.SA (TRORION ON)
661	TRAN PAULIST PN	TRPL4.SA	ISA CTEEP Empresa 
662	TRAN PAULIST ON	TRPL3.SA	ISA CTEEP Empresa 
663	TUPY ON	TUPY3.SA	Tupy Companhia 
664	TUPY PN	TUPY4.SA	TUPY4.SA (TUPY PN)
665	TEX RENAUX ON	TXRX3.SA	Textil Renauxview SA Empresa 
666	TEX RENAUX PN	TXRX4.SA	Textil Renauxview SA Empresa 
667	UNIBANCO ON	UBBR3.SA	UBBR3.SA (UNIBANCO ON)
668	UNIBANCO UNT	UBBR11.SA	UBBR11.SA (UNIBANCO UNT)
669	UNIBANCO PN	UBBR4.SA	UBBR4.SA (UNIBANCO PN)
670	UNIBANCO HLD ON	UBHD3.SA	UBHD3.SA (UNIBANCO HLD ON)
673	USIN C PINTO PN	UCOP4.SA	UCOP4.SA (USIN C PINTO PN)
674	ULTRAPAR ON	UGPA3.SA	Grupo Ultra Companhia 
675	ULTRAPAR PN	UGPA4.SA	Grupo Ultra Companhia 
676	UNIPAR PNB	UNIP6.SA	Unipar Carbocloro Empresa 
677	UNIPAR PNA	UNIP5.SA	Unipar Carbocloro Empresa 
678	UNIPAR ON	UNIP3.SA	Unipar Carbocloro Empresa 
679	UOL PN	UOLL4.SA	UOLL4.SA (UOL PN)
681	USIMINAS PNB	USIM6.SA	USIMINAS PNB 
682	USIMINAS ON	USIM3.SA	Usiminas Empresa 
683	USIMINAS PNA	USIM5.SA	Usiminas Empresa 
684	VARIG PN	VAGV4.SA	VAGV4.SA (VARIG PN)
685	VARIG ON	VAGV3.SA	VAGV3.SA (VARIG ON)
687	VALE PNA	VALE5.SA	VALE5.SA (VALE PNA)
688	V C P ON	VCPA3.SA	VCPA3.SA (V C P ON)
689	V C P PN	VCPA4.SA	VCPA4.SA (V C P PN)
690	VIGOR PN	VGOR4.SA	VGOR4.SA (VIGOR PN)
692	VICUNHA TEXT PNB	VINE6.SA	VINE6.SA (VICUNHA TEXT PNB)
693	VICUNHA TEXT ON	VINE3.SA	VINE3.SA (VICUNHA TEXT ON)
694	VICUNHA TEXT PNA	VINE5.SA	VINE5.SA (VICUNHA TEXT PNA)
695	VIVO PN	VIVO4.SA	VIVO4.SA (VIVO PN)
696	VIVO ON	VIVO3.SA	VIVO3.SA (VIVO ON)
697	VARIG SERV ON	VPSC3.SA	VPSC3.SA (VARIG SERV ON)
698	VARIG SERV PN	VPSC4.SA	VPSC4.SA (VARIG SERV PN)
699	VARIG TRANSP ON	VPTA3.SA	VPTA3.SA (VARIG TRANSP ON)
700	VARIG TRANSP PN	VPTA4.SA	VPTA4.SA (VARIG TRANSP PN)
701	FER C ATLANT ON	VSPT3.SA	VSPT3.SA (FER C ATLANT ON)
703	VULCABRAS ON	VULC3.SA	Vulcabras Azaleia Empresa 
704	WEG ON	WEGE3.SA	WEG S.A. Empresa 
705	WHIRPOOL PN	WHRL4.SA	Whirlpool S/A Empresa
706	WHIRPOOL ON	WHRL3.SA	Whirlpool S/A Empresa
707	WIEST ON	WISA3.SA	WISA3.SA (WIEST ON)
708	WIEST PN	WISA4.SA	WISA4.SA (WIEST PN)
709	WEMBLEY ON	WMBY3.SA	WMBY3.SA (WEMBLEY ON)
710	WILSON SONS BDR	WSON11.SA	WSON11.SA (WILSON SONS BDR)
711	Y P F CDA	YPFL3.SA	YPFL3.SA (Y P F CDA)
712	FII ABC IMOB CI	ABCP11.SA	FIIABCIMO093/Ut
713	AFLUENTE ON	AFLU3.SA	AFLUENTE GERAÇÃO DE ENERGIA ELÉTRICA S.A. 
714	AFLUENTE PNA	AFLU5.SA	AFLU5.SA (AFLUENTE PNA)
716	BRASIL BNS	BBAS13.SA	BBAS13.SA (BRASIL BNS)
717	BRAZILIAN FR ON	BFRE3.SA	BFRE3.SA (BRAZILIAN FR ON)
718	FIP BRASCAN CI	BRCP11.SA	BRCP11.SA (FIP BRASCAN CI)
719	BR PROPERT ON	BRPR3.SA	BR Properties S.A. Empresa 
722	CENT AMAPA ON	CTAP3.SA	CTAP3.SA (CENT AMAPA ON)
723	CENT MIN-RIO ON	CTMI3.SA	CTMI3.SA (CENT MIN
726	FII EUROPAR CI	EURO11.SA	FII EUROPAR CI
727	FDO INV IMOB RIO	FFCI11.SA	FFCI11.SA (FDO INV IMOB RIO)
728	FII JK IMOB CI	FJKI11.SA	FJKI11.SA (FII JK IMOB CI)
729	FII S F LIMA CI	FLMA11.SA	FIISFLIMA9FP/Ut
730	FINAM CI	FNAM11.SA	FINAM9MH/Ut
731	FINOR CI	FNOR11.SA	Fundo de Investimentos do Nordeste
732	FII A BRANCA CI	FPAB11.SA	Fundo de Investimento Imobiliario Projeto Agua Branca Empresa
733	FUNRES CI	FRES11.SA	FRES11.SA (FUNRES CI)
734	FII SIGMA CI	FSIG11.SA	FSIG11.SA (FII SIGMA CI)
735	FISET PESCA CI	FSPE11.SA	FISETPESCA54/Ut
736	FISET FL REF CI	FSRF11.SA	FISETFLREA5A/Ut
737	FISET TUR CI	FSTU11.SA	FISETTURA5U/Ut
738	FDO VIA PARQUE	FVPQ11.SA	Fundo de Investimentos Imobiliario 
739	GOIASPAR ON	GPAR3.SA	Companhia Celg de Participações SA
740	FII HEDGEBS	HGBS11.SA	CSHG Brasil Shopping Fundo de Investimento Imobiliario Empresa
743	FII GUARARAP CI	NCGR11.SA	NCGR11.SA (FII GUARARAP CI)
744	FDO INV IMOB PAN	PABY11.SA	Fundo de Investimento Imobiliario Panamby Empresa
745	IT NOW PIBB IBRX	PIBB11.SA	ITNOWPIBBIL5/Ut It Now PIBB IBrX-50 Fundo de Índice (PIBB11)
748	FII SCP CI	SCPF11.SA	FIISCPLH5/Ut
749	FII HIGIENOP CI	SHPH11.SA	FIIHIGIENLWE/Ut
754	BMF BOVESPA ON	BVMF3.SA	BVMF3.SA (BMF BOVESPA ON)
763	BANESTES PN	BEES4.SA	Banco do Estado do Espírito Santo 
765	COPASA CI	CSMG11.SA	CSMG11.SA (COPASA CI)
766	FDO INV IMOB MEM	FMOF11.SA	FIIMEMORI9KU/Ut
767	IRONX MINER ON	IRON3.SA	IRON3.SA (IRONX MINER ON)
769	LLX LOG ON	LLXL3.SA	LLXL3.SA (LLX LOG ON)
771	PRO METALURG PNA	PMET5.SA	PMET5.SA (PRO METALURG PNA)
772	PRO METALURG PNB	PMET6.SA	PMET6.SA (PRO METALURG PNB)
773	ROSSI RESID ON	RSID9.SA	RSID9.SA (ROSSI RESID ON)
774	SANTANDER BR PN	SANB10.SA	SANB10.SA (SANTANDER BR PN)
775	VALE ON	VALE3.SA	Vale S.A. Empresa 
778	AGCONCESSOES	ANDG4B.SO	ANDG4B.SO (AGCONCESSOES)
785	CAIANDA PART	CAIA3B.SO	CAIA3B.SO (CAIANDA PART)
790	CEEE-D	CEED3B.SO	CEED3B.SO (CEEE
791	CEEE-D	CEED4B.SO	CEED4B.SO (CEEE
794	CONST BETER	COBE3B.SO	COBE3B.SO (CONST BETER)
795	CONST BETER	COBE5B.SO	COBE5B.SO (CONST BETER)
796	CONST BETER	COBE6B.SO	COBE6B.SO (CONST BETER)
797	CAPITALPART	CPTP3B.SO	CPTP3B.SO (CAPITALPART)
802	CEEE-GT	EEEL3B.SO	EEEL3B.SO (CEEE
803	CEEE-GT	EEEL4B.SO	EEEL4B.SO (CEEE
804	CEMAR	ENMA3B.SO	Equatorial Energia Maranhão Companhia 
805	CEMAR	ENMA5B.SO	ENMA5B.SO (CEMAR)
806	CEMAR	ENMA6B.SO	ENMA6B.SO (CEMAR)
821	GTD PART	GTDP3B.SO	GTDP3B.SO (GTD PART)
822	GTD PART	GTDP4B.SO	GTDP4B.SO (GTD PART)
839	MRS LOGIST	MRSA3B.SO	MRSA3B.SO (MRS LOGIST)
840	MRS LOGIST	MRSA5B.SO	MRSA5B.SO (MRS LOGIST)
841	MRS LOGIST	MRSA6B.SO	MRSA6B.SO (MRS LOGIST)
843	NOVA AMERICA	NOVA3B.SO	NOVA3B.SO (NOVA AMERICA)
844	NOVA AMERICA	NOVA4B.SO	NOVA4B.SO (NOVA AMERICA)
860	PROMPT PART	PRPT3B.SO	PRPT3B.SO (PROMPT PART)
862	QGN PARTIC	QGNP3B.SO	QGNP3B.SO (QGN PARTIC)
863	QGN PARTIC	QGNP4B.SO	QGNP4B.SO (QGN PARTIC)
866	RB CREDITO	RBCS3B.SO	RBCS3B.SO (RB CREDITO)
867	RIO BRAVO	RBRA3B.SO	RBRA3B.SO (RIO BRAVO)
871	LONGDIS	SPRT3B.SO	SPRT3B.SO (LONGDIS)
873	AMAZONIA CEL	TMAC11B.SO	TMAC11B.SO (AMAZONIA CEL)
874	AMAZONIA CEL	TMAC3B.SO	TMAC3B.SO (AMAZONIA CEL)
875	AMAZONIA CEL	TMAC5B.SO	TMAC5B.SO (AMAZONIA CEL)
876	AMAZONIA CEL	TMAC6B.SO	TMAC6B.SO (AMAZONIA CEL)
877	AMAZONIA CEL	TMAC7B.SO	TMAC7B.SO (AMAZONIA CEL)
878	AMAZONIA CEL	TMAC8B.SO	TMAC8B.SO (AMAZONIA CEL)
880	ARAUCARIA	VDNP3B.SO	VDNP3B.SO (ARAUCARIA)
883	ITAUUNIBANCO ON	ITUB3.SA	Itaú Unibanco Banco 
884	ITAUUNIBANCO PN	ITUB4.SA	Itaú Unibanco Banco 
885	TEC TOY DIR	TOYB1.SA	TOYB1.SA (TEC TOY DIR)
886	TEC TOY DIR	TOYB2.SA	TOYB2.SA (TEC TOY DIR)
888	TARPON INV ON	TRPN3.SA	TARPON INVESTIMENTOS S.A. 
889	AMBEV PN	AMBV10.SA	AMBEV Empresa 
890	AMBEV ON	AMBV9.SA	AMBV9.SA (AMBEV ON)
891	ECODIESEL ON	ECOD9.SA	ECOD9.SA (ECODIESEL ON)
892	LUPATECH	LUPA11.SA	LUPA11.SA (LUPATECH)
894	ABYARA DIR	ABYA1.SA	ABYA1.SA (ABYARA DIR)
895	ITAUSA PN	ITSA10.SA	ITSA10.SA (ITAUSA PN)
896	ITAUSA ON	ITSA9.SA	ITSA9.SA (ITAUSA ON)
897	TRAN PAULIST DIR	TRPL1.SA	TRPL1.SA (TRAN PAULIST DIR)
898	TRAN PAULIST DIR	TRPL2.SA	TRPL2.SA (TRAN PAULIST DIR)
899	BR BROKERS DIR	BBRK1.SA	BRASIL BROKERS PARTICIPACOES S.A. 
902	PANATLANTICA RTS	PATI1.SA	PATI1.SA (PANATLANTICA RTS)
903	PANATLANTICA RTS	PATI2.SA	PATI2.SA (PANATLANTICA RTS)
906	VISANET ON	VNET3.SA	VNET3.SA (VISANET ON)
907	ECODIESEL DIR	ECOD1.SA	ECOD1.SA (ECODIESEL DIR)
908	KROTON DIR	KROT12.SA	KROT12.SA (KROTON DIR)
909	RENAR DIR	RNAR1.SA	RNAR1.SA (RENAR DIR)
911	P.ACUCAR-CBD PNA	PCAR5.SA	PCAR5.SA (P.ACUCAR
913	P.ACUCAR-CBD DIR	PCAR11.SA	PCAR11.SA (P.ACUCAR
915	ABYARA ON	ABYA9.SA	ABYA9.SA (ABYARA ON)
916	IND JB DUART DIR	JBDU1.SA	JBDU1.SA (IND JB DUART DIR)
917	IND JB DUART DIR	JBDU2.SA	JBDU2.SA (IND JB DUART DIR)
918	TRAN PAULIST PN	TRPL10.SA	TRPL10.SA (TRAN PAULIST PN)
921	KROTON UNIT REC	KROT13.SA	KROT13.SA (KROTON UNIT REC)
925	RENAR ON	RNAR9.SA	RNAR9.SA (RENAR ON)
929	J B DUARTE PN	JBDU10.SA	JBDU10.SA (J B DUARTE PN)
930	J B DUARTE ON	JBDU9.SA	JBDU9.SA (J B DUARTE ON)
931	MAGNESITA SA DIR	MAGG1.SA	MAGG1.SA (MAGNESITA SA DIR)
932	MINERVA	BEEF1.SA	BEEF1.SA (MINERVA)
933	MAGNESITA SA ON	MAGG9.SA	MAGG9.SA (MAGNESITA SA ON)
934	TIVIT ON	TVIT3.SA	TVIT3.SA (TIVIT ON)
935	MINERVA	BEEF9.SA	BEEF9.SA (MINERVA)
936	SANTANDER BR UNT	SANB11.SA	Banco Santander Brasil Subsidiária 
937	ALL AMER LAT DIR	ALLL12.SA	ALLL12.SA (ALL AMER LAT DIR)
938	STEEL BRASIL ON	STLB3.SA	STLB3.SA (STEEL BRASIL ON)
939	DURATEX ON	DTEX3.SA	Duratex S.A. Empresa 
942	TRIUNFO PART DIR	TPIS1.SA	TPIS1.SA (TRIUNFO PART DIR)
945	OSX BRASIL ON	OSXB3.SA	OSX Empresa 
946	CETIP ON	CTIP3.SA	CTIP3.SA (CETIP ON)
947	EMBRATEL PAR DIR	EBTP1.SA	EBTP1.SA (EMBRATEL PAR DIR)
948	EMBRATEL PAR DIR	EBTP2.SA	EBTP2.SA (EMBRATEL PAR DIR)
949	ETERNIT RTS	ETER1.SA	ETER1.SA (ETERNIT RTS)
950	ENERGISA UNT	ENGI11.SA	Grupo Energisa Empresa 
951	BIOMM	BIOM1.SA	-
952	BIOMM DIR	BIOM2.SA	BIOM2.SA (BIOMM DIR)
955	TRIUNFO P ON REC	TPIS9.SA	TPIS9.SA (TRIUNFO P ON REC)
956	DIRECIONAL ON	DIRR3.SA	Direcional Engenharia 
957	FIBRIA ON	FIBR3.SA	FIBR3 Fórum de Discussão
958	INEPAR	INEP1.SA	INEP1.SA (INEPAR)
959	INEPAR DIR	INEP2.SA	INEP2.SA (INEPAR DIR)
960	ETERNIT ON	ETER9.SA	ETER9.SA (ETERNIT ON)
963	MINERVA	BEEF11.SA	BEEF11.SA (MINERVA)
964	BRF FOODS ON	BRFS3.SA	Perdigão Empresa 
966	CIELO ON	CIEL3.SA	Cielo Empresa 
967	FLEURY ON	FLRY3.SA	Fleury Empresa 
968	PET MANGUINH DIR	RPMG1.SA	RPMG1.SA (PET MANGUINH DIR)
969	PET MANGUINH DIR	RPMG2.SA	RPMG2.SA (PET MANGUINH DIR)
970	INEPAR PN REC	INEP10.SA	INEP10.SA (INEPAR PN REC)
971	INEPAR ON REC	INEP9.SA	INEP9.SA (INEPAR ON REC)
972	BIOMM PN	BIOM10.SA	BIOM10.SA (BIOMM PN)
973	BIOMM	BIOM9.SA	BIOMM ON 
976	FII D PEDRO CF	PQDP11.SA	FIIDPEDROJ3Z/Ut
977	MERC BRASIL DIR	BMEB1.SA	BMEB1.SA (MERC BRASIL DIR)
979	BHG ON	BHGR3.SA	BHGR3.SA (BHG ON)
980	JBS DIR	JBSS11.SA	JBSS11.SA (JBS DIR)
983	ALIANSCE ON	ALSC3.SA	ALIANSCE SHOPPING CENTERS S.A. 
985	MERC BRASIL ON	BMEB9.SA	BMEB9.SA (MERC BRASIL ON)
988	MULTIPLUS ON	MPLU3.SA	MPLU3 Fórum de Discussão
989	ISHARES BRAX CI	BRAX11.SA	ISHARESIB3WV/Ut iShares IBrX - Índice Brasil (IBrX-100) Fundo de Índice (BRAX11)
990	ISHARES CSMO CI	CSMO11.SA	iShares Índice BM990 iShares Índice BM&FBOVESPA de Consumo Fundo de Índice
991	ISHARES MOBI CI	MOBI11.SA	MOBI11.SA (ISHARES MOBI CI) iShares Índice BM&FBOVESPA Imobiliário Fundo de Índice
992	AGRE EMP ON	AGEI3.SA	AGEI3.SA (AGRE EMP ON)
993	MMX MINER DIR	MMXM1.SA	MMXM1.SA (MMX MINER DIR)
994	INEPAR	INEP11.SA	INEPAR
995	TECTOY PN	TOYB10.SA	TOYB10.SA (TECTOY PN)
996	TECTOY ON	TOYB9.SA	TOYB9.SA (TECTOY ON)
999	HELBOR DIR	HBOR1.SA	HBOR1.SA (HELBOR DIR)
1000	RENOVA UNT	RNEW11.SA	Renova Energia Empresa 
1001	MMX MINER ON REC	MMXM9.SA	MMXM9.SA (MMX MINER ON REC)
1004	COMGAS	CGAS11.SA	CGAS11.SA (COMGAS)
1005	ECORODOVIAS ON	ECOR3.SA	EcoRodovias Empresa 
1007	GOL DIR	GOLL2.SA	GOLL2.SA (GOL DIR)
1010	HELBOR ON REC	HBOR9.SA	HBOR9.SA (HELBOR ON REC)
1011	IDEIASNET DIR	IDNT1.SA	IDNT1.SA (IDEIASNET DIR)
1014	MILLS ON	MILS3.SA	Mills Empresa
1015	JULIO SIMOES ON	JSLG3.SA	Grupo JSL Empresa 
1016	FII CSHG BC CI	CSBC11.SA	Fundos de Investimentos Imobiliarios
1017	DUFRY AG DRC	DAGB11.SA	DAGB11.SA (DUFRY AG DRC)
1022	ITAUSA DIR	ITSA1.SA	ITSA1.SA (ITAUSA DIR)
1023	ITAUSA DIR	ITSA2.SA	ITSA2.SA (ITAUSA DIR)
1024	FII P VARGAS CI	PRSV11.SA	Fundo de Investimento Imobilario Presidente Vargas Empresa
1027	ISHS IBOVESPA FD	BOVA11.SA	ISHARESBO3QK/Ut Ishares Ibovespa Fundo de Indice
1029	CLARION PN	CLAN4.SA	CLAN4.SA (CLARION PN)
1030	HG RL EST FDO IN	HGRE11.SA	CSHG REAL ESTATE – FUNDO DE INVESTIMENTO IMOBILIÁRIO Empresa CSHG Real Estate FI Imobiliario-FII
1031	ISHARES MILA CI	MILA11.SA	ITNOWIFNC98T/Ut BRL iShares BM&FBOVESPA MidLarge Cap Fundo de Índice
1032	ISH BMFBOVESPA S	SMAL11.SA	ISHARESSMM75/Ut BRL iShares BM&FBOVESPA Small Cap Fundo de Índice
1034	IDEIASNET ON	IDNT9.SA	IDNT9.SA (IDEIASNET ON)
1036	CETIP DIR	CTIP1.SA	CTIP1.SA (CETIP DIR)
1037	NUTRIPLANT ON/d	NUTR3.SA	Nutriplant Indústria e Comércio S/A Empresa 
1041	FII RIOB RC CI	FFCI12.SA	FFCI12.SA (FII RIOB RC CI)
1044	LOJAS MARISA ON	AMAR3.SA	Lojas Marisa 
1045	FII CSHG LOG CI	HGLG11.SA	CSHG LOGÍSTICA FDO INV IMOB 
1050	FII RBRESID1 C/d	RBAG11.SA	RBAG11.SA (FII RBRESID1 C/d)
1055	TRX REALTY FII	TRXL11.SA	TRXL11.SA (TRX REALTY FII)
1056	ATIVO_TESTE_ON	TT013.SA	TT013.SA (ATIVO_TESTE_ON)
1057	ATIVO_TESTE_ON	TT023.SA	TT023.SA (ATIVO_TESTE_ON)
1058	MARFRIG DIR	MRFG11.SA	MRFG11.SA (MARFRIG DIR)
1059	ATIVO_TESTE_ON	TT033.SA	TT033.SA (ATIVO_TESTE_ON)
1060	ATIVO_TESTE_ON	TT043.SA	TT043.SA (ATIVO_TESTE_ON)
1061	FII GWI LOG CI/d	GWIC11.SA	FIIINDLBR97G/Ut
1062	TEREOS ON	TERI3.SA	TERI3.SA (TEREOS ON)
1064	REDE ENERGIA D/d	REDE1.SA	REDE ENERGIA ON 
1065	REDE ENERGIA D/d	REDE2.SA	REDE2.SA (REDE ENERGIA D/d)
1067	REDENTOR ON	RDTR3.SA	RDTR3.SA (REDENTOR ON)
1069	DTCOM-DIRECT DIR	DTCY1.SA	DTCOM ON 
1070	MINUPAR DIR	MNPR1.SA	MNPR1.SA (MINUPAR DIR)
1071	TAM S/A ON/d	TAMM9.SA	TAMM9.SA (TAM S/A ON/d)
1072	REDE ENERGIA PN	REDE10.SA	REDE10.SA (REDE ENERGIA PN)
1073	REDE ENERGIA ON	REDE9.SA	REDE9.SA (REDE ENERGIA ON)
1078	FII REP 1 CI	RCCS11.SA	RCCS11.SA (FII REP 1 CI)
1079	HRT PETROLEO O/d	HRTP3.SA	HRTP3.SA (HRT PETROLEO O/d)
1080	AFLUENTE T ON	AFLT3.SA	AFLUENTE TRANSMISSÃO DE ENERGIA ELÉTRICA SA Empresa
1081	BR INSURANCE ON	BRIN3.SA	BRIN3.SA (BR INSURANCE ON)
1082	FII CSHG JHS CI	HGJH11.SA	HGJH11.SA (FII CSHG JHS CI)
1085	RECRUSUL	RCSL1.SA	RCSL1.SA (RECRUSUL)
1086	RECRUSUL	RCSL2.SA	RCSL2.SA (RECRUSUL)
1087	VALID ON	VLID3.SA	Valid Empresa
1088	GLOBEX DIR/d	GLOB1.SA	GLOB1.SA (GLOBEX DIR/d)
1089	FII LARGO 13 CI	MSHP11.SA	MAIS SHOPPING LARGO 13 FDO INV IMOB 
1091	FII KINEA CI	KNRI11.SA	KINEA RENDA IMOBILIÁRIA FUNDO DE INVESTIMENTO IMOBILIÁRIO 
1092	PORTX ON	PRTX3.SA	PRTX3.SA (PORTX ON)
1093	FDO INV IMOB RB	RBDS11.SA	FDO INV IMOB RB CAP DESENV RESID
1097	FII RB II CI	RBRD11.SA	rb CAPITAL reNDA II FuNDo De INVesTIMeNTo IMobILIárIo – FII Empresa 
1098	FIA FATOR IV C/d	SINQ11.SA	SINQ11.SA (FIA FATOR IV C/d)
1099	RAIA ON	RAIA3.SA	RAIA3.SA (RAIA ON)
1100	ELETROPAULO PN	ELPL4.SA	ELPL4.SA (ELETROPAULO PN)
1102	BRADESCO DIR	BBDC1.SA	BBDC1.SA (BRADESCO DIR)
1103	BRADESCO DIR	BBDC2.SA	BBDC2.SA (BRADESCO DIR)
1104	FII BB VOT JHSF	BBVJ11.SA	FIICJARDI2PX/Ut
1105	FII RBPRIME1 C/d	RBPR11.SA	RBPR11.SA (FII RBPRIME1 C/d)
1108	CEEE-D	ELET1.SA	ELETROBRAS ON 
1109	CEEE-D	ELET11.SA	ELET11.SA (CEEE-D)
1110	AREZZO CO ON	ARZZ3.SA	Arezzo	ARZZ3.SACo Empresa 
1111	SIERRABRASIL ON	SSBR3.SA	SSBR3.SA (SIERRABRASIL ON)
1112	AUTOMETAL ON	AUTM3.SA	AUTM3.SA (AUTOMETAL ON)
1113	CEEE-D ON	CEED3.SA	Companhia Estadual de Distribuição de Energia Elétrica Empresa
1114	CEEE D PN	CEED4.SA	CEED4.SA (CEEE D PN)
1115	CEEE GT ON	EEEL3.SA	CIA ESTADUAL GER.TRANS.ENER.ELET
1116	CEEE GT PN	EEEL4.SA	Companhia Estadual de Geração e Transmissão de Energia Elétrica
1117	QGEP PART ON	QGEP3.SA	QGEP3.SA (QGEP PART ON)
1121	DOC IMBITUBA D/d	IMBI1.SA	IMBI1.SA (DOC IMBITUBA D/d)
1122	BRADESCO PN	BBDC10.SA	BBDC10.SA (BRADESCO PN)
1123	BRADESCO ON	BBDC9.SA	BBDC9.SA (BRADESCO ON)
1131	FII FATOR VE CI	VRTA11.SA	Fator Verita Fundo de Investimento Imobiliario 
1132	IMC HOLDINGS O/d	IMCH3.SA	IMCH3.SA (IMC HOLDINGS O/d)
1134	INDUSVAL RTS	IDVL1.SA	IDVL1.SA (INDUSVAL RTS)
1135	INDUSVAL DIR	IDVL2.SA	IDVL2.SA (INDUSVAL DIR)
1140	B2W DIGITAL	BTOW1.SA	BTOW1.SA (B2W DIGITAL)
1156	DAYCOVAL BNS	DAYC11.SA	DAYC11.SA (DAYCOVAL BNS)
1157	IT NOW IFNC CI	FIND11.SA	ITNOWIFNC98T/Ut It Now IFNC Fundo de Índice
1158	P.ACUCAR CBD DIR	PCAR2.SA	CIA BRASILEIRA DE DISTRIBUICAO 
1160	SHOW ON	SHOW3.SA	Time For Fun Empresa 
1163	OURO XAU=X
1164	PRATA XAG=X
1165	PLATINA XPT=X
1166	PALADIO XPD=X
1167	PETROLEO BRT-
1168	SELIC BRTARGET=CBBR
1169	GLOBAL 40 BRAGLB40=RR
1170	TR BRTR=BRCB
1171	CDI BRCDICETIP=RR
1180	INDUSVAL	IDVL9.SA	IDVL9.SA (INDUSVAL)
1181	B2W DIGITAL	BTOW9.SA	B2W Digital Empresa 
1182	IND BOVESPA CI	IBOV11.SA	IBOV11.SA (IND BOVESPA CI)
1183	MAG LUIZA ON	MGLU3.SA	Magazine Luiza Empresa 
1189	IBRASIL INDEX	.IBRA	IBrA (Índice Brasil Amplo) 
1190	DIVIDEND INDEX	.DIVI	.DIVI (DIVIDEND INDEX)
1191	IMAT BASICOS IND	.IMAT	IMAT BASICOS
1192	UTILITIES INDEX	.UTIL	Public Utilities 
1193	VIVER ON	VIVR3.SA	Viver Incorporadora e Construtora S.A. Empresa 
1194	ALL ORE ON	AORE3.SA	Advanced Digital Health Medicina Preventiva SA Empresa 
1195	BROOKFIELD DIR	BISA1.SA	BISA1.SA (BROOKFIELD DIR)
1198	MMX MINERACAO E	MMXM11.SA	MMX Mineração e Metálicos Empresa 
1199	IBRX BRASIL IND	.IBRX	IBRX e Ibovespa
1201	JBS DIR	JBSS1.SA	JBSS1.SA (JBS DIR)
1202	FII JS RL EST MU	JSRE11.SA	JS REAL ESTATE MULTIGESTÃO 
1205	FII BB CORP CI	BBRC11.SA	BB Renda Corporativa Fundo de Investimento Imobiliario 
1206	RJCP EQUITY ON	RJCP3.SA	-
1207	BRAZIL PHARMA ON	BPHA3.SA	BRASIL PHARMA S.A. 
1209	QUALICORP ON	QUAL3.SA	Qualicorp Empresa 
1210	LOPES BRASIL DIR	LPSB1.SA	LPSB1.SA (LOPES BRASIL DIR)
1211	TECHNOS ON	TECN3.SA	Technos SA Empresa 
1218	ABRIL EDU UNT	ABRE11.SA	ABRE11.SA (ABRIL EDU UNT)
1219	ABRIL EDU ON	ABRE3.SA	ABRE3.SA (ABRIL EDU ON)
1222	TIM PART ON	TIMP3.SA	TIM Brasil Empresa 
1225	FII TRX LOG DIR	TRXL12.SA	TRXL12.SA (FII TRX LOG DIR)
1226	RENOVA DIR	RNEW1.SA	RNEW1.SA (RENOVA DIR)
1227	FDO INV IMOB MER	MBRF11.SA	Fundo de Investimento Imobiliario Mercantil do Brasil
1228	FDO INV IMOB RIO	RBCB11.SA	RIO BRAVO CRÉDITO IMOBILIÁRIO I FDO INV IMOB 
1229	RB CAPITAL GEN S	RBGS11.SA	RB Capital General Shopping Sulacap Fundo de Investimento Imobiliario 
1230	PINE	PINE2.SA	PINE2.SA (PINE)
1232	RENOVA ON	RNEW9.SA	RNEW9.SA (RENOVA ON)
1237	TELEF BRASIL ON	VIVT3.SA	Telefônica Brasil Empresa
1238	TELEF BRASIL PN	VIVT4.SA	Telefônica Brasil Empresa
1239	PINE PN REC	PINE10.SA	PINE10.SA (PINE PN REC)
1240	V-AGRO ON	VAGR3.SA	VAGR3.SA (V
1242	IT NOW IGCT CI	GOVE11.SA	ITNOWIGCTB40/Ut It Now IGCT Fundo de Índice
1243	IT NOW ISE FDO D	ISUS11.SA	ITNOWISEFD5N/Ut It Now ISE Fundo de Índice
1244	RJCP EQUITY DIR	RJCP1.SA	RJCP1.SA (RJCP EQUITY DIR)
1248	FII JS RENDA CI	JSIM11.SA	RB Capital Renda I Fundo de Investimento Imobiliario
1250	FDO INV PART IE	ESUD11.SA	ESUD11.SA (FIP IE II)
1252	FDO INV PART IE	ESUT11.SA	FDO INV PART IE BB VOTORANTIM ENERG SUSTENT III 
1254	FIP IE I	ESUU11.SA	ESUU11.SA (FIP IE I)
1256	FII XP GAIA CI	XPGA11.SA	XPGA11.SA (FII XP GAIA CI)
1257	RAIADROGASIL ON	RADL3.SA	RaiaDrogasil Corporação 
1258	FDO INV IMOB AES	AEFI11.SA	AEFI11.SA (FDO INV IMOB AES)
1259	FII RBPRIME2 CI	RBPD11.SA	RBPD11.SA (FII RBPRIME2 CI)
1260	FII RBPRIME2 CI	RBPD12.SA	RBPD12.SA (FII RBPRIME2 CI)
1261	FII RBPRIME2 CI	RBPD13.SA	RBPD13.SA (FII RBPRIME2 CI)
1262	FDO INV IMO INDS	FIIB11.SA	FIIINDLBR97G/Ut
1265	FII CX TRX CI	CXTL11.SA	Fundo de Investimento Imobiliario TRX Caixa Logistica Renda Empresa
1267	PANAMERICANO DIR	BPNM2.SA	BPNM2.SA (PANAMERICANO DIR)
1268	CELESC PN	CLSC4.SA	Centrais Elétricas de Santa Catarina Empresa 
1269	IT NOW IDIV FDO	DIVO11.SA	ITNOWIDIV74L/Ut It Now IDIV Fundo de Índice
1270	IT NOW IMAT FDO	MATB11.SA	ITNOWIMATF9C/Ut It Now IMAT Fundo de Índice
1277	INDUSVAL	IDVL11.SA	IDVL11.SA (INDUSVAL)
1278	FDO INV IMOB THE	ONEF11.SA	Fundo de Investimento Imobiliário Agências Caixa – FII Empresa
1279	MERC BRASIL DIR	BMEB2.SA	BMEB2.SA (MERC BRASIL DIR)
1280	FII JS REAL	JSRE12.SA	JSRE12.SA (FII JS REAL)
1284	VIA VAREJO ON	VVAR3.SA	Via Varejo Empresa 
1286	OI ON	OIBR3.SA	Oi Empresa 
1287	OI PN	OIBR4.SA	Oi Empresa 
1290	TELEBRAS DIR ORD	TELB1.SA	TELB1.SA (TELEBRAS DIR ORD)
1291	FII RD ESCRI CI	RDES11.SA	RDES11.SA (FII RD ESCRI CI)
1294	LOCAMERICA ON	LCAM3.SA	Locamerica Empresa 
1295	BTG PACTUAL UNT	BBTG11.SA	BBTG11.SA (BTG PACTUAL UNT)
1296	BTG PACTUAL BDR	BBTG12.SA	BBTG12.SA (BTG PACTUAL BDR)
1298	BTGP BANCO ON	BPAC3.SA	BTG Pactual Banco 
1299	BTGP BANCO PN	BPAC5.SA	BTG Pactual Banco 
1303	UNICASA ON	UCAS3.SA	Unicasa Móveis Empresa 
1309	LUPATECH	LUPA1.SA	LUPATECH S.A. 
1312	SENIOR SOL ON	SNSL3M.SA	SNSL3M.SA (SENIOR SOL ON)
1313	ISHARES UTIP CI	UTIP11.SA	Bovespa Fundo de Índice iShares Índice de Utilidade Pública (UTIL) BM&FBovespa Fundo de Índice
1315	MAXI RENDA FII	MXRF11.SA	FIIMAXIREGU3/Ut
1316	CCX CARVAO ON	CCXC3.SA	CCX CARVÃO DA COLÔMBIA S.A. 
1318	CCX CARVAO ON	CCXC3S.SA	CCX CARVÃO DA COLÔMBIA S.A. 
1319	CCX CARVAO ON	CCXC3T.SA	CCXC3T.SA (CCX CARVAO ON)
1320	JOAO FORTES DIR	JFEN1.SA	JFEN1.SA (JOAO FORTES DIR)
1326	MPX ENERGIA DIR	MPXE1.SA	MPXE1.SA (MPX ENERGIA DIR)
1327	TRANS ALIANCA UN	TAEE11.SA	TAESA Empresa 
1328	TRANS ALIANCA ON	TAEE3.SA	TAESA Empresa 
1329	TRANS ALIANCA PN	TAEE4.SA	TAESA Empresa 
1331	ISH INDICE CARBO	ECOO11.SA	ISHARESIN7M2/Ut iShares Índice Carbono Eficiente (ICO2) Brasil - Fundo de Índice
1332	LAN AIRLINES UNT	LATM11.SA	LATM11.SA (LAN AIRLINES UNT)
1333	LUPATECH	LUPA9.SA	LUPA9.SA (LUPATECH)
1335	VIGOR FOOD ON	VIGR3.SA	VIGR3.SA (VIGOR FOOD ON)
1337	FDO INV IMOB POL	PLRI11.SA	FIIPOLOIIS3/Ut
1338	JOAO FORTES ON	JFEN9.SA	JFEN9.SA (JOAO FORTES ON)
1339	MPX ENERGIA ON R	MPXE9.SA	MPXE9.SA (MPX ENERGIA ON R)
1341	ABC BRASIL	ABCB2.SA	ABCB2.SA (ABC BRASIL)
1344	PDG REALT DIR	PDGR11.SA	PDGR11.SA (PDG REALT DIR)
1345	RENOVA ON	RNEW3.SA	Renova Energia Empresa 
1346	RENOVA PN	RNEW4.SA	Renova Energia Empresa 
1347	RENOVA DIR	RNEW12.SA	RNEW12.SA (RENOVA DIR)
1350	FII BB R PAP CI	RNDP11.SA	BB RENDA DE PAPÉIS IMOBILIÁRIOS FDO INV IMOB 
1351	FDO INV IMOB RIO	RNGO11.SA	Fundo de Investimento Imobiliario Rio Negro 
1354	ABC BRASIL	ABCB10.SA	ABCB10.SA (ABC BRASIL)
1356	KINEA II RL EST	KNRE11.SA	Kinea II Real Estate Equity Fundo de Investimento Imobiliario Empresa 
1358	VILA OLIMPIA COR	VLOL11.SA	Fundo de Investimento Imobiliario Vila Olimpia Corporate Empresa
1359	RENOVA PN REC	RNEW10.SA	RNEW10.SA (RENOVA PN REC)
1360	RENOVA  UNT REC	RNEW13.SA	RNEW13.SA (RENOVA UNT REC)
1366	FII MAXI REN	MXRF12.SA	MXRF12.SA (FII MAXI REN)
1367	FDO INV IMOB BAN	BNFS11.SA	FIIBANRIS3LQ/Ut
1368	FII BC FUND CI	BRCR11.SA	FDO INV
1371	VIVER	VIVR1.SA	VIVR1.SA (VIVER)
1374	OSX BRASIL DIR	OSXB1.SA	OSXB1.SA (OSX BRASIL DIR)
1376	FDO INV IMOB KIN	KNCR11.SA	Kinea Rendimentos Imobiliários Fundo de Investimento Imobiliário Empresa
1377	FDO INV IMOB AGE	AGCX11.SA	AGCX11.SA (FDO INV IMOB AGE)
1378	FDO INV IMOB SDI	SDIL11.SA	SDI LOGÍSTICA RIO FDO INV IMOB 
1379	FATOR VER FN RTS	VRTA12.SA	VRTA12.SA (FATOR VER FN RTS)
1380	FDO DE INDICE CA	XBOV11.SA	CAIXAETFXQ7K/Ut CAIXA ETF Ibovespa Fundo de Índice
1381	FDO INV IMOB TRX	XTED11.SA	TRX EDIFÍCIOS CORPORATIVOS FDO INV IMOB 
1384	V-AGRO DIR	VAGR1.SA	VAGR1.SA (V
1385	FDO INV IMOB BB	BBPO11.SA	BB PROGRESSIVO II FUNDO DE INVESTIMENTO IMOBILIÁRIO – FII Banco
1386	FII C TEXTIL CI	CTXT11.SA	Fundo de Investimento Imobiliário Centro Têxtil Internacional Empresa 
1387	FII JS RECIM CI	BJRC11.SA	BJRC11.SA (FII JS RECIM CI)
1389	V-AGRO ON REC	VAGR9.SA	VAGR9.SA (V
1390	ARTERIS ON	ARTR3.SA	ARTR3.SA (ARTERIS ON)
1391	FDO INV IMOB RIO	RBVO11.SA	FIIRIOBCRK72/Ut
1392	CELPA DIR	CELP1.SA	CELP1.SA (CELPA DIR)
1396	FDO INV IMOB SAN	SAAG11.SA	SAAG11.SA (FII SANT AGE CI)
1397	FII BC FUND CI	BRCR12.SA	BRCR12.SA (FII BC FUND CI)
1399	CAMBUCI ETF 2	CAMB2.SA	CAMB2.SA (CAMBUCI ETF 2)
1401	FII CSHG CRI CI	HGCR11.SA	FIICSHGCRBPF/Ut
1403	CELPA ON REC	CELP9.SA	CELP9.SA (CELPA ON REC)
1404	LINX ON	LINX3.SA	Linx Empresa 
1405	CAMBUCI PN	CAMB10.SA	CAMBUCI S.A. 
1408	FII MAXIMARC CI	MXRC11.SA	MXRC11.SA (FII MAXIMARC CI)
1409	ENERGISA	ENGI1.SA	ENGI1.SA (ENERGISA)
1410	ENERGISA	ENGI12.SA	ENGI12.SA (ENERGISA)
1412	FDO INV IMOB XP	XPCM11.SA	XP Corporate Macaé Fundo de Investimento Imobiliário Empresa
1413	FII GWI RI CI	GWIR11.SA	GWIR11.SA (FII GWI RI CI)
1414	FII SP DOWNT CI	SPTW11.SA	SP Downtown Fundo de Investimento Imobiliario 
1415	POLO FDO INV IMO	PORD11.SA	Polo Fundo de Investimento Imobiliario 
1416	FII SANT CI	STFI11.SA	STFI11.SA (FII SANT CI)
1419	ENERGISA	ENGI13.SA	ENGI13.SA (ENERGISA)
1421	FDO INV IMOB BRA	BPFF11.SA	FUNDOINVE3SQ/Ut
1422	BIOSEV ON	BSEV3.SA	BIOSEV SA Empresa 
1423	ALUPAR UNT	ALUP11.SA	Alupar Investimento SA Empresa 
1424	ALUPAR ON	ALUP3.SA	Alupar Investimento SA Empresa 
1425	ALUPAR PN	ALUP4.SA	Alupar Investimento SA Empresa 
1426	SMILES ON	SMLE3.SA	SMILES S.A. 
1427	BBSEGURIDADE ON	BBSE3.SA	BB Seguridade Empresa 
1432	CONTAX UNT	CTAX11.SA	ATMA PARTICIPAÇÕES S.A. 
1433	GAVEA FDO DE FDO	GVFF11.SA	GVFF11.SA (GAVEA FDO DE FDO)
1434	FDO INV IMOB JPP	JPPC11.SA	JPPC11 (JPP Capital) 
1436	FII SANT AGE CI	SAAG12.SA	SAAG12.SA (FII SANT AGE CI)
1437	FDO INV IMOB FAT	FIXX11.SA	FIXX11.SA (FDO INV IMOB FAT)
1438	FDO INV IMOB TB	TBOF11.SA	FDO INV IMOB 
1439	FII GEN SHOP CI	FIGS11.SA	Fundo de Investimento Imobiliario General Shopping Ativo e Renda 
1440	SANTANDER BR DIR	SANB12.SA	SANB12.SA (SANTANDER BR DIR)
1441	BANESTES DIR	BEES1.SA	BEES1.SA (BANESTES DIR)
1442	CPFL RENOVAV ON	CPRE3.SA	CPFL ENERGIAS RENOVÁVEIS S.A. 
1443	FIP XP OMEGA I	XPOM11.SA	FIPXPOMEGQBT/Ut
1446	MERITO DESENVOLV	MFII11.SA	Merito Desenvolvimento Imobiliario I FII Fundo de Investimento 
1448	FDO INV IMOB JHS	RBBV11.SA	FIIJHSFFBK3J/Ut
1449	VIVER DIR	VIVR11.SA	VIVR11.SA (VIVER DIR)
1450	BANESTES ON REC	BEES9.SA	BEES9.SA (BANESTES ON REC)
1451	VULCABRAS DIR	VULC1.SA	VULC1.SA (VULCABRAS DIR)
1453	ALCOA	AALC34.SA	AALC34.SA (ALCOA)
1454	APPLE	AAPL34.SA	Apple Empresa 
1455	ABBOTT	ABTT34.SA	Abbott Laboratories Companhia 
1456	AMGEN	AMGN34.SA	Amgen Empresa 
1457	AMAZON	AMZO34.SA	Amazon Empresa 
1458	ARCELOR	ARMT34.SA	ArcelorMittal Empresa 
1459	ATT INC	ATTB34.SA	AT	ATTB34.SAT Companhia 
1460	AVON	AVON34.SA	AVON34.SA (AVON)
1461	AMERICAN EXP	AXPB34.SA	American Express Empresa 
1462	BRISTOLMYERS	BMYB34.SA	Bristol
1463	BANK AMERICA	BOAC34.SA	Bank of America Banco 
1464	BOEING	BOEI34.SA	Boeing Corporação 
1465	CATERPILLAR	CATP34.SA	Caterpillar Inc. Empresa 
1466	CHEVRON	CHVX34.SA	Chevron Empresa 
1467	COMCAST	CMCS34.SA	Comcast Empresa
1468	COCA COLA	COCA34.SA	The Coca
1469	COLGATE	COLG34.SA	Colgate
1470	COPHILLIPS	COPH34.SA	ConocoPhillips Empresa 
1471	CISCO	CSCO34.SA	Cisco Systems Companhia 
1472	CITIGROUP	CTGP34.SA	Citigroup Empresa 
1474	WALT DISNEY	DISB34.SA	The Walt Disney Company Companhia 
1475	DOW CHEMICAL	DOWB34.SA	DOWB34.SA (DOW CHEMICAL)
1476	DUPONT	DUPO34.SA	DUPO34.SA (DUPONT)
1477	EBAY	EBAY34.SA	EBay Empresa 
1478	EXXON MOBIL	EXXO34.SA	ExxonMobil Empresa 
1479	FREEPORT	FCXO34.SA	Freeport
1480	FORD MOTORS	FDMO34.SA	Ford Motor Company Fabricante de automóveis 
1481	FEDEX CORP	FDXB34.SA	FedEx Empresa 
1482	GE	GEOO34.SA	General Electric Conglomerado 
1483	GOOGLE	GOOG34.SA	Alphabet Inc. Conglomerado 
1484	GOLDMANSACHS	GSGI34.SA	Goldman Sachs Empresa 
1485	HALLIBURTON	HALI34.SA	Halliburton Empresa 
1486	HOME DEPOT	HOME34.SA	The Home Depot Companhia 
1487	HONEYWELL	HONB34.SA	Honeywell Corporação 
1488	HP COMPANY	HPQB34.SA	Hewlett
1489	IBM	IBMB34.SA	IBM Empresa 
1490	INTEL	ITLC34.SA	Intel Empresa 
1491	JOHNSON	JNJB34.SA	Johnson 	JNJB34.SA Johnson Empresa 
1492	JPMORGAN	JPMC34.SA	JPMorgan Chase Empresa 
1493	KRAFT GROUP	KFGI34.SA	Incluir pontuação e letras maiúsculas e minúsculas. ... Ações em Destaque.
1494	LILLY	LILY34.SA	Eli Lilly and Company Empresa 
1495	LOCKHEED	LMTB34.SA	Lockheed Martin Empresa fabricante 
1497	MCDONALDS	MCDC34.SA	McDonald's Cadeia de restaurantes de fast food 
1498	3M	MMMC34.SA	3M 
1499	MERCK	MRCK34.SA	Merck Sharp and Dohme Empresa 
1500	MORGAN STAN	MSBR34.SA	Morgan Stanley Empresa 
1501	MASTERCARD	MSCD34.SA	Mastercard Empresa 
1502	MICROSOFT	MSFT34.SA	Microsoft Empresa 
1503	MONSANTO	MSTO34.SA	MSTO34.SA (MONSANTO)
1504	NETFLIX	NFLX34.SA	Netflix Empresa 
1505	NIKE	NIKE34.SA	Nike, Inc. Empresa 
1506	ORACLE	ORCL34.SA	Oracle Corporation Empresa 
1507	PEPSICO INC	PEPB34.SA	PepsiCo Empresa 
1508	PFIZER	PFIZ34.SA	Pfizer Empresa 
1509	PG	PGCO34.SA	Procter 	PGCO34.SA Gamble Corporação 
1510	PHILIP MORRI	PHMO34.SA	Philip Morris International Empresa 
1511	QUALCOMM	QCOM34.SA	Qualcomm Empresa 
1512	STARBUCKS	SBUB34.SA	Starbucks Empresa 
1513	SCHLUMBERGER	SLBG34.SA	Schlumberger Empresa 
1514	TIME WARNER	TWXB34.SA	TWXB34.SA (TIME WARNER)
1515	UPS	UPSS34.SA	United Parcel Service Empresa 
1516	US STEEL	USSX34.SA	United States Steel Companhia 
1517	VERIZON	VERZ34.SA	Verizon Communications Empresa 
1518	VISA INC	VISA34.SA	Visa Empresa 
1519	WAL MART	WALM34.SA	Walmart Companhia 
1520	WELLS FARGO	WFCO34.SA	Wells Fargo Companhia 
1521	XEROX CORP	XRXB34.SA	Xerox Empresa 
1522	AGRENCO BDR	AGEN33.SA	AGEN33.SA (AGRENCO BDR)
1523	BTG PACTUAL BDR	BBTG35.SA	BBTG35.SA (BTG PACTUAL BDR)
1524	BTG PACTUAL BDR	BBTG36.SA	BBTG36.SA (BTG PACTUAL BDR)
1525	PATAGONIA	BPAT33.SA	BPAT33.SA (PATAGONIA)
1526	COSAN LTD BDR	CZLT33.SA	CZLT33.SA (COSAN LTD BDR)
1527	DUFRY AG DRC	DAGB33.SA	DAGB33.SA (DUFRY AG DRC)
1528	GP INVEST	GPIV33.SA	GP Investments Companhia 
1529	LATAM AIRLN BDR	LATM33.SA	LATM33.SA (LATAM AIRLN BDR)
1530	LAEP INVEST BDR	MILK33.SA	MILK33.SA (LAEP INVEST BDR)
1531	PACIFIC RUB	PREB32.SA	PREB32.SA (PACIFIC RUB)
1532	TGLT	TGLT32.SA	TGLT32.SA (TGLT)
1533	WILSON SONS	WSON33.SA	Wilson, Sons Empresa
1537	LLX LOG DIR	LLXL1.SA	LLXL1.SA (LLX LOG DIR)
1540	SANEPAR RTS	SAPR2.SA	SAPR2.SA (SANEPAR RTS)
1541	ANIMA ON	ANIM3.SA	Anima Educação Empresa 
1542	FII AQUILLA CI	AQLL11.SA	AQLL11.SA (FII AQUILLA CI)
1543	BERKSHIRE BDR	BERK34.SA	Berkshire Hathaway Companhia 
1544	SER EDUCA ON	SEER3.SA	Ser Educacional Empresa 
1545	AMBEV ON	ABEV3.SA	AMBEV Empresa 
1546	LLX LOG ON REC	LLXL9.SA	LLXL9.SA (LLX LOG ON REC)
1547	KLABIN UNT	KLBN11.SA	Klabin Empresa 
1549	INEPAR TEL DIR	INET1.SA	INET1.SA (INEPAR TEL DIR)
1550	CVC BRASIL	CVCB3.SA	CVC BRASIL OPERADORA E AGÊNCIA DE VIAGENS S.A. Empresa 
1554	FII CX RBRAV	CXRI11.SA	CAIXARIOB6TC/Ut
1557	VIAVAREJO UNT	VVAR11.SA	VIA VAREJO S.A. 
1558	VIAVAREJO	VVAR4.SA	VVAR4.SA (VIAVAREJO)
1559	DOMO CI	DOMC11.SA	Domo Fundo de Investimento Imobiliario FII Empresa
1561	BIOMM ON	BIOM3M.SA	Biomm S.A. Empresa 
1563	FII VEREDA CI	VERE11.SA	VERE11.SA (FII VEREDA CI)
1572	SENIOR SOL ON	SNSL3.SA	SNSL3.SA (SENIOR SOL ON)
1574	FIP CONQUEST CI	FCCQ11.SA	CONQUESTF8MN/Ut
1575	FII LOUVEIRA CI	GRLV11.SA	CSHG GR Louveira Fundo de Investimento Imobiliario 
1576	FII C BRANCO CI	CBOP11.SA	CASTELLOB4WI/Ut
1577	FACEBOOK	FBOK34.SA	Facebook Inc. Empresa 
1579	NET PRE DIR	NETC2.SA	NETC2.SA (NET PRE DIR)
1580	PRUMO ON	PRML3.SA	PRUMO LOGÍSTICA S.A. 
1582	KLABIN	KLBN13.SA	KLBN13.SA (KLABIN)
1583	NET PN REC	NETC10.SA	NETC10.SA (NET PN REC)
1586	AMBEV DIR	ABEV1.SA	ABEV1.SA (AMBEV DIR)
1587	COMGAS	CGAS1.SA	CGAS1.SA (COMGAS)
1588	BR PHARMA	BPHA1.SA	BPHA1.SA (BR PHARMA)
1590	PROFARMA	PFRM1.SA	PFRM1.SA (PROFARMA)
1591	ENEVA	ENEV1.SA	ENEV1.SA (ENEVA)
1592	TAURUS	FJTA1.SA	FJTA1.SA (TAURUS)
1593	TAURUS	FJTA2.SA	FJTA2.SA (TAURUS)
1594	PARANA	PRBC2.SA	PRBC2.SA (PARANA)
1595	AMBEV	ABEV9.SA	ABEV9.SA (AMBEV)
1598	CEMAT	CMGR1.SA	CMGR1.SA (CEMAT)
1599	CEMAT	CMGR2.SA	CMGR2.SA (CEMAT)
1600	BOMBRIL	BOBR11.SA	BOBR11.SA (BOMBRIL)
1601	BR PHARMA	BPHA11.SA	BPHA11.SA (BR PHARMA)
1602	PROFARMA	PFRM9.SA	PFRM9.SA (PROFARMA)
1604	ENEVA	ENEV9.SA	ENEV9.SA (ENEVA)
1605	XP FIA TOP DIV	XPTD11.SA	XPTD11.SA (XP FIA TOP DIV)
1606	IOCHP-MAXION	MYPK11.SA	MYPK11.SA (IOCHP
1608	FORJA TAURUS	FJTA9.SA	FJTA9.SA (FORJA TAURUS)
1609	FII VIDANOVA	FIVN11.SA	Fundo de Investimento Imobiliario Vida Nova 
1610	BANCO PAN	BPAN10.SA	BCO PAN S.A. 
1612	BCO PAN	BPAN4.SA	Banco PAN 
1614	TWITTER INC	TWTR34.SA	Twitter, Inc. Empresa 
1616	BANCO PAN	BPAN12.SA	BPAN12.SA (BANCO PAN)
1617	KARSTEN	CTKA1.SA	CTKA1.SA (KARSTEN)
1618	KARSTEN	CTKA2.SA	CTKA2.SA (KARSTEN)
1621	KARSTEN	CTKA10.SA	CTKA10.SA (KARSTEN)
1622	KARSTEN	CTKA9.SA	CTKA9.SA (KARSTEN)
1623	CELPAR	GPAR11.SA	GPAR11.SA (CELPAR)
1624	FII NOVOHORI CI	NVHO11.SA	FUNDOINVEHB7/Ut
1626	COSAN LOG	RLOG3.SA	Cosan Logística S.A. Empresa 
1627	KEPLER WEBER	KEPL11.SA	KEPLER WEBER 
1628	OURO FINO	OFSA3.SA	Ouro Fino Saúde Animal Participações S.A. Empresa 
1629	HRT PETROLEO DIR	HRTP11.SA	HRTP11.SA (HRT PETROLEO DIR)
1630	BANSANTANDER	BSAN30.SA	BSAN30.SA (BANSANTANDER)
1631	PRUMO DIR ORD	PRML1.SA	PRML1.SA (PRUMO DIR ORD)
1632	BANSANTANDER	BSAN33.SA	BCO SANTANDER S.A. 
1636	BB ETF SP DV	BBSD11.SA	BBETFSPDI2OY/Ut BB ETF S&P Dividendos Brasil
1637	PRUMO	PRML9.SA	PRML9.SA (PRUMO)
1639	CEB	CEBR11.SA	CEBR11.SA (CEB)
1640	FER HERINGER	FHER1.SA	FHER1.SA (FER HERINGER)
1641	NUTRIPLANT	NUTR1.SA	NUTR1.SA (NUTRIPLANT)
1642	NOVA OLEO ON	OGSA3.SA	OGSA3.SA (NOVA OLEO ON)
1643	TIFFANY	TIFF34.SA	Tiffany 	TIFF34.SA Co. Empresa 
1644	US BANCORP	USBC34.SA	U.S. Bancorp Empresa 
1645	UNITED TECH	UTEC34.SA	UTEC34.SA (UNITED TECH)
1647	BIOSEV	BSEV1.SA	BSEV1.SA (BIOSEV)
1665	IT NOW S&P500 TR	SPXI11.SA	ITNOWSP50MOK/Ut It Now S&P500® TRN Fundo de Índice
1668	FII MERC BR	FLCI11.SA	FLCI11.SA (FII MERC BR)
1669	FIP PORT SUD CI	FPOR11.SA	PORTOSUDE9U0/Ut
1670	PORTO VM	PSVM11.SA	Porto Sudeste VM SA Empresa
1671	ENERGISA MT ON	ENMT3.SA	Energisa Mato Grosso Empresa
1672	ENERGISA MT PN	ENMT4.SA	Energisa Mato Grosso Empresa
1673	JHSF PART RTS	JHSF1.SA	JHSF1.SA (JHSF PART RTS)
1674	IMC S/A ON	MEAL3.SA	International Meal Company Empresa 
1675	RUMO LOG ON	RUMO3.SA	-
1676	JHSF PART ON REC	JHSF9.SA	JHSF9.SA (JHSF PART ON REC)
1677	FII B VAREJO CI	BVAR11.SA	FDO INV IMOB BRASIL VAREJO 
1678	PDG REALT RTS	PDGR1.SA	PDGR1.SA (PDG REALT RTS)
1679	CYRE COM CCP RTS	CCPR1.SA	CCPR1.SA (CYRE COM CCP RTS)
1680	PDG REALT	PDGR9.SA	PDGR9.SA (PDG REALT)
1681	FII BCIA	BCIA11.SA	BRADESCO CARTEIRA IMOB ATIVA FII
1682	PARCORRETORA ON	PARC3.SA	PARC3.SA (PARCORRETORA ON)
1684	MAESTROLOC ON	MSRO3.SA	MAESTRO LOCADORA DE VEICULOS S.A. 
1685	SWEETCOSMET ON	SWET3.SA	SWET3.SA (SWEETCOSMET ON)
1686	PETRORIO ON	PRIO3.SA	PetroRio Empresa 
1687	FII BEES CRI	BCRI11.SA	Banestes Recebiveis Imobiliarios Fundo de Investimento Imobiliario Empresa
1688	SWEETCOSMET RTS	SWET1.SA	SWET1.SA (SWEETCOSMET RTS)
1690	BOSTON PROP BDR	BOXP34.SA	Boston Properties Real estate investment trust 
1691	COTY INC BDR	COTY34.SA	Coty, Inc. Empresa 
1692	DANAHER CORP BDR	DHER34.SA	Danaher Corporation Conglomerado 
1693	GOOGLE BDR	GOOG35.SA	GOOG35.SA (GOOGLE BDR)
1694	HERSHEY CO BDR	HSHY34.SA	Hershey's Empresa 
1695	L BRANDS BDR	LBRN34.SA	L Brands Moda 
1696	MONDELEZ INT BDR	MDLZ34.SA	Mondelez International Empresa 
1697	MOSAIC CO BDR	MOSC34.SA	The Mosaic Company Empresa 
1698	UNIONPACIFIC BDR	UPAC34.SA	Union Pacific Corporation Empresa 
1699	WESTERNUNION BDR	WUNI34.SA	Western Union Empresa 
1700	SOMOS EDUCA ORD	SEDU3.SA	SOMOS EDUCAÇÃO S.A. 
1703	ACCENTURE	ACNB34.SA	Accenture Empresa 
1704	BNY MELLON	BONY34.SA	Bank of New York Mellon Empresa 
1705	FEMSA	FMXB34.SA	Fomento Econômico Mexicano Empresa 
1706	GEN DYNAMICS	GDBR34.SA	General Dynamics Conglomerado 
1707	KIMBERLY CL	KMBB34.SA	Kimberly KIMBERLYCE17/UnSBDR QI
1708	METLIFE INC	METB34.SA	MetLife Inc. Empresa 
1709	TEXAS INC	TEXA34.SA	Texas Instruments Empresa 
1710	TARGET CORP	TGTB34.SA	Target Corporation Companhia 
1711	CRISTAL ON	CRPG3.SA	Tronox Pigmentos do Brasil SA Empresa 
1712	CRISTAL PNA	CRPG5.SA	Tronox Pigmentos do Brasil SA Empresa 
1713	CRISTAL PNB	CRPG6.SA	Tronox Pigmentos do Brasil SA Empresa 
1717	KRAFT	KHCB34.SA	Kraft Heinz Empresa 
1718	ENERGISA	ENGI15.SA	ENGI15.SA (ENERGISA)
1719	FORJA TAURUS BNS	FJTA11.SA	FJTA11.SA (FORJA TAURUS BNS)
1720	FORJA TAURUS	FJTA12.SA	FJTA12.SA (FORJA TAURUS)
1721	FII T SANTA	TSFI11.SA	TSFI11.SA (FII T SANTA)
1723	ATOMPAR ON	ATOM3.SA	ATOM Participações Empresa 
1728	FUNDES	FDES11.SA	FUNDODESE8S2/Ut
1730	CELGENE	CLGN34.SA	CLGN34.SA (CELGENE)
1731	INEPAR	INEP12.SA	INEPar.SA
1732	IMC S/A DIR	MEAL1.SA	MEAL1.SA (IMC S/A DIR)
1734	POMIFRUTAS	FRTA3.SA	Pomifrutas SA Empresa 
1735	IMC S/A ON REC	MEAL9.SA	MEAL.SA
1736	RUMO LOG DIR	RUMO1.SA	RUMO1.SA (RUMO LOG DIR)
1737	FII TOPFOFII	TFOF11.SA	TFOF11.SA (FII TOPFOFII)
1738	AES TIETE E	TIET11.SA	AES Tietê Empresa 
1739	AES TIETE E	TIET3.SA	AES Tietê Empresa 
1740	AES TIETE E	TIET4.SA	AES Tiete Energia SA Preference Shares
1743	BR INSURANCE	BRIN1.SA	Manufaturas de Brinquedos Estrela SA Empresa
1745	MILLS DIR	MILS1.SA	Bovespa 
1746	DURATEX DIR	DTEX1.SA	DTEX1.SA (DURATEX DIR)
1748	POMIFRUTAS DIR	FRTA1.SA	FRTA1.SA (POMIFRUTAS DIR)
1750	MERC INVEST REC	BMIN9.SA	BMIN9.SA (MERC INVEST REC)
1751	MILLS ON REC	MILS9.SA	MILS9.SA (MILLS ON REC)
1752	COSAN LOG	RLOG1.SA	RLOG1.SA (COSAN LOG)
1753	USIMINAS	USIM11.SA	USIM11.SA (USIMINAS)
1754	DURATEX	DTEX9.SA	DTEX9.SA (DURATEX)
1755	FII CSHGFOFT	FOFT11.SA	HEDGE TOP FOFII 2 FDO INV IMOB 
1756	FII PEDRA NEGRA	FPNG11.SA	FPNG11.SA (FII PEDRA NEGRA)
1757	OGX PETROLEO	OGSA1.SA	OGSA1.SA (OGX PETROLEO)
1758	RANDON PART	RAPT1.SA	RAPT1.SA (RANDON PART)
1759	RANDON PART	RAPT2.SA	RAPT2.SA (RANDON PART)
1760	RLOG ON REC	RLOG9.SA	RLOG9.SA (RLOG ON REC)
1761	FII DEA CARE	CARE11.SA	FIIDEACAR4TB/Ut
1762	USIMINAS DIR	USIM1.SA	USIM1.SA (USIMINAS DIR)
1763	USIMINAS DIR	USIM12.SA	USIM12.SA (USIMINAS DIR)
1764	ABBVIE	ABBV34.SA	AbbVie Empresa 
1765	BIOGEN	BIIB34.SA	Biogen Idec Empresa 
1766	BLACKROCK	BLAK34.SA	BlackRock Empresa 
1767	COSTCO	COWC34.SA	Costco Empresa 
1768	COGNIZANT	CTSH34.SA	Cognizant Empresa 
1769	CVS HEALTH	CVSH34.SA	CVS Caremark Empresa 
1770	DELTA	DEAI34.SA	Delta Air Lines Companhia aérea 
1771	EMC	EMCC34.SA	EMCC34.SA (EMC)
1772	EXPRESCRIPTS	ESRX34.SA	ESRX34.SA (EXPRESCRIPTS)
1773	GILEAD	GILD34.SA	Gilead Sciences Empresa 
1774	GAP	GPSI34.SA	Gap Vestuário 
1775	MACYS	MACY34.SA	Macy's MACYSINCF4S/UnSBDR QI
1776	MEDTRONIC	MDTC34.SA	Medtronic Empresa 
1777	ROSS STORES	ROST34.SA	Ross Stores Empresa 
1778	SCHWAB	SCHW34.SA	The Charles Schwab Corporation Empresa 
1779	SALESFORCE	SSFO34.SA	Salesforce.com Empresa 
1780	THERMFISHER	TMOS34.SA	Thermo Fisher Scientific Empresa
1781	TRAVELERS	TRVC34.SA	The Travelers Companies Seguro 
1782	ENERGIAS BR	ENBR1.SA	ENBR1.SA (ENERGIAS BR)
1784	ALPHABET	GOGL34.SA	Alphabet Inc. Conglomerado 
1785	ALPHABET	GOGL35.SA	Alphabet Inc. Conglomerado 
1787	RANDON PART	RAPT10.SA	RAPT10.SA (RANDON PART)
1788	RANDON PART	RAPT9.SA	RAPT9.SA (RANDON PART)
1789	COPASA	CSMG1.SA	CSMG1.SA (COPASA)
1790	FII FATOR VERITA	VRTA13.SA	VRTA13.SA (FII FATOR VERITA)
1792	ALUPAR DIR	ALUP12.SA	ALUP12.SA (ALUPAR DIR)
1794	USIMINAS	USIM9.SA	USIM9.SA (USIMINAS)
1795	VITALYZE	VTLM3.SA	VTLM3.SA (VITALYZE)
1796	ENERGIAS BR ON	ENBR9.SA	ENBR9.SA (ENERGIAS BR ON)
1797	CCX CARVAO	CCXC1.SA	CCXC1.SA (CCX CARVAO)
1799	GERDAU MET	GOAU11.SA	GOAU11.SA (GERDAU MET)
1801	VITALYZE.ME DIR	VTLM1.SA	VTLM1.SA (VITALYZE.ME DIR)
1802	ENGIE BRASIL	EGIE3.SA	Engie Brasil Companhia 
1804	ALUPAR DIR	ALUP13.SA	ALUP13.SA (ALUPAR DIR)
1805	ALUPAR ON REC	ALUP9.SA	ALUP9.SA (ALUPAR ON REC)
1806	AMERICAN AIR	AALL34.SA	American Airlines Group Companhia 
1807	BEST BUY	BBYY34.SA	Best Buy Empresa 
1808	CHESAPEAKE	CHKE34.SA	CHKE34.SA (CHESAPEAKE)
1809	FIRST SOLAR	FSLR34.SA	First Solar Companhia 
1810	GENERAL MOT	GMCO34.SA	General Motors Marca de automóveis 
1811	GOPRO	GPRO34.SA	GoPro Empresa 
1812	J C PENNEY	JCPC34.SA	JCPC34.SA (J C PENNEY)
1813	TRANSOCEAN	RIGG34.SA	Transocean Empresa 
1814	SANCHEZ ENER	SANC34.SA	SANC34.SA (SANCHEZ ENER)
1815	SPRINT	SPRN34.SA	SPRN34.SA (SPRINT)
1816	TESLA MOTORS	TSLA34.SA	Tesla, Inc. Marca de automóveis 
1817	TESORO CORP	TSOR34.SA	TSOR34.SA (TESORO CORP)
1818	UBS GROUP	UBSG34.SA	UBS Group Empresa
1819	VALERO ENER	VLOE34.SA	Valero Energy Corporation Empresa 
1820	IT NOW IBOV	BOVV11.SA	ITNOWIBOV3QM/Ut It Now Ibovespa Fundo de Índice
1821	METALFRIO	FRIO1.SA	FRIO1.SA (METALFRIO)
1822	AES TIETE E RTS	TIET1.SA	TIET1.SA (AES TIETE E RTS)
1823	AES TIETE E RTS	TIET12.SA	TIET12.SA (AES TIETE E RTS)
1824	AES TIETE E RTS	TIET2.SA	TIET2.SA (AES TIETE E RTS)
1825	TECNISA DIR	TCSA1.SA	TCSA1.SA (TECNISA DIR)
1827	FII INDL BR	FIIB12.SA	FIIB12.SA (FII INDL BR)
1829	FIA FATOR V	SINC11.SA	SINC11.SA (FIA FATOR V)
1830	METALFRIO ON REC	FRIO9.SA	METALFRIO SOLUTIONS S.A. 
1832	FII BEES CRI	BCRI12.SA	BCRI12.SA (FII BEES CRI)
1833	ALIANSCE SHOP	ALSC1.SA	ALSC1.SA (ALIANSCE SHOP)
1835	FII KINEA IP	KNIP11.SA	Kinea Indices Precos Fundo de Investimento Imobiliario Empresa
1837	ENERGISA MT	ENMT2.SA	ENMT2.SA (ENERGISA MT)
1838	LOG IN DIR	LOGN12.SA	LOGN12.SA (LOG IN DIR)
1841	AETNA INC	AETB34.SA	AETB34.SA (AETNA INC)
1842	AIG GROUP	AIGB34.SA	American International Group Empresa 
1843	DUKE ENERGY	DUKB34.SA	Duke Energy Empresa 
1845	ALIANSCE REC	ALSC9.SA	ALSC9.SA (ALIANSCE REC)
1846	ALLIAR	AALR3.SA	Centro de Imagem Diagnosticos SA 
1849	TERRA SANTA	TESA3.SA	Terra Santa Empresa 
1850	ARCONIC	ARNC34.SA	Howmet Aerospace Empresa
1851	MARCOPOLO	POMO2.SA	POMO2.SA (MARCOPOLO)
1852	BATTISTELLA DIR	BTTL1.SA	BTTL1.SA (BATTISTELLA DIR)
1853	BATTISTELLA DIR	BTTL2.SA	BTTL2.SA (BATTISTELLA DIR)
1856	MARCOPOLO PRF	POMO10.SA	POMO10.SA (MARCOPOLO)
1857	CONTAX	CTAX1.SA	CTAX1.SA (CONTAX)
1860	ADVANCED-DH	ADHM3.SA	Advanced Digital Health Medicina Preventiva SA Empresa 
1863	IOCHP-MAXION	MYPK1.SA	MYPK1.SA (IOCHP
1864	MULTIPLAN	MULT1.SA	MULT1.SA (MULTIPLAN)
1865	REAL STATE IF	.IFIX	Índice Fundos de Investimentos Imobiliários 
1866	DASA	DASA1.SA	DASA1.SA (DASA)
1867	MOVIDA	MOVI3.SA	Movida Participacoes SA Empresa
1868	HERMES PARDINI	PARD3.SA	Instituto Hermes Pardini SA Empresa
1870	SAO OTFC L1	EURO12.SA	EURO12.SA (SAO OTFC L1)
1871	MULTIPLAN	MULT9.SA	MULT9.SA (MULTIPLAN)
1872	BTGP BANCO	BPAC11.SA	BTG Pactual Banco 
1874	TESTE IPN VS	IPNN3.SA	IPNN3.SA (TESTE IPN VS)
1876	FII DOMINGOS	FISD11	São Domingos - Fundo de Investimento Imobiliário
1877	RUMO	RAIL3.SA	Rumo Logística Empresa 
1878	GAFISA	GFSA11.SA	GFSA11.SA (GAFISA)
1879	IOCHP-MAXION	MYPK12.SA	MYPK12.SA (IOCHP
1881	AZUL	AZUL4.SA	Azul SA Empresa 
1882	FII TORRE AL	ALMI11.SA	Fundo de Investimento Imobiliario Torre Almirante Empresa
1883	FII CENESP	CNES11.SA	FIICENESP5QD/Ut
1884	FII GALERIA	EDGA11.SA	Fundo de Investimento Imobiliario – FII Edificio Galeria Empresa
1885	FII ANH EDUC	FAED11.SA	Fundo de Investimento Imobiliario Anhanguera Educacional Empresa
1886	FII EXCELLEN	FEXC11.SA	Fundo de Investimento Imobiliario 
1887	FII FLORIPA	FLRP11.SA	Floripa Shopping 
1888	FII VBI 4440	FVBI11.SA	FDO INV IMOB VBI FL 4440 
1889	FII CRIANCA	HCRI11.SA	Fundo de Investimento Imobiliario 
1890	FII HOTEL MX	HTMX11.SA	FIIHOTELMC1D/Ut
1891	FII SHOPJSUL	JRDM11.SA	Fundo de Investimento Imobiliario 
1892	FII MAX RET	MAXR11.SA	FII Max Reatil
1894	FII LOURDES	NSLU11.SA	FIILOURDEH7S/Ut
1895	TECNISA	TCSA9.SA	TCSA9.SA (TECNISA)
1896	FII TORRE NO	TRNT11.SA	Fundo de Investimento Imobiliario 
1897	WIZ	WIZS3.SA	Wiz Soluções e Corretagem de Seguros S.A. Empresa 
1898	FII GGRCOVEP	GGRC11.SA	GGRCOVIPEAU3/Ut
1899	FII CEO CCP	CEOC11.SA	FIICEOCCP54V/Ut
1900	FII CAMPUSFL	FCFL11.SA	FIICAMPUS8ND/Ut
1901	FII OURI JPP	OUJP11.SA	Ourinvest JPP Fundo de Investimento Imobiliario Empresa
1902	FII BM THERA	THRA11.SA	FIIBMTHERNO1/Ut
1903	FII EV KINEA	KINP11.SA	EVENPERMUE01/Ut
1904	WLM IND COM ON	WLMM3.SA	WLM 
1905	WLM IND COM PN	WLMM4.SA	WLM 
1908	BR BROKERS REC	BBRK9.SA	BBRK9.SA (BR BROKERS REC)
1909	CARREFOUR ON	CRFB3.SA	Atacadão 
1910	BIOTOSCANA BDR	GBIO33.SA	BIOTOSCANA INVESTMENTS S.A. 
1911	SAO OTFC L1	CEEB1.SA	CEEB1.SA (SAO OTFC L1)
1914	IRBBRASIL	IRBR3.SA	IRB Brasil RE Empresa 
1915	OMEGA GER	OMGE3.SA	OMEGA GERAÇÃO S.A. Empresa 
1916	ANDEAVOR	ANDV34.SA	ANDV34.SA (ANDEAVOR)
1920	PPLA UNT	PPLA11.SA	PPLA Participations Ltd Empresa
1921	PPLA	PPLA35.SA	PPLA35.SA (PPLA)
1922	PPLA	PPLA36.SA	PPLA36.SA (PPLA)
1923	FII RBRALPHA	RBRF11.SA	RBR Alpha Fundo de Fundos Fundo de Investimento Imobiliario Empresa
1924	SER EDUCA	SEER1.SA	SEER1.SA (SER EDUCA)
1925	DOMMO	DMMO3.SA	Dommo Energia SA Empresa 
1926	CAMIL	CAML3.SA	Camil Alimentos Empresa 
1928	TELEBRAS DIR PRE	TELB2.SA	TELB2.SA (TELEBRAS DIR PRE)
1929	DOMMO	DMMO1.SA	DMMO1.SA (DOMMO)
1931	SER EDUCA	SEER9.SA	SEER9.SA (SER EDUCA)
1932	SMILES	SMLS3.SA	Smiles Fidelidade Empresa 
1933	CEMIG	CMIG1.SA	CMIG1.SA (CEMIG)
1934	CEMIG	CMIG2.SA	CMIG2.SA (CEMIG)
1935	FII VINCI SC	VISC11.SA	Vinci Shopping Centers Fundo de Investimento Imobiliario Empresa 
1937	BANCO PAN	BPAN2.SA	BPAN2.SA (BANCO PAN)
1938	SANEPAR UNT	SAPR11.SA	Companhia de Saneamento do Paraná Empresa 
1939	PRINER	PRNR3.SA	Priner Servicos Industriais SA Empresa 
1940	CEMIG	CMIG10.SA	CMIG10.SA (CEMIG)
1941	FII BC FFII	BCFF11.SA	Fundos de Investimentos Imobiliarios
1942	CEMIG ON	CMIG9.SA	CMIG9.SA (CEMIG ON)
1943	BITCOIN BTC=X
1944	MERC INVEST	BMIN1.SA	BMIN1.SA (MERC INVEST)
1945	PETROBRAS BR	BRDT3.SA	Petrobras Distribuidora Companhia 
1946	DOWDUPONT	DWDP34.SA	DWDP34.SA (DOWDUPONT)
1947	BK BRASIL	BKBR3.SA	BK Brasil Operacao E Assessoria A Restaurantes SA Empresa
1948	FII  MALLS BP	MALL11.SA	MALLSBRASF6L/Ut
1949	FII BRREALTY	BZLI11.SA	BRAZILREA4J0/Ut
1951	GAFISA	GFSA1.SA	GFSA1.SA (GAFISA)
1952	FII UBS	UBSR11.SA	UBSR11.SA (FII UBS)
1954	FII XP MALLS	XPML11.SA	XP MALLS FUNDO DE INVESTIMENTO IMOBILIÁRIO FII Empresa 
1956	FII REIT RIV	REIT11.SA	REITRIVIEKCT/Ut
1958	FII ALIANZA	ALZR11.SA	ALIANZATR179/Ut
1959	GAFISA	GFSA9.SA	GFSA9.SA (GAFISA)
1961	FII NESTPAR	NPAR11.SA	Nestpar Fundo De Investimento Imobiliario Empresa
1962	JEREISSATI	JPSA3.SA	Jereissati Participações S.A. Empresa 
1963	JEREISSATI	JPSA4.SA	JPSA4 
1971	FII HEDGEFOF	HFOF11	HEDGE TOP FOFII 3 Fundo de Investimento Imobiliário Empresa
1973	FII HEDGEFOF	HFOF11	HEDGE TOP FOFII 3 Fundo de Investimento Imobiliário Empresa.SA
1974	LIQ	LIQO3.SA	ATMA PARTICIPAÇÕES S.A. 
1976	FII IRIDIUM	IRDM11.SA	FUNDOINVED2E/Ut
1977	FII VINCI SC	VISC12.SA	VISC12.SA (FII VINCI SC)
1978	B3 SA	B3SA3.SA	B3 SA 
1979	FII MOGNO	MGFF11.SA	FUNDOINVEFOW/Ut
1980	UBS BR R IM RTS	UBSR12.SA	UBSR12.SA (UBS BR R IM RTS)
1981	INTERMEDICA	GNDI3.SA	Notre Dame Intermedica Participacoes SA Empresa
1982	FII VOT LOG	VTLT11.SA	FUNDOINVEPU8/Ut
1983	HAPVIDA	HAPV3.SA	Hapvida Participacoes E Investimentos SA Empresa
1984	BANCO INTER	BIDI11.SA	Banco Inter 
1985	FDO INV IMOB SHO	WPLZ11.SA	FIIWPLAZAQ45/Ut
1986	LOG-IN	LOGN1.SA	LOG
1987	FII BB PAPII	RDPD11.SA	BBRENDAPAKAV/Ut
1988	FII RBRHGRAD	RBRR11.SA	FUNDOINVEK6D/Ut
1989	FII CSHG CRI RTS	HGCR12.SA	HGCR12.SA (FII CSHG CRI RTS)
1990	INTER BANCO	BIDI4.SA	Banco Inter 
1991	FII HABITAT	HBTT11.SA	Habitat I Fundo De Investimento Imobiliario Empresa
1992	FII OURO PRT	ORPD11.SA	ORPD11.SA (FII OURO PRT)
1993	FII OURICYRE	OUCY11.SA	FUNDOINVEHVG/Ut
1994	TARPON INV	TRPN1.SA	TRPN1.SA (TARPON INV)
1995	LOG-IN	LOGN9.SA	LOG
1996	FII XP LOG	XPLG11.SA	XP LOG FUNDO DE INVESTIMENTO IMOBILIÁRIO Empresa
1997	IPCA BRCPI=ECI
1998	IGPM BRIGPMM=FGV
1999	IPC-FIPE BRIPCM=FIPE
2000	OI	OIBR1.SA	OIBR1.SA (OI)
2002	XP MALLS FII RTS	XPML12.SA	XPML12.SA (XP MALLS FII RTS)
2004	FII H UNIMED	HUSC11.SA	FUNDOINVEC1R/Ut
2007	MOVIDA	MOVI1.SA	MOVIDA PARTICIPACOES SA 
2008	INTER BANCO	BIDI2.SA	BIDI2.SA (INTER BANCO)
2009	FII SDI LOG	SDIL12.SA	SDIL12.SA (FII SDI LOG)
2010	FII V MASTER	VOTS11.SA	VOTORANTFPLI/Ut
2013	FII CSHG URB	HGRU11.SA	RENDAURBABQG/Ut
2014	FII RBR PROP	RBRP11.SA	RBRPROPERK6C/Ut
2015	FII VALREIII	VGIR11.SA	Valora RE III Fundo de Investimento Imobiliario
2016	ELETROPAULO	ELPL1.SA	ELPL1.SA (ELETROPAULO)
2017	FII KINEA HY	KNHY11.SA	KINEAHYCRE2Q/Ut
2018	FII BC FFII	BCFF12.SA	BCFF12.SA (FII BC FFII)
2019	BANCO INTER PRF	BIDI10.SA	BIDI10.SA (BANCO INTER PRF)
2020	MOVIDA	MOVI9.SA	-
2021	FII BTG CRI	BTCR11.SA	FUNDOINVE4B4/Ut
2022	FII MALLS BP	MALL12.SA	atual, histórico e gráfico do papel
2023	FII TG ATIVO	TGAR11.SA	FUNDOINVENM2/Ut
2026	RBR ALPHA RTS	RBRF12.SA	RBRF12.SA (RBR ALPHA RTS)
2027	FII CSHGATSA	ATSA11.SA	FIICSHGAT24F/Ut
2028	FII XP INDL	XPIN11.SA	XP Industrial Fundo de Investimento Imobiliario
2029	FORJA TAURUS	FJTA14.SA	FJTA14.SA (FORJA TAURUS)
2030	FORJA TAURUS	FJTA16.SA	FJTA16.SA (FORJA TAURUS)
2031	FORJA TAURUS	FJTA18.SA	FJTA18.SA (FORJA TAURUS)
2032	FII ABSOLUTO	BPFF12.SA	Bovespa
2033	FII HEDMOCA	HMOC11.SA	Fundo de Investimento Imobiliario GWI Renda Imobiliaria 
2034	FII UBS	UBSR13.SA	UBSR13.SA (FII UBS)
2035	LUPATECH	LUPA12.SA	LUPA12.SA (LUPATECH)
2036	FII VBI LOG	LVBI11.SA	FII VBI LOG/Ut
2038	FORJA TAURUS BNS	FJTA13.SA	FORJA TAURUS PN 
2039	FORJA TAURUS BNS	FJTA15.SA	FJTA15.SA (FORJA TAURUS BNS)
2040	FORJA TAURUS BNS	FJTA17.SA	FORJA TAURUS PN 
2041	FUNDOS IMOBIL	RBRR12.SA	atual, histórico e gráfico do papel
2042	FII VOT SHOP	VSHO11.SA	FII VOTO/Ut
2043	ENERGISA	ENGI2.SA	ENGI2.SA (ENERGISA)
2044	FII MAC	DMAC11.SA	MAC FII/Ut
2045	ENERGISA	ENGI14.SA	ENGI14.SA (ENERGISA)
2046	PLASCAR PARTICIP	PLAS1.SA	PLASCAR PARTICIPACOES INDUSTRIAIS S.A. 
2048	FII SC 401	FISC11.SA	FDO INV IMOB SC 401 
2049	LOG COM PROP	LOGG3.SA	LOG Commercial Properties Empresa 
2050	FII STARX	STRX11.SA	STRX11.SA (FII STARX)
2051	ALPER	APER3.SA	Alper Consultoria em Seguros Empresa 
2053	LOG COM PROP	LOGG1.SA	LOG COMMERCIAL PROPERTIES 
2054	OI	OIBR9.SA	OIBR9.SA (OI)
2055	DOMMO	DMMO11.SA	DOMMO ENERGIA S.A. 
2056	VAL RE III RTS	VGIR12.SA	VGIR12.SA (VAL RE III RTS)
2057	FUNDOS IMOBILIAR	TORM13.SA	FDO INV IMOB TOURMALET I 
2058	F INV TOURMLT CI	TOUR11.SA	FDO INV IMOB TOURMALET II 
2059	F INV TOURMLT CI	TOUR12.SA	TOURMALET II/Ut
2060	F INV TOURMLT CI	TOUR13.SA	FDO INV IMOB TOURMALET II 
2063	SINQIA ON	SQIA3.SA	Sinqia Empresa 
2064	KINEA ETF	KFOF11.SA	KINEAFIIDYY/Ut
2067	VINCI LOG ETF	VILG11.SA	VINCILOGFPB9/Ut
2069	FII PATRIA ETF	PATC11.SA	PATRIAEDCI1W/Ut
2070	FII ALIANZA RTS	ALZR12.SA	ALZR12.SA (FII ALIANZA RTS)
2071	FIP BKO I	BKOI11.SA	FIP BKO I
2072	GRUPO SBF ON	CNTO3.SA	Grupo SBF SA Empresa 
2074	ENAUTA PART	ENAT3.SA	Enauta Participacoes SA Empresa 
2075	RBR PRIVCRED ETF	FRBR11.SA	TODAS NOTÍCIAS VÍDEOS IMAGENS
2076	XP HOTEIS ETF	XPHT11.SA	VREHOTEISPNU/Ut
2077	XP HOTEIS ETF	XPHT12.SA	VREHOTEISPNU/Ut
2078	FII XP LOG	XPLG12.SA	XPLG12.SA (FII XP LOG)
2079	ADOBE INC	ADBE34.SA	Adobe Inc. Companhia 
2080	AUTOMATIC DT	ADPR34.SA	Automatic Data Processing 
2081	APTIV PLC	APTV34.SA	Aptiv PLC Empresa 
2082	ACTIVISION	ATVI34.SA	Activision Blizzard Empresa 
2083	BROADCOM INC	AVGO34.SA	Broadcom Empresa 
2084	ARMSTRONG	AWII34.SA	Armstrong World Industries Corporação 
2085	AUTOZONE INC	AZOI34.SA	AutoZone Empresa 
2086	BOOKING	BKNG34.SA	The Priceline Group Empresa 
2087	CAPITAL ONE	CAON34.SA	Capital One Financial Corp. Banco 
2088	CAPRI HOLDI	CAPH34.SA	Michael Kors Corporation Empresa 
2089	CHARTER COMM	CHCM34.SA	Charter Communications Empresa 
2090	CHURCH DWIGH	CHDC34.SA	Church 	CHDC34.SA Dwight Empresa 
2091	CME GROUP	CHME34.SA	CME Group Empresa 
2092	CINCINNATI	CINF34.SA	Cincinnati Financial Empresa 
2093	CLOROX CO	CLXC34.SA	Clorox Empresa 
2094	CANAD NATION	CNIC34.SA	Canadian National Railway Companhia 
2095	CANAD PACIFI	CPRL34.SA	Canadian Pacific Railway Companhia 
2096	CREDIT ACCEP	CRDA34.SA	Credit Acceptance Empresa 
2097	CARTERS INC	CRIN34.SA	Carter's, Inc. Empresa 
2098	CSX CORP	CSXC34.SA	CSX Corporation Holding 
2099	DEUTSCHE AK	DBAG34.SA	Deutsche Bank Banco 
2100	DISCOVERY IN	DCVY34.SA	Discovery Inc. Empresa 
2101	DEERE CO	DEEC34.SA	Deere 	DEEC34.SA Company Corporação 
2102	DOLLAR GENER	DGCO34.SA	Dollar General Empresa 
2103	DOLLAR TREE	DLTR34.SA	Dollar Tree 
2104	DAVITA INC	DVAI34.SA	DaVita Empresa 
2105	ELECTR ARTS	EAIN34.SA	Electronic Arts Empresa 
2106	ESTEE LAUDER	ELCI34.SA	Estée Lauder Companies Empresa 
2107	EQUINIX INC	EQIX34.SA	Equinix Empresa 
2108	EXPEDIA GROU	EXGR34.SA	Expedia Empresa 
2109	FASTENAL	FASL34.SA	Fastenal Empresa 
2110	FIFTH THIRD	FFTD34.SA	Fifth Third Bank Banco 
2111	FLEETCOR TEC	FLTC34.SA	FLEETCOR Empresa 
2112	GEOPARK LTD	GPRK34.SA	Geopark Empresa 
2113	INTUIT INC	INTU34.SA	Intuit Empresa 
2114	INVEST BCORP	ISBC34.SA	Investors Bank 
2115	KINDER MORGA	KMIC34.SA	Kinder Morgan, Inc. Empresa 
2116	KEMPER CORP	KMPR34.SA	Kemper Empresa 
2117	LIBERTY BROA	LBRD34.SA	Liberty Broadband Empresa 
2118	LOWES COMPA	LOWC34.SA	Lowe’s Empresa 
2119	LIBERTY MEDI	LSXM34.SA	Liberty Films Empresa 
2120	MOODYS CORP	MCOR34.SA	Moody's Empresa
2121	MERCADOLIBRE	MELI34.SA	MercadoLivre Empresa 
2122	MARKEL CORP	MKLC34.SA	Markel Corporation Holding 
2123	ALTRIA GROUP	MOOO34.SA	Altria Empresa 
2124	MICRON TECHN	MUTC34.SA	Micron Technology Empresa 
2125	NEXTERA ENER	NEXT34.SA	NextEra Energy Empresa 
2126	NORTHROP GRU	NOCG34.SA	Northrop Grumman Empresa 
2127	NVIDIA CORP	NVDC34.SA	Nvidia Empresa 
2128	OREILLY AUT	ORLY34.SA	O'Reilly Auto Parts Empresa 
2129	OCCIDENT PTR	OXYP34.SA	Occidental Petroleum Empresa 
2130	PNCFNANCIAL	PNCS34.SA	PNC Financial Services Empresa 
2131	PAYPAL HOLD	PYPL34.SA	PayPal Empresa 
2132	FII UBSOFFIC	RECT11.SA	FII OFFICE/Ut
2133	REGENERON PH	REGN34.SA	Regeneron Pharmaceuticals Empresa 
2134	SIGNATURE BK	SBNY34.SA	Signature Bank Banco comercial 
2135	SIMON PROP	SIMN34.SA	Simon Property Group Imóvel 
2136	STERLING BNC	SLBC34.SA	Sterling Bancorp Banco 
2137	SP GLOBAL	SPGI34.SA	SPGI34.SAP Global Empresa
2138	SIRIUS XM HD	SRXM34.SA	Sirius XM Holdings Empresa 
2139	CONSTELLATIO	STZB34.SA	Constellation Brands Empresa 
2140	HANOVER INSU	THGI34.SA	The Hanover Insurance Group, Inc. Seguro 
2141	TJX COMPANIE	TJXC34.SA	TJX Companies Empresa 
2142	TAPESTRY INC	TPRY34.SA	Coach Empresa 
2143	TYSON FOODS	TSNF34.SA	Tyson Foods Empresa 
2144	UNITEDHEALTH	UNHH34.SA	UnitedHealth Group Empresa 
2145	VF CORP	VFCO34.SA	VF Corporation Empresa 
2146	VIACOM INC	VIAM34.SA	VIAM34.SA (VIACOM INC)
2147	VALLEY NTION	VLYB34.SA	Valley National Bank Banco 
2148	VERISIGN INC	VRSN34.SA	VeriSign Empresa 
2149	VERTEX PHARM	VRTX34.SA	Vertex Pharmaceuticals Empresa 
2150	WESTERN BCOR	WABC34.SA	Western Alliance Bancorporation Banco 
2151	WATERS CORP	WATC34.SA	Waters Corporation Empresa 
2152	WALGREENS	WGBA34.SA	Walgreens Boots Alliance Holding 
2153	DENTSPLY SIR	XRAY34.SA	Dentsply Sirona Empresa 
2154	YUM BRANDS	YUMR34.SA	Yum! Brands Cadeia de restaurantes de fast food 
2155	FII GENERAL	GSFI11.SA	GENERAL/Ut
2156	J B DUARTE	JBDU11.SA	JBDU11.SA (J B DUARTE)
2157	J B DUARTE	JBDU12.SA	JBDU12.SA (J B DUARTE)
2158	FII RIOB ED	RBED11.SA	FII RIOB ED/Ut
2159	FII RIOB VA	RBVA11.SA	FII RIOB VA/Ut
2160	TERRA SANTA	TESA1.SA	TESA1.SA (TERRA SANTA)
2162	FII RBR PCRI	RBRY11.SA	FIIRBRPRI9WZ/Ut
2163	GOL	GOLL12.SA	GOL PN 
2164	FII GP RCFA	RCFA11.SA	GRUPO RCFA FDO INV IMOB
2165	CAIXA RIO BRAVO	CRFF11.SA	CXRIOBRAVOII/Ut
2167	HEDGE TOP 3 RTS	HFOF13.SA	atual, histórico e gráfico do papel
2168	FII MOGNO	MGFF12.SA	MGFF12.SA (FII MOGNO)
2169	DUPONT N INC	DDNB34.SA	DUPONT DE NEMOURS INC. 
2170	FII CSHGPRIM	HGPO11.SA	FIICSHGJHBPW/Ut
2171	TERRA SANTA	TESA9.SA	TESA9.SA (TERRA SANTA)
2172	FII OURI JPP	OUJP12.SA	OUJP12.SA (FII OURI JPP)
2173	FII BARIGUI	BARI11.SA	FIIBARIGUI I/Ut
2174	FII G TOWERS	GTWR11.SA	FUNDOINVEBES/Ut
2175	TERRA SANTA	TESA12.SA	TERRA SANTA ON 
2177	BOVB ETF	BOVB11.SA	ETF BRADESCO/Ut ETF Bradesco Ibovespa Fundo de Índice
2178	NEOENERGIA	NEOE3.SA	Neoenergia 
2185	FOX CORP	FOXC34.SA	Fox Corporation Empresa 
2318	FII HECTARE	HCTR11.SA	FIIHECTARECE/Ut
2319	FII OURI FOF	OUFF11.SA	FIIOURINVEST/Ut
2320	FIP XP INFRA	XPIE11.SA	XPINFRAFUND/Ut
2322	FORWARDS OTFC	BIDI11T.SA	BIDI11T.SA (FORWARDS OTFC)
2323	BANCO INTER	BIDI3.SA	Banco Inter 
2324	YDUQS PART	YDUQ3.SA	YDUQS Participacoes SA
2325	BANCO INTER	BIDI12.SA	BIDI12.SA (BANCO INTER)
2326	BANCO INTER	BIDI9.SA	BANCO INTER ON 
2327	GOL LINHAS PRF	GOLL11.SA	GOLL11.SA (GOL LINHAS PRF)
2328	FII HABIT II	HABT11.SA	HABITATIIFII/Ut
2329	ALIANSCE ON	ALSO3.SA	Aliansce Sonae Shopping Centers Empresa
2331	FII VBI LOG	LVBI13.SA	LVBI13.SA (FII VBI LOG)
2332	FII SANT PAP	SADI11.SA	SANTANDERCDI/Ut
2333	HSI MALLS FII	HSML11.SA	HSI MALLS FI IMOBILIARIO
2334	FII JS R EST RTS	JSRE13.SA	atual, histórico e gráfico do papel
2335	BAHEMA	BAHI1.SA	BAHEMA EDUCAÇÃO S.A. 
2336	FII CSHG FOF	HGFF11.SA	CSHG FOF/Ut
2337	FII RIOB FF	RBFF11.SA	Fator IFIX Fundo de Investimento Imobiliário – FII Empresa
2338	FII BRLPROP	BPRP11.SA	FIIBRLPRO3V6/Ut
2339	GOL	GOLL13.SA	GOLL13.SA (GOL)
2340	FII OURICYRE	OUCY12.SA	OUCY12.SA (FII OURICYRE)
2341	FII YAGUARA	YCHY11.SA	YCHY11.SA (FII YAGUARA)
2343	FII XP LOG	XPLG13.SA	XPLG13.SA (FII XP LOG)
2344	AB INBEV	ABUD34.SA	Anheuser Anheuser Busch Inbev Sa Nv BDR (AB INBEV)
2345	ASML HOLD	ASML34.SA	ASML Empresa Asml Holding Nv Bdr
2346	ALIBABAGR	BABA34.SA	Alibaba Group Empresa 
2347	SANTANDER	BCSA34.SA	Grupo Santander Banco 
2348	BHP GROUP	BHPG34.SA	BHP Group Empresa
2349	BAIDU INC	BIDU34.SA	Baidu Empresa 
2350	BILBAOVIZ	BILB34.SA	Banco Bilbao Vizcaya Argentaria 
2351	CANON INC	CAJI34.SA	Canon Empresa 
2352	CRH PLC	CRHP34.SA	CRH plc Empresa 
2353	CTRIPCOM	CRIP34.SA	Ctrip Agência de viagens 
2354	DIAGEO PL	DEOP34.SA	Diageo Empresa 
2356	FRESENIUS	FMSC34.SA	Fresenius Medical Care Empresa 
2357	HONDA MO	HOND34.SA	Honda Fabricante de automóveis 
2358	ING GROEP	INGG34.SA	ING Group Banco 
2359	JD COM	JDCO34.SA	JD.com Empresa 
2360	NETEASE	NETE34.SA	NetEase Empresa 
2361	NOMURA HO	NMRH34.SA	Nomura Holdings Holding 
2362	NOKIA CORP	NOKI34.SA	Nokia Empresa 
2364	KOPHILIPS	PHGN34.SA	Philips Empresa 
2365	PETROCHIN	PTCH34.SA	PetroChina Company Empresa 
2367	RD SHELL	RDSA34.SA	Royal Dutch Shell Empresa 
2368	RIO TINTO	RIOT34.SA	Rio Tinto Empresa
2369	SAP SE	SAPP34.SA	SAP SE Empresa 
2370	SONY CORP	SNEC34.SA	Sony Empresa 
2372	STMICROEL	STMN34.SA	STMicroelectronics Empresa
2373	TAKEDAPH	TAKP34.SA	Farmacêutica Takeda Companhia 
2374	TELEFONIC	TLNC34.SA	Telefónica Empresa 
2375	TOYOTAMO	TMCO34.SA	Toyota Motor Fabricante de automóveis 
2376	TAIWANSMFAC	TSMC34.SA	TSMC Empresa 
2378	TERNIUMSA	TXSA34.SA	Ternium Companhia 
2379	UNILEVER	ULEV34.SA	Unilever N.V. Empresa
2380	FII R INCOME	RBCO12.SA	RBCO12.SA (FII R INCOME)
2381	FII VBI CRI	CVBI11.SA	VBI CREDITO/Ut
2383	FII SDI PROP	SDIP11.SA	SDIP11.SA (FII SDI PROP)
2384	BAHEMA	BAHI9.SA	BAHEMA ON 
2385	FII HREALTY	HRDF11.SA	Hedge Realty Development FII
2387	FII XP MALLS	XPML13.SA	XPML13.SA (FII XP MALLS)
2388	VIVARA NM	VIVA3.SA	Vivara Participacoes SA Empresa
2390	FORWARDS OTFC	VIVA3T.SA	Vivara Participacoes SA Empresa
2391	COGNA ON	COGN3.SA	Cogna Educação Empresa 
2392	FII FOF BREI	IBFF11.SA	FIIFOFINTBRE/Ut
2393	FII R INCOME	RBCO11.SA	RBCAPITALOFF/Ut
2394	ALPER DIR	APER1.SA	ALPER CONSULTORIA E CORRETORA DE SEGUROS S.A. 
2395	C A MODAS ON	CEAB3.SA	CEAB3.SAA Modas Empresa
2396	BANCO BMG	BMGB11.SA	BANCO BMG S.A. 
2397	FII HSI MALL	HSML12.SA	HSML12.SA (FII HSI MALL)
2398	FII RBRESID	RSPD11.SA	RSPD11.SA (FII RBRESID)
2399	FII TG ATIVO	TGAR12.SA	TGAR12.SA (FII TG ATIVO)
2400	FII UBSOFFIC DIR	RECT12.SA	RECT12.SA (FII UBSOFFIC DIR)
2401	FII BTG SHOP	BPML11.SA	FII BTG PACTUAL SHOPPINGS CF
2402	FIP VINCI IE	VIGT11.SA	VINCI ENERGIA FDO INV PART IE ECL
2403	FII RIOB RC	RCRB11.SA	FDO INV IMOB RIO BRAVO RENDA CORPORATIVA
2404	FII ATRIO	ARRI11.SA	FIIATRRRIMOB/Ut
2405	SARAIVA LIVR	SLED1.SA	SARAIVA LIVR ON 
2406	SARAIVA LIVR	SLED12.SA	SARAIVA LIVR 
2407	SARAIVA LIVR	SLED2.SA	SARAIVA LIVR PN 
2408	FII PLURAL R	PLCR11.SA	PLURRIMOBFII/Ut
2409	FII QUASAR A	QAGR11.SA	QUASARAGFII/Ut
2410	TAURUS	TASA13.SA	TASA13.SA (TAURUS)
2411	TAURUS	TASA15.SA	TASA15.SA (TAURUS)
2412	TAURUS	TASA17.SA	TASA17.SA (TAURUS)
2413	TAURUS	TASA3.SA	Taurus Armas Companhia 
2414	TAURUS	TASA4.SA	Taurus Armas Companhia 
2415	ALPER	APER9.SA	APER9.SA (ALPER)
2416	FII JPPMOGNO	JPPA11.SA	JPP ALLOCATION MOGNO 
2417	FII RBR PROP	RBRP12.SA	FII RBR PROPCI
2418	VINCI OFFICES	VINO11.SA	FUNDOINVEKPI/Ut
2419	BANCO BMG PN	BMGB4.SA	Banco BMG 
2420	FII BTLG	BTLG11.SA	BTG PACTUAL LOGÍSTICA FUNDO DE INVESTIMENTO IMOBILIÁRIO Empresa
2421	FII BRESCO	BRCO11.SA	BRESCO FII/Ut
2422	CELGPAR RTS	GPAR1.SA	GPAR1.SA (CELGPAR RTS)
2423	FII UBS	UBSR16.SA	UBSR16.SA (FII UBS)
2424	FII VINCI SC	VISC13.SA	VISC13.SA (FII VINCI SC)
2425	FII XP PROP	XPPR11.SA	XP PROP/Ut
2426	LOJAS AMERIC	LAME1.SA	Lojas Americanas Empresa 
2427	LOJAS AMERIC	LAME2.SA	LAME2.SA (LOJAS AMERIC)
2428	FII MAUA	MCCI11.SA	FDO INV. MAUA CAPITAL RECEBIVEIS IMOB. 
2429	ANALOG DEVIC	A1DI34.SA	Analog Devices Empresa 
2430	ARCHER DANIE	A1DM34.SA	Archer Daniels Midland Empresa 
2431	AMERICAN ELE	A1EP34.SA	American Electric Power Empresa 
2433	ALEXION PHAR	A1LX34.SA	Alexion Pharmaceuticals Empresa 
2434	ADVANCED MIC	A1MD34.SA	Advanced Micro Devices Empresa 
2435	APPLIED MATE	A1MT34.SA	Applied Materials Empresa
2437	APACHE CORP	A1PA34.SA	Apache Corporation Empresa 
2438	BBT CORP	B1BT34.SA	B1BT34.SAT Banco BBT CORP/UnSBDR QI
2440	BOSTON SCIEN	B1SX34.SA	Boston Scientific Empresa 
2444	CARNIVAL COR	C1CL34.SA	Carnival Empresa 
2448	CENTERPOINT	C1NP34.SA	CenterPoint Energy Empresa 
2450	CENTURYLINK	C1TL34.SA	CenturyLink Empresa 
2451	CITRIX SYSTE	C1TX34.SA	Citrix Systems Empresa
2452	CONCHO RESOU	C1XO34.SA	Concho Resources Empresa 
2456	DOMINION ENE	D1OM34.SA	Dominion Energy Empresa 
2460	EOG RESOURCE	E1OG34.SA	EOG Resources Empresa 
2462	EXELON CORP	E1XC34.SA	Exelon Empresa 
2463	FIRSTENERGY	F1EC34.SA	FirstEnergy Empresa 
2464	FISERV INC	F1IS34.SA	Fiserv Empresa 
2465	FIDELITY NAT	F1NI34.SA	Fidelity National Information Services Empresa 
2468	HCA HEALTHCA	H1CA34.SA	Hospital Corporation of America Empresa 
2474	INVESCO LTD	I1VZ34.SA	Invesco Ltd. Empresa 
2475	JOHNSON CONT	J1CI34.SA	Johnson Controls Empresa 
2479	KOHLS CORP	K1SS34.SA	Kohls Corp Brazilian Depositary Receipt
2480	LIBERTY GLOB	L1BT34.SA	Liberty Global Empresa 
2484	MGM RESORTS	M1GM34.SA	MGM Mirage Empresa 
2486	MARATHON OIL	M1RO34.SA	Marathon Oil Empresa 
2487	NOBLE ENERGY	N1BL34.SA	Noble Energy Empresa 
2492	NETAPP INC	N1TA34.SA	NetApp Empresa 
2494	NXP SEMICOND	N1XP34.SA	NXP Semiconductors Empresa 
2497	PHILLIPS 66	P1SX34.SA	Phillips 66 Empresa 
2501	SEAGATE TECH	S1TX34.SA	Seagate Technology Companhia 
2502	SYNCHRONY FI	S1YF34.SA	Synchrony Financial Empresa 
2504	SYSCO CORP	S1YY34.SA	Sysco Corporation Empresa 
2505	T-MOBILE US	T1MU34.SA	T-Mobile Us Inc Brazilian Depositary Receipt
2506	THE SOUTHERN	T1SO34.SA	Southern Company Holding 
2507	UNITED AIRLI	U1AL34.SA	United Continental Holdings Companhia aérea 
2508	UBER TECH IN	U1BE34.SA	Uber Empresa 
2509	WESTERN DIG	W1DC34.SA	Western Digital Empresa 
2511	WASTE MANAG	W1MC34.SA	Waste Management, Inc Empresa 
2513	XCEL ENERGY	X1EL34.SA	Xcel Energy Empresa 
2517	FII XP CRED	XPCI11.SA	XPCREIMOFII/Ut
2518	EQTL PARA ON	EQPA3.SA	Equatorial Energia Pará Empresa 
2519	EQTL PARA PNA	EQPA5.SA	Equatorial Energia Pará Empresa 
2520	EQTL PARA PNB	EQPA6.SA	EQUATORIAL PARA DISTRIBUIDORA DE ENERGIA S.A. 
2521	EQTL PARA PNC	EQPA7.SA	Equatorial Energia Pará Empresa 
2522	GRUPO NATURA ON	NTCO3.SA	Natura Empresa 
2523	BIOMM	BIOM11.SA	BIOMM S.A. 
2524	FII HEDGELOG	HLOG11.SA	HEDGE LOGÍSTICA FDO. INV. IMOB Empresa
2525	HPDP11	HPDP11.SA	HEDGEREALE/Ut
2526	FII LGCP INT	LGCP11.SA	IMOBIFDOIMOB/Ut
2527	FII INTER	BICR11.SA	FII INTER TITULOS CF
2528	FII NEWPORT	NEWL11.SA	NEWPORT LOGISTICA FII CF
2529	FII RBCRI IV CF	RBIV11.SA	RIO BRAVO CREDITO IMOB IV FII
2530	FII LUGGO CI	LUGG11.SA	LUGGOFII/Ut
2531	CAPITANIA	CPFF11.SA	VXXXFDOINVIM/Ut
2532	FII V2 PROP ETF	VVPR11.SA	Fundo de Investimento Imobiliário 
2533	XP CRD IMOB REIT	XPCI12.SA	XPCI12.SA (XP CRD IMOB REIT)
2535	LIQ DIR	LIQO1.SA	ATMA PARTICIPAÇÕES S.A. 
2536	FII SANT REN	SARE11.SA	SANTANDER RENDA DE ALUGUÉIS FUNDO DE INVESTIMENTO IMOBILIÁRIO
2537	SARAIVA LIVR	SLED11.SA	SLED11.SA (SARAIVA LIVR)
2540	FIP PERFIN	PFIN11.SA	PERFIN APOLL/Ut
2542	FII TRX REAL	TRXF11.SA	TRXRENDAFOAC/Ut
2543	FII SUPERNOV	SNCR11.SA	SNCR11.SA (FII SUPERNOV)
2544	ADVANCE AUTO	A1AP34.SA	Advance Auto Parts Empresa 
2545	ABIOMED INC	A1BM34.SA	Abiomed Empresa 
2553	AKAMAI TECHN	A1KA34.SA	Akamai Technologies Empresa 
2554	ALBEMARLE CO	A1LB34.SA	ALBEMARLE CORP 
2563	ANTHEM INC	A1NT34.SA	Anthem Empresa 
2565	AIR PRODUCTS	A1PD34.SA	Air Products Corporação 
2571	AUTODESK INC	A1UT34.SA	Autodesk Empresa 
2579	BIOMARIN PHA	B1MR34.SA	BioMarin Pharmaceutical Empresa 
2583	CBOE GLOBAL	C1BO34.SA	C1BO34.SA (CBOE GLOBAL)
2587	CERNER CORP	C1ER34.SA	C1ER34.SA (CERNER CORP)
2589	CH ROBINSON	C1HR34.SA	C. H. Robinson Worldwide Empresa 
2590	CIGNA CORP	C1IC34.SA	Cigna Empresa 
2605	DTE ENERGY C	D1TE34.SA	D1TE34.SA (DTE ENERGY C)
2607	ECOLAB INC	E1CL34.SA	Ecolab Empresa 
2613	EVERSOURCE E	E1SE34.SA	E1SE34.SA (EVERSOURCE E)
2618	EVERGY INC	E1VR34.SA	E1VR34.SA (EVERGY INC)
2621	EXTRA SPACE	E1XR34.SA	E1XR34.SA (EXTRA SPACE)
2622	DIAMONDBACK	F1AN34.SA	Diamondback Energy Empresa 
2626	FLOWSERVE CO	F1LS34.SA	F1LS34 FLOWSERVE CODRN 
2632	FORTIVE CORP	F1TV34.SA	Fortive Corp 
2638	GARMIN LTD	G1RM34.SA	GARMIN LTD
2639	WW GRAINGER	G1WW34.SA	W.W. Grainger Empresa 
2651	INTERCONTINE	I1CE34.SA	IntercontinentalExchange Empresa 
2656	IHS MARKIT L	I1NF34.SA	Markit Group Ltd Empresa 
2657	IPG PHOTONIC	I1PG34.SA	I1PG34.SA (IPG PHOTONIC)
2672	KLA CORP	K1LA34.SA	K1LA34.SA (KLA CORP)
2678	LINDE PLC	L1IN34.SA	LINDE PLC
2680	LINCOLN NATI	L1NC34.SA	L1NC34.SA (LINCOLN NATI)
2682	LAM RESEARCH	L1RC34.SA	Lam Research Empresa 
2687	MOLSON COORS	M1CB34.SA	Molson Coors Brewing Company Empresa 
2690	MCCORMICK	M1KC34.SA	M1KC34.SA (MCCORMICK)
2702	NATIONAL OIL	N1OV34.SA	N1OV34.SA (NATIONAL OIL)
2711	PAYCHEX INC	P1AY34.SA	P1AY34.SA (PAYCHEX INC)
2713	PRUDENTIAL F	P1DT34.SA	Prudential Financial Empresa 
2719	PIONEER NATU	P1IO34.SA	P1IO34.SA (PIONEER NATU)
2722	PROLOGIS INC	P1LD34.SA	ProLogis Empresa 
2741	REPUBLIC SER	R1SG34.SA	Republic Services Empresa 
2751	SPOTIFY TECH	S1PO34.SA	Spotify Empresa 
2757	TECHNIPFMC P	T1EC34.SA	TechnipFMC Empresa 
2761	TRIPADVISOR	T1RI34.SA	T1RI34.SA (TRIPADVISOR)
2763	TRACTOR SUPP	T1SC34.SA	TRACTOR SUPPLY CO 
2788	FII VECTIS	VCJR11.SA	VECTIS JUROS/Ut
2789	FII XP INDL	XPIN12.SA	XP INDUSTRIAL FDO INV IMOB 
2790	IT NOW SMALL	SMAC11.SA	ITNOWSMACAP/Ut
2791	LOJAS AMERIC	LAME10.SA	LOJAS AMERIC PN 
2792	LOJAS AMERIC	LAME9.SA	LOJAS AMERIC ON 
2793	FII RIOB FF	RBFF12.SA	RIO BRAVO FUNDO DE FUNDOS DE INVESTIMENTO IMOB 
2794	MITRE REALTY	MTRE3.SA	MITRE REALTY EMPREENDIMENTOS E PARTICIPAÇÕES S.A. Empresa 
2795	LOCAWEB ON	LWSA3.SA	Locaweb Empresa 
2796	ADVANCED-DH	ADHM1.SA	ADVANCED
2797	FII VBI REIT	RVBI11.SA	VBRREITSFOFS/Ut
2798	MOURA DUBEUX ON	MDNE3.SA	Moura Dubeux Engenharia SA Empresa 
2799	FII XP SELEC	XPSF11.SA	XPSELECTION/Ut
2800	FIP BRZ IE	BRZP11.SA	BRZINFRA/Ut

