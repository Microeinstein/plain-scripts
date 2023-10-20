#!/bin/bash


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
    [[ $(id -u) != 0 ]] && exec sudo bash "$BASH_SOURCE"
    _dbg echo "WorkDir: $PWD"
fi

TMP="/run/user/$(id -u)/$$"


# dependencies
DEPS=(bash)
if ! command -V "${DEPS[@]}" &>/dev/null; then  # no output if successful
    command -V "${DEPS[@]}"                     # output if failure
    exit 1
fi


main() {
    ln -fsv -t /usr/bin  "$PWD"/http-hook.{sh,py}
    # chmod -v a=rx /usr/bin/http-hook.{sh,py}
    
    ln -fsv -t /usr/share/applications  "$PWD"/http-hook.desktop
    # chmod -v a=rx /usr/share/applications/http-hook.desktop
    
    # might need to install to /usr/share/xfce4/helpers/
}


main "$@"
