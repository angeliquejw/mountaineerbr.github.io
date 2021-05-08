#!/bin/zsh
# create a page with my videos
# v0.1.5  may/2021  by mountaineerbr

# github limits file size to 100MB
# requires ffmpeg, ffprobe and txt2html
# ffprobe version n4.3.2

#script name
SN="${0##*/}"

#vlof root
ROOTV=/home/jsn/www/mountaineerbr.github.io/vlog
 ROOTVW=https://www.mountaineerbr.github.io/vlog

#video database
ROOTMED="$ROOTV/media"
#ROOTMEDW="$ROOTVW/media"

#video individual html pages
ROOTDOC="$ROOTV/doc"

#main index template
INDEXTEMPLATE="$ROOTV/i.html"
INDEXMAIN="$ROOTV/index.html"

#thumbnails (not automatically generated!)
ROOTTHUMB="$ROOTV/thumb"
#ROOTTHUMBW="$ROOTVW/thumb"

#default video thumbnail
THUMBDEF="default.jpg"

#video file list by size
# max 100.000 KB
#msize=99000


#start
set -e
setopt extendedglob  
setopt nullglob
setopt nocaseglob
cd "$ROOTV"

typeset -a prefiles files
for filepath in "$ROOTMED"/*.(mp4|m4a|mpg|avi|mov)~*_low.*
do
	date="$(ffprobe "$filepath" 2>&1 | sed -En '/^\s*date/ s/.*:\s*([^\s]*)/\1/ p' <<<"$probe" )"
	prefiles+=("$date	$filepath")  #separator is a literal <TAB>
done
unset filepath date

#sort
print -l "${prefiles[@]}" | sort -n |
while read FDATE FNAME
do files+=("$FNAME")
done
unset prefiles

for filepath in "$files[@]"
do
	[[ -z "$filepath" ]] && continue
	[[ -d "$filepath" ]] && continue

	#counter
	((++n))

	#get media info, mostly from metadata
	fname="${filepath##*/}"
	itemdocpath="$ROOTDOC/${fname%.*}.html"

	#feedback
	print "$SN: video $n -- $fname" >&2

	#self-referencing canonical url
	canonical="<link rel=\"canonical\" href=\"${ROOTVW%/}/doc/${fname%.*}.html\">"

	size=( $(du -h -- "$filepath") )
	probe="$(ffprobe "$filepath" 2>&1)"

	#from metadata: title="$(sed -En '/^\s*title/ s/.*:\s*([^\s]*)/\1/ p' <<<"$probe")"
	title="${fname%.*}"  title="${title//_/ }"
	
	date="$(
		sed -En '/^\s*[Dd]ate/ s/.*:\s*([^\s]*)/\1/ p' <<<"$probe" |
		sed -E 's/([0-9]{4})([0-9]{2})([0-9]{2})/\1\/\2\/\3/'
		)"
	
	comm="$(
		sed -n '/^\s*[Cc]omment/,/^\s*[Dd]escription/ p' <<<"$probe" |
		sed -E 's/^\s*([Cc]omment)?[: ]*// ;/^\s*[Dd]escription[: ]*/d'
		)"
	desc="$(
		sed -n '/^\s*[Dd]escription/,/^\s*[Dd]uration/ p' <<<"$probe" |
		sed -E 's/^\s*([Dd]escription)?[: ]*// ;/^\s*[Dd]uration[: ]*/d ;4,$d'
		)"
	commhtml="$( txt2html --extract --eight_bit_clean <<<"$comm" )"
	#deschtml="$( txt2html --extract --eight_bit_clean <<<"$desc" )"
	
	dur="$(sed -En '/^\s*[Dd]uration/ s/.*[Dd]uration[: ]*([^\s]*),.*/\1/ p' <<<"$probe")"
	dur="${dur#00:}" dur="${dur#0}" dur="${dur%.*}"

	#is there a thumbnail?
	for img in "$ROOTTHUMB/${fname%.*}".(jpg|png|gif|jpeg)
	do img="${img##*/}" ;break
	done
	if [[ -z "${img// }" ]]
	then print "$SN: no thumbnail -- $fname" >&2 ;img="$THUMBDEF"
	fi
	
	#relative url paths to video files (individual video doc page)
	videorelurldoc="../media/$fname"
	thumbrelurldoc="../thumb/$img"

	
	#low res version?
	for lowpath in "$ROOTMED/${fname%.*}_low".(mp4|m4a|mpg|mpeg|avi|mov)
	do
		#declare parameters
		lowfname="${lowpath##*/}"

		#get size
		sizelow=( $(du -h -- "$lowpath") )

		#html code
		#main video index
		itemlow="; lo-res: <a href=\"media/$lowfname\">${sizelow[1]}</a>"

		#individual video doc
		itemdoclow="
		<tr>
 		<th>File Lo<wbr>Res</th>
		<td><a href=\"../media/$lowfname\">$lowfname</a></td>
		</tr>

		<tr>
 		<th>Size Lo<wbr>Res</th>
		<td>${sizelow[1]}</td>
		</tr>"

		break
	done

	
	#item for main index html template
	item="
	<div class=\"w3-row w3-margin\">

	<div class=\"w3-third\">
	  <a title=\"Go to video page\" href=\"doc/${fname%.*}.html\">
	  <img src=\"thumb/$img\" style=\"width:100%;height:auto\">
	  </a>
	</div>
	<div class=\"w3-twothird w3-container\">
	  <a href=\"doc/${fname%.*}.html\"><h2>$title</h2></a>
	  <p>$desc</p>
	  <p>$date, $dur, ${size[1]}${itemlow}</p>
	</div>
	</div>
	"

	#save item for main video index injection
	injection="$item
	$injection"


	#create a full html page per video
	cat >"$itemdocpath" <<-EOF
	<!DOCTYPE html>
	<html lang="pt">
	<head>
		<meta charset="UTF-8">
		<title>$title -- X GNU Bio</title>
		<meta name="viewport" content="width=device-width, initial-scale=1">
		<link rel="stylesheet" href="../../css/w3.css">
		<link rel="stylesheet" href="../css/style.css">
		$canonical

		<meta name="distribution" content="global">
		<link rel="shortcut icon" href="../../favicon.ico" type="image/x-icon">

	</head>
	<body id="doc">
		<div class="w3-container w3-teal">
		<p class="w3-right"><a href="../" class="navbtn">[BACK]</a></p>
		<h1>$title</h1>
		</div>

		<br>
		<div class="w3-container w3-center img-container">
		<a title="Click to watch or download" href="$videorelurldoc"><img src="$thumbrelurldoc" alt="Video thumbnail">
		<button class="playbtn">Play</button></a>

		</div>

		<div class="w3-content w3-margin">
		<h2>Description</h2>
		$commhtml

		<h2>Details</h2>
		<table>

		<tr>
		<th>Title</th>
		<td>$title</td>
		</tr>

		<tr>
		<th>Channel</th>
		<td>X GNU Bio</td>
		</tr>

		<tr>
		<th>Author</th>
		<td>mountaineerbr</td>
		</tr>

		<tr>
		<th>Date</th>
		<td>$date</td>
		</tr>

		<tr>
		<th>Duration</th>
		<td>$dur</td>
		</tr>

		<tr>
 		<th>File</th>
		<td><a href="$videorelurldoc">$fname</a></td>
		</tr>

		<tr>
 		<th>Size</th>
		<td>${size[1]}</td>
		</tr>

		$itemdoclow

		<tr>
 		<th>License</th>
		<td>Attribution</td>
		</tr>

		</table>
		</div>

		<footer>

		<!--
		- - - -	Copyright ©2021 JSN.
		 - - -	Verbatim copying and distribution of this entire article is
		- - - -	permitted in any medium, provided this notice is preserved.
		-->
		</footer>
	</body>
	</html>
	EOF


	#clean environment!
	unset filepath fname size probe title date  comm desc deschtml commhtml
	unset dur itemdocpath canonical img lowpath lowfname sizelow lowurl
	unset itemlow itemdoclow item videorelurldoc thumbrelurldoc
done

#add number of videos
injection="$injection
<br>
<div class=\"w3-container w3-right\">
<p>Available videos: $n</p>
</div>"

#inject item list in index template
sed '/<!-- videolist -->/ r /dev/stdin' \
	"$INDEXTEMPLATE" <<<"$injection" >"$INDEXMAIN"
unset injection



exit
#NOTES
# Using FFMPEG to Extract a Thumbnail from a Video
#{ ffmpeg -i InputFile.FLV -vframes 1 -an -s 400x222 -ss 30 OutputFile.jpg ;}
#https://networking.ringofsaturn.com/Unix/extractthumbnail.php
# Meaningful thumbnails for a Video using FFmpeg
#{ ffmpeg -ss 3 -i input.mp4 -vf "select=gt(scene\,0.4)" -frames:v 5 -vsync vfr -vf fps=fps=1/600 out%02d.jpg ;}
#https://superuser.com/questions/538112/meaningful-thumbnails-for-a-video-using-ffmpeg

#HTML CODE FOR VIDEO DOC
#Video playback in html
		<!-- <video width="320" height="240" autoplay>
		  <source src="$videorelurldoc" type="video/${fname##*.}">
		  Your browser does not support the video tag.
		</video> -->

		<!-- <button onclick="playPause()">Play/Pause</button> 
		<button onclick="makeBig()">Big</button>
		<button onclick="makeSmall()">Small</button>
		<button onclick="makeNormal()">Normal</button>
		<br><br>
		<video id="video1" width="420">
			<source src="$videorelurldoc" type="video/${fname##*.}">
			Your browser does not support HTML video.
		</video> -->

#Video playback controls
		<!-- video playback controls -->
		<!-- <script> 
		var myVideo = document.getElementById("video1"); 

		function playPause() { 
		  if (myVideo.paused) 
		    myVideo.play(); 
		  else 
		    myVideo.pause(); 
		} 

		function makeBig() { 
		  if (myVideo.width==560) 
		    makeNormal(); 
		  else 
		    myVideo.width = 560; 
		} 

		function makeSmall() { 
		    myVideo.width = 320; 
		} 

		function makeNormal() { 
		    myVideo.width = 420; 
		} 

		function toggleMute() {
		  myVideo.muted = !myVideo.muted;
		}

		</script> -->


