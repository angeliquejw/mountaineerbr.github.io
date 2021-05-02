#!/bin/zsh
# thumbler

#vlof root
ROOTV=/home/jsn/www/mountaineerbr.github.io/vlog
ROOTVW=https://www.mountaineerbr.github.io/vlog

#video database
ROOTMED="$ROOTV/media"

#thumbnails (not automatically generated!)
ROOTTHUMB="$ROOTV/thumb"


set -e
cd "$ROOTMED"

#Intro_do_Canal.mp4  
# *.mp4
#Diario_de_Criptomoedas_2.mp4  Bitcoin_Em_Queda_Crash_Ao_Vivo.mp4  Chuva_no_Por-do-Sol_da_Universidade.mp4  Intro_do_Canal.mp4  Bitcorn_10_000.mp4  Black_Week_do_Bitcoin.mp4  Nano_VIm_Abrir_Arquivo_Ja_na_Posicao_Especifica.mp4  Repos_do_Arch_Linux_Archive_ALA_e_Downgrade_de_Pacotes_no_Pacman.mp4  Sobre_Backups_de_Backups_de_Dados.mp4
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

