#!/bin/zsh
# mountaineerbr  apr/2021
# Create pages for exploring directories and files
# Requires `markdown' and `txt2html'.
# <https://archlinux.org/packages/extra/x86_64/discount/>
# <https://www.pell.portland.or.us/~orc/Code/discount/>
# <https://daringfireball.net/projects/markdown/basics>


treef()
{
	local baseHREF basePATH out title mdarray txtarray notes xtrastyles inject meta
	typeset -a mdarray txtarray
	
	baseHREF="$1"
	basePATH="$2"
	out="${3:-index.html}"
	title="${basePATH##*/}"

	#
	basePATH="${basePATH%/}"
	baseHREF="${baseHREF%/}"
	[[ "$title" = . ]] && title="${PWD##*/}"
	title="${title:u}"

	[[ -d "$basePATH" ]] || exit
	print "BASE HREF: $baseHREF\nBASE PATH: $basePATH\nOUT: $out\n" >&2

	tree "$basePATH" \
		-a \
		-H "$baseHREF" \
		-L 1 \
		-F \
		-h \
		-T "$title - Directory Tree" \
		--dirsfirst \
		-C \
		--charset utf-8 \
		-I 'index.html|README.md' \
		| sed 's/<h1/<h2/g' >"$out"	#change [H1] to [H2]

# 		UNUSED OPTIONS:
#		--noreport \
#		-o "$out" \

	#inject README file
	if
		mdarray=( $( print -l "$basePATH"/(readme|info).md* ) )
		((${#mdarray[@]}))
	then inject="$(
		sed -E -e '/```+/,/```+/ s/^/    /; s/```.*//' "${mdarray[1]}" \
		| markdown
	)<hr>"
	elif
		txtarray=( $( print -l "$basePATH"/(readme|info).txt* ) )
		((${#txtarray[@]}))
	then inject="$(txt2html "${txtarray[1]}" | sed -n '/<body/,/<\/body/ p')"
	fi
	[[ -n "$inject" ]] && sed -i '/<body/ r /dev/stdin' "$out" <<<"$inject"

	#HTML CUSTOMISATION
	#metatags
	meta='<meta name="viewport" content="width=device-width, initial-scale=1.0">
	'
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
	<code>wget -r --no-parent --reject "index.html*" [URL]
	</code><hr>
	'
	
	#add package unicode to any .TGZ filenames (U+1F4E6)
	#and change to class .tar
	if [[ "$(<"$out")" = *.TGZ* ]]
	then sed -i 's|\.TGZ<|.TGZ(📦)<| ;/\.TGZ">/ s|class="[^"]*"|class="tar"|' "$out"
	fi


	#add meta tags
	sed -i '/<head.*/ r /dev/stdin' "$out" <<<"$meta"
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

