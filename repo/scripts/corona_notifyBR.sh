#!/bin/zsh
# Shell functions to download data from SUS Flu Syndrome Notification System
#  and calculate positivity rate of covid19 test.
# Funções de shell para download de dados do sistema SUS de Notificação de Síndrome Gripal
#  e calcular a taxa de positividade do testes de covid19.
# dec/2020  by mountaineerbr
#
# You need to Source this shell function library to use them at will


#results directory (will be created)
RESULTDIR="SUSOPENDATA_$( date -I )"
RESULTDIR="${PWD%/$RESULTDIR}/$RESULTDIR"

#data url
URL=https://s3-sa-east-1.amazonaws.com/ckan.saude.gov.br
ESTADOS=( ac al ap am ba ce es go ma mt ms mg pa pb pr pe pi rj rn rs ro rr sc sp se to df )


#ckeck/make results dir
[[ -d "$RESULTDIR" ]] || mkdir "$RESULTDIR" || exit

#exs:
#dados-pb.csv
#dados-rj-1.csv

testf() 
{
	[[ -s "$file" ]] && ! grep -Fq '<?xml' "$1"
}

coronadown()
{
	local estado VOLOK file filename n comp urltgt

	for estado in "${ESTADOS[@]}"
	do
		unset VOLOK file filename n comp urltgt

		while
			((++n))
			comp="-$n"
			filename="dados-${estado}${comp}.csv"
			file="$RESULTDIR/$filename"
			testf "$file" && continue

			urltgt="$URL/$filename"
			print "\n$urltgt\n"
			curl --compressed -Lb non-existing "$urltgt" -o "$file"
			testf "$file"
		do
			VOLOK=1
			:
		done
		unset comp

		if [[ -e "$file" ]] && ! testf "$file"
		then
			rm -v "$file"
		fi

		if ((VOLOK==0))
		then
			filename="dados-${estado}${comp}.csv"
			file="$RESULTDIR/$filename"
			testf "$file" && continue

			urltgt="$URL/$filename"
			print "\n$urltgt\n"
			curl --compressed -Lb non-existing "$urltgt" -o "$file"
			
			if [[ -e "$file" ]] && ! testf "$file"
			then
				rm -v "$file"
				echo "ERR: cannot download data -- $estado " >&2
			fi
		fi

	done
}

#get positivity rate from SUSOPENDATA csv data
coronapos()
{
	setopt nullglob || shopt -s nullglob
	
	local arqs date dates d result

	for estado in "${ESTADOS[@]}"
	do
		arqs=( dados-"$estado"*.csv )

		result="results_$estado".txt
		dates=( $(
			cut -d\; -f2 "${arqs[@]}" |
				grep -Ev '(null|undefined|dataNoti)' |
				cut -c1-10 |
				sort -V -u
		) )
		
		for date in "${dates[@]}"
		do
			grep -a "$date" "${arqs[@]}" |
				awk -F\; '
				BEGIN{pos=0} ($12 ~ /[Pp]ositivo/ && $30 !~ /([Dd]escartado)/)|| $30 ~ /[Cc]onfirm/ {pos++}
				BEGIN{neg=0} ($12 ~ /[Nn]egativ/ && $30 !~ /([Cc]onfirm)/)|| $30 ~ /[Dd]escart/ {neg++}
				END { if ((pos+neg) > 0){
					print "'$date'","POS:",pos,"NEG:",neg,"SUBT:",(pos+neg),"POSITIVITY%:",(pos/(pos+neg))*100
				    } else {
					print "'$date'","POS:",pos,"NEG:",neg,"SUBT:",(pos+neg),"POSITIVITY%:",0
				    }
				 }
				'
		done |
		tee  "$result"

		echo "result at -- $result" >&2
	done

	unsetopt nullglob || shopt -u nullglob
}
#https://opendatasus.saude.gov.br/dataset/casos-nacionais
#https://stackoverflow.com/questions/9595608/how-to-get-rid-of-awk-fatal-division-by-zero-error

#remove n last lines and first n lines, arg $2 and $3
#gplot [FILE] [RM_LINENUM_END] [RM_LINENUM_START]
gplot()
{
	local result="${1%.*}.png"
	sed -nE 's/^([0-9-]*).*POSITIVITY%:\s*(.*)/\2/p' "$1" |
		head -n-${2:-0} | tail +${3:-1} |
		gnuplot -p -e 'set title "'${result//_/ }'"; show title; set key off; set xlabel "Day"; set ylabel "Positivity%"; set terminal png size 800,600; set autoscale; plot "/dev/stdin" using 1 with linespoints linestyle 1' >"$result" \
		&& feh "$result"

	echo "Saved to \"$result\"" >&2
}

#gplot2 [FILE] [RM_LINENUM_END] [RM_LINENUM_START]
gplot2()
{
	local result="${1%.*}_long.png"
	sed -nE 's/^([0-9-]*).*POSITIVITY%:\s*(.*)/\1,\2/p' "$1" |
		head -n-${2:-0} | tail +${3:-1} |
		gnuplot -p -e 'set title "'${result//_/ }'"; show title; set key off; set ylabel "Positivity%"; set terminal png size 3200,800; set autoscale; set xtics rotate by 90 ;set datafile separator ","; plot "/dev/stdin" using 2:xtic(1) with linespoints linestyle 1' >"$result" \
		#&& feh "$result"

	echo "Saved to \"$result\"" >&2
}

#helper to plot small and full charts
#may need removing some of the last points!
plothelper()
{
	local a=$1 b=$2 c=$3
	gplot results_$a.txt $b $c
	gplot2  results_$a.txt $b $c
}

