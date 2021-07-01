#
# ~/.bashrc
# 2021  by mountaineerbr
                           #                 ###
                    #                        # ##
#####  #  # ## #### ##  #  # ####  #   #  ## ###  ##
# # # # # #  # #  # #   ## # #  # ### ### #  #  # #
# # # # # #  # #  # #  # # # #  # #   #   #  #  # #
# # #  #   ### # ## ##  ## # # ##  ##  ## #  ###  #

# This file is sourced by all *interactive* bash shells on startup,
# including some apparently interactive shells such as scp and rcp
# that can't tolerate any output. So make sure this doesn't display
# anything or bad things will happen !

# Test for an interactive shell. There is no need to set anything
# past this point for scp and rcp, and it's important to refrain from
# outputting anything in those cases.

# If not running interactively, don't do anything
[[ "$-" != *i* ]] && return
#https://wiki.archlinux.org/index.php/Talk:Bash

#set xterm font
#if [[ -z "$TMUX" ]]; then
#	echo -e "\e]50;-xos4-terminus-medium-r-*--18-*-*-*-*-*-*-*\a"
#fi

#tmux
#[[ -z "$TMUX" ]] && (( EUID > 0 )) && tmux
#[[ -z "$TMUX" ]] && exec tmux

#set ps1
if (( EUID == 0 ))
then PS1='\[\033[01;31m\][\h\[\033[01;36m\] \W\[\033[01;31m\]]\$\[\033[00m\] '
#this is the PS1 control for the normal user
else PS1='\[\033[01;32m\][\[\033[01;33m\]\w\[\033[01;32m\]]\$\[\033[00m\] '
fi
#https://misc.flogisoft.com/bash/tip_colors_and_formatting
#https://www.reddit.com/r/linux/comments/94nh4w/what_is_your_ps1/

#history configuration
#max 'history file' size (in lines)
HISTSIZE=10000
#for 'history list' size
HISTFILESIZE=10000
#default HISTFILESIZE is set to follow HISTSIZE
#set custom history file
#HISTFILE="${HOME}/.bash_history"

#history duplicate controls
#history erases duplicates
HISTCONTROL=erasedups:ignoredups
#HISTCONTROL is a colon-separated list of values

#history ignore cmds
HISTIGNORE=bash:q:exit:x:su:sdh:sdr:shutdown

#history date format
#HISTTIMEFORMAT="[%F %T]: "
HISTTIMEFORMAT="$( echo -e "\033[0;32m[%F %T]:\033[0m " )"
#end colour code: \033[0m
#https://gist.github.com/avelino/3188137

#history appending & relaoding the 'history list'
#	( -a ) append history lines from this session to the history file
#	( -n ) read all history lines not already read
#	from the history file and append them to the history list
PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"
#the History file MUST be initialized with one line of text!
#if the variable $PROMPT_COMMAND has already been set:
#PROMPT_COMMAND="$PROMPT_COMMAND; cmd1; cmd2"
#if set, the value is executed as a command prior to issuing each primary prompt
#https://unix.stackexchange.com/questions/18212/bash-history-ignoredups-and-erasedups-setting-conflict-with-common-history
#https://www.shellhacks.com/tune-command-line-history-bash/
#http://web.archive.org/web/20090815205011/http://www.cuberick.com/2008/11/update-bash-history-in-realtime.html
#help history


#globs will ignore filenames with control characters, leading dashes,
#or begin with a ".", as well as traditional hidden files (names beginning
#with "."), yet accept reasonable patterns (including those beginning with
#"./" and "../" and even multiple "../")
#GLOBIGNORE=`printf '.[!/.]*:..[!/]*:*/.[!/.]*:*/..[!/]*:*[\001-\037\177]*:-*'`
#https://dwheeler.com/essays/fixing-unix-linux-filenames.html


#SHell OPTions

#glob
shopt -s globstar  #nocaseglob

#globs for excluding . and ..
#{ **/.[^.]*/**/*rc  **/..?*/**/*rc ;}
#https://unix.stackexchange.com/questions/75786/how-do-i-specify-arguments-to-return-all-dot-files-but-not-and

#lastpipe
#shopt -s lastpipe
#in interactive shell job control is active; disbale with 'set +m'
#if set, and job control is not active, the shell runs the last command of a pipeline not executed in the background in the current shell environment.

#history appending instead of overwriting
#shopt -s histappend
#same as if i'history -a' is set in COMMAND_PROMPT

#history verificatioin before exec
# 	Results of history substitution are not immediately
#	passed to the shell parser (histverify)
shopt -s histreedit cmdhist
#history cmd edition
# 	User is given the opportunity to re-edit a
#	failed history substitution (histreedit)
shopt -s histverify

#history & multi-line
# 	Easy re-editing of multi-line commands
#	Bash  attempts to save all lines of a
# 	multiple-line cmd in the same history entry
#shopt -s cmdhist

#cd magic for minor spelling fixes
# 	Minor errors in spelling of directory component
# 	in a cd command will be corrected. The errors
# 	checked for are transposed char, missing char,
# 	and one char too many.
shopt -s cdspell

#cd auto type
#	Add "cd" when entering just a path
# 	Bash automatically prepend cd
shopt -s autocd

#bash won't get SIGWINCH if another process is in the foreground.
#enable checkwinsize so that bash will check the terminal size when it regains control.
#http://cnswww.cns.cwru.edu/~chet/bash/FAQ (E11)
shopt -s checkwinsize

#alias expansion
#shopt -s expand_aliases

#accidental exiting
#Ctrl+D conveniently exits Bash, sometimes too conveniently
#specify that it must be pressed twice to exit
#export IGNOREEOF=1

#enable vi mode
#set -o vi

#sources

#.rc
#comand-not-found hook from pkgfile
for f in \
	~/.rc \
	/usr/share/doc/pkgfile/command-not-found.bash
do [[ -r "$f" ]] && . "$f"
done
unset f

#bash-completion
f=/usr/share/bash-completion/bash_completion
if [[ -n "$PS1" ]] && [[ -f "$f" ]]
then . "$f"
fi
unset f

#the fuck
eval "$( thefuck --alias )"

#https://github.com/scop/bash-completion
#complete Cmd Names (-c and subsequent cmds)
#complete file names ( -f )
#complete -cf sudo
#this complete built-in may interfere with bash-completions
#https://forum.manjaro.org/t/how-to-auto-complete-a-command-with-sudo-privilege/50263/24

#dirs stack
#add current dir to stack (top of stack is nought)
#alias p.='pushd .'
#check dirs stack
alias d='dirs -v'

#hack the cd command to remember where you have been
#function cd
#{
#    if [ $# -eq 0 ]; then
#        pushd ~ > /dev/null
#    elif [ " $1" = " -" ]; then
#        pushd "$OLDPWD" > /dev/null
#    else
#        pushd "$@" > /dev/null
#    fi
#}
#https://www.redhat.com/sysadmin/cd-command


#custom ls
l()
{
	ls -hF --group-directories-first "${@}" \
		| cut -c1-22 | column -c 80
}
la()
{
	ls -ahF --group-directories-first "${@}" \
		| cut -c1-22 | column -c 80
}
alias ll="ls++ --potsf"
#https://unix.stackexchange.com/questions/112335/can-i-truncate-long-file-names-in-ls-listing/112341#112341

#cd and ls dir
cl()
{
	local dir="$*"
	# if no dir given, go home
	(($# < 1)) && dir="$HOME"

	# use your preferred ls command
	builtin cd "$dir" && ls -F --color=auto
}
#https://opensource.com/article/19/7/bash-aliases

#quit like in z-shell
alias bye=exit

# Enable aliases to be sudo’ed
#alias sudo='sudo '

#"repeat" command.  Like:
#  repeat 10 echo foo
repeat()
{
	local i=  count="$1"
	shift
	for i in $(seq 1 "$count")
	do eval "$@"
	done
}

# Subfunction needed by `repeat'.
#seq ()
#{
# 	local lower upper output;
# 	lower=$1 upper=$2;
#
# 	if [ $lower -ge $upper ]; then return; fi
# 	while [ $lower -le $upper ];
# 	do
# 		echo -n "$lower "
# 		lower=$(($lower + 1))
# 	done
# 	echo "$lower"
#}

# Function which adds an alias to the current shell and to
# the ~/.bash_aliases file.
add-alias()
{
	local name=$1 value="$2"
	echo alias $name=\'$value\' >>~/.bash_aliases
	eval alias $name=\'$value\'
	alias $name
}


#some interesting stuff
#/usr/share/doc/bash/examples/{functions,misc,scripts,startup-files}
#also in bash source package


# Instalacao das Funcoes ZZ (www.funcoeszz.net)
export ZZOFF=""  # desligue funcoes indesejadas
export ZZPATH="$HOME/bin/more/funcoeszz/funcoeszz"  # script
export ZZDIR="$HOME/bin/more/funcoeszz/zz"    # pasta zz/
#source "$ZZPATH"

#ligar funcoezz
alias ZZ='source "'$ZZPATH'"'

