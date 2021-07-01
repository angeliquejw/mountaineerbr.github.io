#
# ~/.zshrc
# 2021  by mountaineerbr
#               __  ___
# _______ ____ / /_/ _ |_    _____ ___ __
#/ __/ _ `(_-</ __/ __ | |/|/ / _ `/ // /
#\__/\_,_/___/\__/_/ |_|__,__/\_,_/\_, /
#                                 /___/

#tmux
#this enables one command to be run when tmux exits.
#it can be another exit or any simple command.
#exit signal file (may hold a command).
__TMUXSIG="/tmp/tmux.exit.$EUID"
#start tmux
if [[ -z "$TMUX$VIFMSET" ]] && (( EUID ))
then
	command tmux

	#is exit signal file present?
	if [[ -f "$__TMUXSIG" ]]
	then
		#execute a simple command
		set -- "$( <"$__TMUXSIG" )"
		rm "$__TMUXSIG"
		eval "$*"
	fi
fi
#exit tmux and terminal emulator, too
qq()
{
	#create signal file
	[[ -n "$TMUX" ]] && echo exit >"$__TMUXSIG"
	echo '[bye..]' >&2
	sleep 0.5
	exit
}

#requires GRML's zshrc for base configs
#grmlzsh() wget -qO- https://git.grml.org/f/grml-etc-core/etc/zsh/zshrc
grmlzsh()
{
	local last="$(curl -s http://deb.grml.org/pool/main/g/grml-etc-core/ |
		sed -e 's/</ </g; s/<[^>]*>//g' -ne '/tar.gz/p' |
		sort -V | awk 'END {print $1}')"

	curl "http://deb.grml.org/pool/main/g/grml-etc-core/$last" |
		tar --extract --wildcards -Ozf - '*/etc/zsh/zshrc'
}
#doc: grml-etc-core*/doc/grmlzshrc.t2t
#https://grml.org/zsh/

#set xterm font
#if [[ -z "${TMUX}" ]]; then
#	echo -e "\e]50;-xos4-terminus-medium-r-*--18-*-*-*-*-*-*-*\a"
#fi

#report time of script execution time
#export REPORTTIME=-1  #do not report
export REPORTTIME=60
#it measures cpu time, not wall clock. commands explicitly marked with
#the time keyword still cause the summary to be printed in this case.

#don’t write over existing files with >
#setopt NOCLOBBER  #use >! instead

#set default pager for '% <file'
export READNULLCMD=less  #defaults=more
#export NULLCMD=cat  #defaults=cat

##add as many underscores as you want in zshell opts
#do not ignore comands that start with space
unsetopt HIST__IGNORE__SPACE  #same as histignorespace

#visual beep
setopt BEEP

#globbing
setopt G_L___OB_ST_A_R__SH____ORT
#**/*c  -> **c

# don't throw errors when file globs don't match anything
#setopt NULL_GLOB
# only throw errors when no globs match anything
#setopt CSH_NULL_GLOB

#If a pattern for filename generation has no matches, leave it unchanged
#do not print an error
#setopt NOMATCH
#or use '$ noglob cmd' to ensure that no glob expansion
#will be performed in any case.

#do not require a leading `.' in a filename to be matched explicitly.
#setopt GLOB_DOTS
#or use '**string(D)'

#avoids reflexively the rm prompt when `rm  *'  or  `rm  path/*'
#wait ten seconds and ignore anything typed in that time
setopt RM_STAR_WAIT

#do not add to history, however it stays in the interactive history
HISTORY_IGNORE='(q|qq)'
#HISTORY_IGNORE="(ls|cd|pwd|exit|cd)"
HISTSIZE=10000
SAVEHIST=1000000

#load zcalc
autoload -Uz zcalc

#load zargs
autoload -U zargs

# zcalc ()  { print $(( ans = ${1:-ans} )) }
zcalch () { print $(( [#16] ans = ${1:-ans} )) }
zcalcd () { print $(( [#10] ans = ${1:-ans} )) }
zcalco () { print $(( [#8] ans = ${1:-ans} )) }
zcalcb () { print $(( [#2] ans = ${1:-ans} )) }
#this last one lets you calculate the ascii value of a single character
zcalcasc () { print $(( [#16] ans = ##${1:-ans} )) }

#a key binding that will allow you to quickly get into zcalc
#bindkey -s '\C-xd' "zcalc \'"

#move and rename files
#zmv '(*).mp3' '$1.wma'

#hash customd dirs
#maybe CDABLE_VARS must be enabled
hash -d media=/run/media
hash -d arq=~/arq
hash -d docs=~/arq/docs
hash -d bin=~/bin
hash -d markets=~/bin/markets
hash -d mkt=~/bin/markets
hash -d bak=~/bak
hash -d tmp=~/tmp
hash -d Doc=~/Documents
hash -d w=~/Downloads
hash -d dl=~/Downloads


#list all binded keys
#bindkey
#obs
#\e is ESC
#^ is Ctrl
#^[[1; is Alt?

#exit shell on partial command line
exit_zsh() { exit }
zle -N exit_zsh
bindkey '^D' exit_zsh

#ctrl+u to kill from cursor to the start of line
#in zsh ctrl+u it deletes whole line
bindkey -e
bindkey \^U backward-kill-line

#expand aliases on space
#expand-alias() { zle _expand_alias; zle self-insert;}
#zle -N expand-alias
#bindkey -M main ' ' expand-alias

#file manager key binds
#first comes back in directory history (Alt+Left)
#the second let the user go to the parent directory (Alt+Up)
cdUndoKey()
{
	popd
	zle reset-prompt
	echo
	ls
	zle reset-prompt
}

cdParentKey()
{
	pushd ..
	zle reset-prompt
	echo
	ls
	zle reset-prompt
}
zle -N cdParentKey
zle -N cdUndoKey
bindkey '^[[1;3A' cdParentKey
bindkey '^[[1;3D' cdUndoKey
#https://wiki.archlinux.org/index.php/Zsh#Configuration_frameworks

# global aliases (expand whatever their position)
# # e.g. find . E L
#alias -g :E='2> /dev/null'
#alias -g :C='| wc -l'
#alias -g :H='| head'
#alias -g :L='|& less'
#alias -g :S='| sort'
#alias -g :SN='| sort -n'
#alias -g :T='| tail'
#unglobalalias() {
# 	for i in ':E' ':C' ':H' ':L' ':S' ':SN' ':T'; unalias $i
#}
#https://matt.blissett.me.uk/linux/zsh/zshrc

#insert octothorpe at beggingin of line
bindkey '\e\#' pound-insert  #ESC-#

#bins -- list all executable files in $PATH as called by basename
bins()
{
	rehash
	whence -p ${(kon)commands}
}

#base NUM -- convert between bases
#20jul2014  +chris+  zsh function
base()
{
	setopt LOCAL_OPTIONS C_BASES OCTAL_ZEROES
	printf "%s = %08d %d 0%o 0x%x\n" $1 ${$(([#2] $1))#2\#} $(($1)) $(($1)) $(($1))
}


# ltime - start and run time of last commands
# 05feb2018  +leah+  use tail -n
ltime()
{
	fc -liDI | tail -n ${1:-10}
}

# clot - fill screen with garbage, as visual separator
# 17aug2015  +chris+
# 11mar2016  +chris+ print seperate lines
clot()
{
	head -c $((LINES*COLUMNS)) </dev/urandom |
		LC_ALL=C tr '\0-\377' ${(l:256::.*o@:)} |
		fold -w $COLUMNS
}

# wrap - wrap long lines using backslashes
wrap()
{
	perl -pe 's/.{'$(( ${COLUMNS:-80} - 1))'}/$&\\\n/g' -- "$@"
}
#https://leahneukirchen.org/dotfiles/.zshrc


#sources

#.rc extensive aliases ans functions
#command-not-found hook from pkgfile
#zsh syntax highliting plugin
for f in \
	~/.rc \
	/usr/share/doc/pkgfile/command-not-found.zsh \
	/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
do
	[[ -r "$f" ]] && . "$f"
done
unset f

#highlight brackets
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)  #(pattern)


#declare user-overidable styles
#ZSH_HIGHLIGHT_STYLES[default]=none
#ZSH_HIGHLIGHT_STYLES[unknown-token]=fg=red,bold
#ZSH_HIGHLIGHT_STYLES[reserved-word]=fg=green
#ZSH_HIGHLIGHT_STYLES[alias]=none
#ZSH_HIGHLIGHT_STYLES[builtin]=none
#ZSH_HIGHLIGHT_STYLES[function]=none
#ZSH_HIGHLIGHT_STYLES[command]=none
#ZSH_HIGHLIGHT_STYLES[precommand]=none
#ZSH_HIGHLIGHT_STYLES[commandseparator]=none
#ZSH_HIGHLIGHT_STYLES[hashed-command]=none
#ZSH_HIGHLIGHT_STYLES[path]=none
#ZSH_HIGHLIGHT_STYLES[path_prefix]='none'
#ZSH_HIGHLIGHT_STYLES[path_approx]='fg=yellow'
ZSH_HIGHLIGHT_STYLES[globbing]=fg=blue,bold
#ZSH_HIGHLIGHT_STYLES[history-expansion]=fg=blue
#ZSH_HIGHLIGHT_STYLES[single-hyphen-option]=none
#ZSH_HIGHLIGHT_STYLES[double-hyphen-option]=none
#ZSH_HIGHLIGHT_STYLES[back-quoted-argument]=none
#ZSH_HIGHLIGHT_STYLES[single-quoted-argument]=fg=yellow
#ZSH_HIGHLIGHT_STYLES[double-quoted-argument]=fg=yellow
#ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]=fg=cyan
#ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]=fg=cyan
#ZSH_HIGHLIGHT_STYLES[assign]=none
#https://blog.patshead.com/2012/01/using-and-customizing-zsh-syntax-highlighting-with-oh-my-zsh.html
#https://blog.aktsbot.in/color-me-baby.html

#When you hit return it saves the cursor position, and then it's restored when
#moving to the last command in the history
#https://www.zsh.org/mla/users/2008/msg00607.html

#sometimes, I will start typing a command, realize I do not want to execute
#it, hit CTRL-C, only to realize I would have saved a lot of typing if I
#had instead modified it. What I would love to see is a feature that
#holds onto the last buffer content and revives it into ZLE, so to speak.
#alt-q does the job. If don't, just add to zshrc;
#bindkey "ESC-q" push-line

#from alan third
most_useless_use_of_zsh()
{
    local lines columns colour a b p q i pnew
    ((columns=COLUMNS-1, lines=LINES-1, colour=0))
    for ((b=-1.5; b<=1.5; b+=3.0/lines)) do
        for ((a=-2.0; a<=1; a+=3.0/columns)) do
            for ((p=0.0, q=0.0, i=0; p*p+q*q < 4 && i < 32; i++)) do
                ((pnew=p*p-q*q+a, q=2*p*q+b, p=pnew))
            done
            ((colour=(i/4)%8))
            echo -n "\\e[4${colour}m "
        done
        echo
    done
}

#fun
#usage:  haha [word] [+interger]
haha() ( x=.2; y=0.00000002; i=$x; [[ $1 = [0-9+]* ]] && set - "$2" $1; while { i=$(( i ${sign:--} ( i / ${2:-10} ) )) } { print -n "\e[${RANDOM:1:1};${RANDOM:1:2};${RANDOM:1:2}m${1:-haha?}\e[0m"; sleep $i; ((i<y)) && sign=+; ((i>=x)) && sign=- } )

#quote positional args '$@'
#${(q)^^@}
#${(qq)^^@}
#print ${(qq)^^@}

#get name of last file matching the glob?
#file*.ext([-1])

#read prompting mechanism
#read 'foo?prompt: '
#read '?Delete these merged branches? '
#answer in $REPLY

#command : to create empty file
#$ : >file

#array elements one per line
#echo "${ARRAY[@]}" | xargs -n 1 command
#echo ${(j:\n:)ARRAY} | command
#print -l "$a[@]"
#command "$ARRAY[@]"  #if feasible

##two args from fields of same line
#awk '{print $1,$2}' FILE | xargs -n 2 mv

#the rule is:  define first those aliases you expect to use in the body
#of a function, but define the function first if the alias has the same
#name as the function.


#search history when Up or Down is pressed
#this widget is better than grml-zsh defaults
up-history()
{
	#zle up-line-or-search $LBUFFER
	zle history-beginning-search-backward
}
down-history()
{
	#zle down-line-or-search $LBUFFER
	zle history-beginning-search-forward
}
zle -N up-history
zle -N down-history
bind2maps emacs viins vicmd -- Up     up-history
bind2maps emacs viins vicmd -- Down   down-history
#see also these other widgets:
#zle up-line-or-history
#zle history-beginning-search-backward
#zle .up-history


# Filename:      /etc/skel/.zshrc
# Purpose:       config file for zsh (z shell)
# Authors:       (c) grml-team (grml.org)
# Bug-Reports:   see http://grml.org/bugs/
# License:       This file is licensed under the GPL v2 or any later version.
################################################################################
# Nowadays, grml's zsh setup lives in only *one* zshrc file.
# That is the global one: /etc/zsh/zshrc (from grml-etc-core).
# It is best to leave *this* file untouched and do personal changes to
# your zsh setup via ${HOME}/.zshrc.local which is loaded at the end of
# the global zshrc.
#
# That way, we enable people on other operating systems to use our
# setup, too, just by copying our global zshrc to their ${HOME}/.zshrc.
# Adjustments would still go to the .zshrc.local file.
################################################################################

## Inform users about upgrade path for grml's old zshrc layout, assuming that:
## /etc/skel/.zshrc was installed as ~/.zshrc,
## /etc/zsh/zshrc was installed as ~/.zshrc.global and
## ~/.zshrc.local does not exist yet.
if [ -r ~/.zshrc -a -r ~/.zshrc.global -a ! -r ~/.zshrc.local ]
then
    printf '-!-\n'
    printf '-!- Looks like you are using the old zshrc layout of grml.\n'
    printf '-!- Please read the notes in the grml-zsh-refcard, being'
    printf '-!- available at: http://grml.org/zsh/\n'
    printf '-!-\n'
    printf '-!- If you just want to get rid of this warning message execute:\n'
    printf '-!-        touch ~/.zshrc.local\n'
    printf '-!-\n'
fi

## Settings for umask
#if (( EUID == 0 )); then
#    umask 002
#else
#    umask 022
#fi

## Now, we'll give a few examples of what you might want to use in your
## .zshrc.local file (just copy'n'paste and uncomment it there):

## Prompt theme extension ##

# Virtualenv support

#function virtual_env_prompt () {
#    REPLY=${VIRTUAL_ENV+(${VIRTUAL_ENV:t}) }
#}
#grml_theme_add_token  virtual-env -f virtual_env_prompt '%F{magenta}' '%f'
#zstyle ':prompt:grml:left:setup' items rc virtual-env change-root user at host path vcs percent

## ZLE tweaks ##

## use the vi navigation keys (hjkl) besides cursor keys in menu completion
#bindkey -M menuselect 'h' vi-backward-char        # left
#bindkey -M menuselect 'k' vi-up-line-or-history   # up
#bindkey -M menuselect 'l' vi-forward-char         # right
#bindkey -M menuselect 'j' vi-down-line-or-history # bottom

## set command prediction from history, see 'man 1 zshcontrib'
#is4 && zrcautoload predict-on && \
#zle -N predict-on         && \
#zle -N predict-off        && \
#bindkey "^X^Z" predict-on && \
#bindkey "^Z" predict-off

## press ctrl-q to quote line:
#mquote () {
#      zle beginning-of-line
#      zle forward-word
#      # RBUFFER="'$RBUFFER'"
#      RBUFFER=${(q)RBUFFER}
#      zle end-of-line
#}
#zle -N mquote && bindkey '^q' mquote

## define word separators (for stuff like backward-word, forward-word, backward-kill-word,..)
#WORDCHARS='*?_-.[]~=/&;!#$%^(){}<>' # the default
#WORDCHARS=.
#WORDCHARS='*?_[]~=&;!#$%^(){}'
#WORDCHARS='${WORDCHARS:s@/@}'

# just type '...' to get '../..'
#rationalise-dot() {
#local MATCH
#if [[ $LBUFFER =~ '(^|/| |	|'$'\n''|\||;|&)\.\.$' ]]; then
#  LBUFFER+=/
#  zle self-insert
#  zle self-insert
#else
#  zle self-insert
#fi
#}
#zle -N rationalise-dot
#bindkey . rationalise-dot
## without this, typing a . aborts incremental history search
#bindkey -M isearch . self-insert

#bindkey '\eq' push-line-or-edit

## some popular options ##

## add `|' to output redirections in the history
#setopt histallowclobber

## try to avoid the 'zsh: no matches found...'
#setopt nonomatch

## warning if file exists ('cat /dev/null > ~/.zshrc')
#setopt NO_clobber

## don't warn me about bg processes when exiting
#setopt nocheckjobs

## alert me if something failed
#setopt printexitvalue

## with spelling correction, assume dvorak kb
#setopt dvorak

## Allow comments even in interactive shells
#setopt interactivecomments


## compsys related snippets ##

## changed completer settings
#zstyle ':completion:*' completer _complete _correct _approximate
#zstyle ':completion:*' expand prefix suffix

## another different completer setting: expand shell aliases
#zstyle ':completion:*' completer _expand_alias _complete _approximate

## to have more convenient account completion, specify your logins:
#my_accounts=(
# {grml,grml1}@foo.invalid
# grml-devel@bar.invalid
#)
#other_accounts=(
# {fred,root}@foo.invalid
# vera@bar.invalid
#)
#zstyle ':completion:*:my-accounts' users-hosts $my_accounts
#zstyle ':completion:*:other-accounts' users-hosts $other_accounts

## add grml.org to your list of hosts
#hosts+=(grml.org)
#zstyle ':completion:*:hosts' hosts $hosts

## telnet on non-default ports? ...well:
## specify specific port/service settings:
#telnet_users_hosts_ports=(
#  user1@host1:
#  user2@host2:
#  @mail-server:{smtp,pop3}
#  @news-server:nntp
#  @proxy-server:8000
#)
#zstyle ':completion:*:*:telnet:*' users-hosts-ports $telnet_users_hosts_ports

## the default grml setup provides '..' as a completion. it does not provide
## '.' though. If you want that too, use the following line:
#zstyle ':completion:*' special-dirs true

## aliases ##

## translate
#alias u='translate -i'

## ignore ~/.ssh/known_hosts entries
#alias insecssh='ssh -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -o "PreferredAuthentications=keyboard-interactive"'

## global aliases (for those who like them) ##

#alias -g '...'='../..'
#alias -g '....'='../../..'
#alias -g BG='& exit'
#alias -g C='|wc -l'
#alias -g G='|grep'
#alias -g H='|head'
#alias -g Hl=' --help |& less -r'
#alias -g K='|keep'
#alias -g L='|less'
#alias -g LL='|& less -r'
#alias -g M='|most'
#alias -g N='&>/dev/null'
#alias -g R='| tr A-z N-za-m'
#alias -g SL='| sort | less'
#alias -g S='| sort'
#alias -g T='|tail'
#alias -g V='| vim -'

## instead of global aliase it might be better to use grmls $abk assoc array, whose contents are expanded after pressing ,.
#$abk[SnL]="| sort -n | less"

## get top 10 shell commands:
#alias top10='print -l ${(o)history%% *} | uniq -c | sort -nr | head -n 10'

## Execute \kbd{./configure}
#alias CO="./configure"

## Execute \kbd{./configure --help}
#alias CH="./configure --help"

## miscellaneous code ##

## Use a default width of 80 for manpages for more convenient reading
#export MANWIDTH=${MANWIDTH:-80}

## Set a search path for the cd builtin
#cdpath=(.. ~)

## variation of our manzsh() function; pick you poison:
#manzsh()  { /usr/bin/man zshall |  most +/"$1" ; }

## Switching shell safely and efficiently? http://www.zsh.org/mla/workers/2001/msg02410.html
#bash() {
#    NO_SWITCH="yes" command bash "$@"
#}
#restart () {
#    exec $SHELL $SHELL_ARGS "$@"
#}

## Handy functions for use with the (e::) globbing qualifier (like nt)
#contains() { grep -q "$*" $REPLY }
#sameas() { diff -q "$*" $REPLY &>/dev/null }
#ot () { [[ $REPLY -ot ${~1} ]] }

## get_ic() - queries imap servers for capabilities; real simple. no imaps
#ic_get() {
#    emulate -L zsh
#    local port
#    if [[ ! -z $1 ]] ; then
#        port=${2:-143}
#        print "querying imap server on $1:${port}...\n";
#        print "a1 capability\na2 logout\n" | nc $1 ${port}
#    else
#        print "usage:\n  $0 <imap-server> [port]"
#    fi
#}

## List all occurrences of programm in current PATH
#plap() {
#    emulate -L zsh
#    if [[ $# = 0 ]] ; then
#        echo "Usage:    $0 program"
#        echo "Example:  $0 zsh"
#        echo "Lists all occurrences of program in the current PATH."
#    else
#        ls -l ${^path}/*$1*(*N)
#    fi
#}

## Find out which libs define a symbol
#lcheck() {
#    if [[ -n "$1" ]] ; then
#        nm -go /usr/lib/lib*.a 2>/dev/null | grep ":[[:xdigit:]]\{8\} . .*$1"
#    else
#        echo "Usage: lcheck <function>" >&2
#    fi
#}

## Download a file and display it locally
#uopen() {
#    emulate -L zsh
#    if ! [[ -n "$1" ]] ; then
#        print "Usage: uopen \$URL/\$file">&2
#        return 1
#    else
#        FILE=$1
#        MIME=$(curl --head $FILE | \
#               grep Content-Type | \
#               cut -d ' ' -f 2 | \
#               cut -d\; -f 1)
#        MIME=${MIME%$'\r'}
#        curl $FILE | see ${MIME}:-
#    fi
#}

## Memory overview
#memusage() {
#    ps aux | awk '{if (NR > 1) print $5;
#                   if (NR > 2) print "+"}
#                   END { print "p" }' | dc
#}

## print hex value of a number
#hex() {
#    emulate -L zsh
#    if [[ -n "$1" ]]; then
#        printf "%x\n" $1
#    else
#        print 'Usage: hex <number-to-convert>'
#        return 1
#    fi
#}

## log out? set timeout in seconds...
## ...and do not log out in some specific terminals:
#if [[ "${TERM}" == ([Exa]term*|rxvt|dtterm|screen*) ]] ; then
#    unset TMOUT
#else
#    TMOUT=1800
#fi

## associate types and extensions (be aware with perl scripts and anwanted behaviour!)
#check_com zsh-mime-setup || { autoload zsh-mime-setup && zsh-mime-setup }
#alias -s pl='perl -S'

## ctrl-s will no longer freeze the terminal.
#stty erase "^?"

## you want to automatically use a bigger font on big terminals?
#if [[ "$TERM" == "xterm" ]] && [[ "$LINES" -ge 50 ]] && [[ "$COLUMNS" -ge 100 ]] && [[ -z "$SSH_CONNECTION" ]] ; then
#    large
#fi

## Some quick Perl-hacks aka /useful/ oneliner
#bew() { perl -le 'print unpack "B*","'$1'"' }
#web() { perl -le 'print pack "B*","'$1'"' }
#hew() { perl -le 'print unpack "H*","'$1'"' }
#weh() { perl -le 'print pack "H*","'$1'"' }
#pversion()    { perl -M$1 -le "print $1->VERSION" } # i. e."pversion LWP -> 5.79"
#getlinks ()   { perl -ne 'while ( m/"((www|ftp|http):\/\/.*?)"/gc ) { print $1, "\n"; }' $* }
#gethrefs ()   { perl -ne 'while ( m/href="([^"]*)"/gc ) { print $1, "\n"; }' $* }
#getanames ()  { perl -ne 'while ( m/a name="([^"]*)"/gc ) { print $1, "\n"; }' $* }
#getforms ()   { perl -ne 'while ( m:(\</?(input|form|select|option).*?\>):gic ) { print $1, "\n"; }' $* }
#getstrings () { perl -ne 'while ( m/"(.*?)"/gc ) { print $1, "\n"; }' $*}
#getanchors () { perl -ne 'while ( m/«([^«»\n]+)»/gc ) { print $1, "\n"; }' $* }
#showINC ()    { perl -e 'for (@INC) { printf "%d %s\n", $i++, $_ }' }
#vimpm ()      { vim `perldoc -l $1 | sed -e 's/pod$/pm/'` }
#vimhelp ()    { vim -c "help $1" -c on -c "au! VimEnter *" }


#http://zsh.sourceforge.net/FAQ/zshfaq02.html
alias -- -="fg %-"

## END OF FILE #################################################################

