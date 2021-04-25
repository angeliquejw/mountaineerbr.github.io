#!/bin/zsh
# vim:ft=sh
# sync.sh -- UPDATE BLOG, RSS AND TUBLELOG
# v0.1  mar/2021  mountaineerbr
#   __ _  ___  __ _____  / /____ _(_)__  ___ ___ ____/ /  ____
#  /  ' \/ _ \/ // / _ \/ __/ _ `/ / _ \/ -_) -_) __/ _ \/ __/
# /_/_/_/\___/\_,_/_//_/\__/\_,_/_/_//_/\__/\__/_/ /_.__/_/   


#defaults

#script name
SN="${0##*/}"

#home page root
ROOT="$HOME/www/mountaineerbr.github.io"
#website root
ROOTW="https://mountaineerbr.github.io"
#blog root
ROOTB="$ROOT/blog"
#website blog root
ROOTBW="$ROOTW/blog"


#run
set -e
#cd into webpage $ROOT
#cd "$ROOTB"/

#update blog pages
"$ROOTB"/blog.sh
print

#generate the blog rss feed
"$ROOTB"/rss.sh
print

#generate the podcast rss feed
"$ROOTB"/podcast/podcast.sh
print


