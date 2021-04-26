#!/usr/bin/bash
# v0.4.2  mar/2021  by mountaineerbr
#sync a git repository in one go (simple)

#defaults

#git user
defuser=mountaineerbr
#git repo
defrepo=dotfiles
#commit msg
defmsg='sync'
#default file(s) to update
#files=( "$HOME/.bashrc" )

#editor
VISUAL="${VISUAL:-vim}"
export VISUAL

#file manager
deffm=vifm
#deffm=thunar

#temporary directory for git clones
tmpdir="${TMPDIR:-/tmp}"

#overwrite defaults
#get parameter definition from user environment
[[ -n "$GSUSER" ]] && defuser="$GSUSER"
#env def repo
[[ -n "$GSREPO" ]] && defrepo="$GSREPO"
#env def file manager
[[ -n "$GSFILEMAN" ]] && deffm="$GSFILEMAN"
#env def temporary directory
[[ -d "$GSTMPDIR" ]] && tmpdir="$GSTMPDIR"

#script name
SN="${0##*/}"

#help
HELP="$SN -- Sync a git repository in one go (git wrapper)


SINOPSYS
	$SN  [-FFG] [-Mmsg] [-[R][user/]repo] [-Ssubpath/of/repo] /path/to/file..


	Clone a repo, copy new files to it and sync to github. If REPO
	is all lowercase, the uppercase R in flag -R is not required.
	Alternatively, REPO may be set in the format USER/REPO .

	The script will clone a repository into a temporary directory;
	if the repository exists already, user may hard reset the repo
	to HEAD with option -F or remove and reclone before any files
	are copied over with option -FF. Option -G will make a soft reset.
	Warning: there may need running \`git push --force' manually after-
	wards to overwrite remote branch with local changes.

	User may set a persistent directory to store repos with
	\$GSTMPDIR , check ENVIRONMENT section below.

	The script will copy target files, if any, to cloned repository.
	A prompt menu will give a chance for the user navigate to the
	cloned repo folder with her file manager and also to set a new
	commit message. The commit message can be one a one-liner or
	longer text, in which case an editor buffer will be opened
	(requires \`\`vipe'' from moreutils). Finally, the script will
	try to push changes.

	If you set option -S to a relative path under the repository
	structure, all files will be copied to that location instead
	of the repository root.

	Set default user and default repo in script head source code,
	section defaults.


ENVIRONMENT
	An environment variable must have been exported. The following
	variables are read by this script:

	\$GSFILEMAN 	Sets default file manager; defaults=$deffm .
	\$GSREPO 	Sets default repo; defaults=$defrepo .
	\$GSTMPDIR 	Sets default temporary directory; if not
			Sets default to TMPDIR=$tmpdir .
	\$GSUSER 	Sets default git user; defaults=$defuser .
	\$VISUAL 	Sets text editor for editing commit messages.


USAGE EXAMPLES
	1. Copy .bashrc and .zshrc to repo dotfiles:

		$  $SN  -dotfiles ~/.bashrc ~/.zshrc


	2. Copy .vifmrc to repo dotfiles subdirectory (vifm folder):
	
		$  $SN  -dotfiles -S.config/vifm ~/.config/vifm/vifmrc


	3. Clone a repo from other user, in this case Grondilu's
	   bitcoin-bash-tools repository:

		$  $SN  gs.sh -grondilu/bitcoin-bash-tools


OPTIONS
	-F 	Hard-reset local git repo before copying new files.
	-FF 	Remove local git repo and reclone before copying files.
	-G 	Soft-reset local git repo.
	-M 'COMMIT MESSAGE'
		Commit message, accepts multiple lines.
	-R 'REPOSITORY'
		User repository name.
	-S 'SUBPATH/OF/CLONE'
		Repository subpath to copy new files."


#functions

#trap func
trapf()
{
	trap \  EXIT
	[[ -d "$tmpdir" ]] && echo -e "\nGit_dir_: ${tmprepo:-$tmpdir}"
}


#parse opts
while getopts :FGHM:R:S: c
do
	case $c in
		F)
			#hard repo resets
			((++optforce))
			;;
		G)
			#soft repo resets
			((++optforcesoft))
			;;
		H)
			#help
			helpopt=1
			;;
		M)
			#commit msg
			msg="$OPTARG"
			;;
		R)
			#repository name
			repo="$OPTARG"
			;;
		S)
			#repo subdir to copy new files
			sub="$OPTARG"
			sub="${sub#$HOME/}"
			sub="${sub#$HOME/}"
			;;
		\?) 	
			#if user sets only -h,
			#it will print help page later

			#set a repo name
			repo+="$OPTARG"
			;;
	esac
done
shift $(( OPTIND - 1 ))
unset c

#help page?
if [[ -n "$helpopt" ]] || [[ "$repo" = h ]]
then
	cat <<-!
	====
	Git commands used in this script:
	$(sed -nE 's/^\s*(git\s.*)/\1/ p'  "$0")
	====

	$HELP
	!

	exit 0
fi

#set trap
trap trapf EXIT

#exit on any error
set -e

#check tmp dir exists
if [[ ! -d "$tmpdir" ]]
then
	echo -e "\aERROR: temporary directory does not exist -- $tmpdir" >&2
	exit 1
fi

#check user input for repo name
[[ -n "$repo" ]] || repo="$defrepo"

#remove trailing slashes
repo="${repo#/}"
repo="${repo%/}"
tmpdir="${tmpdir%/}"

#try to break user and repository strings
if [[ "$repo" = */* ]]
then
	defuser="${repo%%/*}"
	repo="${repo##*/}"
fi

#set paths
tmpdir="$tmpdir/$defuser"
#consolidate paths
tmprepo="$tmpdir/$repo"

#set commit msg
msg="${msg:-$defmsg}"

#make file array
files+=( "$@" )


#check local dirs
#only overwrite clone files if user set explicitly
#maybe he edited clone files already and on purposed
if [[ -d "$tmprepo" ]]
then
	#soft reset git repo?
	if ((optforcesoft))
	then
		#reset clone
		echo -e "\aWARNING: soft-resettig local repo -- $tmprepo" >&2
		git -C "$tmprepo" reset --soft origin/master
	#hard reset git repo?
	elif ((optforce>1))
	then
		#remove clone
		echo -e "\aWARNING: removing local git repo -- $tmprepo" >&2
		rm -rfv "$tmprepo"
		echo
	elif ((optforce))
	then
		#reset clone
		echo -e "\aWARNING: hard-resettig local repo -- $tmprepo" >&2
		git -C "$tmprepo" fetch --all
		git -C "$tmprepo" reset --hard origin/master
	else
		#check for changed files
		if
			TODO="$(git -C "$tmprepo" add --dry-run -A)"
			[[ -n "$TODO" ]]
		then
			echo -e "\aWARNING: local is not in sync with remote!!" >&2
			echo "$TODO"
		else
			echo "Repo seems to be synced with remote"
		fi
		unset TODO
	fi
	echo
fi

#(re)clone the repo?
if [[ ! -d "$tmprepo" ]]
then
	mkdir -p "$tmpdir"
	echo "Warning: (re)cloning -- $tmprepo" >&2
	echo
	git -C "$tmpdir" clone "https://github.com/$defuser/$repo"
fi

#check repo subdir path if set
if [[ -n "$sub" ]]
then
	#
	sub="${sub#$HOME}"
	sub="${sub#$tmprepo}"
	sub="${sub#/}"
	sub="${sub%/}"
	#set new repo path
	tmprepo="$tmprepo/$sub"

	#check for recursive directories with the same name
	for f in "${files[@]}"
	do
		f="${f%/}"
		if [[ -d "$f" ]] &&
			[[ -z "${f#*$sub}" ]]
		then
			echo -e "\aWARNING: recursive same-named directories" >&2
			echo -e "\a-- \"${f##*/}\" under" >&2
			echo -e "\a-- \"$tmprepo\"" >&2
			break
		fi
	done
	unset f

	#create complete directory structure
	if [[ ! -d "$tmprepo" ]]
	then
		mkdir -p "$tmprepo"
	fi
	echo
fi

#remove files that are identical from array
for f in "${files[@]}"
do
	f="${f%/}"
	ff="${f##*/}"
	tg="${tmprepo%/}/$ff"

	#remove files that exist and are the same in both dirs
	if [[ -e "$f" ]] &&
		[[ -e "$tg" ]] &&
		diff -q "$f" "$tg" &>/dev/null
	then
		echo "Identical: ${f/$HOME/\~} and ${tg/$HOME/\~}"
		continue
	fi
	
	filesx+=( "$f" )
done
unset f

#copy new files to destination repo subdir
if [[ -n "${filesx[*]}" ]]
then
	cp -frvt "$tmprepo" "${filesx[@]}"
	echo
fi

#finally cd into cloned repo
cd "$tmprepo"

while true
do
	#count message chars of the `first' line
	n="$( read -r <<<"$msg" ;printf %02d "${#REPLY}" )"
	
	#options menu
	cat <<-!
	Clone__: $tmprepo
	Msg[$n]: $msg
	(;)  new commit msg [readline]
	(:)  edit commit msg [readline]
	(m)  edit multiline commit msg [$VISUAL]
	(d)  cd clone [$deffm]
	(ENTER)  add files and commit
	(*)  quit
	!

	#read answer
	read -r -n 1
	case "${REPLY:-#enter}" in
		[dD])
			( command "$deffm" "$tmprepo" )
			echo
			;;
		[mM])
			if buffer="$( vipe <<<"$msg" )"
			then
				msg="$buffer"
			else
				msg="${msg:-$defmsg}"
			fi
			echo
			;;
		[\;:])
			[[ "$REPLY" = \; ]] && unset msg
			#read with readline -e and initial value -i
			read -er -p Msg:\  -i "$msg" msg
			;;
		\#enter)
			#
			break
			;;
		*)
			#quit if user pressed `q' or invalid options
			exit 1
			;;
	esac
	echo
done

#add new files and commit
git add -A
git commit -m "$msg" || true 

#final confirmation before pushing changes
cat <<!
GitRepo: $defuser/$repo
(ENTER)  push to master
(*)  quit
!

#read answer
read -r -n 1
#quit if user did not press ENTER
[[ -z "$REPLY" ]] || exit 1
echo

#git push
if ! git push origin master
then
	printf "\a%s: run \`git push --force'? y/N  " "$SN" >&2
	read -n1 ;[[ "$REPLY" = [yY]* ]] && git push --force origin master
fi

#if git is still showing deleted files
#If you type `git status' and the result says up to date, but in red are warnings.
#{ git add -u . ;}
#https://stackoverflow.com/questions/4307728/git-still-showing-deleted-files-after-a-commit


