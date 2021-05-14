#!/bin/zsh
# mountaineerbr  may/2021
# Create pages for exploring directories and files
# Requires `markdown' and `txt2html'.
# <https://archlinux.org/packages/extra/x86_64/discount/>
# <https://www.pell.portland.or.us/~orc/Code/discount/>
# <https://daringfireball.net/projects/markdown/basics>

#script name
SN="${0##*/}"
#home page root
ROOT="$HOME/www/mountaineerbr.github.io"
#repo root
ROOTR="$ROOT/repo"

#start
set -e
setopt extendedglob


#try to autosync files from repos
##requires script `diffcp.sh"
export HOTRUN=1
cd "$ROOTR"/scripts && diffcp.sh  --  ~/bin  *.sh 
cd "$ROOTR"/markets && diffcp.sh  --  ~/bin/markets  *.sh 
cd "$ROOTR"/dotfiles && diffcp.sh  --  ~  .*(.) 
cd "$ROOTR"/dotfiles/.config/vifm && diffcp.sh  --  ~/.config/vifm  vifmrc
cd "$ROOTR"/dotfiles/.newsboat && diffcp.sh  --  ~/.newsboat  urls
cd  "$ROOTR"


#STEP 1
#MAKE TAR FILES FROM DIRECTORIES
./mktar.sh "$@"


#STEP 2
#GENERATE HTML PAGES WITH `TREE'
./tree.sh


