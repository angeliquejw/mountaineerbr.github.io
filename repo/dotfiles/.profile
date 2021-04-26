# ~/.profile
# 2021  by mountaineerbr
#                                                                      
#     ,o888888o.           .8.            d888888o. 8888888 8888888888 
#    8888     `88.        .888.         .`8888:' `88.     8 8888       
# ,8 8888       `8.      :88888.        8.`8888.   Y8     8 8888       
# 88 8888               . `88888.       `8.`8888.         8 8888       
# 88 8888              .8. `88888.       `8.`8888.        8 8888       
# 88 8888             .8`8. `88888.       `8.`8888.       8 8888       
# 88 8888            .8' `8. `88888.       `8.`8888.      8 8888       
# `8 8888       .8' .8'   `8. `88888.  8b   `8.`8888.     8 8888       
#    8888     ,88' .888888888. `88888. `8b.  ;8.`8888     8 8888       
#     `8888888P'  .8'       `8. `88888. `Y8888P ,88P'     8 8888       
#                                                                    
#         .8. `8.`888b                 ,8' .8.   `8.`8888.      ,8' 
#        .888. `8.`888b               ,8' .888.   `8.`8888.    ,8'  
#       :88888. `8.`888b             ,8' :88888.   `8.`8888.  ,8'   
#      . `88888. `8.`888b     .b    ,8' . `88888.   `8.`8888.,8'    
#     .8. `88888. `8.`888b    88b  ,8' .8. `88888.   `8.`88888'     
#    .8`8. `88888. `8.`888b .`888b,8' .8`8. `88888.   `8. 8888      
#   .8' `8. `88888. `8.`888b8.`8888' .8' `8. `88888.   `8 8888      
#  .8'   `8. `88888. `8.`888`8.`88' .8'   `8. `88888.   8 8888      
# .888888888. `88888. `8.`8' `8,`' .888888888. `88888.  8 8888      
#.8'       `8. `88888. `8.`   `8' .8'       `8. `88888. 8 8888
#
# art: figlet

# executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login exists.
# see /usr/share/doc/bash/examples/startup-files for examples.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
# umask 022

#make sure user locale is loaded (depends on user settings)
#I don't know of programs that will use ~/.config/locale.conf.
#Most (if not all) Linux/glibc programs use the LANG and LC_* environment 
#variables. So to have a working locale in your environment, you have to know
#how unix environment variables are inherited and from where in your case.
#https://arch-general.archlinux.narkive.com/XzmUEBIU/where-s-my-locale-gone
#unset LANG && source /etc/profile.d/locale.sh

#sourced by my ~/.zhenv, too.

#if running bash
#source from .bashrc if it exists
[[ -n "$BASH_VERSION" ]] &&
	[[ -f "$HOME/.bashrc" ]] && . "$HOME/.bashrc"

#set custom $PATH
for d in  \
	"/opt" \
	"$HOME/.local/bin" \
	"$HOME/bin/more" \
	"$HOME/bin" \
	"$HOME/bin/markets" \
	.
do
	if [[ -d "$d" ]] && [[ :"$PATH": != *:"${d:-x}":* ]]
	then PATH="$d:$PATH"
	fi
done
unset d

#set $CDPATH
CDPATH=".:..:$HOME:$HOME/bin:$CDPATH"
CDPATH="${CDPATH%:}"
#ex: % CDPATH=/etc
#ex: % cd mail
#pwd: /etc/mail
#https://linux.101hacks.com/cd-command/cdpath/
#a . is needed to cd into $PWD dir before any other in $CDPATH
#https://bosker.wordpress.com/2012/02/12/bash-scripters-beware-of-the-cdpath/

#go path
export GOPATH="$HOME/go"

#full-screen text editor
export VISUAL=vim
#stream editor
export EDITOR="$VISUAL"
#sudoers editor
export SUDO_EDITOR="$VISUAL"

#man pager
#export MANPAGER="vim -M +MANPAGER -u ~/.vimrc_manpager -"
#export MANWIDTH=83

#pager
#export PAGER=less

#ViFM c file
#MYVIFMRC="$VIFM/vifmrc"
#MYVIFMRC="$HOME/.vifmrc"

#fim, fbi improved file viewer
#export FBFONT=/usr/share/kbd/consolefonts/ter-216n.psf.gz

export QT_QPA_PLATFORMTHEME=qt5ct
export QT_SELECT=4
export QT_AUTO_SCREEN_SCALE_FACTOR=0
#export QT_SCALE_FACTOR=1  #for hi dpi
export GTK2_RC_FILES="$HOME/.gtkrc-2.0"
#https://github.com/manjaro/manjaro-xfce-settings/blob/master/skel/.profile

#gtk 3
#export NO_AT_BRIDGE=1
#keep gtk scrollbars from autohidding:
export GTK_OVERLAY_SCROLLING=0
#https://github.com/AladW/dotfiles/blob/master/xinit/.xinitrc
#https://github.com/linuxmint/Cinnamon/issues/5306

#xdg base directory specification
#export XDG_DATA_HOME="$HOME/.local/share"
#export XDG_CONFIG_HOME="$HOME/.config"
#export XDG_CACHE_HOME="$HOME/.cache"

#enable 32x32 cursors
#XCURSOR_SIZE=32
#from crystal-style icon-set (Marco Martin, 2004)

#set default repo for ala.sh script
#default repo?
#user set environment variable $DEFALAREPO ?
#export DEFALAREPO=month

#set temporary directory for gs.sh
export GSTMPDIR="$HOME/www"

#$BROWSER contains the path to the web browser
export BROWSER=w3m
#if [ -n "$DISPLAY" ]; then
#    export BROWSER=firefox
#else 
#    export BROWSER=links
#fi
#https://wiki.archlinux.org/index.php/environment_variables#Examples


#MOZILLA FIREFOX
#This content should be clarified
#`gfx.webrender.all = true' only works on Firefox Nightly
#https://mozillagfx.wordpress.com/2019/01/17/webrender-newsletter-36/
#To enable WebRender on Firefox Stable:
export MOZ_ACCELERATED=1 	#same as:`layers.acceleration.force-enabled = true'
#export MOZ_WEBRENDER=1 	#same as: `gfx.webrender.all = true'
#https://wiki.archlinux.org/index.php/Talk:Firefox/Tweaks

#Enable OpenGL in `pvkrun' and `primusrun'
#export LD_PRELOAD=/usr/lib/libGL.so
#export ENABLE_PRIMUS_LAYER=1
#{ ENABLE_PRIMUS_LAYER=1 optirun path/to/application ;}
#https://github.com/felixdoerre/primus_vk
#`LD_PROLOAD' causes problems with `seccomp', for eg `file .bashrc'
#Disable `seccomp' in this case, for eg `file -S .bashrc'
#{ LD_PRELOAD=/usr/lib/libGL.so firefox ;}
#Hardened malloc: https://wiki.archlinux.org/index.php/Security
#https://bugs.archlinux.org/task/65250
#https://bbs.archlinux.org/viewtopic.php?id=252257
#`layers.offmainthreadcomposition.enabled' became on by defaults.
#https://www.reddit.com/r/firefox/comments/4j0tzz/what_happened_to/

#Do *not* set if using NVIDIA `primusrun'
export MOZ_OMTC_ENABLED=1
export MOZ_USE_OMTC=1
#https://gist.github.com/yuttie/de097d004499adb984bd

#check performance running a demo from `mesa-demos'
#demos: glxgears -info, glxspheres64 and glxspheres32
#optirun [demo]
#optirun -b primus [demo]
#primusrun [demo]
#pvkrun  [demo]
#OBS: `optirun' is the only which enables NVIDIA renderer for me


#is it linux tty?
if [[ "$TERM" = linux ]]
then
	#set linux tty font
	#terminus-normal-18 or 20 (for 15" displays)
	setfont ter-u18n -m 8859-2

	#cursors for linux tty
	#normal blinking underline:
	#{ echo -e '\033[?2c';}
	#blinking block:
	#{ echo -e '\033[?6c';}
	#red non-blinking block:
	#{ echo -e '\033[?17;0;64c';}
	#bold white on red
	echo -e "\e[?16;0;74c"
	#is it possible that hardware has got default cursor colour?
	#https://linuxgazette.net/137/anonymous.html
	#VGA-softcursor.txt 
	#http://fxr.watson.org/fxr/source/Documentation/VGA-softcursor.txt?v=linux-2.4.22
	#as per reference, you may find crazy combinations (hardware-specific and unpredictable results)

	#linux tty text and background colours
	#bold  - extra  bright, mode on|off
	#invert fb and bg colours - --inversescreen on|off
	#{ setterm -background black -foreground green --bold on;}
	#https://unix.stackexchange.com/questions/55423/how-to-change-cursor-shape-color-and-blinkrate-of-linux-console
fi

#config for bitcoin.{blk,tx}.sh
export BITCOINCONF=/media/primary/blockchain/bitcoin.conf

#cgk.sh
#expiration of cache files in seconds
#set to 0 or unset to disable expiration
#export CGKEXPIRATION=259200  #(3 days)


#start x? - simple x init
#mystartxf()
#{
#	local REPLY
#	# If other than ROOT
#	if (( EUID > 0 ))
# 	then
#		## Start X Server?
#		printf 'Start X Server? y/N ' ;read
#		case $REPLY in
#			[Yy]* ) echo 'Yes!' ;startx ;;
#			[Nn]* ) echo 'Answer is no' ;;
#			* ) 	echo 'No!' >&2 ;;
#		esac
#	fi
#}
#mystartxf

