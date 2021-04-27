#!/bin/zsh
# mountaineerbr  apr/2021
# Create pages for exploring directories and files
# Requires `markdown' and `txt2html'.
# <https://archlinux.org/packages/extra/x86_64/discount/>
# <https://www.pell.portland.or.us/~orc/Code/discount/>
# <https://daringfireball.net/projects/markdown/basics>

#script name
SN="${0##*/}"

treef()
{
	local baseHREF basePATH out title mdarray txtarray notes xtrastyles inject meta ext
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
		| sed -e 's/<h1/<h2/g ;s/<\/h1/<\/h2/g' \
			-e 's|<a class="NORM" href=".">|<a class="NORM" href="..">..</a><br>\n&|' \
			>"$out"
		#change [H1] to [H2]
		#add go up dir

# 		UNUSED OPTIONS:
#		--noreport \
#		-o "$out" \

	#inject README file
	if
		mdarray=( $( print -l "$basePATH"/(readme|info).md* ) )
		((${#mdarray[@]}))
	then inject="$(
		sed -E -e '/^\s*```+/,/^\s*```+/ s/^/    /; s/```.*//' "${mdarray[1]}" \
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
		max-width: 500px;
		display: block;
		margin-left: auto;
		margin-right: auto;
	}
	'
	#notes
	notes='To download all files from a directory, try:
	<code>wget -r --no-parent --reject "index.html*" [URL]
	</code><br>
	That is a shame GitHub limits file size to 100MB.<hr>
	'
	
	#add package unicode to any .TGZ filenames (U+1F4E6)
	#and change to class .tar
	ext='tar.bz2\|tar.gz\|bz2\|rar\|gz\|tar\|tbz2\|tgz\|zip\|Z\|7z\|deb\|zstd\|tar.xz\|txz'
	extt='tar.bz2|tar.gz|bz2|rar|gz|tar|tbz2|tgz|zip|Z|7z|deb|zstd|tar.xz|txz'
	if [[ "$(<"$out")" =~ \.($extt) ]]
	then
		sed -i -E -e "s|\.($ext)<|.\1(📦)<|I" "$out"
		sed -i -e "/\.($ext)\">/ s|class=\"[^\"]*\"|class=\"tar\"|I" "$out"
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


#make index pages with `tree'
for dir in . **/(D)
do
	dir="${dir%/}"
	treef "$hbase" "$dir" "$dir/index.html"
done
unset dir

