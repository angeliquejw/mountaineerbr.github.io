#!/bin/bash
#!/bin/zsh
# skel.sh  --  script skeleton and tips
# v0.2.10  jul/2021  by mountaineerbr
# https://github.com/mountaineerbr
#               __  ___                  
# _______ ____ / /_/ _ |_    _____ ___ __
#/ __/ _ `(_-</ __/ __ | |/|/ / _ `/ // /
#\__/\_,_/___/\__/_/ |_|__,__/\_,_/\_, / 
#                                 /___/  
#                        __       _                  ___     
#  __ _  ___  __ _____  / /____ _(_)__  ___ ___ ____/ _ )____
# /  ' \/ _ \/ // / _ \/ __/ _ `/ / _ \/ -_) -_) __/ _  / __/
#/_/_/_/\___/\_,_/_//_/\__/\_,_/_/_//_/\__/\__/_/ /____/_/   
                                                            

#defaults

#script name
SN="${0##*/}"
#script filepath
SCRIPT_PATH="$0"

#set locale
#export LC_NUMERIC=C

#help page
HELP="NAME
	$SN - Short Description


SYNOPSIS
	$SN [-dhv]

	Text.

DESCRIPTION
	More text.


ENVIRONMENT
	JOBMAX 	Maximum number of background jobs.


SEE ALSO
	Refs.


WARRANTY
	Licensed under the GNU Public License v3 or better and
	is distributed without support or bug corrections.
   	
	This script requires ?? and ?? to work properly.

	If you found this useful, please consider sending me a
	nickle!  =)

		bc1qlxm5dfjl58whg6tvtszg5pfna9mn2cr2nulnjr


AUTHOR



BUGS



USAGE EXAMPLES
	(1) 	Function example.
		
		$ $SN -c


OPTIONS
	-d 	Debug, dump data.
	-h 	Help page.
	-v 	Script version."


#functions
main()
{
	:
}


#parse options
while getopts 0123456789dhj:v c
do case $c in
	[0-9]) SCL="${SCL}${c}" ;;
	d) OPTDEBUG=1 ;;
	h) echo "$HELP"; exit 0	;;
	j) JOBMAX="$OPTARG" ;;
	v) grep -m1 '^# v[0-9]' "$0" ;exit ;;
	\?) exit 1 ;;
   esac
done
shift $(( OPTIND - 1 ))
unset c
#to enable management of illegal options,
#add : as the first character in optstring

#required packages
for pkg in ??
do if ! command -v "$pkg" &>/dev/null
   then echo "$SN: err  -- $pkg is required" >&2 ;exit 1
   fi
done
unset pkg

#consolidate max background jobs
#JOBMAX="${JOBMAX:-4}"

#set traps
#trap cleanf EXIT
#trap trapf SIGINT SIGTERM

#call opt functions
#fun x
if (( OPTX ))
then optxf "$@"
#main function
else mainf "$@"
fi


exit



##semaphores
##job controls

#launch $JOBMAX jobs and wait for all of them to finish
#ksh-like (ksh has a built-in batch mechanism, check $JOBMAX)
#((COUNTER % JOBMAX)) || wait


#not ideal semaphores
#below, the sleep time must be tweaked according to the processing
#requirements of the job and machine processor speed. if badly set,
#sleep time may actually throttle processing!

#bash semaphore
#usage: semaphore [maximum_jobs] [sleep_time]
#example: while true ;do semaphore ; (cmd ;cmd) & done
#while jobs=( $(jobs -p) ) ;((${#jobs[@]} > JOBMAX)) ;do sleep 1 ;done

#zsh semaphore
#while ((${#jobstates[@]} > JOBMAX)) ;do sleep 1 ;done


