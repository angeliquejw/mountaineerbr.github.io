#!/bin/bash
#make an xml sitemap
# v0.1.1  sep/2020  by mountaineerbr

#Based on Google & Bing's sitemap guidelines, XML sitemaps
#shouldn't contain more than 50,000 URLs and should be no
#larger than 50Mb when uncompressed. So in case of a larger
#site with many URLs, you can create multiple sitemap files. 
#no more than 10M(safer)-50M uncompressed or 50K links
#needs to verify ownership and submit sitemap.xml to search
#provideres as they don't read sitemap.xml by defaults.
#base urls matter: http vs https.
#add Sitemap entry to robots.txt.
#https://www.sitemaps.org/protocol.html
#https://support.google.com/webmasters/answer/183668?hl=en
#https://www.bing.com/webmaster/help/sitemaps-3b5cf6ed
#localised versions (alternative languages):
#https://support.google.com/webmasters/answer/189077#sitemap

#local home page root
ROOT="$HOME/www/mountaineerbr.github.io"
#target xml file
TARGET="$ROOT/sitemap.xml"

#website root
SITE_ROOT="https://mountaineerbr.github.io"

#find files with these extensions
EXTENSIONS=( .htm .html .php .asp .aspx .jsp )

#xml parts
XMLHEAD='<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
XMLTAIL='</urlset>'


#entity escaping
escf()
{
	sed 	-e 's/&/\&amp;/g' \
		-e "s/'/\&apos;/g" \
		-e 's/"/\&quot;/g' \
		-e 's/>/\&gt;/g' \
		-e 's/</\&lt;/g'
}


#start

#exit on any error
set -e


##FROM PMWMT SITEMAP1.SH WITH MODIFICATIONS##
#cd into webpage root directory
cd "$ROOT"

#make temp file
FOUNDFILES="$(mktemp)"

for ext in "${EXTENSIONS[@]}"
do
	 find . -name "*$ext"
done >"$FOUNDFILES"

# if there is an exclude list, exclude the files in it from the sitemap
exlst=exclude.lst
empty=""
if [[ -f "$exlst" ]]
then
	while read entry
	do 
		sed  -i "s,$entry,$empty,g" "$FOUNDFILES"
	done <"$exlst"

	# remove blank lines as well
	sed -i '/^$/d' "$FOUNDFILES"
fi

# remove leading . and insert site_root to build urls	
sed -i 's|\./||' "$FOUNDFILES"

# finishing touches
sort -f -u "$FOUNDFILES" > "$FOUNDFILES.files"
##FROM PMWMT SITEMAP1.SH##


#remove "old" sitemap.xml
[[ -f "$TARGET" ]] && rm -v "$TARGET"

#make new sitemap.xml
{
	#xml top
	echo "$XMLHEAD"

	#make url entries
	while IFS=  read
	do
		#counter
		(( ++n ))

		echo -e '\t<url>'
	
		#escape urls
		URL="$( escf <<<"$REPLY" )"
		echo -e "\t\t<loc>${SITE_ROOT}/${URL}</loc>"

		#check the i.html file stat, if there is
		if ALT="${REPLY/index.html/i.html}"
			[[ -f "$ALT" ]]
		then
			REPLY="$ALT"
		fi

		#last modification date
		MOD="$( TZ=0 stat --format="%Y" "$REPLY" )"
		MOD="$( date -Isec -d@"$MOD" )"
		echo -e "\t\t<lastmod>${MOD}</lastmod>"
	
		echo -e '\t</url>'
	
	done <"$FOUNDFILES.files"

	#xml bottom
	echo "$XMLTAIL"
	
	#add timestamp
	TS="$( date -Isec )"
	echo "<!-- generated-on=\"$TS\" -->"
	echo "<!-- items=\"$n\" -->"
	
} >"$TARGET"
#optional attributes:
#lastmod, changefreq and priority


#clean up
rm "$FOUNDFILES" "$FOUNDFILES.files"

