#!/bin/bash
# Start Web Browser with NVIDIA Graphics Card
# 2021  by mountaineerbr

#user choice
user="$1"

#firefox path
ff=/bin/firefox
#chromium path
ch=/bin/chromium
#chrome path
cr=/bin/google-chrome-stable


case "$user" in
#run chrome?
chrome*)
	browser="$cr"
	
	;;
#run chromium?
chrom*)
	browser="$ch"
	
	;;
#run firefox
*)
	browser="$ff"

	#This content should be clarified
	#`gfx.webrender.all = true' only works on Firefox Nightly
	#https://mozillagfx.wordpress.com/2019/01/17/webrender-newsletter-36/
	#To enable WebRender on Firefox Stable:
	export MOZ_ACCELERATED=1 	#same as:`layers.acceleration.force-enabled = true'
	#export MOZ_WEBRENDER=1 	#same as: `gfx.webrender.all = true'
	#https://wiki.archlinux.org/index.php/Talk:Firefox/Tweaks

	#While recent Firefox releases have seen VA-API video acceleration
	#working when running natively under Wayland, the Firefox 80
	#release later this summer will bring VA-API support by default
	#to those running on a conventional X.Org Server.
	#export MOZ_X11_EGL=1
	#https://www.phoronix.com/scan.php?page=news_item&px=Firefox-80-VA-API-X11

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

	;;
esac

#
if command -v optirun
then /bin/optirun "$browser" &
#elif command -v pvkrun
#then /bin/pvkrun "$browser" #&
#elif command -v primusrun
#then /bin/primusrun "$browser" #&
else command "$browser" &
fi

#check performance running a demo from `mesa-demos'
#demos: glxgears -info, glxspheres64 and glxspheres32
#optirun [demo]
#optirun -b primus [demo]
#primusrun [demo]
#pvkrun  [demo]
#OBS: `optirun' is the only which enables NVIDIA renderer for me
	

disown

