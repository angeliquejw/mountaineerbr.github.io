#!/bin/bash
# script to create sitemap.txt
# Koen Noens, October 2006
#http://users.telenet.be/mydotcom/howto/www/sitemap.htm

LOCAL_ROOT="/home/jp/websites/mysite"		# replace with your path
SITE_ROOT="http://my.isp.com/my_site"		# replace with your site URL
EXTENSIONS=".htm .html .php .asp .aspx .jsp"

pushd $LOCAL_ROOT

#find all .htm, .html, .php, ... pages, remove trailing dot and concatenate with SITE_ROOT

cd $LOCAL_ROOT
rm sitemap.txt || echo "no previous sitemap found"
FOUNDFILES=$(mktemp)

for ext in $EXTENSIONS ; do
	 find . -name "*$ext" >> $FOUNDFILES
done

# remove leading . and insert site_root to build urls	
sed -i 's/\.//' $FOUNDFILES
for FILE in $(cat $FOUNDFILES); do
		echo $SITE_ROOT$FILE  >> $FOUNDFILES.0
done


# if there is an exclude list, exclude the files in it from the sitemap
empty=""
if [[ -e exclude.lst ]]; then
	cat exclude.lst | while read entry; do 
		sed  -i "s,$entry,$empty,g" $FOUNDFILES.0  
	done; 
	# remove blank lines as well
	sed -i '/^$/d' $FOUNDFILES.0 
fi

# finishing touches
sort -f -u $FOUNDFILES.0 >> sitemap.txt
rm $FOUNDFILES.0
rm $FOUNDFILES

# add sitemap to files_to_upload
echo "$LOCAL_ROOT/sitemap.txt" >>  $LOCAL_ROOT/upload
