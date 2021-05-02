#!/bin/zsh
# thumbler

#vlof root
ROOTV=/home/jsn/www/mountaineerbr.github.io/vlog
ROOTVW=https://www.mountaineerbr.github.io/vlog

#video database
ROOTMED="$ROOTV/media"

#thumbnails (not automatically generated!)
ROOTTHUMB="$ROOTV/thumb"


#start
set -e
cd "$ROOTMED"

for fname
do
	#fname="${fname##*/}"

	[[ -d "$fname" ]] && continue
	print "$fname"

	#
	# Using FFMPEG to Extract a Thumbnail from a Video
	#{ ffmpeg -i InputFile.FLV -vframes 1 -an -s 400x222 -ss 30 OutputFile.jpg ;}
	#https://networking.ringofsaturn.com/Unix/extractthumbnail.php
	# Meaningful thumbnails for a Video using FFmpeg
	#{ ffmpeg -ss 3 -i input.mp4 -vf "select=gt(scene\,0.4)" -frames:v 5 -vsync vfr -vf fps=fps=1/600 out%02d.jpg ;}
	#https://superuser.com/questions/538112/meaningful-thumbnails-for-a-video-using-ffmpeg
	

	#ffmpeg -i "$fname" -vframes 1 -an -ss 30 "$ROOTTHUMB/Athumb_%02d_${fname}.jpg"
	ffmpeg -ss 3 \
		-i "$fname" \
		-vf "select=gt(scene\,0.4)" \
		-frames:v 5 \
		-vsync vfr \
		-vf fps=fps=1/600 \
		"$ROOTTHUMB/thumb_%02d_${fname}.jpg"
done

