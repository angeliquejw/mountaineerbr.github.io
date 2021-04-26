#!/bin/zsh
# portal.sh -- SYNC MY WEBSITE
# v0.1.9  apr/2021  by mountaineerbr

#    #  ####  #    # #    # #####   ##   # #    # ###### ###### #####  #####  #####  
##  ## #    # #    # ##   #   #    #  #  # ##   # #      #      #    # #    # #    # 
# ## # #    # #    # # #  #   #   #    # # # #  # #####  #####  #    # #####  #    # 
#    # #    # #    # #  # #   #   ###### # #  # # #      #      #####  #    # #####  
#    # #    # #    # #   ##   #   #    # # #   ## #      #      #   #  #    # #   #  
#    #  ####   ####  #    #   #   #    # # #    # ###### ###### #    # #####  #    # 


#home page root
ROOT="$HOME/www/mountaineerbr.github.io"
#website root
ROOTW="https://mountaineerbr.github.io"
#blog root
ROOTB="$ROOT/blog"
#website blog root
ROOTBW="$ROOTW/blog"

#clear everything on the line
CLR='\033[2K'


#start

#exit on error
set -e
#cd into webpage $ROOT
cd "$ROOT"



#PART ONE
#update blog
#generate blog pages, rss and feeds
blog/sync.sh "$@"
print



#PART TWO
#update sitemaps
#bash PMWMT/zzsitemap1.sh
#bash PMWMT/zzsitemap2.sh
#bash PMWMT/zzsitemap3.sh
./sitemaps.sh
print



#PART THREE
#add newest link and quote items
./linksq.sh
print


#PART FOUR
##make repo tree pages
cd repo
tree.sh
cd -
print

