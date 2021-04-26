#!/usr/bin/bash
#open some tradingview windows at specific screen positions
#screen resolution at 1366x768, one display

#sleep between new windows opening
SLEEP=2
#script name
SNAME="${0##*/}"

#get window id
getidf() {
	ids=( $( xdotool search --name tradingview ) )
	ID="${ids[-1]}" ||
		echo "$SNAME: cannot get window ID" >&2
}

#demonise first google-chrome
{
google-chrome-stable --app=https://www.tradingview.com/chart/ISmYtO7U/
getidf
xdotool windowsize "$ID" 680 700 
xdotool windowmove "$ID" 0 0
} &
#first sleep may need to be increased to allow chrome opening fully
sleep 6

google-chrome-stable --app=https://www.tradingview.com/chart/vSIVmcxS/
getidf
xdotool windowsize "$ID" 680 700 
xdotool windowmove "$ID" 680 0
sleep $SLEEP

google-chrome-stable --app=https://www.tradingview.com/chart/h2YRqfnP/
getidf
xdotool windowsize "$ID" 680 700
xdotool windowmove "$ID" 10 10
sleep $SLEEP

google-chrome-stable --app=https://www.tradingview.com/chart/nNx9sErC/
getidf
xdotool windowsize "$ID" 680 700 
xdotool windowmove "$ID" 690 10

disown 
echo "$SNAME: took $SECONDS seconds to execute" >&2

