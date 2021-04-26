# function lib
# corona aug/2020
#some functions to manipulate corona virus data
#these functions are rather hacks, usage is not much comprehensible
#source this file to make them available in your shell
#requires bash bc

#make sure locale is set correctly
#LC_NUMERIC=en_US.UTF-8

#corona virus functions

#corona brasil -- ministério da saúde
#as of 09/june/2020, the public health department uses .xlsx
#which makes it necessary to convert to plain csv format
#that is completely terrible and i am not going to support it

#brasil.io
#get csv data of municipalities
coronab()
{
	local url tempfile

	url='caso_full'
	case "$1" in
		#dados brutos em csv
		csv)
			curl -o - -L -H 'user-agent: Mozilla/5.0 Gecko' 'https://brasil.io/dataset/covid19/caso/?is_last=True&place_type=city&format=csv'
			return;;
		#boletim, infomações gerais
		boletim)
			url='boletim'
			set -- .
			;;
		#casos, resumo
		c)
			url='caso'
			shift;;
		#óbitos, resumo
		o)
			url='obito_cartorio'
			shift;;
		#use existing file?
		*)
			if [[ -f "$1" ]]
			then
				tempfile="$1"
				shift
			fi
			;;
	esac

	#set tempfile path
	if [[ ! -f "$tempfile" ]]
	then
		tempfile="/tmp/${url}.$( date -I ).csv"

		#get data and uncompress it to $tempfile
		curl -o - -L -H 'user-agent: Mozilla/5.0 Gecko' "https://data.brasil.io/dataset/covid19/${url}.csv.gz" |
			gunzip -c > "$tempfile" || return 1
	fi

	#if stdout is free and there is an arg
	if [[ -t 1 ]] && (( $# ))
	then
		column -et -s, -N"$( head -1 "$tempfile" )" <( grep -i "${@:-.}" "$tempfile" ) | less -S
	fi

	#print column names
	head -1  "$tempfile" >&2
	#print tempfile path
	echo "warning: temp file -- $tempfile" >&2
}

#international

#reuters
#usage: corona [-r] COL
#flag -r to reverse order
#COL is a numeric positional argument to select column sort
corona() {
	local flag=-n flag2=-r flag3=-c150
	local opt sort data update keys stats

	#opts
	getopts r opt && unset flag2 && shift

	#is output being redirected?
	[[ -t 1 ]] && unset flag3
	
	#sort order
	[[ "$1" = [1-7] ]] || set -- 1
	case "$1" in
		1) sort=CASES;;
		2) sort=DEATHS;;
		3) sort=RECOVERED;;
		4) sort=POPULATION;;
		5) sort=LETALITY%;;
		6) sort=LETALITY/100K;;
		7) sort=LOCATION; unset flag;;
	esac
		
	#get data if empty
	if [[ -z "$data" ]]
	then
		data="$( curl -sL 'https://graphics.thomsonreuters.com/data/2020/coronavirus/tracking/global/data.json' )" 
	fi

	#update timestamp
	update="$( jq -r '.lastUpdated' <<< "$data" )"

	keys="$( jq -r '.countries|keys_unsorted[]' <<< "$data" )"

	stats="$( jq -r '.countries[] | "\(.cases[-1])\t\(.deaths[-1])\t\(.recovered[-1])\t\(.population)\t\(((.deaths[-1]/.cases[-1])*100) | tostring | .[0:6] )%\t\(((.deaths[-1]/.population)*100000) | tostring | .[0:7] )" ' <<<"$data" )"

	paste <( echo "$stats") <( echo "$keys" ) |
		sort ${flag} ${flag2} -t$'\t' -k"$1" | nl -s$'\t' -w1 | tac | 
		column ${flag3} -ets$'\t' -N'RNK,CASES(1),DEATH(2),REC(3),POP(4),LET%(5),LET/100K(6),LOC(7)' -T'LOC(7)'

	echo "updated__: $update"
	echo "sorted_by: $sort"
	echo 'source___: reuters news agency'
}

#worldometers
corona2() {
	local data
	
	data="$( curl --compressed -s 'https://www.worldometers.info/coronavirus/' )"
	
	sed 's/<[^>]*>//g' <<<"$data" |
		grep -Fm1 'Coronavirus Update' |
		tee >(grep -oE '[0-9,]{3,}' |
		tr -d ',' | tac | paste -sd/ |
		xargs printf 'scale=4;(%s)*100\n' | bc -l |
		xargs printf 'Letality: %s%%\n') | sed 's/^\s*//'

	echo '<https://www.worldometers.info/coronavirus/>'
}

#corona-stats api
#usage: corona3 [region]
#[region] is a two letter symbol for country, eg. us, br, it
corona3() {
        local regiao
	
	regiao="/$(tr 'a-z' 'A-Z' <<<"$1")"
        curl -s "https://corona-stats.online$regiao?source=2&minimal=true" | tac
}
#https://github.com/sagarkarira/coronavirus-tracker-cli

corona3a() {
	curl --compressed -s 'https://corona-stats.online?format=json' |
		jq -r '(.data[],.worldStats)|"\(.country)\t\(.cases)\t\(.todayCases)\t\(.deaths)\t\((.deaths/.cases)*100)%\t\(.casesPerOneMillion)"' |
		sort -nrt$'\t' -k2 | cat -n | tac |
		sed -E 's/^\s*([0-9]+)(\s)(.*)/\1\t\3/' |
		column -ets$'\t' -NRNK,LOCAL,CASES,NEW,DEATHS,MORT%,C/Mil -TLOCAL,MORT%
}

#johns hopkins university center for systems science and engineering (jhu csse)
#usage: corona4 [location] [confirmed|recovered|deaths] [global|US]
#usage: corona4 help
corona4() {
	local data

	#help
	if [[ "$1" = *[Hh]elp* ]]
	then
		cat <<-!
		usage: corona4 [location] [confirmed|recovered|deaths] [global|US]
		usage: corona4 'united kingdom|Montserrat|Quebec|US' recovered
		usage: corona4 florida '' US
		usage: corona4 US recovered
		usage: corona4 '' '' US
		!

		return 0
	fi

	#set positional parameter if empty
	[[ "$3" = us ]] && set -- "$1" "$2" US

	#get data
	data="$( curl -s "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_${2:-confirmed}_${3:-global}.csv" )"

	#process
	if [[ -n "$1" ]]
	then
		grep -Ei "(,|^)$1," <<<"$data" |
			sed 's/^/\n&/' |
			#cut -d, -f5- |
			tr ',' '\n'
	else
		echo "$data"
	fi

	#print some cmd references to stderr
	echo "$1 $2 $3" 1>&2
}

#misc

#gnu plot simple graph
plot()
{
	gnuplot -p -e 'plot "/dev/stdin"'
}
plot2()
{
	gnuplot -p -e 'plot "/dev/stdin" with linespoints linestyle 1'
}
plot3()
{
	gnuplot -p -e 'set logscale y "'${1:-10}'"; plot "/dev/stdin" with linespoints linestyle 1'
}

#set first column as x tick (non-numerical)
#comma-separated
#a,1
#b,2
#will have a hard time if xticks are non-numeric
#gnuplot -p -e "set xtics rotate by 30 ;set datafile separator \",\" ;plot '-' using 2:xtic(1) with lines notitle"
#gnuplot -p -e 'set terminal jpeg size 3200,800 ;set autoscale ;set xtics 200 rotate by 90; set datafile separator ","; plot "/dev/stdin" using 2:xtic(1) with linespoints linestyle 1'

#percentage rate between two values
#one value per line
#this needs a remake..
percentagef()
{
	local n line perline last rate
	n=1
	while read line; do
		if [[ "$line" = *[a-zA-Z]* || "$line" =~ ^\s*$ ]]
		then
			echo "$line" >&2
			continue
		fi
	
		#(( perline = line - last ))
		(( ${last/.} )) || last=1
		
		if (( ZSH_VERSION ))
		then
			#zsh
			typeset -F 4 rate line last
			(( rate = ( ( line / last ) * 100) - 100 ))
		else
			#bash bc
			rate="$( bc -l <<<"scale=4; ( ( $line / $last ) * 100) - 100" )"
		fi
	
		echo "$rate"
	
		#printf '%s\t%s\t+%s\t%.2f%%\n' "$n" "$line" "$perline" "$rate"
		
		last="$line"
		(( ++n ))
	done
}
#column -ets$'\t' -NN,LINE,+INC,INC%  #cols: N,LINE,+INC,INC%%

