#!/bin/bash

set -e


# print gray to stderr without commands
_dbg() ( set +x;  echo -n $'\e[90m';  "$@";  echo -n $'\e[0m'; ) >&2


# self-knowledge
SELF="${BASH_SOURCE[0]}"
REALSELF="$(realpath -s "$SELF")"


# script is sourced?
if [[ "$0" != "$BASH_SOURCE" ]]; then
    # debug
    set -x
else
    # change directory (must exists) without following symlinks
    cd "$(dirname "$REALSELF")" || exit
    _dbg echo "WorkDir: $PWD"
fi


# dependencies
DEPS=(xrandr cvt)
if ! command -V "${DEPS[@]}" &>/dev/null; then  # no output if successful
    command -V "${DEPS[@]}"                     # output if failure
    exit 1
fi


get_outputs() {
    xrandr --prop | sed -nE "s/^([^ ]+) (dis)?connected.*$/\1/g; T; p"
}

ALL_RES=()
make_resolution() {
    local props
    read -ra props < <(cvt "$@" | tail -n+2)
    unset props[0]
    xrandr --newmode "${props[@]}"
    ALL_RES+=("${props[1]}")
}

make_resolution -r  640 480
make_resolution -r  800 600
make_resolution -r 1024 768
make_resolution -r 1280 720
for out in $(get_outputs); do
    xrandr --output "$out" --set 'scaling mode' 'Center'
    for res in "${ALL_RES[@]}"; do
        xrandr --addmode "$out" "$res"
    done
done
