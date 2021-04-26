#!/bin/zsh
# vi:filetype=sh
# v0.3.26 dec/2020  by mountaineer_br
# ts.sh - test repetitive commands

#<<it's important to have a test suite that runs in a reasonable amount of
#time to increase the chances of tests being run and that they don't
#impact developer flow too much>>

#script path
SCRIPT="$0"
#script name
SN="${0##*/}"

#defaults
SLEEPDEF=1
TIMEOUTDEF=5
LOGFILE="/tmp/$SN.$$.log"

#add scripts to $PATH
#PATH=$HOME/some/path:$PATH

#invocation shell
ISHELL=/usr/bin/bash

COLOR1='\e[1;37;44m'
COLOR2='\e[1;33;41m'
COLOREND='\e[0;00m'

#default post-command
CAT=head
#CAT=tail
#CAT=cat

HELP="$SN - Test repetitive commands

SYNOPSIS
	$SN [-ael] [-i [bash|zsh]] [-sNUM] [-tNUM] NICKNAME [CMDMOD] [STARTPOS]

	$SN [-hllv]


	Test repetitive script commands for debbuging.

	NICKNAME is a set-up name referencing a script test group of
	commands. It is required setting up script nickname and test
	commands in this script source code to run them.

	Option '-i' changes the invocation shell, i.e. which shell
	will run commands and that is responsible to positional par-
	ameter interpretation and glob expansion.

	CMDMOD is a pre-command modifier. For example, if invocation
	shell is 'zsh', then CMDMOD may be 'noglob'.

	STARTPOS is an index number of the testing command array to
	start execution instead from the first testing command. It
	must be an integer value.

	For a little demo, run:

		$ ${ZSH_SOURCE[0]} test


OPTIONS
	-a 	Disable printing command head, print full output.
	-e 	Stop on error.
	-h 	Show this help.
	-i [bash|zsh]
		Invocation/interactive shell which will run the script,	inter-
		pret positional arguments (globbing etc); tested with bash and
		zsh; defaults=${ISHELL}
	-l 	Do not log to ${LOGFILE}.
	-ll	Remove script-made log files.
	-s [NUM]
		Sleep time between testing commands; defaults=${SLEEPDEF}.
	-t [NUM]
		Timeout; defaults=${TIMEOUTDEF}.
	-v 	Print this script version."



#testing script and cmd arrays
#scripts must use full path
#or be under user $PATH

bcalcf()
{
	savefile="$HOME/.bcalc_record"
	[[ -f "$savefile" ]] &&
		mv "$savefile" "${savefile}Bak$(date +%s)"
	
	CMD=(

'bcalc.sh 50.7891798100000000000000000+978169872'
'bcalc.sh 507891798100000000000000000+0'
'bcalc.sh -2 50.78917981+978169872'
'bcalc.sh \(100+100/2\)*2'
'bcalc.sh 2^2+\(8-4\)'
'bcalc.sh -s2 100/120'
'bcalc.sh \(100+100\)/1'
'bcalc.sh ans+33'
'bcalc.sh -t -s4 50000*5'
'bcalc.sh -c 0.234\*na'
'bcalc.sh -t -s2 <<<70000.450000'
'bcalc.sh -t2 <<<70000.450000'
'bcalc.sh -n This is my note.'
'bcalc.sh -t -2 50000*5'
'bcalc.sh -v'
"bcalc.sh -- -0.2*10"
"bcalc.sh '-0.2*10'"
'bcalc.sh -c ln\(0.3\)'
'bcalc.sh -c log\(0.3\)'
'bcalc.sh "a=5; -a+20"'
'bcalc.sh 3/4'
'bcalc.sh -3/4'
'bcalc.sh res'

)
}

cgkf()
{
	CMD=(
'cgk.sh -H eth brl'
'cg.sh -t xrp eur'
'cgk.sh -bg brl usd'
'cgk.sh -11'
'cgk.sh -s12'
'cgk.sh -b "1*28.3495" eur xau'
'cgk.sh -b "1/28.3495" xau eur'
'cgk.sh 1470 usdt xau'
'cgk.sh -bg 1 xau brl'
'cgk.sh -bg 199 brl xau'
'cgk.sh btc'
'cgk.sh 1 btc usd'
'cgk.sh -b btc dgb'
'cgk.sh -b -s8 100 zcash digibyte'
'cgk.sh -b -s8 100 zec dgb'
'cgk.sh -b -s4 1000 brl usd'
'cgk.sh -b xau'
'cgk.sh -b 1 xau usd'
'cgk.sh 1 btc xau'
'cgk.sh -t eth'
'cgk.sh -t -p3 eth btc'
'cgk.sh -m cny'
'cgk.sh 1 btc xau'
'cgk.sh -x 100000000 btc xau'

)
}

clayf()
{
	CMD=(
'clay.sh brl'
'clay.sh 1 brl usd'
'clay.sh usd brl'
'clay.sh  xau usd'
'clay.sh -g usd brl '
'clay.sh -g 51 usd xau'
'clay.sh -10'
'clay.sh -10g xag brl'
'clay.sh -s11 xag brl'
'clay.sh -s3 50 djf cny'
)
}

binancef()
{
	CMD=(
'binance.sh -rw eth usdt'
'binance.sh -ri btc usdt'
'binance.sh -bbu eth usdt'
'binance.sh -cu xrp'
'binance.sh -f4 xrp usdc'
'binance.sh -3 xrp usdc'
'binance.sh -0 xrp usdc'
'binance.sh -f1 btc usdt'
'binance.sh -f btc usdt'
'binance.sh btc usdt'
'binance.sh -u btc usdt'
'binance.sh 0.5 dash bnb'
'binance.sh 100 zec pax'
'binance.sh -3 xrp usdc'
'binance.sh -l'
'binance.sh -l | grep -i BTC'
'binance.sh -a2us btc.usd' #don't change the grep tests!
)
}

cmcf()
{
	CMD=(
'cmc.sh -t'
'cmc.sh -t btc'
'cmc.sh -t xrp'
'cmc.sh -tt 5 btc'
'cmc.sh -bg brl usd'
'cmc.sh -11'
'cmc.sh -s12'
'cmc.sh -b "1*28.3495" eur xau'
'cmc.sh -b "1/28.3495" xau eur'
'cmc.sh 1570 usdt xau'
'cmc.sh -bg 1 xau brl'
'cmc.sh -bg 199 brl xau'
'cmc.sh btc'
'cmc.sh 1 btc usd'
'cmc.sh dash zec'
'cmc.sh -b cad jpy'
'cmc.sh -b -s4 1000 brl usd'
'cmc.sh -m jpy'
'cmc.sh 1 btc xau'
'cmc.sh -x 100000000 btc xau'
'cmc.sh -a'

)
}

binfof()
{
	CMD=(
'binfo.sh -l'
'binfo.sh -b | head -10'
'binfo.sh -b 00000000d1145790a8694403d4063f323d499e655c83426834d4ce2f8dd4a2ee | tail -10'
'binfo.sh -n 0'
'binfo.sh -s 34xp4vRoCGJym3xR7yCVPFHoCNxv4Twseo'
'binfo.sh -ss 34xp4vRoCGJym3xR7yCVPFHoCNxv4Twseo'
'binfo.sh -a 34xp4vRoCGJym3xR7yCVPFHoCNxv4Twseo'
'binfo.sh -a 34xp4vRoCGJym3xR7yCVPFHoCNxv4Twseo|tail -10'
'binfo.sh -aa 34xp4vRoCGJym3xR7yCVPFHoCNxv4Twseo|head -10'
'binfo.sh -aa 34xp4vRoCGJym3xR7yCVPFHoCNxv4Twseo|tail -10'
'binfo.sh -t a1075db55d416d3ca199f55b6084e2115b9345e16c5cf302fc80e9d5fbf5d48d'
'binfo.sh -i'
'binfo.sh -ii'

)
}

alaf()
{
	CMD=(
'ala.sh'
'ala.sh f'
'ala.sh -2 f'
'ala.sh -2 firefox'
'ala.sh firefox'
'ala.sh month/core/os/x86_64'
'ala.sh -2 month/core/os/x86_64'
'ala.sh -2s 2019/09/01'
'ala.sh -s last'
'ala.sh -2s last'
'ala.sh -n'
'ala.sh -2'
'ala.sh -i'
'ala.sh -2i'
'ala.sh -i 2019.10.01'
'ala.sh -2i 2019.10.01'
'ala.sh -w vim-8.1.2268-2-x86_64.pkg.tar.xz'
'ala.sh -2w vim-8.1.2268-2-x86_64.pkg.tar.xz'
'ala.sh 2014 jan 20'
'ala.sh -2 2014 january 20'
'ala.sh -s 2019/09/01'
'ala.sh last'
'ala.sh .'
'ala.sh /'
'ala.sh -i /'
'ala.sh 2015 01 20'
'ala.sh 2015 01 20..'
'ala.sh 2015--jan-20..'
'ala.sh 2015'
'ala.sh 20160101'

'ala.sh -k grep week'
'ala.sh -k grep /2020/01/01/core'
'ala.sh -k grep /2020/01/01/core..'
'ala.sh -2k firefox /2014/01/01 community i686..'
'ala.sh /2014/01/01 community i686..'
'ala.sh 2015..'  #should not autocomplete
'ala.sh 201501..'  #should not autocomplete
'ala.sh -i 2007.05-Linuxtag2007/'
'ala.sh 2 days ago'

)
}

alphaf()
{
	CMD=(
'alpha.sh'
'alpha.sh aapl'
'alpha.sh usd brl'
'alpha.sh -d aapl'
'alpha.sh -d usd brl|less'
'alpha.sh -m aapl'
'alpha.sh -j aapl'
'alpha.sh -jj usd jpy'
)
}

stocksf()
{
	CMD=(
'stocks.sh -s '
'stocks.sh -i .ixic'
'stocks.sh -i'
'stocks.sh .ixic'
'stocks.sh -t aapl'
'stocks.sh -tt aapl'
'stocks.sh aapl'
'stocks.sh 10 aapl'
'stocks.sh -q Oil'

)
}

antaf()
{
	CMD=(
'anta.sh -f https://www.oantagonista.com/brasil/o-que-o-congresso-ressuscitou-na-lei-de-abuso-de-autoridade/'
'anta.sh "/brasil/o-que-o-congresso-ressuscitou-na-lei-de-abuso-de-autoridade/" "/brasil/toffoli-nega-ter-recebido-e-acessado-relatorios-do-coaf/"'
'anta.sh -p2'
'anta.sh -f -2'
'anta.sh -f2'
'anta.sh -11'
'anta.sh -r -s"10m"'
'anta.sh -r -s600'
'anta.sh 12512'

)
}

#debug/testing funct
echof()
{
	CMD=(
'echo testing..; exit 54'
'echo testing..; exit 141'
'echo testing..; exit 124'
'echo testing..; exit 0'
'cat -Z testing..'
'cat "$SCRIPT"'
)
}

#testf helper
feedbackf()
{
	print "\n${COLOR1}cmd[$((++counter))/${#CMD}]: ${testcmd}${COLOREND}  "
}

## Functions
# The testing loop
testf()
{
	#test for no cmd in list
	if (( ${#CMD[@]} == 0 ))
	then
		print "$SN: err -- CMD list is empty" >&2
		exit 1
	fi

	## Trap Ctr+D to kill this script
	trapf

	#set counter
	counter=$(( ${INDEX:-1} - 1 ))

	#heading
	cat >&2 <<-!
	Cmds_____: ${#CMD}
	Sleep____: ${SLEEP}
	Timeout__: ${TIMEOUT}
	CmdModif_: ${CMDMOD:-none}
	InvcShell: ${ISHELL}
	CmdIndex_: ${INDEX:-1}
	!

	sleep 1

	#test loop
	##set -o pipefail  #requires zsh ver>5.0.8
	while read testcmd
	do

		#print feedback
		feedbackf >&2

		#run testing command
		timeout "${TIMEOUT}" \
			"${ISHELL}" -c "${CMDMOD} ${testcmd}" |
			"$CAT"

		#check exit code
		EXITC=( "${pipestatus[@]}" )
		
		case "${EXITC[1]}" in
			( [1-9]* )
				((++counterX))
				;|
			( 124 )
				((++counterb))
				;;
			( 141 )
				((++counterc))
				;;
			( [1-9]* )
				[[ -n "${STOPOPT}" ]] && exit 1
				;;
		esac
		
		#print feedback
		print "${COLOR2}Exit ${EXITC[1]}${COLOREND}  " >&2

	done <<< "$( print -l "${CMD[@]}" | tail -n+${INDEX:-1} )"
	
	#report
	cat >&2 <<-!

	Exit Report
	Logfile_______: ${LOGFILE:-unset}
	Execution_time: ${SECONDS}s
	Total_errors__: ${counterX:=0}
	Timeout(124)__: ${counterb:=0} 	-cmd took too long
	PipeClose(141): ${counterc:=0} 	-head or tail closed pipe early
	*Other_errors_: $((counterX-counterb-counterc))
	!

}

# Trap Ctr+D to kill this script
trapf() { trap 'break 2>/dev/null' INT TERM;}


# Parse options
while getopts aelhi:ps:t:v opt
do
	case $opt in
		a )
			# disable head command on output of testing commands
			CAT=cat
			;;
		e )
			# Stop on error
			STOPOPT=1
			;;
		h )
			# Help
			print "${HELP}"
			exit 0
			;;
		l )
			# Don't Log to tmp or remove tmp files
			if (( LOGOPT ))
			then
				if ! rm -v "${LOGFILE}"*
				then
					print "$SN: err -- no log files removed" >&2
					exit 1
				fi
				exit 0
			else
				LOGOPT=1
			fi
			;;
		t ) #timeout
			TIMEOUT="$OPTARG"
			;;
		s ) #sleep between testing cmds
			#confusing opts -s and -i ..
			if [[ "$OPTARG" = [0-9]* ]]
			then
				SLEEP="${OPTARG}"
			else
				ISHELL="$OPTARG"
			fi
			;;
		i ) #invocation/interactive shell
			ISHELL="$OPTARG"
			;;
		v ) # Version of Script
			grep -m1 '# v' "${0}"
			exit 0
			;;
		\? )
			#print "$SN: invalid option -- -${OPTARG}" >&2
			exit 1
			;;
	 esac
done
shift $((OPTIND -1))

#set testing command array
case "$1" in
	( test | echo )
		SLEEPC=1
		echof
		;;
	( ala* )
		TIMEOUTC=10
		alaf
		;;
	( alpha* )
		SLEEPC=11
		alphaf
		;;
	( stocks* )
		#SLEEPC=
		TIMEOUTC=15
		stocksf
		;;
	( bcalc* )
		bcalcf
		;;
	( cgk* )
		SLEEPC=1.2
		cgkf
		;;
	( clay* )
		clayf
		;;
	( binance* )  
		SLEEPC=0.2
		binancef
		;;
	( cmc* )
		SLEEPC=2.5
		cmcf
		;;
	( binfo* )
		binfof
		;;
	( anta* )
		antaf
		;;
	( * )
		print "$SN: test undefined -- ${1:-null}" >&2
		exit 1
esac
shift

#set indexes and commands
[[ "$1" = [a-zA-Z]* ]] && CMDMOD="$1"
[[ "$2" = [a-zA-Z]* ]] && CMDMOD="$1 $2"
[[ "$1" = [0-9]* ]] && INDEX="$1"
[[ "$2" = [0-9]* ]] && INDEX="$2"

## Set sleep time
SLEEP="${SLEEP:-${SLEEPC:-${SLEEPDEF}}}"
TIMEOUT="${TIMEOUT:-${TIMEOUTC:-${TIMEOUTDEF}}}"

## Run tests
## Don't Log?
if (( LOGOPT ))
then
	unset LOGFILE
	testf
else
	TIME="$( date +%s )"
	LOGFILE="$( mktemp "${LOGFILE}.${TIME}.XXXXXX" )" || exit 1
	
	testf >( tee >( sed -e 's/\x1b\[[0-9;]*m//g' -e 's/\r//g' > "${LOGFILE}" ) ) \
		2> >( tee >( sed -e 's/\x1b\[[0-9;]*m//g' -e 's/\r//g' > "${LOGFILE}") 1>&2 )
fi
#https://stackoverflow.com/questions/692000/how-do-i-write-stderr-to-a-file-while-using-tee-with-a-pipe

exit

#dead code
#setopt MULTIOS
#testf &>( sed -e 's/\x1b\[[0-9;]*m//g' -e 's/\r//g' > "${LOGFILE}" ) &>/dev/stdin

