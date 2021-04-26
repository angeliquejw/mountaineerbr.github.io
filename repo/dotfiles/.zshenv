#
# ~/.zshenv
#

#source from ~/.profile
[[ -r "$HOME/.profile" ]] && . "$HOME/.profile"

#set PATH  ##set in .profile
#typeset -U path
#path=( . "$HOME/bin" "$HOME/bin/markets" "$HOME/bin/more" $path )

#set PATH
#typeset -U cdpath  ##set in .profile
#cdpath=( . "$HOME" "$HOME/bin" $cdpath )
#you had the options auto_cd and cdable_vars turned on. with auto_cd, 
#if you type a directory as a command name, the cd command is implied.
#with cdable_vars, if a directory doesn't exist, or a command doesn't
#exist with auto_cd, then the name is looked up in the directory hash table
#https://unix.stackexchange.com/questions/284105/zsh-hash-directory-completion

