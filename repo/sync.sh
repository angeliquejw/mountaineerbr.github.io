#!/bin/zsh
# mountaineerbr  apr/2021
# Create pages for exploring directories and files
# Requires `markdown' and `txt2html'.
# <https://archlinux.org/packages/extra/x86_64/discount/>
# <https://www.pell.portland.or.us/~orc/Code/discount/>
# <https://daringfireball.net/projects/markdown/basics>

#script name
SN="${0##*/}"


#start
set -e

#STEP 1
#MAKE TAR FILES FROM DIRECTORIES
./mktar.sh


#STEP 2
#GENERATE HTML PAGES WITH `TREE'
./tree.sh


