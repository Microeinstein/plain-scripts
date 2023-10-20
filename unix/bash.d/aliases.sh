
# basic utils
alias ls='ls --color=always -h --group-directories-first -v -S -X'  # human
alias tree='tree -a --dirsfirst -v -h -C'
alias cls='clear'
alias grep='grep --color=always'
alias egrep='egrep --color=always'
alias fgrep='fgrep --color=always'
alias dd='dd status=progress'
alias wget='wget --content-disposition --no-verbose --show-progress --continue'


# maintenance
alias pacman='pacman --color=always'
alias paru='paru --bottomup --sudoloop'
alias grupd='grub-mkconfig -o /boot/grub/grub.cfg'
alias refont='fc-cache -r -v && xset fp rehash'
alias freshmirrors='reflector --sort rate -c DE -c IT -c FR -c GB -c RO -f 10 -l 10 --save /etc/pacman.d/mirrorlist'


# bash
alias histsave='history >> "$HOME/.historyfile"'
alias incognito='set +o history'
alias reload='source /etc/bash.bashrc'
#alias aliasfunc='_aliasfunc() { local n="${1:?Missing alias name.}"; shift; alias "$n"="_${n}() { ${@:?Missing alias content.}; unset _${n}; }; _${n}"; unset _aliasfunc; }; _aliasfunc'


# monitor
alias speedtest='speedtest --bytes --secure'
alias pscpu='watch -n .8 "ps axo pid,pcpu,comm:24,args k -pcpu ww"'
alias psmem='watch -n .8 "ps axo pid,pmem,comm:24,args k -pmem ww"'
netwatch() { watch -d -n 1 "netstat -a -n -p ${1:+| grep -i \"$1\"}"; }


env() {
    if (($#)); then
        command env "$@"
        return
    fi
    command env | sort
}

esudo() {
    local a=(
        PULSE_SERVER="$XDG_RUNTIME_DIR/pulse/native"
        PULSE_COOKIE="$HOME/.config/pulse/cookie"
        XDG_RUNTIME_DIR=
        "$@"
    )
    sudo -E "${a[@]}"
}
