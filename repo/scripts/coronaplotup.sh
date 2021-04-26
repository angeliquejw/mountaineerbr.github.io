#!/bin/zsh
# sync git repo with updated data

#load functions
. ~/.rc || exit 1

#exit on any error
set -e

#target dir
tmpdir="/tmp/coronaPlotSync"

if [[ -d "$tmpdir" ]] && (( $(du -s "$tmpdir" 2>/dev/null | cut -f1) ))
then
	cd "$tmpdir"
	gres
else
	[[ -d "$tmpdir" ]] && rm -rf "$tmpdir"
	mkdir "$tmpdir"
	cd "$tmpdir"
	git clone 'https://github.com/mountaineerbr/coronaPlot' .
fi

#remove old scripts and copy updated ones
for f in coronaplot.sh coronaplotup.sh corona_func.sh corona_tables.sh
do
	[[ -f "$f" ]] && \rm "$f"
	\cp ~/bin/"$f" ./"$f"
done

#remove old folders
for d in csse reuters reutersTables
do 
	[[ -d "$d" ]] && \rm -rf "$d"
done

#make updated plots
zsh coronaplot.sh 
#make updated tables
zsh corona_tables.sh

printf 'coronaplotup.sh: graphs and tables generated at %s\n\n' "$( date -uR )" >sync.txt >>README.md >/dev/stdin

#check dir size
SIZE=( $( du -s . ) )
if (( SIZE[1] < 41000 ))
then
	echo "coronaplotup.sh: generated files seem to lack size" >&2
	exit 1
fi
#43820

#sync git repo
git add -A
git commit -msync..
#remove old objects, sync with no old data
grmob

printf 'coronaplotup.sh: sync success at     %s\n\n' "$( date -uR )" >>sync.txt >/dev/stdin

