#!/bin/bash
# imagens de radar do ipmet
#Instituto de Pesquisas Meteorológicas (UNESP)

#image viewer
IMGVIEWER=( feh )

#temp dir
TEMPDIR=/tmp/ipmet_radar

#tempo entre conexões
SLEEP=6m

#url parameters
BASEURL=https://www.ipmetradar.com.br/ipmet_html/radar
REFERER=Referer:https://www.ipmetradar.com.br/2imagemRadar.php

HELP="ipmet.sh -- Puxar Imagens de Radar
O script puxa a última imagem de radar do IPMET e a abre com $IMGVIEWER.
Alternativamente, pode-se puxar imagens repetidamente com a opção -l,
tempo entre conexões $SLEEP.

opção: -h  exibir esta página de ajuda.
opção: -l  puxar imagens a cada $SLEEP.
cache: $TEMPDIR"

#imagem de radar ipmet
#https://www.ipmetradar.com.br/2imagemRadar.php
ipmetf()
{
	local data name info time

	#create dir if it does not exist
	[[ -d "$TEMPDIR" ]] || mkdir -pv "$TEMPDIR" || return

	data="$( curl -L --compressed "$BASEURL/2carga_img.php" )"
	name="$( sed -nE 's/.*(nova.jpg\?[0-9]+).*/\1/p' <<<"$data" )"
	info="$( sed -nE 's/.*(Imagem Composta dos Radares.*)<.*/\1/p' <<<"$data" )"
	time="$( grep -Eo '[0-9]+/[0-9]+/[0-9: ]+$' <<<"$info" )"
	TEMPFILE="${TEMPDIR%/}/ipmet_${time//[^a-zA-Z0-9:]/_}.jpg"

	#if file does not exist already
	#download new image to file
	if [[ ! -e "$TEMPFILE" ]]
	then curl -L --compressed --header "$REFERER" "$BASEURL/$name" -o "$TEMPFILE"
	fi

	echo "$info"
	echo "$TEMPFILE"
}

#trap function
trapf()
{
	trap \  INT TERM
	exit
}

#opções
while getopts hl c
do
    case $c in
        h) echo "$HELP" ;exit ;;
        l) OPTLOOP=1 ;;
        \?) exit 1 ;;
    esac
done
shift $((OPTIND -1))
unset c


#are we calling from the ``ipmetloop'' function?
#record pid, else open image with feh
if ((OPTLOOP))
then
	trap trapf INT TERM
	echo -e "pid:\t$$\t$(date -Isec)" | tee -a "${TEMPDIR%/}/loop_pids.txt"
	while true
	do ipmetf ;sleep $SLEEP
	done
else
	ipmetf
	( "${IMGVIEWER[@]}" "$TEMPFILE" & )
fi

