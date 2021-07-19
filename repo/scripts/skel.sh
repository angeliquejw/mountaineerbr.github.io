#!/bin/bash
#!/bin/zsh
# skel.sh  --  script skeleton and tips
# v0.2.5  jul/2021  by mountaineerbr
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
	$SN - desc


SYNOPSIS
	$SN [-dhv]

	

DESCRIPTION



ENVIRONMENT



SEE ALSO



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
	(1) 	??
		
		$ $SN -c


OPTIONS
	-d 	Debug, dump data.
	-h 	Help page.
	-v 	Script version."




#functions


#parse options
while getopts :0123456789dhj:v c
do case $c in
	[0-9]) SCL="${SCL}${c}" ;;
	d) OPTDEBUG=1 ;;
	h) echo "$HELP"; exit 0	;;
	j) JOBMAX="$OPTARG" ;;
	v) grep -m1 '^# v[0-9]' "$0" ;exit ;;
#	\?) echo "$SN: illegal option -- $c" >&2 ;exit 1 ;;
   esac
done
shift $(( OPTIND - 1 ))
unset c
#to enable management of illegal options,
#remove : from optstring

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
if (( OPTX ))
then
	#
	optxf "$@"
else
	#main function
	mainf "$@"
fi


exit



##semaphores
##job controls (not optimal)

#ksh
#check special shell variable $JOBMAX

#bash
#while JOBS=( $( jobs -p ) ) ;(( ${#JOBS[@]} > JOBMAX )) ;do sleep 1 ;done

#zsh
#while (( ${#jobstates[@]} > JOBMAX )) ;do sleep 1 ;done


#launch $JOBMAX jobs and wait for all of them to finish
#ksh-like (ksh has a builtin $JOBMAX)
#(( COUNTER % JOBMAX )) || wait

