#!/bin/bash
# urlgrep.sh -- grep full-text urls
# v0.18.2  jun/2021  by mountaineerbr

#defaults
#colours (comment out to disable)
#use grep colour? (only interactively)
COLOUROPT='--color=always'

#loading bar
COLOUR1='\e[1;34;47m' 		#white bg, blue fg
#match addresses
COLOUR2='\e[1;37;44m' 		#blue bg, white fg
#error
COLOUR3='\e[1;37;41m' 		#red bg, white fg
#warning
COLOUR4='\e[1;33;44m' 		#blue bg, yellow fg 
#warning
COLOUR5='\e[1;32;44m'  		#blue bg, green fg
#end colour code
ENDC='\e[00m' 			#end color code

#webpage result separator/delimiter
#SEP='====\n'
SEP='\n'

#defaults maximum number
#of background jobs
JOBSDEF=4

#script name
SN="${0##*/}"

#user cache dir for results copy
#eg. ~/.cache/urlgrep
CACHEDIR="$HOME/.cache/${SN%.*}"

#temporary directory
TMPD="/tmp/$SN.$$.XXXXXXXX"

#user agent
#chrome on windows 10
UAG='user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.83 Safari/537.36'

#some binary extensions
BINEXTS='bz2|gz|gzip|rar|tbz2|tgz|txz|zip|Z|7z|deb|tar|pdf|exe|png|jpg|jpeg|bmp|tiff|gif|xpm|pnm|wav|mp3|flac|m4a|wma|ape|ac3|og[agx]|spx|opus|avi|mp4|wmv|dat|3gp|ogv|mkv|mpg|mpeg|vob|fl[icv]|m2v|mov|webm|ts|mts|m4v|r[am]|qt|divx|as[fx]'
#ignore empty strings from stdin or urls starting with the following:
IGNORE='file|telnet|gopher|mailto|about|wais'
#https|http|ftp
#http://www.subspacefield.org/~travis/urlgrep.pl

HELP="NAME
	$SN -- Search Full-Text Web Content from a List of URLs


SYNOPSIS
	$SN [-jNUM] [-akt] -- [GREP-OPTION..] PATTERN [URLFILE]
	$SN [-jNUM] [-akt] -- [GREP-OPTION..] -e PATTERNS ... [URLFILE]
	$SN [-hv]


	Grep full-text content of webpages from a list of URLs. URLs
	can be read via pipe (stdin) or from a text file.


DESCRIPTION
	The script will read a URL list from stdin or file with one URL
	per line.

	When a match is found, result is dumped to the screen as soon as
	possible. Due to the asynchronous nature of the processes, output
	to screen from different jobs may interleave.

	To run grep on pdf, tar and other compressed files set option -a
	or --text (treat binary data as text). GNU grep and lynx may throw
	a warning when it goes through binary files.

	It is important to make a distinction between script-reserved
	and grep options. Script-reserved options must be set before any
	grep option, otherwise the script may parse them improperly. A
	--  signals the end of script options and disables further script-
	specific option processing. Any arguments after the -- are treated
	as grep options/arguments.
	
	HTML will be processed/filtered by a terminal web browser. Envi-
	ronment \$BROWSER is read. If that is not set the script will
	check for elinks, links, lynx or w3m, otherwise sed is executed
	to remove HTML tags. To disable html filters, use option -t or
	set \$BROWSER to cat.

	On exit or abortion, the script will concatenate and write results
	to a file at ${CACHEDIR/$HOME/\~} .

	A copy of webpages and grep results are kept at a temporary dir-
	ectory. To keep fully downloaded webpages and other buffer files,
	set option -k. Temporary directory defaults=${TMPD} .

	Jobs (subprocesses) for downloading data are launched asynchro-
	nously. Each job will download data from a URL and grep text 
	independently. As such, internet may jam and system slow down
	depending on your contracted internet bandwidth and CPU power.
	You should try and adjust the maximum number of background jobs
	with option -jNUM, in which NUM is an integer, defaults=${JOBSDEF} .

	The script checks minimally for url structure validity. Empty
	strings or strings with only blanks will be skipped. URLs starting
	with any of the following will be ignored as well:
	${IGNORE//|/:, }: .

	Take you time to carefully plan your search ahead and choose a
	list of URLs carefully. You may also decide to keep downloaded
	temporary files (option -k) to redo searches manually.

	Reaccessing the same urls repeateadly in a short period of time
	may trigger soft blockage from the server. In that case, wait for
	some time before running this script with those urls.


ENVIRONMENT
	It is possible to configure some options of curl and wget by set-
	ting some environment variables.

	The number of retries upon a temporary error, connection timeout
	and the maximum time for the whole operation can be adjusted set-
	ting variables \$RETRIES, \$TOCONNECT and \$TOMAX, respectively,
	to appropriate integer values and exporting them before running
	the script. Alternatively, set script environment by prefixing
	the script command with parameter assignments, see usage example(4).

	\$JOBSMAX
			Controls the maximum number of background jobs,
			that is the equivalent of option '-jNUM'.

	\$RETRIES
			Sets a number of retries if a transient error is
			returned when curl or wget tries to perform a
			transfer. Note that curl and wget differ in their
			default values (curl no retries, wget three retries).

	\$TOCONNECT
			Limits the connection phase only, so if connection
			occurs within the given period it will continue,
			while \$TOMAX sets maximum time in seconds that
			the whole operation is allowed to take. This is
			useful for preventing your batch jobs from hanging
			for hours due to slow networks or links going down.
	
	\$BROSWER
			Sets the browser to process HTML; if none set,
			the script will set a browser automatically.


	#maximum asynchronous jobs
	JOBSMAX=${JOBSDEF} 		(integer)

	#curl/wget retries
	RETRIES=${RETRIES:-unset} 		(integer)
	
	#curl/wget connection timeout
	TOCONNECT=${TOCONNECT:-unset} 	(integer, seconds)
	
	#curl/wget operation maximum timeout
	TOMAX=${TOMAX:-unset} 		(integer, seconds)
	
	#cli browser pkg name (html filter)
	BROWSER=[cat|elinks|links|lynx|w3m|sed]


URL LISTS
	GRAPHICAL INTERFACE

	Use webbrowser bookmarks/history managers to create URL lists.
	Open the manager, select all URLs of interest, copy and paste
	them into a new plain text file, one URL per line and save it.
	There are web browser utilities like 'CopyTabTitleUrl' by toshi.
	
	Firefox
		Menu > Libraries > Bookmarks > Show All Bookmarks

		Menu > Libraries > History > Show All History
			

	Chrome 
		Menu > Bookmarks > Bookmark Manager

		Menu > History > History
			
		chrome://history
	

	TERMINAL

	Close webbrowsers before reading '.sqlite' databases or make a 
	copy to use them. The following commands may require adjusting
	the path to the databases if the star glob does not work.

	Firefox 
		$ echo 'select url from moz_bookmarks, moz_places where moz_places.id=moz_bookmarks.fk;' | sqlite3 ~/.mozilla/firefox/*.default/places.sqlite
			
		$ echo 'select url from moz_places where 1;' | sqlite3 ~/.mozilla/firefox/*.default/places.sqlite


	Chrome
		$ cat ~/.config/google-chrome/Default/Bookmarks | jq -r '..|.url? // empty'
		
		$ echo 'select url from urls where 1;' | sqlite3 ~/.config/google-chrome/Default/History


SHELL FUNCTIONS
	Below are some useful shell functions to get a URL list from
	mozilla firefox and google chrome and pipe them to this script.

	Set paths to webbrowser databases appropriately. Also, you may
	want to add this script to your \$PATH or use the full path ref-
	erence to it in the functions below. Tac can be used to reverse
	URL order, so that recent URLs will be on top of the list.

	These functions require jq and sqlite3.


# ~/.bashrc

#url lists

#firefox user database
FFUSER=\"\$HOME/.mozilla/firefox/XXXXXXXX.default/places.sqlite\"

#google chrome user database
GCUSER=\"\$HOME/.config/google-chrome/Default/History\"

#temp file
TEMPFILE=\"\$HOME/Downloads/urls.sqlite\"

#firefox -- all urls (history, etc)
faurls() { 
	/bin/cp \"\$FFUSER\" \"\$TEMPFILE\" <<<y || return
	sqlite3 \"\$TEMPFILE\" <<<'select url from moz_places where 1;'
	/bin/rm \"\$TEMPFILE\"
}

#firefox -- bookmarks
fburls() { 
	/bin/cp \"\$FFUSER\" \"\$TEMPFILE\" <<<y || return
	sqlite3 \"\$TEMPFILE\" <<<'select url from moz_bookmarks, moz_places where moz_places.id=moz_bookmarks.fk;'
	/bin/rm \"\$TEMPFILE\"
}

#chrome -- all urls (history, etc)
caurls() { 
	/bin/cp \"\$GCUSER\" \"\$TEMPFILE\" <<<y || return
	sqlite3 \"\$TEMPFILE\" <<<'select url from urls where 1;'
	/bin/rm \"\$TEMPFILE\"
}

#chrome -- bookmarks
cburls() {
	jq -r '..|.url? //empty' \"\$HOME/.config/google-chrome/Default/Bookmarks\"
}

#url grep (suggestion)
alias ugrep='faurls | tac | $SN'


The current shell script can be summarised in its simplest form in the
followin function:

function()
{
	while read
	do  curl -s \"\$REPLY\" | grep \"\$@\" && echo \">>>\$REPLY\"
	done <[URLLIST.TXT|/dev/stdin]
}


SEE ALSO
	I wrote \`ug.sh' which is the \`light version' of this current
	script. May be easier to understand, although that is less robust
	and does not keep buffer files at all:
	<https://github.com/mountaineerbr/scripts/blob/master/ug.sh>

	Simple urlgrep from nriitala:
	<https://gist.github.com/nriitala/6110899>

	Perl URLgrep, a simple perl web crawler that gives you the
	ability to perform a grep search on all links of any webpage
	using regular expressions:
	<https://github.com/roinfogath/urlgrep>
	<https://code.google.com/archive/p/urlgrep/>


WEBBROWSER PLUG-INS
	Google Chrome and Firefox have got extensions/add-ons that search
	URL full-text, too. However, they only index random words from
	websites the user visit *after* installation. Also, they may send
	statistics or a copy of user data back to the developer.

	The advantage of webbrowser plugins is their speed of search af-
	ter indexing is complete.

	This script source code is easy to read, does not share stats and
	is distributed as free software.
	

WARRANTY
	This programme/script is Free Software and is licensed under the
	GNU General Public License v3 or better and is distributed with-
	out support or bug corrections.

	Required packages are Bash v5.0+, cURL or Wget and GNU Coreutils.
	It also uses the file programme to try and detect file types.
	Optionally, one terminal-based web browser is required: elinks,
	links, lynx or w3m. If you want to make URL lists from Firefox
	and Chrome, you will also need sqlite3 and jq.

	If useful, please consider sending me a nickle!
		=)

		bc1qlxm5dfjl58whg6tvtszg5pfna9mn2cr2nulnjr


BUGS
	Asynchronous processes may print interleaved text results to
	stdout (that is why a file with results is created when the
	script exits).

	When \$BROWSER is set to lynx to process html, grep often throws
	a warning about binary data unless grep --text option is set.

	The script may consume a lot of internet bandwidth and CPU
	power if options are not set properly as per system.


USAGE EXAMPLES
	( 1 ) Simple search:
		
		$ $SN  'PATTERN'  ~/URLFILE.txt 

		
	( 2 ) URLs from pipe, search case-insensitive:

		$ $SN  -ie  PATTERN  -ePATTERN2  \"${HOME}/URLFILE.txt\"

		
	( 3 ) Print one line before and one after matches, case is
	      insensitive:
	
		$ cat URLFILE.txt | $SN  -B1  -A1  -i  'PATTERN'
	

	( 4 ) Use lynx as HTML filter:
	
		$ cat URLFILE.txt | BROWSER=lynx  $SN  'PATTERN'
	

	( 5 ) Set timeout and retries of curl/wget for one-shot execu-
	      tion by setting the environment temporarily by prefixing
	      the script command with parameter assignments:
	
		$ TOCONNECT=20  RETRIES=4  $SN  -f  URLFILE.txt  PATTERN


GREP OPTIONS
	With exception of the script-reserved options listed in the next
	section, all other options are assigned to grep.

	In order to avoid collision between script-reserved options and
	Grep options, a double dash -- may be used to signal the end of
	script-reserved options, causing all remaining arguments to be
	passed to grep. Alternatively, use the corresponding long options
	of grep.

	By defaults, matches will be colorised unless stdout is redirected.
	Some useful grep options are summarised below.

		-A NUM 	Lines after match.
		-B NUM 	Lines before match.
		-C NUM 	Context lines.
		-e PATTERN
			Target matches PATTERN. This opt can be
			used multiple times.
		-E 	Interpret PATTERNS as extended regex.
		-F 	Interpret PATTERNS as fixed strings,
			not as regular expressions.
		-i 	Case is insensitive.
		--color=never
			Do not colorise matches.
		-q 	Prints only the website URL on match.


	To print matches with the preceding and a maximum of ten following
	characters, try:

		-E  -o  -e  '.{0,10}PATTERN.{0,10}'
				

RESERVED OPTIONS
	-a	Process a binary file as if it were text.
	-h 	Show this help.
	-j NUM	Maximum number of background jobs, defaults=${JOBSDEF} .
	-k 	Keep buffer files, defaults=${TMPD} .
	-t 	Do not use the HTML filters.
	-v 	Print script version."


#functions

urlencode() {
    # urlencode <string>
    local i length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:$i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            *) printf '%%%02X' "'$c" ;;
        esac
    done
}

urldecode() {
    # urldecode <string>

    local url_encoded="${1//+/ }"
    printf '%b' "${url_encoded//\%/\\x}"
}
#https://gist.github.com/cdown/1163649

#grep downloded page text
#run in async subshell
curlgrepf() 
{ 
	#download link
	"${YOURAPP[@]}" "$TMPFILE" "$LINK"
	curlexit="$?"

	#check to see if there is curl/wget error
	case "$curlexit" in
		0)
			#good exit code
			#minimally check for file type
			#try to provide a useful name for the file

			#if ext is recognised, rename temp file accordingly
			if
				#decode url and see if you find an extension
				nametry="$( urldecode "${LINK##*/}" )"
				ext=( $( tr A-Z a-z <<<"${nametry##*.}" ) )
				[[ "${ext[0]}" =~ ^($BINEXTS)$ ]]
			then
				isbin=1
				
				if tmpchange="${TMPFILE%/*}/$nametry"
					[[ "$tmpchange" != "$TMPFILE" ]]
				then
					#change filename
					mv -- "$TMPFILE" "$tmpchange"

					TMPFILE="$tmpchange"
				fi
			elif
				#try to get extension with `file'
				ext=( $( file -b "$TMPFILE" 2>/dev/null | tr A-Z a-z ) )
				[[ "${ext[0]}" =~ ^($BINEXTS)$ ]]
			then
				isbin=1

				if tmpchange="${TMPFILE%.html}.${ext[0]}"
					[[ "$tmpchange" != "$TMPFILE" ]]
				then
					#change filename
					mv -- "$TMPFILE" "$tmpchange"
					
					TMPFILE="$tmpchange"
				fi

			fi
			
			#skip binary files if --text opt is not set
			if (( isbin )) && (( BINASTEXT ))
			then
				printaddf "${nametry:-${ext[0]}}" "$LINK" 2
				echo >&2
				return
			fi

			#filter HTML and print any match to stdout (with web address)
			if htmlfilter "$TMPFILE" | grep $COLOUROPT "$@" && printaddf "$LINK"
			then
				{
					htmlfilter "$TMPFILE" | grep --color=never "$@" && printaddf "$LINK"
				} >"$TMPFILE2"
			fi
			;;
		130)
			#Control-C is fatal error signal 2, (130 = 128 + 2)
			false
			;;
		*)
			#print failure warning
			printf "${COLOUR3}%s: fail: %s[%s] -- %s${ENDC}\n\n" "$SN" "${YOURAPP[0]}" "$curlexit" "$LINK" >&2
			;;
	esac

	#-k keep temp file?
	(( OPTKEEP == 0 )) && [[ -f "$TMPFILE" ]] && rm -- "$TMPFILE"

	#this function is called from a subshell
	exit "${curlexit:-0}"
}

#html filter
htmlfilter()
{
	"${FILTERCMD[@]}" "$1"
}

#print website address
printaddf()
{
	local addr="$1"  name="$2"
	(
		#is stdout free?
		[[ -t 1 ]] || unset ENDC COLOUR1 COLOUR2 COLOUR3 COLOUR4 COLOUR5 COLOUROPT

		if [[ "${@: -1}" = 2 ]]
		then
			#warning: print `skipping..'
			printf "${COLOUR5}>>>skipping ${COLOUR4}%s${ENDC}${COLOUR5} from %s${ENDC}\n" "$name" "$addr" >&2
		else
			printf "${COLOUR2}>>>%s${ENDC}  \n${SEP}" "$addr"
		fi
	)
}

#status bar
statusbarf() {
	printf "${COLOUR1}%04d/%04d${ENDC}\r" "$N" "$T"
}

#exit function
exitf()
{
	#unset trap
	trap \  INT HUP TERM
	
	#kill process group
	pkill -P $$
	
	echo -e "\n$SN: info -- stop at $N  " >&2
	echo -e "$SN: warning -- user interrupt  \n\n" >&2

	exit
}

cleanf() {
	#disable trap
	trap \  EXIT

	local exitcode files
	typeset -a files

	shopt -s nullglob

	cd "$TMPD" || exit 1

	#get all positive result files
	#bash#mapfile -t files <<<"$( printf '%s\n' *.grep | sort -n )"
	while read && [[ -n "${REPLY// }" ]]
	do
		files+=( "$REPLY" )
	done <<<"$( printf '%s\n' *.grep | sort -n )"

	#is there any files matching result glob?
	if (( ${#files[@]} ))
	then
		exitcode=0
		
		#feedback
		echo ">>>matches -- ${#files[@]}" >&2

		#check for user cache dir
		if [[ ! -d "$CACHEDIR" ]]
		then
			#if that does not exist, create
			if ! mkdir -pv "$CACHEDIR"
			then
				echo "$SN: could not create cache directory -- $CACHEDIR" >&2
				return 1
			fi
		fi
		
		#concatenate buffer files in the correct order
		#get a unique name
		while
			RESULTFNAME="results-$(date +%Y-%m-%dT%T).txt"
			RESULT="$CACHEDIR/$RESULTFNAME"
			[[ -f "$RESULT" ]]
		do
			sleep 0.6
		done
		#reserve the results file asap
		: >"$RESULT"

		#concatenate result files
		cat -- "${files[@]}" > "$RESULT" &&
			echo ">>>result file -- $RESULT" >&2
	fi

	#keep temporary files?
	if (( OPTKEEP ))
	then
		[[ -d "$TMPD" ]] && echo ">>>temporary files at $TMPD" >&2
	else
		[[ -d "$TMPD" ]] && rm -rf -- "$TMPD"
	fi

	exit "${exitcode:-1}"
}	


#start

#pre-parse opts
#check if there is any positional argument
if [[ -z "$*" ]]
then
	echo "$SN: err  -- run with -h for help" >&2
	exit 1
fi

#if stdout is not free or colour option is set
if [[ ! -t 1 ]] ||
	[[ " $* " =~ \ --colou?r=never\  ]]
then
	unset COLOUR1 COLOUR2 COLOUR3 ENDC COLOUROPT
fi

#treat binary files as text?
if [[ " $* " =~ \ --text\  ]] ||
	[[ " $* " =~ \ --binary-files=text\  ]] ||
	[[ " $* " =~ \ -a\  ]]
then
	BINASTEXT=2
fi
#--text or --binary-files=text process a binary file as text

#parse options
while 
	getopts :ahj:ktv- opt
do
	case $opt in
		a) 
			#treat binary file as text
			BINASTEXT=1
			;;
		h) 
			#help
			echo "$HELP"
			exit 0
			;;
		j) 
			#max jobs
			JOBSMAX="$OPTARG"
			;;
		k)
			#keep temp result files
			OPTKEEP=1
			;;
		t) 
			#disable htmlfilter
			BROWSER=cat
			;;
		v) 
			#version of script
			grep -m1 '\# v' "$0"
			exit
			;;
		-)
			#grep -- long opts
			OPTOTHER=1
			break
			;;
		?) 
			#grep -- other opts
			OPTOTHER=2
			break
			;;
	esac
done

#consolidate $JOBSMAX
JOBSMAX="${JOBSMAX:-$JOBSDEF}"

#set shell options
#and shift arg positions
if (( OPTOTHER == 2 ))
then
	shift $(( OPTIND - 2 ))
else
	shift $(( OPTIND  - 1 ))
fi

#shift if $1 is '--' (bash-like) or '-' (zsh-like)
[[ "$1" = -- || "$1" = - ]] && shift

#is last positional argument a file?
if (( $# )) && [[ -f "${@: -1}" ]]
then
	URLFILE="${@: -1}"
	set -- "${@:1:$(( $# - 1 ))}"
elif [[ ! -t 0 ]]
then
	URLFILE=/dev/stdin
elif [[ ! -f "$URLFILE" ]]
then
	echo "$SN: err  -- list of URLS is required" >&2
	exit 1
fi

#binary as text? add --text flag to user args
(( BINASTEXT == 1 )) && set -- --text "$@"

#test if grep args are valid
if
	#grep err msg?
	ERRMSG="$( grep "$@" <<<' ' 2>&1 )"
	#exit code
	GREPEXIT="$?"
	
	#is there is error message?
	[[ -n "$ERRMSG" ]] && (( GREPEXIT > 1 ))
then
	#print error message (remove some lines from error message)
	grep -v -- --help <<< "$ERRMSG" >&2 

 	echo "$SN: err  -- check script help page with -h" >&2
	exit "$GREPEXIT"
fi
unset ERRMSG GREPEXIT

#test for curl or wget
if command -v curl &>/dev/null
then
	#consolidate opts
	[[ -n "$RETRIES" ]]   && OPTS=(  --retry "$RETRIES" )
	[[ -n "$TOCONNECT" ]] && OPTS+=( --connect-timeout "$TOCONNECT" )
	[[ -n "$TOMAX" ]]     && OPTS+=( --max-time "$TOMAX" )

	YOURAPP=( curl -sL -b emptycookie --insecure --compressed ${OPTS[@]} --header "$UAG" --output )

	#--insecure , don't check https certificate
	#by defaults, curl does not follow redirects, does not use the cookie engine,
	#performs no retries and connect-timeout is 5 minutes
	#https://github.com/curl/curl/blob/master/lib/connect.h
elif command -v wget &>/dev/null
then
	#consolidate opts
	[[ -n "$RETRIES" ]]   && OPTS=(  --tries="$RETRIES" )  #-t
	[[ -n "$TOCONNECT" ]] && OPTS+=( --connect-timeout="$TOCONNECT" )
	[[ -n "$TOMAX" ]]     && OPTS+=( --timeout="$TOMAX" )
	
	YOURAPP=( wget -q --no-check-certificate ${OPTS[@]} --header="$UAG" -e robots=off -O )
	
	#by defaults, wget follows redirects, uses cookie engine, 
	#retries 20 times and --read-timeout is 900 seconds
else
	echo "$SN: err  -- package curl or wget is required" >&2
	exit 1
fi
unset OPTS

#html filter
#check $BROWSER 
if [[ ! "$BROWSER" =~ ^(cat|elinks|links|lynx|w3m|sed) ]]
then
	if command -v links
	then
		BROWSER=links
	elif command -v lynx
	then
		BROWSER=lynx
	elif command -v w3m
	then
		BROWSER=w3m
	elif command -v elinks
	then
		BROWSER=elinks
	fi &>/dev/null
fi

#set filter command 
case "$BROWSER" in
	cat*) 	 FILTERCMD=(cat);;
	elinks*) FILTERCMD=(elinks -force-html -dump -no-references);;
	links*)  FILTERCMD=(links -force-html -dump);;
	lynx*) 	 FILTERCMD=(lynx -force_html -dump -nolist);;
	w3m*) 	 FILTERCMD=(w3m -dump -T text/html);;
	*) 	 FILTERCMD=(sed 's/<[^>]*>//g');;  #defaults
esac
#lynx makes grep throws warnings that file contains binary

#give a chance to check final settings
cat >&2 <<!
>urls__: $URLFILE
>jobs__: $JOBSMAX
>filter: ${FILTERCMD[*]}
>${YOURAPP[*]} -
>grep $*
$( printf "$SEP" )

!

#set traps
trap exitf INT HUP TERM
trap cleanf EXIT

#make temporary directory
TMPD="$( mktemp -d "$TMPD" || mktemp -d )" || exit 1
#temp file for job control
TMPJOBS="$TMPD/00.$SN.$$.jobs"
#links/stdin temp file
TMPLINKS="$TMPD/00.$SN.$$.links"

#copy stdin or links file
#remove carriage returns
tr -d '\r' <"$URLFILE" >"$TMPLINKS"

#count links (lines)
T="$( wc -l <"$TMPLINKS" )"


#asynchronous search loop
while read -r LINK
do
	#counter
	(( ++N ))

	#skips
	if
		[[ -z "${LINK// /}" ]] ||
		[[ "${LINK// /}" =~ ^($IGNORE): ]] ||
		[[ \ "${LINKCACHE[*]}"\  = \ "$LINK"\  ]]
	then
		continue
	fi
	#cache address
	LINKCACHE+=( "$LINK" )

	#get a useful filename
	NAME="$( sed 's/[^/]*\/\/\([^@]*@\)\?\([^:/]*\).*/\2/' <<<"$LINK" )"

	#temp file
	TMPFILE="$TMPD/$N.$NAME.html"
	TMPFILE2="$TMPD/$N.$NAME.grep"

	#feedback (to stderr)
	statusbarf >&2

	#job control -- bash and zshell
	#print one job per line to temp file
	while
		JOBS=( $( jobs -p ) )
		(( ${#JOBS[@]} > JOBSMAX ))
	do
		sleep 0.1
	done
	#semaphore: { (1/.1)*4 = max 40 calls/sec }

	#launch new jobs (subprocesses)
	curlgrepf "$@" &
	
done <"$TMPLINKS"

#wait for all jobs to complete
wait

