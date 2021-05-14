#!/bin/zsh
# v0.3.5  may/2021  mountaineerbr
# Create pages for exploring directories and files
# Requires `markdown' and `txt2html'.
# <https://archlinux.org/packages/extra/x86_64/discount/>
# <https://www.pell.portland.or.us/~orc/Code/discount/>
# <https://daringfireball.net/projects/markdown/basics>

#script name
SN="${0##*/}"

treef()
{
	local baseHREF basePATH out title mdarray meta txtarray notes xtrastyles inject
	local ext extt pic media doc txt pdf 
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

	#make html tree 
	#add package unicode to any .TGZ filenames (U+1F4E6)
	#change class of some filetypes
	#change [H1] to [H2]
	#add go up dir
	ext='tar.bz2\|tar.gz\|bz2\|rar\|gz\|tar\|tbz2\|tgz\|zip\|Z\|7z\|deb\|zstd\|tar.xz\|txz\|iso'
	extt='tar.bz2|tar.gz|bz2|rar|gz|tar|tbz2|tgz|zip|Z|7z|deb|zstd|tar.xz|txz|iso'
	pic='jpg|jpeg|png|gif|tiff|webp|bmp|svg|svgz|ico|svg|ppm|tga|tif|xbm|xcf|xpm|xspf|xwd'
	media='mp3|ogg|oga|flac|m4a|mp4|aac|wma|anx|asf|au|axa|m2a|mid|midi|mpc|ogx|ra|ram|spx|wma|ac3'
	doc='doc|docx|odt|xls|xlsx|odp|pptx|ppt|ods'
	txt='txt|rtf|conf'  #maybe only .txt should be here
	pdf=pdf
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
		-I 'index.html|cksum.d' \
		| sed -E \
			-e 's/<h1/<h2/g ;s/<\/h1/<\/h2/g' \
			-e 's|<a class="NORM" href=".">|<a class="NORM" href="..">..</a><br>\n&|' \
			-e "s|\.($ext)<|.\1(📦)<|I" \
			-e "/\.($extt)\">/I s|class=\"[^\"]*\"|class=\"tar\"|I" \
			-e "/\.($pic)\">/I s|class=\"[^\"]*\"|class=\"pic\"|I" \
			-e "/\.($media)\">/I s|class=\"[^\"]*\"|class=\"media\"|I" \
			-e "/\.($doc)\">/I s|class=\"[^\"]*\"|class=\"doc\"|I" \
			-e "/\.($txt)\">/I s|class=\"[^\"]*\"|class=\"txt\"|I" \
			-e "/\/\.[^\"]+\">/I s|class=\"[^\"]*\"|class=\"hidden\"|I" \
			-e "/\.($pdf)\">/I s|class=\"[^\"]*\"|class=\"pdf\"|I" \
			>"$out"

# 		TREE UNUSED OPTIONS:
#		--noreport \
#		-o "$out" \


	#inject MD file?
	if mdarray=( $( print -l "$basePATH"/(readme|info).md* ) )
		((${#mdarray[@]}))
	then
		inject="$( sed -E -e '/^\s*```+/,/^\s*```+/ s/^/    /; s/```.*//' "${mdarray[1]}" | markdown )<hr>"
	#inject TXT file?
	elif txtarray=( $( print -l "$basePATH"/(readme|info).txt* "$basePATH"/(readme|info )) )
		((${#txtarray[@]}))
	then
		inject="$(txt2html --extract --eight_bit_clean "${txtarray[1]}")"
	fi
	[[ -n "$inject" ]] && sed -i '/<body/ r /dev/stdin' "$out" <<<"$inject"

	#HTML CUSTOMISATION
	#metatags
	meta='<meta name="viewport" content="width=device-width, initial-scale=1.0">
	'
	#extra styles
	xtrastyles='h1 { text-transform: uppercase; } 
	img {
		max-width: 500px;
		display: block;
		margin-left: auto;
		margin-right: auto;
	}
	.tar  { color: brown;  background-color: beige;}
	.pic  { color: blueviolet;}
	.media  { color: orange;}
	.doc  { color: indianred;}
	.txt  { color: crimson;}
	.pdf  { color: white;  background-color: blue;}
	.hidden  { background-color: azure;}
	'
	#notes
	notes='To download all files from a directory, try:
	<!-- wget -r --no-parent --reject "index.html*" [URL]/ -->
	<code>wget -r -np [URL]/</code><br>
	That is a shame GitHub limits file size to 100MB.<hr>
	'
	
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

