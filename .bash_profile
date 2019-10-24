# Git stuff
function stashdiff() {
	git stash show -p stash@{$1};
}

source ~/git-completion.bash

# Don't record some commands
export HISTIGNORE="&:[ ]*:exit:ls:bg:fg:history:clear"

# Correct spelling errors in arguments supplied to cd
shopt -s cdspell;

# Networking. IP address, dig, DNS
alias ip="dig +short myip.opendns.com @resolver1.opendns.com"

# show hidden files starting with a dot, and sort
alias ll='ls -lGaf'

function man() {
    LESS_TERMCAP_mb=$'\e'"[1;31m" \
    LESS_TERMCAP_md=$'\e'"[1;31m" \
    LESS_TERMCAP_me=$'\e'"[0m" \
    LESS_TERMCAP_se=$'\e'"[0m" \
    LESS_TERMCAP_so=$'\e'"[1;44;33m" \
    LESS_TERMCAP_ue=$'\e'"[0m" \
    LESS_TERMCAP_us=$'\e'"[1;32m" \
    command man "$@"
}


# Go stuff
export GOPATH="/Users/Nilay/Dropbox/Gocode"
PATH="$PATH:$GOPATH/bin"


# Python stuff
function venv() {
	python3 -m venv $HOME/.venvs/$1;
	chmod +x $HOME/.venvs/$1/bin/activate;
}
function activate() {
	source $HOME/.venvs/$1/bin/activate;
}


PATH=$PATH:~/usr/local/bin

export PATH

if [ -e /Users/nilay/.nix-profile/etc/profile.d/nix.sh ]; then . /Users/nilay/.nix-profile/etc/profile.d/nix.sh; fi # added by Nix installer
