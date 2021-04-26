#!/bin/bash

# Written by Demetrio Ferro <ferrodemetrio@gmail.com> <https://twitter.com/DemetrioFerro>
# Distributed under license GPLv3+ GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY. YOU USE AT YOUR OWN RISK. THE AUTHOR
# WILL NOT BE LIABLE FOR DATA LOSS, DAMAGES, LOSS OF PROFITS OR ANY
# OTHER KIND OF LOSS WHILE USING OR MISUSING THIS SOFTWARE.
# See the GNU General Public License for more details.
# source : https://gist.github.com/red-noise/9789642
# adapted by http://www.erikdubois.be

first_album=""


	new_album=`dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:'org.mpris.MediaPlayer2.Player' string:'Metadata'|egrep -A 1 "album"|egrep -v "album"|cut -b 44-|cut -d '"' -f 1|egrep -v ^$`
	if [ "$new_album" != "$first_album" ]
	then
		first_album="$new_album"
		echo "$new_album"
	fi
	

