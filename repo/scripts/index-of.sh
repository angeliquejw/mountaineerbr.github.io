#!/bin/zsh
# vim:ft=bash
#download (book) files from
#http://index-of.co.uk/
# dec/2020  by mountaineerbr

#defaults
SN="${0##*/}"

#help
if [[ "$1" = -h || "$1" = --help ]]; then
	cat <<-!
	$SN - download books and files from <index-of.co.uk>

	usage: $SN [-wDIR] [LOCALDIR]


	LOCALDIR is an optional download directory,
	download defaults to /tmp/index-of.sh.\$UNIXTIME

	to download only one of the directories listed at
	<index-of.co.uk>, use option '-wDIR', for example:
	'-w "Bio-Informatics"'.

	warning: large data, may require dozens of giga bytes!
	!
	exit
fi

#download user agent
UAG='user-agent: Mozilla/5.0 Gecko'

#use some aliases
alias curlu='curl --compressed -sLb non-existing --header "$UAG"'
alias hf="sed 's/<[^>]*>//g'"

#make sure locale is set correctly
LC_NUMERIC=C

#download only one dir?
#important: options o and w are the same!
getopts :o:w: opt && shift $(( OPTIND - 1 ))

if [[ "$OPTARG" = ? ]] &&; then
	printf '%s: illegal option -- %s\n' "$SN" "$OPTARG" >&2
	exit 2
fi

#start
if [[ -n "$1" ]]; then
	tmp="$1"
else
	tmp="/tmp/$SN.download"
	tmp="/tmp/$SN.$( date +%s )"
fi

mkdir -p "$tmp"

printf '%s: warning -- very large data is about to start downloading\n' "$SN" >&2
printf '%s: files will be downloaded to %s\n\n' "$SN" "$tmp" >&2

#access site root an dget subdir names
curlu http://index-of.co.uk/ |
	hf | grep -F \ -\ | cut -d/  -f1 | awk NF |
	while read line; do

	#download only one dir?
	[[ -n "$OPTARG" ]] && line="$OPTARG"

	#access first subdir and get a list of files
	curlu "http://index-of.co.uk/$line" |
		hf | sed -n '/^ Name/,/^$/p' | awk 'NF{--NF};1' |
		awk NF | grep -ve '^Name' -e '^Parent Directory' |

		#check file name and download it
		#won't work if that is another subdir
		while read arq; do

			#file names
			arqh="$( sed 's/ /%20/g' <<< "$arq" )"  #for html request
			arqf="$( sed 's/ /_/g ; s/&amp;//g' <<< "$arq" | tr -d ',|"{}*#$@!' | sed 's/_*-_*/-/g ; s/\.*__*/_/g' )"
			
			#dir and file locations at local system
			tmpd="$tmp/$line"
			tmpf="$tmp/$line/$arqf"

			#if arq name is empty or exists, skip it
			if [[ -z "${arq// /}" || -f "$tmpf" ]]; then
				printf "\n>>%s: OK -- %s  [%s s]\n" "$SN" "$tmpf" "$SECONDS" >&2
				continue
			else
				#make sure subdir existis in local system
				printf "\n>>%s: http://index-of.co.uk/%s/%s  [%s s]\n" "$SN" "$line" "$arq" "$SECONDS" >&2
				mkdir -p "$tmpd"
			fi

			#download it
			curl "http://index-of.co.uk/$line/$arqh" -H "$UAG" -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Accept-Language: en-GB;q=0.5,en;q=0.3' --compressed -H 'DNT: 1' -H 'Connection: keep-alive' -H "Referer: http://index-of.co.uk/$line/" -H 'Cookie: SERVERID105614=1420236|XtpxI|XtptF' -H 'Upgrade-Insecure-Requests: 1' -o "$tmpf"
			#maybe remove ``Cookie''?

			#don't overload server
			sleep 2

		done


	#download only one dir?
	[[ -n "$OPTARG" ]] && exit 0

	done

#where files were downloaded
printf '%s: files at %s\n' "$SN" "$tmp"

