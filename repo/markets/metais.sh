#!/bin/bash
# Metal prices in BRL/Grams
# v0.2.10  feb/2020  by mountaineer_br
## Este script pega cotações através de outros
## scripts e imprime os resultados em formato de tabelas.
## Porém, cotação do Ouro e USD do Banco Central somente neste script.

## Funções de metais ( em BRL )
cmcouro() { ~/bin/markets/cmc.sh -bg6 xau brl; }
cmcprata() { ~/bin/markets/cmc.sh -bg6  xag brl; }
cgkouro() { ~/bin/markets/cgk.sh -bg6 xau brl; }
cgkprata() { ~/bin/markets/cgk.sh -bg6 xag brl; }
openxouro() { ~/bin/markets/openx.sh -g6 xau brl; }
openxprata() { ~/bin/markets/openx.sh -g6 xag brl; }
clayouro() { ~/bin/markets/clay.sh -g6 xau brl; }
clayprata() { ~/bin/markets/clay.sh -g6 xag brl; }

## USD/BRL Rate & Metais
{

	echo ""
	printf '\e[8;30;43m                        \e[m\n'
	date '+%Y-%m-%dT%H:%M:%S(%Z)'
	
	echo ""
	~/bin/markets/uol.sh -d
	

	echo ""
	echo "       Real BRL"
	echo "ERates:  $(~/bin/markets/erates.sh -s4 usd brl)"
	OPENXBRL=$(~/bin/markets/openx.sh -4 usd brl)
	CLAYBRL=$(~/bin/markets/clay.sh -4 usd brl)
	echo "CLay:    ${CLAYBRL}"
	echo "OpenX:   ${OPENXBRL}"
	CMCBRL=$(~/bin/markets/cmc.sh -4 -b usd brl)
	CGKBRL=$(~/bin/markets/cgk.sh -4 -b usd brl)
	echo "CMC:     ${CMCBRL}"
	echo "CGK:     ${CGKBRL}"
	MYCBRL=$(~/bin/markets/myc.sh -s4 usd brl)
	echo "MyC:     ${MYCBRL}"
	echo "Média:   $(echo "scale=4; (${OPENXBRL}+${CMCBRL}+${CGKBRL}+${MYCBRL})/4" | bc -l)"
	

	echo ""
	## Não irá fazer média com CLay por enquanto
	echo "       Ouro XAU      Prata XAG"
	echo "CLay:  $(clayouro)    $(clayprata)"
	OPENXO="$(openxouro)"
	OPENXP="$(openxprata)"
	echo "OpenX: ${OPENXO}    $OPENXP"
	CMCO="$(cmcouro)"
	CMCP="$(cmcprata)"
	echo "CMC:   ${CMCO}    ${CMCP}"
	CGKO="$(cgkouro)"
	CGKP="$(cgkprata)"
	echo "CGK:   ${CGKO}    ${CGKP}"
	AVGO=$(echo "scale=6; ($CMCO+$CGKO+$OPENXO)/3" | bc -l)
	AVGP=$(echo "scale=6; (($CMCP+$CGKP+$OPENXP)/3)" | bc -l)
	echo "Média: $AVGO    $AVGP"
	

	echo ""
	printf "CGK XAU: %s\n" "$(~/bin/markets/cgk.sh -b2 xau)"


	echo ""
	~/bin/markets/uol.sh -m
	

	echo ""
	echo "Banco central"
	#Get last weekday data
	day_of_week=`date +%w`
	if [ $day_of_week == 1 ] ; then
		look_back=3
	elif [ $day_of_week == 0 ] ; then
		look_back=2
	else
		look_back=1
	fi
	TS="$(date --date "${look_back} day ago" "+%Y%m%d")"
	curl --compressed -sL "http://www4.bcb.gov.br/Download/fechamento/${TS}.csv" | grep -e XAU -e USD -e EUR |
		sed -e 's/\/2020//g' -e 's/00*;/;/g' | column -et -s';' -N'DATA,A,B,COD,COMPRA,VENDA,C,D' -T'DATA,COMPRA,VENDA' -H'A,B,C,D'
	#trimming columns will not work because fd1 is redirected to tee
	

	echo ""
	echo "Parmetal XAU"
	OPAR="$(~/bin/markets/parmetal.sh)"
	grep RBM <<< "${OPAR}" | cut -c-32
	grep Dolar <<< "${OPAR}"
	

	echo ""
	printf "Ourominas XAU\n"
	OMINAS="$(~/bin/markets/ourominas.sh)"
	grep "Venda estimada" <<<"${OMINAS}"
	grep 'rAmericano' <<<"${OMINAS}" | sed -e 's/\s\s*/  /g' -e 's/^\s\s*//g'

} | tee -a ~/.metais_record


