#!/bin/bash

set meta-flag on
set input-meta on
set output-meta on
set convert-meta off
set show-all-if-ambiguous on
set bell-style none
set print-completions-horizontally off

export CLICOLOR=1
export TERM=xterm-color
export LSCOLORS=GxFxCxDxBxegedabagaced

c_red=`tput setaf 1`
c_green=`tput setaf 2`
c_blue=`tput setaf 4`
c_light_red="$(tput setab 1)"
c_cyan=`tput setaf 6`
c_sgr0=`tput sgr0`

branch_color ()
{
    if git rev-parse --git-dir >/dev/null 2>&1
    then
        color=""
	# check if it is smoething not pushed in submodule
        if (cd `git rev-parse --show-toplevel`; git submodule foreach git status) | grep "ahead" --quiet >/dev/null >&2
        then
                color=${c_light_red}
         else
		# check if something is not commited
		if git status | grep "clean" --quiet 2>/dev/null >&2 
		then
		    #check if something is not pushed
		    if git status | grep "ahead" --quiet >/dev/null >&2
		    then
			color=${c_cyan}
		    else
			color=${c_green}
		    fi
		else
		    color=${c_red}
		fi
         fi
    else
        return 0
    fi
    echo -n $color
}

parse_git_branch ()
{
    if git rev-parse --git-dir >/dev/null 2>&1
    then
        gitver="["$(git branch 2>/dev/null| sed -n '/^\*/s/^\* //p')"]"
    else
        return 0
    fi
    echo -e $gitver
}

bash_source_file=${HOME}/.git-completion.bash
if [ -f $bash_source_file ];
then
    source $bash_source_file
else
    echo 'Warning: Git auto-completion $bash_source_file is not installed.'
fi
bash_source_file=${HOME}/.git-flow-completion.bash
if [ -f $bash_source_file ];
then
    source $bash_source_file
else
    echo 'Warning: Git-flow auto-completion $bash_source_file is not installed.'
fi
bash_source_file=${HOME}/.adb-completion.bash
if [ -f $bash_source_file ];
then
    source $bash_source_file
else
    echo 'Warning: ADB auto-completion $bash_source_file is not installed.'
fi

bash_source_file=${HOME}/.git-prompt.bash
if [ -f $bash_source_file ];
then
    source $bash_source_file
    # color hints is only available with PROMPT_COMMAND
    GIT_PS1_SHOWCOLORHINTS=1
    # Untracked files
    GIT_PS1_SHOWUNTRACKEDFILES=1
    # Dirty state
    GIT_PS1_SHOWDIRTYSTATE=1
    # Stash state
    #GIT_PS1_SHOWSTASHSTATE=1
    # Show diff between HEAD and its upstream
    GIT_PS1_SHOWUPSTREAM="auto"

    PROMPT_COMMAND='__git_ps1 "\u@\h:\[\e[0;34m\]\W\[${c_sgr0}\]" "\\\$ "'
    #PS1='\u@\h \[${c_blue}\]\W\[${c_sgr0}\]$(__git_ps1 "(%s)")]\$ '
else
    PS1='\u@\[${c_blue}\]\w\[${c_sgr0}\]\[\[$(branch_color)\]$(parse_git_branch)\[${c_sgr0}\]$ '
fi

# Dynamic resizing
shopt -s checkwinsize

# Create alias and enable auto-completion for them if auto-completion installed.
# Params:
#   $1: command base name
#   $2: alias name.
#   others: full command for alias
# For example:
#   Create an alias: "alias go='git checkout', and support auto-completion if 
#   git-completion.bash installed.
#      make_alias_auto_completion go git checkout
# Ref: Bash completion for alias command from Olejorgen
#      http://ubuntuforums.org/showthread.php?t=733397
#
function make_alias_auto_completion () {
    local base_cmd_name=$2
    local complete_result=$(complete -p $base_cmd_name)
    if [ "$complete_result" == "" ]
    then
        echo "$1 does not have auto completion function."
        return -1
    fi
    local complete_result_arr=(${complete_result//;/ })
    local len=${#complete_result_arr[@]}
    local index=$((len-2))
    local comp_function_name="${complete_result_arr[$index]}"
    local alias_name="$1"
    local comp_wrapper_function_name="__my_alias_completion_$alias_name"
    local arg_count=$(($#-2))
    shift 1
    local make_alias_cmd="alias $alias_name='$@'"
    local wrapper_function="
        function $comp_wrapper_function_name {
            ((COMP_CWORD+=$arg_count))
            COMP_WORDS=( "$@" \${COMP_WORDS[@]:1} )
            \"$comp_function_name\"
            return 0
        }"
    # Create alias for your command
    # echo "make alias command: $make_alias_cmd"
    eval "$make_alias_cmd"
    # Create auto-completion wrapper function for this alias
    # echo "$wrapper_function"
    eval "$wrapper_function"
    # Assign auto-completion wrapper for alias.
    local complete_cmd="complete -o default -F $comp_wrapper_function_name $alias_name"
    # echo "Complete: $complete_cmd"
    eval "$complete_cmd"
    return 0
}

# User defined aliases
alias cls='clear'
alias clls='clear; ls'
alias ll='ls -l'
alias lsa='ls -A'
alias lsg='ls | grep'
alias vi='vim'

# git command alias
make_alias_auto_completion gs git status
make_alias_auto_completion ga git add
make_alias_auto_completion grs git reset HEAD
make_alias_auto_completion grb git reset --soft HEAD^
make_alias_auto_completion gsh git stash
make_alias_auto_completion gush git stash pop
make_alias_auto_completion gb git branch
make_alias_auto_completion gc git commit
make_alias_auto_completion gcmsg git commit -m
make_alias_auto_completion gcmd git commit --amend
make_alias_auto_completion gr git remote
make_alias_auto_completion gpl git pull
make_alias_auto_completion gph git push
make_alias_auto_completion gfh git fetch
make_alias_auto_completion go git checkout
make_alias_auto_completion gf git flow
make_alias_auto_completion gd git diff
make_alias_auto_completion gdc git diff --cached
alias gm='git mergetool'
alias gx='gitx --all'
alias gt='gitk --all&'


# Load your private bashrc file
PRIVATE_BASHRC=${HOME}/.bashrc_private
if [ -f $PRIVATE_BASHRC ];
then
  source $PRIVATE_BASHRC
fi
