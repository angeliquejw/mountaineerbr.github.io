#!/bin/zsh
# portal.sh -- SYNC MY WEBSITE
# v0.1.13  apr/2021  by mountaineerbr

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
set -e  #!#
#cd into webpage $ROOT
cd "$ROOT"
#!#IMPORTANT: REMOVE COPROCESS OPERATOR (&) FOR DEBUGGING


#PART ONE
#update blog
#generate blog pages, and blog rss feeds
blog/sync.sh "$@"  &
print


#PART TWO
#generate the podcast rss feed
podcast/podcast.sh  &
print


#PART THREE
#add newest link and quote items
./linksq.sh  &
print


#PART FOUR
##make repo tree pages
cd repo
./sync.sh  &
cd -
print


#PART FIVE
##make video vlog pages
#cd vlog
#./vid.sh
#cd -
#print



#wait for all coprocesses to exit
wait

#PART LAST
#update sitemaps
#bash PMWMT/zzsitemap1.sh
#bash PMWMT/zzsitemap2.sh
#bash PMWMT/zzsitemap3.sh
./sitemaps.sh
print


