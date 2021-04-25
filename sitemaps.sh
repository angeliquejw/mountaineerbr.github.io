#!/bin/bash
# sitemap.sh -- SITEMAP SYSTEM
# v0.4.15  apr/2021  by mountaineerbr
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

#find files with these extensions
EXTENSIONS=( htm html php asp aspx jsp )
#exclude patterns from the sitemaps
EXARR=(
	#valid pattern must run in `sed -E "s,PATTERN,,"`
	#do escape \ as \\

	'index\.html$' 		#don't add index.html but their parent dir only
	'.*/[._].*' 		#files starting with either . or (hidden or unlisted)
	'.*/[a-z]/.*' 		#template files such as a.html, z.html, etc
	'.*/[a-z]\.html$'  	#unlisted directories
	'.*/bak/.*' 		#backup directory
	'.*/css/.*' 		#css stuff
	'.*/gfx/.*' 		#graphics
	'.*/js/.*' 		#java script shit
	'.*/misc/.*' 		#miscellaneous dir
	'.*/res/.*' 		#general resources dir
	'.*/PMWMT/.*' 		#some stuff i got from poor man's webmaster tools
	'.*/business/.*' 	#under construction
	'.*/podcast/archive.*' 	#podcast files
	'.*/podcast/tumblelog.*' 	#podcast files

	'.*/fool\.html$' 	#this is a redirection page --> fool/index.html
	'.*google.*' 		#google shit
)

#exts for `tree` (should be equivalent to $EXTENSIONS)
EXTENSIONSTREE='*.htm|*.html|*.php|*.asp|*.aspx|*.jsp|sitemap.txt|rss.xml|rss_alt.xml|rss_podcast.xml'
#exclude for `tree` (should be equivalent to $EXARR[@])
EXTREE='[._]*|[a-z].html|[a-z]|index.html|bak|css|gfx|js|misc|res|PMWMT|business|archive|tumblelog|fool.html|google*'

#sitemap files
#txt
SMAPTXT="$ROOT/sitemap.txt"
#xml
SMAPXML="$ROOT/sitemap.xml"
#html (directory tree)
SMAPTREE="$ROOT/sitemap.html"

#temporary found files
SMAPFILES="$ROOT/sitemap.files.txt"

#clear everything on the line
CLR='\033[2K'

#xml tags for skel
XMLHEAD='<?xml version="1.0" encoding="utf-8"?>
<urlset>'
XMLTAIL='</urlset>'
#xml schema for namespaces (xmlns attribute)
XMLSCHEMA='http://www.sitemaps.org/schemas/sitemap/0.9'
XMLWARNING='	<!--

	  Hey!
	  This web page is actually a data file that is meant to be
	   read by RSS reader programs.
	  See https://mountaineerbr.github.io/sitemap.html to go to
	   the human-readable sitemap page.

	-->'
#https://infinitesticks.com/2018/07/generate-a-list-of-urls-from-a-sitemap

#html tags for injection
HTMLHEAD='<meta http-equiv="content-type" content="text/html; charset=UTF-8">
<title>Website map, navigate to all pages</title>
<meta name="resource-type" content="document">
<meta name="description" content="Site map for human visitors; this navigation page may be preferable for some people to use">
<meta name="keywords" content="navigation, navegação, accessibility, acessibilidade, interface, alternativo, alternative, user navigation, navegação de usuário, discover the webste, descubra o website">
<meta name="distribution" content="global">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<!-- <link rev="made" href="mailto:jamilbio20[[at]]gmail[[dot]]com"> -->
<link rel="shortcut icon" href="favicon.ico" type="image/x-icon">
<style>
	H1, H1 + P
	{
		margin: 1em 0 1em 4em;
	}
</style>'

#google analytics
GANALYTICS="<!-- Google Analytics -->
	<!-- Global site tag (gtag.js) -->
	<!-- uBlock seems to blocks this -->
	<script async src=\"https://www.googletagmanager.com/gtag/js?id=UA-177031288-1\"></script>
	<script>
	  window.dataLayer = window.dataLayer || [];
	  function gtag(){dataLayer.push(arguments);}
	  gtag('js', new Date());

	  gtag('config', 'UA-177031288-1');
	</script>
	<!-- Google Analytics -->"


#help page
HELP="NAME
	$SN -- SITEMAP SYSTEM


SYNOPSIS
	$SN

	Based on Google & Bing's sitemap guidelines. In short,  XML site-
	maps shouldn't contain more than 50,000 URLs and should be no
	larger than 50M when uncompressed. In case of a larger site with
	many URLs, multiple sitemap files should be created. Their size
	should be no more than 10M(safer)-50M uncompressed or 50K links
	each.

	It is necessary to verify ownership and submit sitemap.xml to
	search engines as they may not read sitemap.xml by defaults.

	Don't forget to add the \`Sitemap' entry to robots.txt. Take
	notice that base URLs matter (http vs https).

	Human-readable time format should defaults to UTC0 when printed.

	Initial ideas were taken from \`Poor Man's Webmaster Tools'.
	Special thanks goes to Koen Noens for the scripts.


REFERENCES
	Localised versions (alternative languages)
	<https://support.google.com/webmasters/answer/189077#sitemap>

	Google
	ping: <http://www.google.com/ping?sitemap=https://example.com/sitemap.xml>
	<https://support.google.com/webmasters/answer/183668?hl=en#addsitemap>
	<https://search.google.com/search-console/sitemaps>

	Bing & Yahoo!
	ping: <http://www.bing.com/ping?sitemap=http%3A%2F%2Fwww.example.com/sitemap.xml>
	<https://www.bing.com/webmaster/help/how-to-submit-sitemaps-82a15bd4>
	<https://www.bing.com/webmasters/sitemaps>

	Duckduckgo
	<<We get our results from multiple sources so there's no place to
	submit them to DuckDuckGo directly. Once your site is indexed by
	our sources, it should show on DuckDuckGo correctly.>>

	<<There's no direct way to submit your website URL to Yahoo! and
	AOL. All search results at Yahoo! and AOL are now powered by Bing.
	Ask.com no longer allows you to submit sitemaps.>>

	Ask.com
	<<Launch your Web browser and copy and paste the entire submission URL,
	including your sitemap, into the browser address bar and press Enter.
	A confirmation message from Ask.com appears in the browser.>>
	ping: <http://submissions.ask.com/ping?sitemap=http://<The Domain Name>/sitemapxml.aspx>
	ping: <http://submissions.ask.com/ping?sitemap=http%3A//www.URL.com/sitemap.xml>

	More
	<https://www.sitemaps.org/protocol.html>
	<https://support.google.com/webmasters/answer/183668?hl=en>
	<https://www.bing.com/webmaster/help/sitemaps-3b5cf6ed>


OPTIONS
	-h 	Help page.
	-v 	Verbose.
	-V 	Script version."


#functions

#entity escaping
#and change local path to site url
escf()
{
	local input
	input="$1"

	#change local root to website root
	input="${input/"$ROOT"/"$ROOTW"}"

	#escape to entity names
	input="${input//&/&amp;}" 	#ampersand
	input="${input//\'/&apos;}"	#less-than
	input="${input//\"/&quot;}"	#greater-than
	input="${input//>/&gt;}" 	#apostrophe
	input="${input//</&lt;}" 	#quotation

	input="${input//©/&\#xA9;}" 	#copyright
	input="${input//℗/&\#x2117;}" 	#sound recording copyright
	input="${input//™/&\#x2122;}" 	#TM trademark

	echo "$input"
}


#start

#parse options
while getopts hvV c
do
	case $c in
		h)
			#help
			echo "$HELP"
			exit 0
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
for pkg in xmlstarlet tree   #tidy
do
	if ! command -v "$pkg" &>/dev/null
	then echo "$SN: err: package missing -- $pkg" >&2 ;exit 1
	fi
done
unset pkg


#exit on any error
set -e



#PART ZERO
#make file lists

#cd into webpage root directory
cd "$ROOT"

#remove previously generated files
for r in "$SMAPTXT" "$SMAPXML" "$SMAPTREE" "$SMAPFILES"
do
	[[ -f "$r" ]] || continue
	rm -v "$r"
	: >"$r"
done
unset r

#find files
#ignore file path with /. (hidden files and directories)
for ext in "${EXTENSIONS[@]}"
do
	find "$ROOT" \( ! -path '*/.*' \) -name "*.$ext" >>"$SMAPFILES"
done
unset ext
#https://superuser.com/questions/152958/exclude-hidden-files-when-searching-with-unix-linux-find
#add slash after directories
#find "$ROOT" \( ! -path '*/.*' \) -type d -exec sh -c 'printf "%s/\n" "$0"' {} \;
#https://unix.stackexchange.com/questions/4847/make-find-show-slash-after-directories

#add items to sitemap files
#these files may not have been included.
#for sitemap.txt and sitemap.xml
cat >> "$SMAPFILES" <<!
$SMAPTXT
$SMAPTREE
$SMAPXML
$ROOTB/rss.xml
$ROOTB/rss_alt.xml
$ROOTB/rss_podcast.xml
!

#exclude list
#run the exclusion array
echo "$SN: removing entries matching exclusion criteria.." >&2
empty=""
for entry in "${EXARR[@]}"
do
	#counter
	((++e))
	((ee=ee+1))

	#feedback
	printf "\r${CLR}>>>%4d/%4d  %s  " "$e" "$ee" "$entry" >&2
	sed -i -E "s,$entry,$empty,g" "$SMAPFILES"
done
echo >&2
unset empty entry e ee

#remove blank lines from path lists
sed -i '/^\s*$/d' "$SMAPFILES"

#sort path lists
sort -f -V -u -o "$SMAPFILES" "$SMAPFILES"



#PART ONE
#TXT
#change site root to build urls
sed "s,$ROOT,$ROOTW," "$SMAPFILES" > "$SMAPTXT"



#PART TWO
#XML

#make timestamp
TS="$( date -u -Isec )"
#get total links
TOTAL="$( wc -l <"$SMAPFILES" )"

#make xml skeleton
cat >"$SMAPXML" <<-!
$XMLHEAD
$XMLWARNING
$XMLTAIL
<!-- generated-on="$TS" -->
<!-- items="$TOTAL" -->
!

#inject url entries
echo "$SN: inject url entries in XML.." >&2
while IFS=  read
do
	#counter
	(( ++n ))

	#feedback
	((OPTV)) && eol='\n' || eol='\r'
	printf "${eol}${CLR}>>>%4d/%4d  %s  " "$n" "$TOTAL" "$REPLY"  >&2

	#escape urls
	URL="$( escf "$REPLY" )"

	#last modification date
	if [[ -e "$REPLY" ]]
	then
		MOD="$( stat --format="%Y" "$REPLY" )"
		MOD="$( date -u -Isec -d@"$MOD" )"
	else
		MOD="$( date -u -Isec )"
	fi

	xmlstarlet ed -L \
		-s "//urlset" -t elem -n url -v "" \
		-s "//url[$n]" -t elem -n loc -v "$URL" \
		-s "//url[$n]" -t elem -n lastmod -v "$MOD" \
		"$SMAPXML"

done <"$SMAPFILES"
echo >&2

#clean up
rm -v "$SMAPFILES"

#add xmlns attribute to urlset element with namespace
xmlstarlet ed -L \
	-a "/urlset" -t attr -n xmlns -v "$XMLSCHEMA" \
	"$SMAPXML"

unset REPLY n URL ALT MOD TS
#optional attributes:
#lastmod, changefreq and priority



#PART THREE
#HTML (use relative paths!)
#create directory tree
echo "$SN: create sitemap.html with  \`tree' package.." >&2
#remove default meta tags
tree -r -H "." -P "$EXTENSIONSTREE" -I "$EXTREE" \
	-T Sitemap -L 6 -F -v --noreport --charset utf-8 |
	sed '/<meta/,/<title/ d' > "$SMAPTREE"

#hack `tree' output
echo "$SN: hack \`tree' output" >&2
echo "$SN: injecting my own meta tags.." >&2
#add custom meta tags
sed -i '/<head>/ r /dev/stdin' "$SMAPTREE" <<<"$HTMLHEAD"
#add google analytics
#sed -i -e '/<\/body>/ r /dev/stdin' -e '//d' "$SMAPTREE" <<!
#
#<footer>
#$GANALYTICS
#</footer>
#</body>
#
#!

#tip: sed `//d' removes last expression



#PART FOUR
#optionally ping search engines with HTTP GET request
#or submit sitemap to their respective webmaster tools pages


