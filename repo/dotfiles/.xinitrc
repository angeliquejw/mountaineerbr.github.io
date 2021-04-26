#!/bin/sh

#some defaults files are not present
#in arch linux by defaults

sysresources=/etc/X11/xinit/.Xresources
sysmodmap=/etc/X11/xinit/.Xmodmap
userresources="$HOME/.Xresources"
usermodmap="$HOME/.Xmodmap"

# merge in defaults and keymaps
if [ -f $sysresources ]; then


	xrdb -merge $sysresources
fi

if [ -f $sysmodmap ]; then


	xmodmap $sysmodmap
fi

if [ -f "$userresources" ]; then


	xrdb -merge "$userresources"
fi

if [ -f "$usermodmap" ]; then
	
	#hack: wait until xfce starts
	{ sleep 40; xmodmap "$usermodmap" ;} &
fi
#xmodmap and xfce4 may not well together.
#culprit may be panel plugin xfce4-xkb-plugin
#https://unix.stackexchange.com/questions/119994/xmodmap-configuration-get-resetted-after-some-time
#https://lists.debian.org/debian-user/2011/04/msg01875.html

# start some nice programs
if [ -d /etc/X11/xinit/xinitrc.d ] ; then 
	for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
		[ -x "$f" ] && . "$f"
	done
	unset f
fi

#start picom (fork of compton)
picom -b

#nvidia driver
#xrandr --setprovideroutputsource modesetting NVIDIA-0
#xrandr --auto

#load key binding
xbindkeys

#start xfce4
exec startxfce4
#if you want to run Xfce4 from .xinitrc, only use »startxfce4 --with-ck-
#launch« (only on non-systemd systems). »startxfce4« itself starts dbus
#and (if advised and not already running) consolkit in a proper way.
#»ck-launch-session dbus-launch …« tend to break session stuff and is wrong. 
#http://xfce.10915.n7.nabble.com/startxfce4-and-ck-launch-td50149.html

#start tim wm
#twm &
#xclock -geometry 50x50-1+1 &
#xterm -geometry 80x50+494+51 &
#xterm -geometry 80x20+494-0 &
#exec xterm -geometry 80x66+0+0 -name login

