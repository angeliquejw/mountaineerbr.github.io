#!/bin/zsh
# mountaineerbr  apr/2021
# Create pages for exploring directories and files
# Requires `markdown' and `txt2html'.


treef()
{
	local baseHREF basePATH out title mdarray txtarray notes xtrastyles inject
	typeset -a mdarray txtarray
	
	baseHREF="$1"
	basePATH="$2"
	out="${3:-index.html}"
	title="${basePATH##*/}"

	basePATH="${basePATH%/}"
	baseHREF="${baseHREF%/}"
	title="${title:u}"

	[[ -d "$basePATH" ]] || exit
	print "BASE HREF: $baseHREF\nBASE PATH: $basePATH\nOUT: $out\n" >&2

	tree "$basePATH" \
		-H "$baseHREF" \
		-L 1 \
		-F \
		-h \
		--dirsfirst \
		-C \
		--charset utf-8 \
		-I 'index.html|README.md' \
		| sed 's/<h1/<h2/g' >"$out"	#change [H1] to [H2]

# 		UNUSED OPTIONS:
#		-T "$title" \
#		--noreport \
#		-o "$out" \

	#inject README file
	if
		mdarray=( $( print -l "$basePATH"/(readme|info).md* ) )
		((${#mdarray[@]}))
	then inject="$(markdown "${mdarray[1]}")<hr>"
	elif
		txtarray=( $( print -l "$basePATH"/(readme|info).txt* ) )
		((${#txtarray[@]}))
	then inject="$(txt2html "${txtarray[1]}" | sed -n '/<body/,/<\/body/ p')"
	fi
	[[ -n "$inject" ]] && sed -i '/<body/ r /dev/stdin' "$out" <<<"$inject"

	#HTML CUSTOMISATION
	#extra styles
	xtrastyles='.tar  { color: red;  background-color: beige;}
	h1 { text-transform: uppercase; } 
	img {
		max-width: 400px;
		display: block;
		margin-left: auto;
		margin-right: auto;
	}
	'
	#notes
	notes='To download all files from a directory, try:
	<code>wget -r --no-parent --reject "index.html*"
	</code><hr>
	'
	
	#add package unicode to any .TGZ filenames (U+1F4E6)
	#and change to class .tar
	if [[ "$(<"$out")" = *.TGZ* ]]
	then sed -i 's|\.TGZ<|.TGZ(📦)<| ;/\.TGZ">/ s|class="[^"]*"|class="tar"|' "$out"
	fi


	#add extra styles
	sed -i '/<style.*/ r /dev/stdin' "$out" <<<"$xtrastyles"
	#inject notes
	sed -i '/<p class="VERSION"/ r /dev/stdin' "$out" <<<"$notes"

}


#start
set -e
setopt extendedglob  
setopt nullglob
setopt nocaseglob  #or use `(#i)(readme.md)*'

#BASE HREF AND PATH
pbase=$HOME/www/mountaineerbr.github.io
hbase=.  #relative paths
#hbase=https://mountaineerbr.github.io


#DIRECTORY: REPOS
pbaserepos="$pbase/repo"
cd "$pbaserepos"

#make tar for repos
if read -q '?Update repo TGZ files? y/N '
then
	for repo in */
	do
		repo="${repo%/}"
		tarfile="${repo:u}".TGZ
		tar czvf "$tarfile" "$repo"
	done
	unset tarfile repo
fi

#make index pages with `tree'
for dir in . **/(D)
do
	dir="${dir%/}"
	treef "$hbase" "$dir" "$dir/index.html"
done
unset dir

