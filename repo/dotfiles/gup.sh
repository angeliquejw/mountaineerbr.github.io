#!/bin/zsh
# lazy script to update these files for me
# v0.1  dec/2020  by mountaineerbr


set -e

setopt extendedglob globstarshort nullglob

#~/ dotfiles
#~/.config
diffcp.sh  "$HOME"  .*(.)  .config/**(.)

#/etc
cd etc
diffcp.sh  /etc  *(.)
cp -f /etc/pacman.d/mirrorlist pacman.d/mirrorlist
cd ..

