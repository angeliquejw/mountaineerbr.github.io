#!/bin/bash
# (c) Koen Noens 2009
#
# Silly Software Productions  - Poor Man's Webmaster Tools
#
# find dead links in a set of html files
# 	only checks the off-site links, identified by absolute url href
#http://users.telenet.be/mydotcom/howto/www/deadlinks.html

## PARAMS
#directory for search
LOCALDIR="websites/mydotcom" 

#file to list pages that contain dead links
UPLOADFILE="websites/mydotcom/upload_after_fix"
TODOLIST="websites/mydotcom/deadlinkslist.$( date +%F )" 

TMPFILE=$(mktemp)



### Main -- rather verbose so we have progress indication
echo -e "\n\n collecting hyperlinks in $LOCALDIR \n\n"

# find files and hyperlinks
find $LOCALDIR -exec  grep -l "<a href=\"http://.*>" {} \;  |\
  while read FILE ; do
	#gradually reduce the matches untill we have a clean url, 
	
	grep -o "<a href=\"http://.*>" $FILE  | \
	grep -o "http://[[:graph:]]*\"" | 	\
	while read URL
	do
		URL=${URL%'"'}	;#remove trailing double quote
		
		#dump filenames and urls in tempfile for further processing 
		echo "${FILE};${URL}" >> $TMPFILE
	done
  done 


echo -e "\n\n starting check for broken links ... \n\n"

sort -u <$TMPFILE | while read RECORD;
  do
	FILE=$( echo $RECORD | cut -d';' -f1 - )
	URL=$( echo $RECORD | cut -d';' -f2 - )

	echo -e "\n $FILE  - checking $URL \n"

	wget --spider $URL || BADLINK="true"

	if [[ "$BADLINK" = "true" ]]; then
		# url not found
		echo -e "ERROR retrieving  $URL \n\n"

		#put file + url on todo-list, and put file on list to upload after fix
		echo "$FILE" >>$UPLOADFILE
		echo "$FILE  -  $URL" >>$TODOLIST

		BADLINK="noted"
	fi
  done 

# sort and uniq the upload_file
mv  $UPLOADFILE $TMPFILE
sort -u <$TMPFILE > $UPLOADFILE && rm $TMPFILE
