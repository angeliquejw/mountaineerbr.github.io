#!/bin/bash
# script to create sitemap.txt
# Koen Noens, October 2006
# modified by mountainbeerbr 2020
#http://users.telenet.be/mydotcom/howto/www/sitemap.htm

LOCAL_ROOT="/home/jsn/www/mountaineerbr.github.io"		# replace with your path
SITE_ROOT="https://mountaineerbr.github.io"		# replace with your site URL
EXTENSIONS=( .htm .html .php .asp .aspx .jsp )
TARGET="${LOCAL_ROOT}/sitemap.txt"

pushd "$LOCAL_ROOT"

#find all .htm, .html, .php, ... pages, remove trailing dot and concatenate with SITE_ROOT

cd "$LOCAL_ROOT" || exit 1
rm sitemap.txt || echo "no previous sitemap found"
FOUNDFILES="$(mktemp)"

for ext in "${EXTENSIONS[@]}"
do
	 find . -name "*$ext"
done >"$FOUNDFILES"

# remove leading . and insert site_root to build urls	
sed -i 's/^\.//' "$FOUNDFILES"
while read FILE
do
	echo "$SITE_ROOT$FILE"
done <"$FOUNDFILES" >"$FOUNDFILES.0"


# if there is an exclude list, exclude the files in it from the sitemap
exlst=exclude.lst
empty=""
if [[ -e "$exlst" ]]
then
	while read entry
	do 
		sed  -i "s,$entry,$empty,g" "$FOUNDFILES.0"
	done <"$exlst"

	# remove blank lines as well
	sed -i '/^$/d' "$FOUNDFILES.0"
fi


# finishing touches
sort -f -u "$FOUNDFILES.0" > "$TARGET"
rm "$FOUNDFILES.0"
rm "$FOUNDFILES"

# add sitemap to files_to_upload
#echo "$LOCAL_ROOT/sitemap.txt" >>  $LOCAL_ROOT/upload

