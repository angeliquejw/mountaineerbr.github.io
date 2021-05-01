#!/bin/zsh
# create a page with my videos
# v0.1.2  apr/2021  by mountaineerbr

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

#video individual html pages
ROOTDOC="$ROOTV/doc"

#main index template
INDEXTEMPLATE="$ROOTV/i.html"
INDEXMAIN="$ROOTV/index.html"

#thumbnails (not automatically generated!)
ROOTTHUMB="$ROOTV/thumb"

#default video thumbnail
THUMBDEF="default.jpg"

#video file list by size
# max 100.000 KB
#msize=99000


set -e
setopt extendedglob  
setopt nullglob
setopt nocaseglob
cd "$ROOTV"

typeset -a prefiles files
#files=( $(du -s "$ROOTMED"/*.mp4) )
for filepath in "$ROOTMED"/*.(mp4|m4a|mpg|avi|mov)
do
	date="$(ffprobe "$filepath" 2>&1 | sed -En '/^\s*date/ s/.*:\s*([^\s]*)/\1/ p' <<<"$probe" )"
	prefiles+=("$date	$filepath")  #separator is a literal <TAB>
done

#sort
print -l "${prefiles[@]}" | sort -n |
while read FDATE FNAME
do files+=("$FNAME")
done

for filepath in "$files[@]"
do
	((++n))
	fname="${filepath##*/}"

	[[ -d "$filepath" ]] && continue
	#((fsize<msize))
	

	#
	size=( $(du -h "$filepath") )
	probe="$(ffprobe "$filepath" 2>&1)"
	#title="$(sed -En '/^\s*title/ s/.*:\s*([^\s]*)/\1/ p' <<<"$probe")"
	title="${fname%????}"  title="${title//_/ }"
	date="$(
		sed -En '/^\s*date/ s/.*:\s*([^\s]*)/\1/ p' <<<"$probe" |
		sed -E 's/([0-9]{4})([0-9]{2})([0-9]{2})/\1\/\2\/\3/'
		)"
	comm="$(
		sed -n '/^\s*comment/,/^\s*description/ p' <<<"$probe" |
		sed -E 's/^\s*(comment)?[: ]*// ;/^\s*description:/d'
		)"
	desc="$(
		sed -n '/^\s*description/,/^\s*Duration/ p' <<<"$probe" |
		sed -E 's/^\s*(description)?[: ]*// ;/^\s*Duration:/d ;4,$d'
		)"
	#deschtml="$( txt2html --extract --eight_bit_clean <<<"$desc" )"
	commhtml="$( txt2html --extract --eight_bit_clean <<<"$comm" )"
	
	dur="$(sed -En '/^\s*[Dd]uration/ s/.*[Dd]uration[: ]*([^\s]*),.*/\1/ p' <<<"$probe")"
	dur="${dur#00:}" dur="${dur#0}" dur="${dur%.*}"

	itemfullpath="$ROOTDOC/${fname%???}html"

	#add self-referencing canonical url
	canonical="<link rel=\"canonical\" href=\"${ROOTVW%/}/doc/${fname%???}html\">"

	for t in "$ROOTTHUMB/${fname%???}"(jpg|png|gif|jpeg)
	do [[ -e "$t" ]] && img="${t##*/}" && break
	done
	if [[ -z "$img" ]]
	then print "$SN: no thumbnail -- $fname" >&2 ;img="$THUMBDEF"
	fi
	
	#item html template
	item="
<div class=\"w3-row w3-margin\">

<div class=\"w3-third\">
  <a title=\"Click to go to video page\" href=\"doc/${fname%???}html\">
  <img src=\"thumb/$img\" style=\"width:100%;min-height:200px\">
  </a>
</div>
<div class=\"w3-twothird w3-container\">
  <a href=\"doc/${fname%???}html\">
  <h2>$title</h2></a>
  <p>$desc</p>
  <p>$date, $dur, ${size[1]}</p>
</div>
</div>
	"

	#full html injection
	injection="$item
	$injection"

	#relative url paths to video files
	videourl="media/$fname"
	videourl2="../media/$fname"

	#create a full html page per video
	cat >"$itemfullpath" <<-EOF
	<!DOCTYPE html>
	<html lang="pt">
	<head>
		<meta charset="UTF-8">
		<title>$title -- X GNU Bio</title>
		<meta name="viewport" content="width=device-width, initial-scale=1">
		<link rel="stylesheet" href="../../css/w3.css">
		$canonical
		<style>
			img
			{
				margin: auto;
				max-width: 600px;
			}
			p
			{
				font-size: 1.2em;
			}

			table th
			{
				text-align: left;
			}
			table
			{
				padding: 1em;
				margin: 1em;
			}
			table *
			{
				padding-right: 0.6em;
				padding-top: 0.4em;
			}

			 /* Container needed to position the play button */
			 /* https://www.w3schools.com/howto/howto_css_button_on_image.asp */
			.img-container {
			  position: relative;
			  /* width: 50%; */
			}

			/* Make the image responsive */
			/* .img-container img {
			  width: 100%;
			  height: auto;
			} */

			/* Style the button and place it in the middle of the container/image */
			.img-container .playbtn {
			  position: absolute;
			  top: 50%;
			  left: 50%;
			  transform: translate(-50%, -50%);
			  -ms-transform: translate(-50%, -50%);
			  background-color: #555;
			  color: white;
			  font-size: 16px;
			  padding: 12px 24px;
			  border: none;
			  cursor: pointer;
			  border-radius: 5px;
			}

			.img-container .playbtn:hover {
			  background-color: black;
			} 

		</style>

	</head>
	<body>
		<div class="w3-container w3-teal">
		<p class="w3-right"><a href="../"><em>[BACK]</em></a></p>
		<h1>$title</h1>
		</div>

		<br>
		<div class="w3-container w3-center img-container">
		<a title="Click to watch or download" href="$videourl2"><img src="../thumb/$img" alt="Video thumbnail">
		<button class="playbtn">Play</button></a>

		<!-- <video width="320" height="240" autoplay>
		  <source src="$videourl2" type="video/${fname##*.}">
		  Your browser does not support the video tag.
		</video> -->

		<!-- <button onclick="playPause()">Play/Pause</button> 
		<button onclick="makeBig()">Big</button>
		<button onclick="makeSmall()">Small</button>
		<button onclick="makeNormal()">Normal</button>
		<br><br>
		<video id="video1" width="420">
			<source src="$videourl2" type="video/${fname##*.}">
			Your browser does not support HTML video.
		</video> -->

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
 		<th>Size</th>
		<td>${size[1]}</td>
		</tr>

		<tr>
 		<th>File</th>
		<td><a href="$videourl2">$fname</a></td>
		</tr>

		<tr>
 		<th>License</th>
		<td>Attribution</td>
		</tr>

		</table>
		</div>

		<footer>
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

		<!--
		- - - -	Copyright ©2021 JSN.
		 - - -	Verbatim copying and distribution of this entire article is
		- - - -	permitted in any medium, provided this notice is preserved.
		-->
		</footer>
	</body>
	</html>
	EOF
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



#NOTES
# Using FFMPEG to Extract a Thumbnail from a Video
#{ ffmpeg -i InputFile.FLV -vframes 1 -an -s 400x222 -ss 30 OutputFile.jpg ;}
#https://networking.ringofsaturn.com/Unix/extractthumbnail.php
# Meaningful thumbnails for a Video using FFmpeg
#{ ffmpeg -ss 3 -i input.mp4 -vf "select=gt(scene\,0.4)" -frames:v 5 -vsync vfr -vf fps=fps=1/600 out%02d.jpg ;}
#https://superuser.com/questions/538112/meaningful-thumbnails-for-a-video-using-ffmpeg

