#!/bin/zsh
# vim:ft=sh
# blog.sh -- BLOG POSTING SYSTEM
# v0.6.5  apr/2021  mountaineerbr
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

#template files
TEMPLATE_POST="$ROOTB/p.html"
TEMPLATE_CAT="$ROOTB/c.html"
TEMPLATE_CREAT="$ROOTB/a"  #directory template

#raw postfile name
RAWPOST_FNAME="i.html"

#set targets
#post titles
TARGET_TITLES="$ROOTB/titles.txt" 		#this is the full postlist
TARGET_TITLES_HOME="$ROOTB/titles.homepage.txt"	#this is the lastest 10 posts list
TARGET_TITLES_PLAIN="$ROOTB/titles.plain.txt" 	#index table for own use
TARGET_TITLES_TEMP="${TARGET_TITLES}.new" 	#buffer
#all posts
TARGET_CAT="$ROOTB/cat.html"
#blog index
TARGET_BLOGIND="$ROOTB/index.html"

#target home page index.html
TARGET_HOME="$ROOT/index.html"

#tidy up post and cat.html
OPTI=1

#log file
LOGFILE="$ROOTB/$SN.log.txt"
TIDY_ERRFILE="$ROOTB/$SN.log.tidy.txt"

#clear everything on the line
CLR='\033[2K'

#help page
HELP="NAME
	$SN - Blog posting system


SYNOPSIS
	$SN [-a] [POST TITLE]
	$SN [-fitv]
	$SN [-hV]


DESCRIPTION
	This script manages the blog page of my website.

	Executing functions:
		0)  Preparation; check template files, set variable names
			and paths, temp files.
		1)  Compile individual post pages, prepare buffers
			for cat.html; make page <TITLE> from the source
			<H1> tag and compile post index.html from sources
			and templates.
		2)  Prepare more buffers for cat.html; fix relative paths
			of source references.
		3)  Make post title list.
		4)  Update blog post titles in /blog/index.html.
		5)  Update blog post titles in homepage /index.html; only
			ten most recent posts, also fixes references to
			post pages under /blog/ .
		6)  Miscellaneous tasks; clean up, final checks and
			warnings.


	UPPERCASE tags will not be processed by this script, so you
	may use uppercase tags to write examples in inside <PRE> tags,
	etc.

	Tags <LINK> and <SCRIPT> in the head section of $RAWPOST_FNAME files
	will be checked and added to cat.html head.

	Keep java scripts in the /blog/js/ directory, so they can be
	used in mutiple pages and add <SCRIPT> close to the </ARTICLE>
	end tag.

	The script will check for some errors and warnings. Some of the
	warnings do not cause problems but may need or not be addressed
	sometime in the future. Log file at ${LOGFILE} .

	We are using package \`tidy' so many would be errors for processing
	are no more, for example, important tags such as description do
	not need be in a single line anymore.

	Tidy will tidy up the final generated pages, unless option -i is set.

	Option -a will create a new post from template directory,
	defaults template dir=$TEMPLATE_CREAT .

	Inspired by the Poor Man Wemaster Tools from the Silly Software
	Company.


DIRECTORY AND FILE STRUCTURE
	Blog post directories start with a number /[0-9]* . The post
	directory must hold an $RAWPOST_FNAME file, which is a clone from
	template which will hold the author raw text for the post
	within <ARTICLE> tags as well as additional metatags at the
	<HEAD> section, such as . Filepath ex: blogRootDir/1/$RAWPOST_FNAME

	$RAWPOST_FNAME files are processed/compiled to generate index.html
	files at the same directory as their post source. A copy of
	the articles are prepared (source attributes are fixed, etc)
	for concatenation at a later stage.

	The script timestamps generated files and checks last modified
	date against source files and only re-process them if they
	differ or buffer files from last run are missing, which speeds
	re-running the script.

	Previously generated files are replaced with new ones.


ENVIRONMENT
	VISUAL 		New posts created with -a will be edited with text
			editor set in \$VISUAL, otehrwise uses vim.


REFERENCES
	Poor Man Wemaster Tools
	<http://users.telenet.be/mydotcom/howto/www/tools.htm>

	Roman Zolotarev's ss5
	<https://www.romanzolotarev.com/ssg.html>

	Slackjeff's hacktuite
	<https://github.com/slackjeff/hacktuite>

	More
	<https://unix.stackexchange.com/questions/502230/how-to-apply-sed-if-it-contains-one-string-but-not-another/502233>


WARRANTY
	Licensed under the GNU Public License v3 or better and is
	distributed without support or bug corrections.

	This script requires ?? and ?? to work properly.

	If you found this useful, please consider giving me a nickle!
		=)

		bc1qlxm5dfjl58whg6tvtszg5pfna9mn2cr2nulnjr


BUGS
	The script needs more testing.

	Usage may not be much comprehensible.


OPTIONS
	-a [TITLE]
		Creates a new post from template, optionally add TITLE.
	-f 	Force recompile post index.html files.
	-h 	Help page.
	-i 	Do not use tidy up generated pages.
	-t 	Update mod time of $RAWPOST_FNAME and the new index.html with
		old index.html timestamp; this avoids sitemap.xml up-
		dating blog page timestamps.
	-v 	Verbose mode, debug; log file=${LOGFILE} .
	-V 	Script version."


#functions
cleanf()
{
	trap \   HUP INT TERM EXIT


	#PART LAST
	#clean up
	#set nullglob
	(( ZSH_VERSION )) && setopt nullglob || shopt -s nullglob

	#clean up
	for r in \
		"$TMP" \
		"$TARGET_TITLES_HOME" \
		"$TARGET_TITLES_TEMP" \
		"$ROOTB"/*/.*.part
	do
		[[ -f "$r" ]] && rm -- "$r"
	done
	unset r
	#"$TARGET_TITLES"

	#more checks
	for log in "$LOGFILE" "$TIDY_ERRFILE"
	do
		if [[ -s "$log" ]]
		then
			#code=1
			echo -e "\a$SN: WARNING: check log -- $log" >&2
			((OPTV)) && echo && cat -- "$log"
		elif [[ -f "$log" ]]
		then
			rm -- "$log"
		fi
	done
	print

	exit "${code:-0}"
}


#create a new post from template dir
creatf()
{
	local tgt tgti postn stamp1 stamp2 var title templdir desc keywords

	templdir="$TEMPLATE_CREAT" templdir="${templdir%/}/"
	((LASTP)) || { print "$SN: cannot get last post index -- $LASTP" >&2 ;return 1 ;}
	[[ -d "$templdir" ]] || { print "$SN: template dir not found -- $templdir" >&2 ;return 1 ;}
	postn=$((LASTP+1)) || return
	tgt="${templdir%/a/}" tgt="${tgt}/$postn"
	tgti="${tgt}/i.html"
	stamp1="$(date +%Y-%m-%d)" stamp2="$(date +%d/%b/%Y)"
	title="$*" ;[[ -z "$title" ]] && { echo "Type a post TITLE (optional):" >&2 ;vared -c title ;}
	[[ -z "$desc" ]] && { echo "Type a post DESCRIPTION (optional):" >&2 ;vared -c desc ;}
	[[ -z "$keywords" ]] && { echo "Type post KEYWORDS, use comma for multiple (optional):" >&2 ;vared -c keywords ;}

	#check all required vars are set
	for var in postn tgt tgti stamp1 stamp2
	do [[ -z "${(P)var}" ]] && echo -e "\n\a$SN: unset var -- $var" >&2 | tee "$LOGFILE" && return 1
	done

	#copy template and rename new directory with post number
	cp -vr "$templdir" "$tgt"

	#update post id, post #number and TITLE in in i.html
	((OPTV)) && echo "$SN: update post id, #NUM, TITLE, DESCRIPTION and KEYWORDS -- $tgti" >&2
	if [[ -n "$title" ]]
	then sed -i -E "s/id=\"[0-9?]*\">#[^<]*/id=\"$postn\">#$postn - $title/" "$tgti"
	else sed -i -E "s/id=\"[0-9?]*\">#[0-9?]*/id=\"$postn\">#$postn/" "$tgti"
	fi
	[[ -n "$desc" ]] &&
		sed -i -E "/name=\"description/ s/(content=\")([^\"]*)/\1$desc/" "$tgti"
	[[ -n "$keywords" ]] &&
		sed -i -E "/name=\"keywords/ s/(content=\")([^\"]*)/\1$keywords/" "$tgti"

	#update date in i.html
	((OPTV)) && echo "$SN: update time stamps -- $tgti" >&2
	sed -i -E "s|datetime=\"[mMyYdD0-9?/-]*\">[mMyYdD0-9a-zA-Z?/-]*<|datetime=\"$stamp1\">${stamp2:l}<|" "$tgti"

	#first post edit
	((OPTV)) && echo "$SN: post editor -- ${VISUAL:-vim}" >&2
	"${VISUAL:-vim}" "$tgti"
	
	echo "post: $tgti" >&2
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

#unwrap html lines
unwrapf()
{
	tidy --quiet yes \
		--show-warnings no \
		--show-info no \
		--wrap 0 \
		--wrap-attributes no \
		--tidy-mark no \
		--show-body-only yes \
		--preserve-entities yes \
		--quote-ampersand yes \
		--quote-marks yes \
		--quote-nbsp yes \
		-- "$@" || true
}

#tidy up files
tidyupf()
{
	local warnings

	tidy --quiet yes \
		--show-warnings no \
		--show-info no \
		--wrap 68 \
		--break-before-br yes \
		--fix-style-tags yes \
		--fix-uri yes \
		--vertical-space yes \
		--hide-comments no \
		--tidy-mark yes \
		--preserve-entities yes \
		--quote-ampersand yes \
		--write-back yes \
		-- "$@"

	warnings="$(
		tidy -errors -q "$@" |&
		grep -v \
		-e 'Warning: unescaped &' \
		-e 'proprietary attribute "hreflang"'
		)"


	if [[ -n "$warnings" ]]
	then
		cat >>"${TIDY_ERRFILE:-/dev/null}" <<-!
		File: $*
		$warnings

		!

		return 1
	fi
	
	return 0
}

tidyerrf()
{
	tidy -errors -q -f "${TIDY_ERRFILE:-/dev/null}" "$@"
}
#https://stackoverflow.com/questions/1837624/validating-html-from-the-command-line

#start

#parse options
while getopts afhitvV c
do
	case $c in
		a)
			#create a new post?
			OPTA=1
			;;
		h)
			#help
			echo "$HELP"
			exit 0
			;;
		f)
			#force recompile post index.html files
			OPTF=1
			;;
		i)
			#tidy up
			OPTI=0
			;;
		t)
			#keep old mod time
			OPTT=1
			;;
		v)
			#debug, verbose mode
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
for pkg in tidy
do
	if ! command -v "$pkg" &>/dev/null
	then echo "$SN: err: package missing -- $pkg" >&2 ;exit 1
	fi
done
unset pkg


#PART ZERO
#preparation

if (( ZSH_VERSION ))
then
	#zsh is a little faster
	setopt PIPE_FAIL KSH_ZERO_SUBSCRIPT
else
	#bash
	shopt -o pipefail
fi

#exit on any error
set -e

#trap exit
trap cleanf HUP INT TERM EXIT

#generic buffer temp file
TMP="$( mktemp )"

#remove existing warning log file
[[ -e "$LOGFILE" ]] && rm -- "$LOGFILE"
[[ -e "$TIDY_ERRFILE" ]] && rm -- "$TIDY_ERRFILE"

#changing to $ROOTB is required!
echo "$SN: change to website root -- $ROOTB" >&2
cd "$ROOTB"

#check for template files
for t in "$TEMPLATE_CAT" "$TEMPLATE_POST"
do
	if [[ ! -f "$t" ]]
	then echo "$SN: Template file missing -- $t" >&2 ;exit 1
	fi
done
unset t


echo "$SN: generate an array with raw post paths.." >&2
#make an array with raw post filepaths
typeset -a POSTFILES
while IFS=  read
do
	POSTFILES+=( "$REPLY" )
done <<< "$( printf '%s\n' [0-9]*/"$RAWPOST_FNAME" | sort -nr )"
unset REPLY

#check directory array is not empty
(( ${#POSTFILES[@]} )) || exit 1



echo "$SN: compile index.html files for individual posts.." >&2
#set vars
LASTP="${POSTFILES[0]%/*}" 	#last post number
LASTP="$( basename "$LASTP" )"  #last post number
n="$LASTP" 			#post counter (starts from last post number)
m=1 				#first post number

#-a function: create new post only?
if ((OPTA))
then creatf "$@" ;exit
fi

for f in "${POSTFILES[@]}"
do
	#PART ONE
	#make post html pages from templates
	#set post index.html path
	targetpost="${f/$RAWPOST_FNAME/index.html}"
	#partial/buffer file
	TEMP_TARGETPOST="${f/$RAWPOST_FNAME/.index.html.part}"
	#cat.html-specific
	TEMP_TARGETCAT="${f/$RAWPOST_FNAME/.index.html.cat}"

	#array with buffer files for cat.html
	CATFILES+=( "$TEMP_TARGETCAT" )

	#skip this step if any buffer files are present and
	#source and target post files have the same last-changed time
	#MUST KEEP BUFFER FILES FOR CAT.HTML AT CLEAN UP..
	if
		#get post i.html and index.html modification timestamps
		stamp1=( $( stat --printf='%Y\n' "$f") )  #i.html
		[[ -f "$targetpost" ]] && stamp2=( $( stat --printf='%Y\n' "$targetpost") ) #old index.html

		(( OPTF )) || 			#option -f
		[[ ! -f "$TEMP_TARGETCAT" ]] || #no buffer for cat.html
		[[ ! -f "$targetpost" ]] || 	#no target post index.html
		(( stamp1 != stamp2 )) || 	#i.html and index.html mod time differs
		{ (( n < LASTP )) && ! grep -q 'w3-bar-item.*>Next<' "$targetpost" ;} #has the post got the NEXT nav button yet?
	then
		#feedback
		((OPTV)) && eol='\n' || eol='\r'
		printf "${eol}${CLR}>>>%3d/%3d  %s " "$n" "${#POSTFILES[@]}" "$f" >&2

		#get unwrapped content
		unwrapped="$(unwrapf "$f")"

		#add title and meta tags to buffer file
		sed -n '/<head>/,/<\/head>/ p' "$f" |
			sed 's/<\/*head>// ;/^\s*$/d' |
			sed '/<!-- metatags -->/ r /dev/stdin' \
			"$TEMPLATE_POST" >"$TEMP_TARGETPOST"

		#add self-referencing canonical url
		canonical="<link rel=\"canonical\" href=\"${ROOTBW%/}/$n/\">"
		sed -i '/<!-- metatags -->/ r /dev/stdin' \
			"$TEMP_TARGETPOST" <<<"$canonical"

		#make and entry title tag from article>header>h1+time
		title="$( <<<"$unwrapped" sed -nE '/<header>/,/<\/header>/ s|.*h1[^>]*>([^<]*)<.*|\1| p' )"
		time="$( <<<"$unwrapped" sed -nE '/<header>/,/<\/header>/ s|.*<time[^>]*>([^<]*)<.*|\1| p' )"
		sed -i '/<!-- metatags -->/ r /dev/stdin' \
			"$TEMP_TARGETPOST" <<<"<title>$time $title</title>"

		#add article and create final html page
		sed -n '/<article/,/<\/article>/ p' "$f" |
			sed '/<!-- article -->/ r /dev/stdin' \
			"$TEMP_TARGETPOST" >"$targetpost"
		#https://stackoverflow.com/questions/46423572/append-a-file-in-the-middle-of-another-file-in-bash

		#add navigation items
		(( n == ${#POSTFILES[@]} )) ||
			next="<a class=\"w3-bar-item w3-right\" href=\"../$((n+1))/\">Next</a>"
		(( n == m )) ||
			prev="<a class=\"w3-bar-item w3-right\" href=\"../$((n-1))/\">Previous</a>"

		sed -i "s|<!-- navitem -->|&\n${next}\n${prev}|" "$targetpost"
		unset next prev


		#check all required vars are set
		for var in unwrapped canonical title time
		do [[ -z "${(P)var}" ]] && echo -e "\n\a$SN: unset var -- $var" >&2 | tee "$LOGFILE"
		done
		#bash parameter indirection: "${!var}"
		#https://unix.stackexchange.com/questions/68035/foo-and-zsh

		#log if there are more than a single ref source per line
		#only a warning
		p='(src|href)="'
		if q="$( grep -EHn -i "${p}.*${p}" "$f" )"
		then
			cat >>"$LOGFILE" <<-!
			===
			File -- $f
			Warning -- more than one reference per line
			$q

			!
		fi
		unset p q

		#get rid of some comments
		sed -i '/^\s*<!--\s*#.*-->/ d' "$targetpost"



		#PART TWO
		#prepare for cat.html
		#make a temp copy for concatenation
		#cp -- "$targetpost" "$TEMP_TARGETCAT"
		sed -n '/<article.*>/,/<\/article.*>/ p' "$targetpost" >"$TEMP_TARGETCAT"

		#add navigation to individual posts
		navitem="<nav><a href=\"$n/\">[stand-alone]</a></nav>"
		sed -i "0,/<\/time/ s|<\/time.*|&\n${navitem}|" "$TEMP_TARGETCAT"

		#line-by-line check and change of ref sources
		cp -- "${TEMP_TARGETCAT}" "$TMP"
		
		#fix relative references
		#map relative references
		p='(src|href)="'
		while IFS=  read -r
		do
			#line number
			l="$(cut -d: -f1 <<<"$REPLY" )"

			#get all line reference sources
			while IFS=  read -r SRC
			do
				if
					#try inserting probable downwards path to post
					SRCCHANGE="$n/$SRC"
					#check that file exists
					[[ -f "$SRCCHANGE" ]]
				then
					#feedback
					((OPTV)) && eol='\n' || eol='\r'
					printf "${eol}${CLR}>>>file: %s  line: %3d  src: %s " "$TEMP_TARGETCAT" "$l" "$SRC" >&2

					#insert downwards path to post
					#also insert website blog address
					##this activates full-urls##SRCCHANGE="$ROOTBW/$SRCCHANGE"

					#clean url
					#remove implicit refs .. and .
					SRCCHANGE="$( rmimpf "$SRCCHANGE" )"

					#change src relative paths
					sed -i -E "${l}s,(${p})(${SRC}),\1${SRCCHANGE}," "$TEMP_TARGETCAT"
				fi
			done <<<"$( sed -n "${l} p" "$TMP" | grep -oE "${p}([^\"]*)\"" | sed -E "s/^${p}// ;s/\"$//" )"
		done <<<"$( grep -noE "$p" "$TMP" )"



		#PART ONE (REMAINING..)
		#tidy up post index.html?
		((OPTI)) && tidyupf "$targetpost" || true

		#keep index.html with old timestamp
		((OPTT)) && touch -d@"$stamp2" "$f"
		#clone file attributes (such as modification date)
		touch -r "$f" "$targetpost"
	fi



	#PART THREE
	#make a post title list
	#the resulting file can be used by other scripts
	#depends on part one
	TAGPZ='<!-- postlist -->'
	TAGPX='<!-- postlistX -->'

	#grep the post title
	#make the post title list item
	t="${f%\/*}\/"
	pname="$( grep -Fm1 '<h1' "$f" | sed "s|<h1|<a href=\"$t\"| ;s|</h1|</a|" )"
	dtpub="$( grep -Fm1 '<time' "$f")"

	echo "<li>${dtpub} ${pname}</li>" >>"$TARGET_TITLES_TEMP"
	#sed ';s|</time>|&<br>|'

	#counter
	((--n)) || true

done
echo >&2
#keep environment clean
unset canonical dtpub linerefs targetpost next prev pname stamp1 stamp2 navitem unwrapped var
unset TEMP_TARGETPOST TEMP_TARGETCAT REPLY SRCCHANGE SRC PRE LASTP
unset f l m n p q r rr t


#PART THREE (REMAINING..)
#add custom tag to titles.txt.new
((n==${#POSTFILES[@]})) && echo
sed -i "1 s/.*/${TAGPX}\n&/" "$TARGET_TITLES_TEMP"
sed -i "$ s/.*/&\n${TAGPX}/" "$TARGET_TITLES_TEMP"

#move (rename) new titles file
mv -f -- "$TARGET_TITLES_TEMP" "$TARGET_TITLES"

#make a plain text title index file (for my finding the posts via cli later)
sed -E 's/<[^>]*>//g ;s/[\t ]+/ /g' "$TARGET_TITLES" >"$TARGET_TITLES_PLAIN"


#PART TWO (REMAINING..)
echo "$SN: compile cat.html with all posts.." >&2
#use array $POSTFILES file list (reverse-ordered)
#concatenate posts
#make new cat.html
sed -n '/<article/,/<\/article/ p' "${CATFILES[@]}" |
	sed '/<!-- articles -->/ r /dev/stdin' "$TEMPLATE_CAT" >"$TARGET_CAT"

#select unique <LINK> and <SCRIPT> tags from individual posts head
#and add to cat.html
p='<(link|script)[^>]+>'
sed -nE "/<head/,/<\/head/ s/${p}/&/ p" "${CATFILES[@]}" |
	grep -vF -e '<!--' -e '"canonical"' |
	sort -u |
	while read
	do
		#check if tag is already present
		if sed -n '/<head/,/<\/head/ p' "$TARGET_CAT" |
			grep -q -F -- "$REPLY"
		then
			echo "Ignoring addition of duplicate link/script reference to cat.html -- $REPLY" >&2
		else
			echo "adding link/script reference to top of cat.html -- $REPLY" >&2
			#add tag
			<<<"$REPLY" sed -i '/<!-- metatags -->/ r /dev/stdin' "$TARGET_CAT"
		fi >>"$LOGFILE" 2>&1 2>/dev/stdin
	done
unset REPLY p

#log any duplicate link/script references found in body
p='<(link|script)[^>]+>'
#get all duplicate link/script references
sed -nE "/<body/,/<\/body/ { /<!--/! s/${p}/&/ p }" "$TARGET_CAT" |
	sort | uniq -d > "$TMP"
#any link/script duplicate found?
if [[ -s "$TMP" ]]
then
	echo -e "\nFound duplicate references in cat.html:"
	cat "$TMP"
fi  >>"$LOGFILE"


#more cat.html fixes
#get rid of some comments
sed -i '/^\s*<!--\s*#.*-->/ d' "$TARGET_CAT"

#change heading numbers
for h in 4 3 2 1
do
	i="$((h+1))"
	sed -i "/<article/,$ s|<h${h}|<h${i}|g ;/<article/,$ s|</h${h}|</h${i}|g" "$TARGET_CAT"
done
unset h i
#try to avoid 'picket fence' in sed commands!
#http://johnbokma.com/blog/2016/08/02/tar-files-in-other-directory.html

#tidy up cat.html?
((OPTI)) && tidyupf "$TARGET_CAT" || true



#PART FOUR
echo "$SN: update blog post titles.." >&2
#remove old list from BLOG home page and
#add updated post titles to blog/index.html
sed -i "/$TAGPX/,/$TAGPX/ d" "$TARGET_BLOGIND"
sed -i "/^\s*$TAGPZ/ r $TARGET_TITLES" "$TARGET_BLOGIND"




#PART FIVE
echo "$SN: update homepage recent post titles.." >&2
#make a post title file for WEBSITE home page
#must fix ref sources!
#get only the top 10 post titles
sed 's|href="|href="blog/|' "$TARGET_TITLES" |
	sed '12,$ s|^\s*<li.*|| ; /^$/ d' >"$TARGET_TITLES_HOME"

#update WEBSITE home page with latest post list
sed -i "/$TAGPX/,/$TAGPX/ d" "$TARGET_HOME"
sed -i "/^\s*$TAGPZ/ r $TARGET_TITLES_HOME" "$TARGET_HOME"




#PART SIX
#miscellaneous tasks

#always sync `archInstallPkgSuggestion.txt' with post 18
filep18="$HOME/arq/docs/archInstallPkgSuggestion.txt"
post18="$ROOTB/18/"
[[ -e "$filep18" ]] &&
	cp -vf "$filep18" "$post18" ||
	print "\awarning: cannot sync package list (post #18) -- $filep18" >&2



exit 0

