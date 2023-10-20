#!/bin/bash

declare -n grp=BASH_REMATCH

SFX='./Win7/Media/Windows Navigation Start.wav'


startup_no_sound() {
    if [[ -z "$STARTUP_OK" ]]; then
        local discard
        while read -r -t .5 -n 10000 discard; do :; done
        # echo cleared
        STARTUP_OK=1
        echo "monitoring"
    fi
    return 0
}


WAS_BLOCK=0
IS_BLOCK=0
IS_DIR=0
while startup_no_sound; read -r evt; do
    #[[ "$evt" =~ ^inotify.*\ =\ (-?[0-9]+)$ ]] || continue
    #((${BASH_REMATCH[1]}>=4)) || continue
    [[ "$evt" =~ "\""(/[^\"]*)"\"",\ F_OK ]] || continue
    p="${grp[1]}"
    #printf '[%s]\n' "${grp[@]}"
    #echo
    ! [[ -b "$p" && "$p" =~ ^/dev/[0-9A-Za-z]+$ ]]; IS_BLOCK=$?
    ! [[ -d "$p" && "$p" != "/dev/block" ]]; IS_DIR=$?
    if ((IS_BLOCK)); then
        echo "blk  $p"
    fi
    if ((IS_DIR && WAS_BLOCK && ! IS_BLOCK)); then
        echo "dir  $p"
        aplay "$SFX" &>/dev/null &
        disown
    fi
    WAS_BLOCK=$IS_BLOCK
done < <(
    strace -z --trace=access dolphin "$@" 2>&1
)
