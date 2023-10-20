#!/bin/bash

ec-writable() {
    modprobe -r ec_sys
    modprobe ec_sys write_support=1
}

ec-write-byte() {
    local ec="${EC_PATH:-/sys/kernel/debug/ec/ec0/io}"
    if ! [[ -f "$ec" ]]; then
        echo "Missing EC debug path."
        return 1
    fi
    local reg="${1:?Missing register. (decimal)}"
    local v="${2:?Missing value. (decimal)}"
    if ((v < 0 || v > 255)); then
        echo "Value is out of range. (0..255)"
        return 1
    fi
    local dd_args=(
        of="$ec"
        bs=1 count=1
        seek="$reg"
        conv=notrunc
        status=none
    )
    echo "EC[$reg] = $v"
    printf "\x$(printf %x "$v")" | command dd "${dd_args[@]}"
}

fan-speed-override() {
    # tuned for HP G62 150SL
    local reg="${FAN_REGISTER:-177}"
    local vreset="${FAN_RESET:-0}"
    local vmin="${FAN_MIN:-1}"
    local vmax="${FAN_MAX:-21}"
    
    local v="$vreset"
    if [[ -v 1 ]]; then
        v="$1"
        if ((v != vreset && (v < vmin || v > vmax))); then
            echo "Speed is out of range. ($vmin..$vmax)"
            return 1
        fi
    fi
    ec-write-byte "$reg" "$v"
}
