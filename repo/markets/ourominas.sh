#!/bin/bash
# v0.3.12  jun/2020  by mountaineer_br
# Free Software under the GNU Public License 3
# Ourominas não trabalha com Prata!

#make sure locale is set correctly
export LC_NUMERIC=C

AJUDA="Ourominas.sh -- Puxa as cotações das moedas de Ouro Minas


SINOPSE
	O script puxa as cotações de <https://www.ourominas.com/om/page.html>.
	O portal observa que os valores são exclusivos para compras no site e
	que as cotações não tem IOF incluso.

	Para estimar o valor dia grama de ouro, deve-se multiplicar a cotação
	do dólar americano da Ouro Minas pela cotação em dólar do ouro inter-
	nacional. Para puxar a cotação do ouro em dólares/onça troy, utiliza-
	se cotação do UOL.

	Os pacotes Bash, Curl e iconv (Glibc) são necessários."

# Ajuda
if [[ "${1}" = '-h' ]]; then
	printf "%s\n" "${AJUDA}"
	exit
fi

## Taxas da Ouro Minas
DATA="$(curl --compressed -s "https://www.cambiorapido.com.br/tabelinha_wl.asp?filial=MESAVAREJO%20243" | sed -E 's/<[^>]*>//g' | iconv -c -f utf-8 | tr -d ' ' | grep -iv "pr-pago" | sed -e 's/^[ \t]*//')"

USD=($(grep -i -A2 "laramericano" <<< "${DATA}" | sed 's/.$/=/g'))
EUR=($(grep -i -A2 "euro" <<< "${DATA}" | sed 's/.$/=/g'))
GBP=($(grep -i -A2 "libra" <<< "${DATA}" | sed 's/.$/=/g'))
AUD=($(grep -i -A2 "laraustraliano" <<< "${DATA}" | sed 's/.$/=/g'))
CAD=($(grep -i -A2 "larcanadense" <<< "${DATA}" | sed 's/.$/=/g'))
NZD=($(grep -i -A2 "larneozelandes" <<< "${DATA}" | sed 's/.$/=/g'))
CHF=($(grep -i -A2 "francosui" <<< "${DATA}" | sed 's/.$/=/g'))
JPY=($(grep -i -A2 "iene" <<< "${DATA}" | sed 's/.$/=/g'))
CNY=($(grep -i -A2 "yuan" <<< "${DATA}" | sed 's/.$/=/g'))
ARS=($(grep -i -A2 "pesoargentino" <<< "${DATA}" | sed 's/.$/=/g'))
CLP=($(grep -i -A2 "pesochileno" <<< "${DATA}" | sed 's/.$/=/g'))
MXN=($(grep -i -A2 "pesomexicano" <<< "${DATA}" | sed 's/.$/=/g'))
UYU=($(grep -i -A2 "pesouruguaio" <<< "${DATA}" | sed 's/.$/=/g'))
COP=($(grep -i -A2 "pesocolombiano" <<< "${DATA}" | sed 's/.$/=/g'))
ZAR=($(grep -i -A2 "rande" <<< "${DATA}" | sed 's/.$/=/g'))
RUB=($(grep -i -A2 "ruble" <<< "${DATA}" | sed 's/.$/=/g'))
ILS=($(grep -i -A2 "shekel" <<< "${DATA}" | sed 's/.$/=/g'))

# Fazer tabela
printf "OUROMINAS Cotações\n"
printf "%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n" \
	"${USD[*]}" "${EUR[*]}" "${GBP[*]}" "${AUD[*]}" "${CAD[*]}" "${NZD[*]}" \
	"${CHF[*]}" "${JPY[*]}" "${CNY[*]}" "${ARS[*]}" "${CLP[*]}" "${MXN[*]}" \
	"${UYU[*]}" "${COP[*]}" "${ZAR[*]}" "${RUB[*]}" "${ILS[*]}" |
	sed -e 's/Dlar/Dólar/g' -e 's/Suio/Suiço/g' -e 's/Chins/Chinês/g' |
	column -t -s"=" -N'Moeda,Venda,Compra' -R'Moeda'

# Estimagem do preço por cotação do UOL
USDP="${USD[@]:1:1}"
USDP="${USDP%\=}"
UOLXAU="$(curl --compressed -s "https://economia.uol.com.br/cotacoes/" | sed -e 's/<[^>]*>//g' -e 's/\s\s*/ /g' | grep -m1 -Eo --color=never 'Ouro.{25}' | grep -Eo '[^- ][0-9][0-9][0-9]+,[0-9]+')"

{ printf "XAU(troyoz)/USD UOL  %s\n" "$(bc -l <<< "scale=4;${UOLXAU/,/.}/1")"
printf "Venda estimada(R$/g)  %s\n" "$(bc -l <<< "scale=4; ${UOLXAU/,/.}*${USDP/,/.}/31.1034768")"; } | tr '.' ','

exit

