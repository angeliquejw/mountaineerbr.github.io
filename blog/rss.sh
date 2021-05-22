#!/bin/zsh
# vim:ft=sh
# rss.sh -- BLOG RSS FEED SYSTEM
# v0.3.13  may/2021  mountaineerbr
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
#website blog root
ROOTBW="$ROOTW/blog"

#raw postfile name
RAWPOST_FNAME="i"
#for i.html or i.md

#template files
TEMPLATE_FEED="$ROOTB/r.xml"
#main feed location
TARGET_FEED="$ROOTB/rss.xml"
TEMP_TARGET_FEED="${TARGET_FEED}.tmp"
#alternative feed
TEMPLATE_FEED_ALT="$ROOTB/r_alt.xml"
TARGET_FEED_ALT="$ROOTB/rss_alt.xml"
TEMP_TARGET_FEED_ALT="${TARGET_FEED}_alt.tmp"

#clear everything on the line
CLR='\033[2K'

#help page
HELP="NAME
	$SN -- BLOG RSS FEED SYSTEM


SYNOPSIS
	$SN


	Generate XML code for RSS feeds in my website. This script will
	create <item> nodes, inject data, update <channel> information
	and generate a RSS file.

	Two RSS documents will be generated, the defaults/main one with
	short descriptions of post entries and an alternative one with
	full content of blog posts.

	The full content feed is much larger in size than the defaults
	feed (more than 10 times larger) and subscriber RSS parser may
	not parse all complex HTML code correctly.

	A template XML file for the RSS is required:
	${TEMPLATE_FEED} and ${TEMPLATE_FEED_ALT} .

	Human-readable time format shall defaults UTC-03.

	Package \`xmlstarlet' and \`uuidgen' are required.

	Package \`tidy' is required and it will tidy up the final generated
	pages for the feeds, unless option -i is set.


REFERENCES
	In case of Atom, you could even provide both in the same feed.
	Use a content element for the full content, and a summary element
	for the excerpt (I guess other feed formats allows this, too).
	<https://webmasters.stackexchange.com/questions/100290/duplicating-a-rss-feed-to-show-the-whole-post-in-addition-to-the-feed-showing-sn/100296#100296>

	Use Tidy to escape HTML code
	https://stackoverflow.com/questions/5272819/xmlstarlet-parser-error-entity-not-defined

	Don't forget to add RSS reference in <head> of index.html files
	<link rel=\"alternate\" type=\"application/rss+xml\" title=\"Biology Blog RSS\" href=\"rss.xml\">

	GUIDs
	<https://tools.ietf.org/html/rfc4122.html#section-4.3>
	<https://validator.w3.org/feed/docs/error/InvalidPermalink.html>
	<http://www.詹姆斯.com/blog/2006/08/rss-dup-detection>

	RSS and Atom
	<https://info.sice.indiana.edu/~dingying/Teaching/S604/RSS.ppt>
	<http://www.intertwingly.net/wiki/pie/Rss20AndAtom10Compared#major>
	<https://www.scriptol.com/rss/comparison-atom-rss-tags.php>
	<http://weblog.philringnalda.com/>

	SPECS
	RSS 1.0
	<http://web.resource.org/rss/1.0/spec>
	RSS 2.0
	<https://cyber.harvard.edu/rss/rss.html
	Atom
	<https://www.ietf.org/rfc/rfc4287.txt>
	<https://tools.ietf.org/rfc/rfc4287.txt>

	Atom xml:base attribute
	<https://tools.ietf.org/html/rfc4287>
	<https://www.odata.org/documentation/odata-version-2-0/atom-format/>
	<https://pythonhosted.org/feedparser/common-atom-elements.html>

	More
	<https://www.w3schools.com/xml/xml_rss.asp>
	<https://www.w3schools.com/xml/xpath_syntax.asp>
	<https://validator.w3.org/feed/docs/atom.html>
	<https://ddialliance.org/Specification/DDI-Codebook/2.5/XMLSchema/field_level_documentation_files/namespaces/http_purl_org_dc_elements_1_1/namespace-overview.html>
	<https://www.dublincore.org/specifications/dublin-core/dcmi-terms/>
	<https://stackoverflow.com/questions/24984162/xmlstarlet-utf-8-nordic-characters>
	<https://stackoverflow.com/questions/15400259/can-xmlstarlet-preserve-cdata-during-copy>
	<https://webmasters.stackexchange.com/questions/102139/can-a-website-have-multiple-rss-feeds-how-would-the-link-and-channel-elemen>


OPTIONS
	-f 	Force recompile html content for alt rss.
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
	for r in "$TMP1"
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

#parse options
while getopts hfivV c
do
	case $c in
		h)
			#help
			echo "$HELP"
			exit 0
			;;
		f)
			#force reprocess html content for alt rss feed
			OPTF=1
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
for pkg in xmlstarlet uuidgen curl tidy markdown
do
	if ! command -v "$pkg" &>/dev/null
	then
		echo "$SN: err: package missing -- $pkg" >&2
		[[ "$pkg" = markdown ]] || exit 1
	fi
done
unset pkg


#exit on any error
set -e

#changing to $ROOTB is required!
echo "$SN: change to blog root -- $ROOTB" >&2
cd "$ROOTB"

#check for template files
for t in "$TEMPLATE_FEED" "$TEMPLATE_FEED_ALT"
do
	if [[ ! -f "$t" ]]
	then echo "$SN: template file missing -- $t" >&2 ;exit 1
	fi
done
unset t

#trap exit
trap cleanf HUP INT TERM EXIT

echo "$SN: generate an array with raw post paths.." >&2
#make an array with raw post filepaths
#raw post = i.html
typeset -a POSTFILES
while IFS=  read
do
	POSTFILES+=( "$REPLY" )
done <<< "$( printf '%s\n' [0-9]*/"$RAWPOST_FNAME".(html|md) | sort -n )"
unset REPLY
#BASH# use: "$RAWPOST_FNAME".@(html|md)

#check directory array is not empty
(( ${#POSTFILES[@]} )) || exit 1


#copy feed templates
cp -fv "$TEMPLATE_FEED_ALT" "$TEMP_TARGET_FEED_ALT"
cp -fv "$TEMPLATE_FEED" "$TEMP_TARGET_FEED"

echo "$SN: add item to XML file for individual posts.." >&2
##lastp="${POSTFILES[0]%/*}" ;lastp="$( basename "$lastp" )"  #last post number
for f in "${POSTFILES[@]}"
do
	#counter
	((++n))

	#feedback
	((OPTV)) && eol='\n' || eol='\r'
	printf "${eol}${CLR}>>>%4d/%4d  %s  " "$n" "${#POSTFILES[@]}" "$f"  >&2

	#unwrapped html
	if [[ "$f" = *.md ]]
	then
		#if raw text is mardown
		unwrapped="$(markdown "$f" | unwrapf)"
	else
		#raw text is markup
		unwrapped="$(unwrapf "$f")"
	fi

	#author (e-mail address)
	auth="jamilbio20@gmail.com (JSN)"
	#consider using <dc:creator> tag instead

	#title
	pname="$( <<<"$unwrapped" sed -nE "1,/<h1/ s|.*<h1[^>]*>([^<]*)<.*|\1| p" )"
	pname="$( escf "$pname" )"

	#published date
	DTPUB="$( <<<"$unwrapped" sed -nE "1,/<time/ s|.*<time.*datetime=\"([^\"]+)\".*|\1| p" )"
	#print date and time in RFC 5322 format
	DTPUB="$( date -R -d"$DTPUB" )" || echo -e "\a$SN: warning: cannot get publication date -- $f" >&2

	#link
	link="${ROOTBW#/}/${f/${RAWPOST_FNAME}.(html|md)}"
	link="$( escf "$link" )"

	#post language
	lang="$( <<<"$unwrapped" sed -nE "s|<article\s*lang=\"([^\"]*)\".*|\1| p" )"
	lang="${lang:-en}"

	#unique identifier
	#can be a permalink or a 16 byte string
	guidname=blog
	guid="$( uuidgen -s -n @dns -N "${guidname}${n}" )"
	guidaltname=blogalt
	guidalt="$( uuidgen -s -n @dns -N "${guidaltname}${n}" )"

	#category
	catg="$( <<<"$unwrapped" sed -nE '/meta name="keywords/ s/.*content="([^"]+)".*/\1/ p' )"
	catg="${catg//, /,}"
	catg="${catg// ,/,}"
	catg="${catg//,//}"
	catg="$( escf "$catg" )"
	catg="${catg:-science}"

	#descriptions
	#MAIN FEED
	desc="$( <<<"$unwrapped" sed -nE '/meta name="description/ s/.*content="([^"]+)".*/\1/ p' )"
	desc="$( escf "$desc" )"

	#ALTERNATIVE FEED
	#only reprocess if
	if
		#buffer filename (as dotfile)
		fbuf="${f/${f##*\/}/.${f##*\/}}.rss.buf"
		#fbuf="${f%${f##*/}}.${${f##*/}%.*}.buf.rss.${f##*.}"

		#get post i.html and index.html modification timestamps
		stamp1=( $( stat --printf='%Y\n' "$f") )  #i.html
		[[ -e "$fbuf" ]] && stamp2=( $( stat --printf='%Y\n' "$fbuf") ) #processed buffer

		(( OPTF )) || 			#option -f
		[[ ! -e "$fbuf" ]] || 		#no buffer for cat.html
		(( stamp1 != stamp2 )) 		#i.html and index.html mod time differs
	then
		#generate buffer file
		<<<"$unwrapped" sed -n '/<article/,/<\/article>/ p' >"$fbuf"

		#fix relative references
		if changerefs="$( grep -nE "$p" "$fbuf" )"
		then
			p='(src|href)="'
			while IFS=  read -r
			do
				#line number
				l="$(cut -d: -f1 <<<"$REPLY" )"

				#get line reference sources
				while IFS=  read -r SRC
				do
					#check that file is downwards path
					if 
						#try inserting probable downwards path to post
						SRCCHANGE="$n/$SRC"
						[[ -f "$SRCCHANGE" ]]
					then
						#feedback
						((OPTV)) && eol='\n' || eol='\r'
						printf "${eol}${CLR}>>>file: %s  line: %3d  src: %s " "${fbuf#$ROOT}" "$l" "$SRC" >&2

						#insert downwards path to post
						#also insert website blog address
						SRCCHANGE="$ROOTBW/$SRCCHANGE"

						#clean url
						#remove implicit refs .. and .
						SRCCHANGE="$( rmimpf "$SRCCHANGE" )"

						#change it
						sed -i -E "${l}s,(${p})(${SRC}),\1${SRCCHANGE}," "$fbuf"
					fi
				done <<<"$( sed -n -E "s,.*${p}([^\"]*)\".*,\2,g p" <<<"$REPLY" )"
			done <<<"$changerefs"
		fi


		#keep timestamps in sync
		#clone file attributes (such as modification date)
		touch -r "$f" "$fbuf"
	fi
	#load buffer into var
	descalt="$( <"$fbuf" )"

	#add media (enclosure)
	enc="$( <<<"$unwrapped" sed -nE '1,/<img/ s/.*<img.*src="([^"]+)".*/\1/ p' )"
	ext=${enc##*.}
	#if there is any result
	if [[ -n "$enc" ]]
	then
		if
			#try inserting probable downwards path to post
			#and get size of file
			encchange="$n/$enc"
			encsize=( $( du -b "$encchange" 2>/dev/null) )
		then
			#insert downwards path to post
			#also insert website blog address
			enc="$ROOTBW/$encchange"

			#clean url
			#remove implicit refs .. and .
			enc="$( rmimpf "$enc" )"

		else
			TMP1="$ROOTB/image.temp.buffer"
			curl -\# "$enc" -o "$TMP1" 2>/dev/null &&
				encsize=( $( du -b "$TMP1" 2>/dev/null ) )
		fi
	fi

	#unavailable messages
	unavailable="unavailable"
	unavailablerep="err  -- please report to ${auth:-${creator:-publisher}}"


	#check all vars are set
	for var in \
		auth pname DTPUB link lang \
		guid guidalt desc descalt catg
	do [[ -z "${(P)var}" ]] && echo -e "\n\a$SN: unset var -- $var" >&2
	done
	#bash parameter indirection: "${!var}"
	#https://unix.stackexchange.com/questions/68035/foo-and-zsh


	#add item to xmls

	#MAIN FEED
	#use xmlstarlet
	#great tool, only for simple RSS document
	xmlstarlet ed -L  \
		-a "//generator" -t elem -n item -v ""  \
		-s "//item[1]" -t elem -n title -v "${pname:-$unavailablerep}" \
		-s "//item[1]/title" -t attr -n xml:lang -v "${lang:-en}" \
		-s "//item[1]" -t elem -n pubDate -v "${DTPUB:-$unavailable}" \
		-s "//item[1]" -t elem -n description -v "${desc:-$unavailablerep}" \
		-s "//item[1]" -t elem -n link -v "${link:-$ROOTBW}" \
		-s "//item[1]" -t elem -n dc:language -v "${lang:-en}" \
		-s "//item[1]" -t elem -n category -v "${catg:-$unavailable}" \
		-s "//item[1]" -t elem -n author -v "${auth:-mountaineerbr}" \
		-s "//item[1]" -t elem -n guid -v "${guid:-$unavailable}" \
		-a "//item[1]/guid" -t attr -n isPermaLink -v false \
		"$TEMP_TARGET_FEED"

	#add enclosure?
	(( encsize[1] )) \
		&& xmlstarlet ed -L  \
		-s "//item[1]" -t elem -n enclosure -v ""  \
		-a "//item[1]/enclosure" -t attr -n url -v "$enc" \
		-a "//item[1]/enclosure" -t attr -n length -v "${encsize[1]:-10}" \
		-a "//item[1]/enclosure" -t attr -n type -v "image/${ext:-gif}" \
		"$TEMP_TARGET_FEED"



	#ALTERNATIVE FEED
	#use shell tools for complex RSS document
	itemalt="	<item>
		<title xml:lang=\"${lang:-en}\">${pname:-$unavailablerep}</title>
		<pubDate>${DTPUB:-$unavailable}</pubDate>
		<link>${link:-$ROOTBW}</link>
		<dc:language>${lang:-en}</dc:language>
		<category>${catg:-$unavailable}</category>
		<author>${auth:-mountaineerbr}</author>
		<guid isPermaLink=\"false\">${guidalt:-$unavailable}</guid>
		<description><![CDATA[ ${descalt:-$unavailablerep} ]]></description>
	</item>"
	#itemaltenc="        <enclosure url=\"$enc\" length=\"${encsize[1]:-10}\" type=\"image/${ext:-gif}\"/>"
	#obs: cannot have `]]>'  inside CDATA
	#`]&gt;' is an acceptable means of encoding a CDEnd within a CDATA

	#add descriptional item (first channel)
	sed -i '/<!-- additemsfull -->/ r /dev/stdin' \
		"$TEMP_TARGET_FEED_ALT" <<<"$itemalt"

	#add enclosure to alternative feed?
	#(( encsize[1] )) &&
	#	sed -i '/<!-- additemsfull -->/ r /dev/stdin' \
	#	"$TEMP_TARGET_FEED_ALT" <<<"$itemaltenc"



	unset f l u 
	unset REPLY SRC SRCCHANGE
	unset eol enc encsize ext auth pname link guid guidalt guidname guidaltname
	unset fbuf desc descalt catg changerefs enc ext encsize itemalt itemaltenc lang var unwrapped
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
channeldesc="Current as of $( date -R )."

#MAIN FEED
xmlstarlet ed -L  \
	-u "//channel/description" -v "$channeldesc" \
	-u "//channel/lastBuildDate" -v "${DTPUB:-$unavailable}" \
	"$TEMP_TARGET_FEED"


#ALTERNATIVE FEED
sed -Ei \
	-e "1,/<description>/ s|(<description>)([^<]*)(</description>)|\1${channeldesc}\3|" \
	-e "s|(<lastBuildDate>)([^<]*)(</lastBuildDate>)|\1${DTPUB:-$unavailable}\3|" \
	"$TEMP_TARGET_FEED_ALT"

#rename to final rss.xml and rss_alt.xml
mv -fv "$TEMP_TARGET_FEED" "$TARGET_FEED"
mv -fv "$TEMP_TARGET_FEED_ALT" "$TARGET_FEED_ALT"

#unset DTPUB channeldesc

