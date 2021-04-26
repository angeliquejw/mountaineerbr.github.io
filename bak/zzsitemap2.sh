#!/bin/bash
# Koen Noens, December 2007
# modified by mountainbeerbr 2020
# site map generator
#
#create indented list of hyperlinks to represent
#a directory listing of a web site ("sitemap")
#http://users.telenet.be/mydotcom/howto/www/sitemap02.txt
#http://users.telenet.be/mydotcom/upub/sitemap.htm

## script gloabal vars
TARGET="/home/jsn/www/mountaineerbr.github.io"
URLPRE="https://mountaineerbr.github.io"
SITEMAP="/home/jsn/www/mountaineerbr.github.io/sitemap.html"

EXT="html"
OUT=""
SKIP="0"

# constants for html tags
HTMLTAB="&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"

## functions
function countIndents {
	# count depth in directory three
	COUNT=1
	STRING=$1

	 while [[ "$(dirname $STRING)" != "/" ]]; do
		STRING=$(dirname $STRING) 
		let COUNT=$((COUNT + 1)); 
	done
	return $COUNT
}


## main
countIndents "$TARGET"
SKIP=$?

OUT=$(mktemp)
#remove "old" sitemap.html
[[ -e "$SITEMAP" ]] && rm "$SITEMAP"


### experiment with find and sort to get ordered output
#find $TARGET -type d -o -name "*.$EXT" >> $OUT
find "$TARGET" -name "*.$EXT" -o -type d >> "$OUT"
sort -n -o "$OUT" "$OUT"

# if there is an exclude list, exclude the files in it from the sitemap
exlst=exclude.lst
empty=""
if [[ -e "$exlst" ]]
then
	while read entry
	do 
		sed  -i "s,$entry,$empty,g" "$OUT"
	done <"$exlst"

	# remove blank lines as well
	sed -i '/^$/d' "$OUT"
fi

#create html doc
{
	#html top
	cat <<-!!
	<!DOCTYPE html>
	<html lang="">
	<head>
	<meta http-equiv="content-type" content="text/html; charset=UTF-8">
	<title>sitemap</title>
	<meta name="resource-type" content="document">
	<meta name="description" content="Site map for visitors">
	<meta name="keywords" content="navigation, navegação">
	<meta name="distribution" content="global">
	<link rel="shortcut icon" href="favicon.ico" type="image/x-icon">
	<!--<link rev="made" href="mailto:jamilbio20[[at]]gmail[[dot]]com">-->
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	</head>
	<body>
	!!

	#entries
	while read ENTRY
	do
		countIndents "$ENTRY"
		let TABS=$(( $? - $SKIP ))
	
		for i in $(seq 0 $TABS); do
			echo -n "$HTMLTAB"
		done
		echo "<a href=\"$ENTRY\">$(basename "$ENTRY")</a><br>"
	
		#progres
		echo -n '.' >&2
	done <"$OUT"
	
	#html bottom
	echo '</body></html>'

} > "$SITEMAP"

### replace local hierarchy with url-prefix
sed -i "s,$TARGET,$URLPRE,g" "$SITEMAP"


# cleanup
echo >&2
rm "$OUT"

