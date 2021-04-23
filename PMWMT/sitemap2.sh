#!/bin/bash
# Koen Noens, December 2007
# site map generator
#
# create indented list of hyperlinks to represent a directory listing of a web site ("sitemap")
#http://users.telenet.be/mydotcom/howto/www/sitemap02.txt
#http://users.telenet.be/mydotcom/upub/sitemap.htm

## script gloabal vars
TARGET="/home/me/website"
URLPRE="http://my.hosting.provider.com/mywebsite"
SITEMAP="/home/me/website/sitemap.htm"

EXT="htm"
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
countIndents $TARGET
SKIP=$?

OUT=$(mktemp)
[[ -e $SITEMAP ]] && rm $SITEMAP

### experiment with find and sort to get ordered output
#find $TARGET -type d -o -name "*.$EXT" >> $OUT
find $TARGET -name "*.$EXT" -o -type d >> $OUT
#sort -n -o $OUT $OUT

echo "<html><head><title>sitemap</title></head><body>" >> $SITEMAP
cat $OUT | while read ENTRY ; do
	countIndents $ENTRY
	let TABS=$(( $? - $SKIP ))

	for i in $(seq 0 $TABS); do
		echo -n $HTMLTAB >> $SITEMAP
	done
	echo "<a href=\"$ENTRY\">$(basename $ENTRY)</a><br>" >> $SITEMAP

	#progres
	echo -n "."
done
echo "</body></html>" >> $SITEMAP

### replace local hierarchy with url-prefix
sed -i "s,$TARGET,$URLPRE,g" $SITEMAP


# cleanup
echo
rm $OUT
exit
