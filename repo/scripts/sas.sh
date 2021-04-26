#!/bin/bash
#set audio streams for my system 
#external hdmi monitor speakers + external loudspeakers + laptop builtin speakers

#this script needs to perform various steps
# set card profile ==>>==>> default-sink combined ==>>
#    ==>> default-sink ladspa (filter) ==>>==>> alsa mixer settings
#
#a profile can be stored with
# $ alsactl --file ~/.config/asound.state store
#
#set default profile for pulseaudio:
#https://www.whatsdoom.com/posts/2015/12/01/configure-pulseaudio-output-via-command-line/
#https://unix.stackexchange.com/questions/462670/set-default-profile-for-pulseaudio

#defaults
#script name
SN="${0##*/}"
#sleep time
S=2

#all stderr
exec >&2
#exit on error
#set -e

if [[ -n "${TMUX}" ]]; then
	printf '%s: cannot run inside TMUX session\n\a' "$SN"
	exit 1
fi

cat <<!
[ ################ Set Audio Streams ################ ]
[         Setting Pulseaudio card profile...          ]
!

#set card profile
pacmd set-card-profile 0 output:analog-stereo+output:hdmi-stereo

#check for combined sink
if ! pacmd list-sinks | grep -q combined; then
	cat <<!
[         Set a combined sink...                      ]
!
	sleep "$S"
	#create combined sink	
	pacmd load-module module-combine-sink sink_name=combined \
		slaves=alsa_output.pci-0000_00_1f.3.analog-stereo,alsa_output.pci-0000_00_1f.3.hdmi-stereo

fi

cat <<!
[    Setting Pulseaudio default-sink to combined...   ]
!
sleep "$S"
#set default sink to combined
pacmd set-default-sink combined

#equalizer setting
#cat <<!
#[ Setting Pulseaudio default-sink to LADSPA-plugin... ]
#!
#pacmd set-default-sink ladspa_output.mbeq_1197.mbeq

cat <<!
[     Setting ALSA Mixer streams volumes right...     ]
!
#restore alsa mixer profile
alsactl --background --file ~/.config/asound.state restore

cat <<!
[ ********************** Done! ********************** ]
!

