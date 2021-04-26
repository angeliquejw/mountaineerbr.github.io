#!/bin/zsh
# dec/2020  by castaway

#zsh, gnuplot, jq, datamash and curl are required!

#usage: coronaplot.sh [DIR]
#
#if DIR is set, data will be downloaded to and processed in DIR,
#otherwise defaults to $PWD. if DIR does not exist, it will be created.
#csse and reuters data and graphs will be placed in subdirs.
#
#some graphs have multiple versions. number after underscore ('_NUM') in 
#filename represents how many data points were removed from the series beginning.
#
#data sources:
#Johns Hopkins University CSSE <https://github.com/CSSEGISandData/COVID-19>
#Reuters News Agency <https://graphics.reuters.com/CHINA-HEALTH-MAP/0100B59S39E/index.html>

rootdir="${1:-${PWD}}"
dir="$rootdir/csse"
dirb="$rootdir/reuters"

dir1="$dir/confirmed"
dir4="$dirb/cases"

dir2="$dir/newCasesPercentage"
dir5="$dirb/newCasesPercentage"

dir3="$dir/deaths"
dir6="$dirb/deaths"

dir7="$dir/recovered"
dir8="$dirb/recovered"

export LC_NUMERIC=C

plotcmd() {
	gnuplot -p -e 'set title "'$tt'"; show title; set key off; set xlabel "day"; set ylabel "'$ylabel'"'  -e "set terminal png size 800,600; set output '$( sed -En "s/ /_/g; s/[,']//g; s/_+/_/g; s/_$//; 1p" "$arq" )$2.$ylabel.png'" -e 'plot "'<( tail -n $1 "$arq" )'" with linespoints linestyle 1' 2>/dev/null &
	}

plotf() {
	while read arq; do
		{
		[[ "$(wc -l <"$arq")" -lt 2 ]] && rm "$arq" && exit
		loc="${loc:-$name}"
		loc="${loc:-$( sed -n "1p; s/ /_/g; s/[\"',()]//g"  "$arq" )}"
		printf '\r\033[2Kplotting__: %s %s %s' "${ylabel:0:10}" "${arq##*/}" "${loc:0:10}"

		#graph title
		tt="$(sed -n 's/ //g; 1p' "$arq")"

		#process
		plotcmd +2  #remove first line -- title

		#remove some points in specific cases
		if [[ "$ylabel" = newCasesPercentage ]]  #&& [[ "$arq" =~ (World|US|China|Taiwan|Hubei|Wuhan|Japan|Korea|India|Mongolia) ]]
		then
			plotcmd +31 _030
			plotcmd +100 _099
			plotcmd +141 _140
		fi
		} &
	done
	#wait
}

#rate func
#must not run in bg, other steps need this finished
#use zsh maths
ratef() {
	last=1
	typeset -F 6 last rate total
	tail -n +2 |  #get rid of first line
	while read total; do
		(( last )) || last=1
		(( rate = ( ( total / last ) * 100) - 100))
		[[ "$rate" = -* ]] && rate=0
		printf '%.4f\n' "${rate}"
		last="$total"
	done
}

#graphs with data from reuters
reutersf() {
	printf '\r\033[2KReuters data\n'
	dataf="$dirb/reutersData${stamp}.json"

	curl -sL 'https://graphics.thomsonreuters.com/data/2020/coronavirus/tracking/global/data.json' > "$dataf"

	#get the right timestamp from data file and rename it
	stamptrue="$( jq -r '.lastUpdated' "$dataf" )"
	dataf2="${dataf/$stamp/$stamptrue}"

	mv "$dataf" "$dataf2"
	
	dataf="$dataf2"

	for i in cases cases deaths recovered; do
		counter=

		[[ -z "$pass" ]] && ylabel="newCasesPercentage" && pass=1 || ylabel="$i"
		#mkdir -p "$dirb/$ylabel"
		cd "$dirb/$ylabel" || exit 1

		while read loc; do
			((++counter))

			{
			filename="$dirb/$ylabel/xx${counter}x$loc"
			filename="${filename// }"

			printf '\r\033[2Kprocessing: %s %s %s' "${ylabel:0:10}" "${filename:0:10}" "${loc:0:10}"

			if [[ "$ylabel" = newCasesPercentage ]]; then
				printf '%s\n' "$loc" > "$filename"
				jq -r '.countries."'$loc'"."'$i'"[]' "$dataf" | ratef >> "$filename"
			else
				jq -r '"'$loc'",.countries."'$loc'"."'$i'"[]' "$dataf" > "$filename"

			fi

			plotf <<< "$filename"
			} &
		done <<<"$( jq -r '.countries|keys[]' "$dataf" )"


		#world
		for f in xx* ; do
			tail -n +2 "$f" | tac > "yy${f#xx}.tac"
		done


		if [[ "$ylabel" != newCasesPercentage ]]; then
			#create file
			wfile="$dirb/$ylabel/world.sum"
			echo World > "$wfile"

			paste -d+ yy* | sed 's/++*/+/g ;  s/^+// ; s/+$//' |
				tac | tail -n +2 |
				while read line; do
					printf '%d\n' "$(( line ))" >> "$wfile"
				done

			#plot
			plotf <<< "$wfile"
		fi

		{
		#plot world of newcasespercentage
		if [[ "$ylabel" = cases ]]; then
			ylabel=newCasesPercentage
			wsfile="$dirb/$ylabel/world.sum.percentage"
			echo World > "$wsfile"

			ratef < "$wfile" >> "$wsfile"

			cd "$dirb/$ylabel"
			plotf <<< "$wsfile"
		fi
		} &

	done

	#clean up environment
	unset ylabel pass listf arq loc i counter filename name f wfile wsfile
}

#historical data from
#https://github.com/CSSEGISandData/COVID-19/tree/master/csse_covid_19_data/csse_covid_19_time_series
cssef() {
	printf '\r\033[2KCSSE data\n'

	for i in confirmed confirmed deaths recovered; do

		[[ -z "$pass" ]] && ylabel="newCasesPercentage" && pass=1 || ylabel="$i"

		dataforig="$dir/${ylabel}.${stamp}.orig.csv"
		dataf="$dir/${ylabel}/${ylabel}.${stamp}.csv"
		dataw="$dir/${ylabel}/worldData.cvs"
		listf="$dir/processedData.txt"

		#get data
		curl -s --compressed "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_${i}_global.csv" > "${dataforig}"

		#remove timestamos (relative analysis)
		sed -e 1d -e 's/["\r]//g' "${dataforig}" > "$dataf"

		sed 's/,/ /' "$dataf" | cut -d, -f1,4- | sed  -e 's/,/\n/g' -Ee 's/^\s//' -e 's/^[^0-9]*/\n&/' > "$listf"

		cd "$dir/$ylabel" || exit 1

		if [[ "$ylabel" = newCasesPercentage ]]; then
			csplit --suppress-matched  --prefix="$dir/$ylabel"/yy "$listf" '/^$/' '{*}' 1>/dev/null

			for arq in $(printf '%s\n' yy* | sort -n -k3 -ty); do
				{
				title="$(head -1 "$arq")"
				printf '\r\033[2Kprocessing: %s %s %s' "${ylabel:0:10}" "${arq:0:10}" "${title:0:10}"

				[[ "$(wc -l <"$arq")" -lt 2 ]] && {
					rm "$arq"
					#echo "coronaplot.sh: warning -- removed $arq"
					exit 1
					}
				#name="$(head -1 "$arq" | tr ' ' '_' | tr -d "\"',)(")"
				name="$( sed -ne "s/ /_/g; s/[',()\"]//g; 1p"  "$arq" )"
				echo "$name" > "xx$name"

				tail -n +2 "$arq" | ratef >> "xx$name"
				} &
			done
			#wait

			#sum world data
			tail -n+2 "$dataf" | cut -d, -f5- > "$dataw"
			cols="$(( $(awk -F, '{print NF; exit}' "$dataw") - 1 ))"
			echo 'World' >> "xxWorld"
			datamash -t, sum 1-"$cols" <"$dataw" | tr ',' '\n' | ratef >> "xxWorld"

		else
			csplit --suppress-matched  --prefix="$dir/$ylabel"/xx "$listf" '/^$/' '{*}' 1>/dev/null

			#sum world data
			tail -n+2 "$dataf" | cut -d, -f5- > "$dataw"
			cols="$(( $(awk -F, '{print NF; exit}' "$dataw") - 1 ))"
			echo 'World' >> "xxWorld"
			datamash -t, sum 1-"$cols" < "$dataw" | tr ',' '\n' >> "xxWorld"

		fi

		cd "$dir/$ylabel" || exit 1;
		printf '%s\n' "$dir/$ylabel"/xx* |
			sort -n -k3 -tx | plotf

		mv "$listf" "$listf.$ylabel"
	done
	#clean up environment
	unset ylabel pass listf arq loc name
}


#trap INT
trapf() {
	#disable trap
	trap \   INT HUP TERM

	#kill sub-processes
	pkill -P $$

	echo 'coronaplot.sh: err -- user interrupt  '

	exit 1
}

#set a good trap
trap trapf INT HUP TERM

#test for required packages
for pkg in gnuplot jq datamash curl
do
	command -v "$pkg" &>/dev/null || {
		echo "coronaplot.sh: err -- $pkg is required"
		exit 1
		}
done

#set timestamps
stamp="$( date -u +%Y%m%d )"
stamp2="$( date -u +%Y%m%d.%s )"

#test if plot dirs are present
if [[ -d "$dir" ]]; then
	#echo "coronaplot.sh: err -- $rootdir already exists, refusing to overwrite"
	#exit 1
	echo "coronaplot.sh: backing up ${dir}.."
	mv "$dir" "${dir}${stamp2}"
fi
if [[ -d "$dirb" ]]; then
	echo "coronaplot.sh: backing up ${dirb}.."
	mv "$dirb" "${dirb}${stamp2}"
fi

#start
exec >&2

#make all needed dirs
mkdir -p "$dir1" "$dir2" "$dir3" "$dir4" "$dir5" "$dir6" "$dir7" "$dir8"

#make plots
#obs: gnuplot is set to not print error or warning messages!

#run functions
printf '%s: world graphs are available from reuters and johns hopkins csse\n\n' "${0##*/}"

reutersf
cssef

printf '\r\033[2Kwaiting..'
wait
sleep 1

#list files and dir
printf '\r\033[2Ktook %s seconds\n\n%s\n' "$SECONDS" "$rootdir"
ls "$rootdir"

