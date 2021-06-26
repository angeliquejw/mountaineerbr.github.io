#!/bin/bash
# ug.sh -- grep full-text urls
# v0.1.4  jun/2021  by mountaineerbr

# This is the light version of urlgrep.sh.
# 1. Choose your preferred application to download pages and a markup filter
#    in the source code below (just uncomment the line with the option you want).
# 2. Make a URL list.
# 3. Send URLs via stdin.
# 4. All script positional arguments will be passed to grep.

# URLs lists
# Firefox -- All URLs (history, etc)
#{ sqlite3 "$HOME/.mozilla/firefox/XXXXXXXX.default/places.sqlite" <<<'select url from moz_places where 1;' ;}
# Firefox -- Bookmarks
#{ sqlite3 "$HOME/.mozilla/firefox/XXXXXXXX.default/places.sqlite" <<<'select url from moz_bookmarks, moz_places where moz_places.id=moz_bookmarks.fk;' ;}

# Chrome -- All URLs (history, etc)
#{ sqlite3 "$HOME/.config/google-chrome/Default/History" <<<'select url from urls where 1;' ;}
# Chrome -- Bookmarks
#{ jq -r '..|.url? //empty' "$HOME/.config/google-chrome/Default/Bookmarks" ;}


# Options

# Maximum number of simultaneous bg jobs
JOBMAX=4

# User agent
#``Chrome on Windows 10''
UAG="user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) \
AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.83 Safari/537.36"


# CURL
yourapp() { curl -sL -b emptycookie --insecure --compressed --header "$UAG"  "${CURLOPTS[@]}" "$1" ;}
# Useful curl options
#CURLOPTS=( --retry 2  --connect-timeout 240  --max-time 240 )
#By defaults, curl does not follow redirects, does not use the
#cookie engine, performs no retries and connect-timeout is 5 minutes.
#--insecure , don't check https certificate.
#https://github.com/curl/curl/blob/master/lib/connect.h

# WGET
yourapp() { wget -q -O- --no-check-certificate --header="$UAG" -e robots=off "${WGETOPTS[@]}" "$1" ;}
# Useful wget options
#WGETOPTS=( --tries=2  --connect-timeout=240  --timeout=240 )
#By defaults, wget follows redirects, uses cookie engine, 
#retries 20 times and --read-timeout is 900 seconds


# Markup filter
#filter() { elinks -force-html -dump -no-references ;}
#filter() { links -force-html -dump ;}
filter() { w3m -dump -T text/html ;}
#filter() { lynx -force_html -dump -nolist ;} 	#lynx makes grep throws warnings about binary data
#filter() { sed 's/<[^>]*>//g' ;} 		#defaults
#filter() { sed '/</{ :loop ;s/<[^<]*>//g ;/</{ N ;b loop } }' ;}  #rm multiline tags, too
#filter() { cat ;} 				#turn off filter


# Start

#checks
(($#)) || exit 2
grep "$@" <<<' ' ;e=$?
((e>1)) && exit $e

#asynchronous search loop
#remove carriage returns
tr -d '\r' |
while read -r
do
	(( ++N ))
	#feedback
	printf ">>>stdin: %04d  \r" "$N"

	#job control
	while  JOBS=($( jobs -p )) ;((${#JOBS[@]} > JOBMAX))
	do  sleep 0.1;
	done

	#launch new jobs
	yourapp "$REPLY" | filter | grep "$@" && echo -e ">>>$REPLY\n"  &
done
wait

