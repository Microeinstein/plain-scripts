#!/bin/bash

# this script can be sourced from .bashrc, from outer scripts as library, and yet be executable

# is interactive shell? (imply sourced)
if [[ $- == *i* ]]; then
    # set wrappers (exports) to run this file as
    for exp in bashrc-sync; do
        eval "$exp() ( exec -a ${exp@Q} ${BASH_SOURCE[0]@Q} \"\$@\" )"
    done
    unset __ACTIONS
    return
fi

deps() {
    if ! command -V "$@" &>/dev/null; then
        errlog command -V "$@"
        return 1
    fi
}

ensure-root() {
    # pass launch arguments to this function and check for $0
    (($(id -u))) || return 0
    exec sudo bash "$(realpath "${BASH_SOURCE[0]}")" "$@"
}

clear-stdin() {  # avoids duplicate events
    local discard
    while read -r -t .1 -n 10000 discard; do :; done
    # echo cleared
    return 0
}

monitor-loop() {
    local files evt f IFS=''
    # includes hidden files
    mapfile -t files < <(find -L "$src" -iname '*.sh')
    while clear-stdin; read -r -d' ' evt && read -r f; do
        # reload monitor when a new symlink is detected
        [[ "$f" && "$evt" == *CREATE* ]] && return
        echo "> [$evt] $f"
        # keep every attribute but copy symlinks' content
        rsync -a -L --delete "$src/" "$dest"
        chmod -R 755 "$dest"
    done < <(
        # first sync
        sleep .5;
        echo 'none dummy';
        
        # symbolic links are NOT dereferenced with recursion,
        # hence no "modify" event - must pass file list by hand
        inotifywait -m --format '%e %f' -e create,delete,move \
        --exclude '.*(\..*-swp|~)' "$src" 2>/dev/null &
        
        inotifywait -m --format '%e %f' -e modify \
        --exclude '.*(\..*-swp|~)' "${files[@]}" 2>/dev/null &
    )
}

bashrc-sync() {
    deps inotifywait rsync || return

    ensure-root "$@"
    
    local home="$HOME"
    [[ "$SUDO_USER" ]] && home="/home/$SUDO_USER"
    local src="$home/.local/scripts/unix/bash.d"
    local dest="/etc/bash.d"
    src="$(realpath "$src")"
    dest="$(realpath "$dest")"
    
    [[ -d "$src" ]]  || { echo "Source is missing: $src"; return 1; }
    [[ -d "$dest" ]] || { mkdir -v "$dest"; }
    
    echo "  User: $USER"
    echo "Source: $src"
    echo "  Dest: $dest"
    cd "$src"
    
    # add to: /etc/bash.bashrc
    # # Load profiles from bash.d
    # #set -x
    # if test -d /etc/bash.d; then
    #   while read -r profile; do
    #     test -r "$profile" && source "$profile"
    #   done < <(find -L /etc/bash.d -type f -iname '*.sh')
    #   unset profile
    # fi
    # #set +x
    
    echo
    while monitor-loop; do :; done
}


return &>/dev/null  # do not run when sourced
set -euo pipefail
"$(basename "${0%.*sh}")" "$@"
