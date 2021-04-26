#!/bin/bash
## find files that don't have 'webstat' text in it
#	 grep, recursive, list non-matching --> files with .htm extension only --> list in 'targets' file
#http://users.telenet.be/mydotcom/program/shell/textprocess.htm


grep -L -R "webstat" /home/me/website | grep ".htm" > targets.lst

## review and edit target list (remove files that don't need changing)
vim targets.lst

## read file list and process files therein
cat targets.lst | while read filename ; do 
	# remove /body and /html tags at end of file so insertion doesn't fall ouside html document body
	sed -i 's/<\/html>//g' $filename
	sed -i 's/<\/body>//g' $filename
	sed -i 's/<\/HTML>//g' $filename
	sed -i 's/<\/BODY>//g' $filename

	# insert text from a file (eg the webstat counter script)
	cat srcfile  >> $filename

	# insert body and html end tags again
	echo "  </body>" >> $filename
	echo "</html>" >> $filename
done
	
