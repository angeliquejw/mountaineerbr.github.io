#!/bin/zsh
# vim:ft=sh
# linksq.sh -- automatically add newest links and quotes to the main page
# v0.1.1  by mountaineerbr
#   __ _  ___  __ _____  / /____ _(_)__  ___ ___ ____/ /  ____
#  /  ' \/ _ \/ // / _ \/ __/ _ `/ / _ \/ -_) -_) __/ _ \/ __/
# /_/_/_/\___/\_,_/_//_/\__/\_,_/_/_//_/\__/\__/_/ /_.__/_/   
                                                            

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

#links file
LINKSF="$ROOT/links.html"
#quotes file
QUOTESF="$ROOT/quotes.html"
#main file
MAINF="$ROOT/index.html"

#clear everything on the line
CLR='\033[2K'

#tidy up markup
#unwrap html lines
unwrapf()
{
	tidy --quiet yes \
		--show-warnings no \
		--show-info no \
		--wrap 0 \
		--wrap-attributes no \
		--fix-uri yes \
		--vertical-space no \
		--hide-comments yes \
		--tidy-mark no \
		--write-back no \
		--show-body-only yes \
		--preserve-entities yes \
		--quote-ampersand yes \
		--quote-marks yes \
		--quote-nbsp yes \
		-- "$@" || true
}



#start

#check for pkgs
for pkg in tidy
do
	if ! command -v "$pkg" &>/dev/null
	then echo "$SN: err: package missing -- $pkg" >&2 ;exit 1
	fi
done
unset pkg

#exit on error
set -e
#cd into webpage $ROOT
cd "$ROOT"



#PART ONE
#add links to main page
print "$SN: add newest links to main page.." >&2

#unwrap links.html
unwrapped="$( unwrapf "$LINKSF")"

#map [tr]s
trmaps=( $(grep -n '^\s*<tr' <<<"$unwrapped" | cut -d: -f1) )
trmape=( $(grep -nF '</tr' <<<"$unwrapped" | cut -d: -f1) )

#remove older items
sed -i '/<!-- linklistX -->/,/<!-- linklistX -->/ d' "$MAINF"

#inject newest items
injection="<!-- linklistX -->
$(sed -n "${trmaps[1]},${trmape[3]} p" <<<"$unwrapped" )
<!-- linklistX -->"

sed -i '/<!-- linklist -->/ r /dev/stdin' "$MAINF" <<<"$injection" 

unset unwrapped trmaps trmape injection



#PART TWO
#add quotes to main page
print "$SN: add newest quotes to main page.." >&2

#unwrap quotes.html
unwrapped="$( unwrapf "$QUOTESF")"

#map [dt]s and [dd]s
dtmap=( $(grep -n '^\s*<dt' <<<"$unwrapped" | cut -d: -f1) )
ddmap=( $(grep -nF '</dd' <<<"$unwrapped" | cut -d: -f1) )

#remove older items
sed -i '/<!-- quotelistX -->/,/<!-- quotelistX -->/ d' "$MAINF"

#inject newest items
injection="<!-- quotelistX -->
$(sed -n "${dtmap[1]},${ddmap[4]} p" <<<"$unwrapped" )
<!-- quotelistX -->"

sed -i '/<!-- quotelist -->/ r /dev/stdin' "$MAINF" <<<"$injection" 

unset unwrapped dtmap ddmap injection


