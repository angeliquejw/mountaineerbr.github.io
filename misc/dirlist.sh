#!/bin/bash
#https://stackoverflow.com/questions/21395159/shell-script-to-create-a-static-html-directory-listing

#see pkg `tree` with flag -H
#https://stackoverflow.com/questions/3785055/how-can-i-create-a-simple-index-html-file-which-lists-all-files-directories
#tree -H '.' -L 1 --noreport --charset utf-8 > tree.html

#My /tmp/test
#
#/tmp/test
#├── accidents
#│   ├── accident2.gif
#│   ├── accident3.gif
#│   └── accident4.gif
#├── bears
#│   ├── bears1.gif
#│   ├── bears2.gif
#│   ├── bears3.gif
#│   └── bears4.gif
#└── cats
#    ├── cats1.gif
#    └── cats2.gif

ROOT=/tmp/test
HTTP="/"
OUTPUT="_includes/site-index.html" 

i=0
echo "<UL>" > $OUTPUT
for filepath in `find "$ROOT" -maxdepth 1 -mindepth 1 -type d| sort`; do
  path=`basename "$filepath"`
  echo "  <LI>$path</LI>" >> $OUTPUT
  
  #echo "  <UL><a href=\"/$path\">$path</a>" >> $OUTPUT
  echo "  <UL>" >> $OUTPUT
  
  for i in `find "$filepath" -maxdepth 1 -mindepth 1 -type f| sort`; do
    file=`basename "$i"`
    echo "    <LI><a href=\"/$path/$file\">$file</a></LI>" >> $OUTPUT
  done
  echo "  </UL>" >> $OUTPUT
done
echo "</UL>" >> $OUTPUT

