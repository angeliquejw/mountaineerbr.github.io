#!/bin/zsh
# vim:ft=sh
# podcast.sh -- BLOG RSS FEED AND TUMBLELOG SYSTEM 
# v0.2.7  apr/2021  mountaineerbr
#                       |        _)                  |        
#   ` \   _ \ |  |   \   _|  _` | |   \   -_)  -_)  _|_ \  _| 
# _|_|_|\___/\_,_|_| _|\__|\__,_|_|_| _|\___|\___|_|_.__/_|   


#defaults

#script name
SN="${0##*/}"

#home page root
ROOT="$HOME/www/mountaineerbr.github.io"
#website root
ROOTW="https://mountaineerbr.github.io"

#blog root
ROOTB="$ROOT/blog"
#podcast root
ROOTP="$ROOT/podcast"
#tumblelog root
ROOTT="$ROOTP/tumblelog"
#website blog root
ROOTBW="$ROOTW/blog"
#website podcast root
ROOTPW="$ROOTW/podcast"

#raw postfile name
RAWPOST_FNAME="ep*.xml"

#main and secondary feed location
TARGET_FEED="$ROOTP/rss_podcast.xml"
TARGET_FEED_SEC="$ROOTB/rss_podcast.xml"
#template files
TEMPLATE_FEED="$ROOTP/r_podcast.xml"
TEMP_TARGET_FEED="${TARGET_FEED}.tmp"

#blog>podcast index.html list
TARGET_INDEX="$ROOTB/index.html"
#TARGET_INDEX2="$ROOTP/index.html"

#main feed location
TARGET_TUMBLE="$ROOTP/index.html"


#clear everything on the line
CLR='\033[2K'

#help page
HELP="NAME
	$SN -- PODCAST RSS FEED AND TUMBLELOG SYSTEM


SYNOPSIS
	$SN


	Generate XML code for RSS feeds for the podcast in my website.
	This script will process entry xml files (manually written) to
	create create the podcast RSS feed. It will also update the pod-
	cast list of the main podcast index.html page.

	A template XML file for the RSS is required:
	${TEMPLATE_FEED} .

	Human-readable time format shall defaults UTC-03.

	Package \`xmlstarlet', \`uuidgen' and ffmpeg are required.

	Package \`tidy' is required and it will tidy up the final generated
	pages for the feeds, unless option -i is set.

	This script will also generate Tumblelog pages.


REFERENCES
	Tumblelog
	<https://github.com/john-bokma/tumblelog>


OPTIONS
	-h 	Help page.
	-v 	Verbose.
	-V 	Script version."


#functions

#trap cleaning
cleanf()
{
	trap \   HUP INT TERM EXIT

	#clean up

	#clean up
	for r in "$TEMP_TARGET_FEED"
	do  [[ -f "$r" ]] && rm -- "$r"
	done
	unset r

	exit 0
}

#simple html filter
hf()
{
	sed 's/<[^>]*>//g' "$@"
}

#remove implicit refs .. and .
#ex: a/b/../img.gif -> a/img.gif
rmimpf()
{
	#repeat 3 times
	sed -E \
		-e 's|[^/]+/\.\./|| ;s|^\./|| ;s|/\./|/|' \
		-e 's|[^/]+/\.\./|| ;s|^\./|| ;s|/\./|/|' \
		-e 's|[^/]+/\.\./|| ;s|^\./|| ;s|/\./|/|' \
		<<<"$*"
}

#entity escaping
escf()
{
	local input
	input="$*"

	#escape to entity names
	#input="${input//&/&amp;}" 	#ampersand
	#input="${input//\'/&apos;}"	#less-than
	#input="${input//\"/&quot;}"	#greater-than
	#input="${input//>/&gt;}" 	#apostrophe
	#input="${input//</&lt;}" 	#quotation

	#apple podcasts require the following
	input="${input//©/&\#xA9;}" 	#copyright
	input="${input//℗/&\#x2117;}" 	#sound recording copyright
	input="${input//™/&\#x2122;}" 	#TM trademark

	echo "$input"
}

#tidy up markup
#unwrap html lines
unwrapf()
{
	#xmllint --format --nowrap --nowarning --recover
	tidy --quiet yes \
		--show-warnings no \
		--show-info no \
		--input-xml yes \
		--output-xhtml yes \
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

#parse options
while getopts hivV c
do
	case $c in
		h)
			#help
			echo "$HELP"
			exit 0
			;;
		i)
			#tidy up
			OPTI=0
			;;
		v)
			#verbose
			OPTV=1
			;;
		V)
			#print script version
			while IFS=  read -r
			do
				[[ "$REPLY" = \#\ v[0-9]* ]] && break
			done < "$0"
			echo "$REPLY"
			exit 0
			;;
		\?)
			exit 1
			;;
	esac
done
shift $(( OPTIND - 1 ))
unset c

#check for pkgs
for pkg in xmlstarlet tidy uuidgen ffmpeg  #mp3info  #xmllint
do
	if ! command -v "$pkg" &>/dev/null
	then echo "$SN: err: package missing -- $pkg" >&2 ;exit 1
	fi
done
unset pkg


#exit on any error
set -e

#changing to $ROOTP is required!
echo "$SN: change to podcast root -- $ROOTP" >&2
cd "$ROOTP"

#check for template files
for t in "$TEMPLATE_FEED"
do
	if [[ ! -f "$t" ]]
	then echo "$SN: template file missing -- $t" >&2 ;exit 1
	fi
done
unset t

#trap exit
trap cleanf HUP INT TERM EXIT


#PART ZERO: GET POST FILE LIST
echo "$SN: generate an array with raw post paths.." >&2
#make an array with raw post filepaths
typeset -a POSTFILES
while IFS=  read
do
	POSTFILES+=( "$REPLY" )
done <<< "$( print -l ep[0-9]*.xml | sort -n )"
unset REPLY

#check directory array is not empty
(( ${#POSTFILES[@]} )) || exit 1


#copy feed template
cp -fv "$TEMPLATE_FEED" "$TEMP_TARGET_FEED"


#PART ONE: PROCESS AND INJECT ENTRIES
echo "$SN: add item to rss feed for individual entries.." >&2
#episodes=( $( sed -nE 's|.*<itunes:episode>([^<]+)<.*|\1|p' "$POSTFILES[@]" | sort -n ) )
#lastp="$episodes[-1]" #last post number
#firstp="$episodes[1]"  #last post number
for f in "${POSTFILES[@]}"
do
	#declare arrays
	typeset -a size lowressize

	#counter
	((++n))

	#feedback
	((OPTV)) && eol='\n' || eol='\r'
	printf "${eol}${CLR}>>>%4d/%4d  %s  " "$n" "${#POSTFILES[@]}" "$f"  >&2

	#unwrapped html
	unwrapped="$( unwrapf "$f" )"

	#mp3 filename
	mp3file="$( <<<"$unwrapped" sed -nE 's|.*<enclosure.*url="([^"]+)".*|\1|p' )"
	mp3file="${mp3file##*/}"

	#title
	title="$( <<<"$unwrapped" sed -En 's|.*<title>(.*)</title>.*|\1|p' )"

	#episode description
	desc="$( <<<"$unwrapped" sed -En 's|.*<description>(.*)</description>.*|\1|p' )"

	#episode text link, if any
	link="$( <<<"$unwrapped" sed -En 's|.*<link>(.*)</link>.*|\1|p' )"

	#language
	lang="$( <<<"$unwrapped" sed -En 's|.*<dc:language>(.*)</dc:language>.*|\1|p' )"

	#size (human readable)
	size=( $( du -h "$mp3file" ) ) || exit

	#publication date
	pubDate_pre="$( <<<"$unwrapped" sed -nE 's|<pubDate>([^<]+)</pubDate>|\1|p' )"
	#print date and time in RFC 5322 format
	pubDate="$( date -R -d"$pubDate_pre" )" || echo -e "\a$SN: warning: cannot get publication date -- $f" >&2
	pubDate_index="$( date -d"$pubDate_pre" +%0d/%b/%Y )" || echo -e "\a$SN: warning: cannot get publication date -- $f" >&2

	#duration (human- readable)
	duration="$( ffprobe "$mp3file" 2>&1 | sed -En 's|Duration:\s*([0-9:.]+).*|\1|p' | sed 's/\.[0-9]*// ;s/\s*//g' )"
	duration="${duration#00:}" duration="${duration#0}"
	#duration (seconds)
	length="$( <<<"$duration" awk -F: '{ print ($1 * 3600) + ($2 * 60) + $3 }' )"
	#https://askubuntu.com/questions/407743/convert-time-stamp-to-seconds-in-bash

	#unique identifier
	#can be a permalink or a 16 byte string
	guidname=podcast
	guid="$( uuidgen -s -n @dns -N "${guidname}${n}" )"

	#check episode number
	episodenum="$( xmlstarlet sel -t -v '//item[1]/itunes:episode' "$f" 2>/dev/null )"

	#is there a low-resolution audio option?
	lowres="${mp3file%.*}low.${mp3file##*.}"
	if [[ -e "$lowres" ]]
	then
		lowressize=( $( du -h "$lowres" ) )
		lowresmainindex=", <em>low-res:</em> ${lowressize[1]} <a href=\"../podcast/${lowres}\">${lowres}</a>"
		lowrestumbleindex=", low-res: *${lowressize[1]}* [${lowres}](${lowres})"
	fi

	#unavailable messages
	unavailable="unavailable"
	unavailablerep="err  -- please report to publisher"


	#check all vars are set
	for var in \
		mp3file pubDate duration \
		length title lang size \
		pubDate_pre pubDate_index
	do [[ -z "${(P)var}" ]] && echo -e "\n\a$SN: unset var -- $var" >&2
	done
	#check if episode number is alright
	((episodenum == n)) || echo "\n\a$SN: warning: possibly wrong episode number ($episodenum vs. $n) -- $f" >&2


	#add item to xmls
	item="$( sed -nE '/<item/,/<\/item/ { /(<!-- #|^\s*$)/! p }' "$f" )"
	#item="$( xmlstarlet sel -t -c '//item' "$f" 2>/dev/null )"


	#add descriptional item (first channel)
	sed -i '/<\/generator/ r /dev/stdin' \
		"$TEMP_TARGET_FEED" <<<"$item"


	#MAIN FEED
	#update fields
	xmlstarlet ed -L  \
		-N googleplay='http://www.itunes.com/dtds/podcast-1.0.dtd' \
		-N itunes='http://www.itunes.com/dtds/podcast-1.0.dtd' \
		-N dc='http://purl.org/dc/elements/1.1/' \
		-u "//item[1]/pubDate" -v "${pubDate:-$unavailablerep}" \
		-u "//item[1]/itunes:duration" -v "${duration:-$unavailable}" \
		-u "//item[1]/enclosure/@length" -v "${length:-$unavailable}" \
		-u "//item[1]/guid" -v "${guid:-$unavailablerep}" \
		"$TEMP_TARGET_FEED"

	

	#PART TWO: PREPARE LIST FOR BLOG>PODCAST INDEX.HTML INJECTION
	mainindex="<li>
	<time class=\"dt-published\" datetime=\"${pubDate_pre}\">${pubDate_index}</time>
	<a class=\"p-name\" lang=\"pt\" hreflang=\"pt\" href=\"../podcast/${mp3file}\">
	${title}</a>,
	<strong>${duration}</strong>, ${size[*]}${lowresmainindex}

	</li>

	${mainindex}"



	#PART THREE: PREPARE LIST FOR TUMBLELOG INJECTION
	tumbleindex="${pubDate_pre} #${n} - ${title}
## ${title}

$desc

***[${mp3file}](${ROOTPW}/${mp3file})***, **${duration}**, *${size[1]}*${lowrestumbleindex}

${link+Supporting reference: <}${link}${link+>}
%
${tumbleindex}"


	unset f
	unset unwrapped mp3file duration length eol guidname guid episodenum
	unset var item title size lowres lowressize lowresmainindex lowrestumbleindex desc link
done
echo >&2
#XMLSTARTLET TIPS
#update the value:
#-u "//channel/link" -v "${ROOTW#/}/"
#remove item greater than 10:
#-d "//item[position()>10]"
#add CDATE array:
#-i "//item[1]/description/text()" -t text -n "" -v "<![CDATA["
#-a "//item[1]/description/text()" -t text -n "" -v "]]>"
#sed -i '/CDATA/ r /dev/stdin' "$TEMP_TARGET_FEED" <<<"$desc"


#update lastBuildDate in <channel> with last $DTPUB
#append timestamo to blog description
channeldesc="Podcast stream. Current as of $( date -R )."

xmlstarlet ed -L  \
	-u "//channel/description" -v "$channeldesc" \
	-u "//channel/lastBuildDate" -v "${pubDate:-$unavailable}" \
	"$TEMP_TARGET_FEED"

unset pubDate pubDate_pre pubDate_index unavailable unavailablerep channeldesc


#remove comments '<--! #' and remove empty lines
sed 's/<!-- #.*//' "$TEMP_TARGET_FEED" | awk NF >"$TARGET_FEED"



#PART TWO: UPDATE PODCAST LIST INDEX IN PODCAST/BLOG MAIN PAGE
echo "$SN: update podcast list (index.html)" >&2
TAGPZ='<!-- podcastlist -->'
TAGPX='<!-- podcastlistX -->'
mainindex="
	$TAGPX
	$mainindex
	$TAGPX"

#update files
sed -i "/$TAGPX/,/$TAGPX/ d" "$TARGET_INDEX"
echo -n "$mainindex" |
	sed -i "/^\s*$TAGPZ/ r /dev/stdin" "$TARGET_INDEX"

unset mainindex



#PART THREE: UPDATE TUMBLELOG
echo "$SN: update podcast list (index.html)" >&2
cd "$ROOTT"
channeldesc="Audio episodes of our podcast in which we talk about biology, science and free software."

#convert the SCSS style sheet to CSS
# adrift-in-dreams.scss 	black-and-white.scss
# floating-in-the-dark.scss 	happy-cat.scss
# ice.scss 			october.scss
# pages.scss 			soothe.scss
# steel.scss 			thought-provoking.scss
# tuesday.scss 			vector.scss
# wednesday.scss
style=steel
styletgt="$ROOTP/css/${style}.css"
[[ -e "$styletgt" ]] ||
	sass --sourcemap=none -t compressed styles/${style}.scss "$styletgt"

#generate pages
#perl tumblelog.pl  #requires perl-json-xs perl-path-tiny cmark
python3 tumblelog.py \
	--template-filename tumblelog.html \
	--output-dir ../ \
	--author 'Mountaineerbr' \
	--name 'Biology Blogger' \
	--description "$channeldesc" \
	--blog-url "$ROOTW" \
	--css "css/$style.css" \
	<( print -n "$tumbleindex" | sed "1 r /dev/stdin" "$ROOTT/tumblelog.md" | grep -v '^\s*<!--' )

#serve the generated blog site inside a web browser
#at <http://localhost:8000/> 
#cd htdocs ;python3 -m http.server #python3
#python -m SimpleHTTPServer 8000   #python2

unset f tumbleindex style channeldesc styletgt


#copy rss to secondary location
cp -fv "$TARGET_FEED" "$TARGET_FEED_SEC"

