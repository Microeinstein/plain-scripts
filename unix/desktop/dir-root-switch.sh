#!/bin/bash

set -e

FILEURL="file://"


declare -n ME=BASH_SOURCE
declare -n RE=BASH_REMATCH
# script is sourced?  ($0 == bash)
if [[ "$0" != "$ME" ]]; then
    unalias -a  # WARNING please source in a subshell: (set -x; source my_script.sh)
fi


# dependencies
DEPS=(xdotool qdbus)
if ! command -V "${DEPS[@]}" &>/dev/null; then  # no output if successful
    command -V "${DEPS[@]}"                     # output if failure
    exit 1
fi


get_active_win() { win="$(xdotool getactivewindow)"; }

get_active_pid() { pid="$(xdotool getwindowpid "$@")"; }

get_app_instance() {
    get_active_win
    get_active_pid "$win"
    app="$(qdbus | grep "$pid" | tr -d ' ')"  # works for Dolphin
}

normalize_path() {
    if [[ "$u" == "$FILEURL"* ]]; then
        u="${u#$FILEURL}"
    elif [[ "$u" =~ ^[a-zA-Z]+://[^/]+(/.*) ]]; then
        u="${RE[1]}"
    fi
    u="$(realpath -ms -- "$u")"
}

to_url() {
    u="${FILEURL}$u"
}


EXT="/run/media/$USER"
MAPS=(
    "/mnt/files/Torrent:$EXT/Dispose/Torrent"
               "/builds:$EXT/Dispose/System/builds"
            "/mnt/files:$EXT/Files"
                      ":$EXT/ArchLinux"  # root
                      ":$EXT/Arch"       # root
)
find_matching() {
    local m a b
    for m in "${MAPS[@]}"; do
        IFS=: read -r a b <<<"$m"
        if [[ "$u" == "$b"* ]]; then
            [[ ! "$b" || -d "$b" ]] || continue
            u="${a}${u#$b}"
            return
        elif [[ "$u" == "$a"* ]]; then
            [[ ! "$a" || -d "$a" ]] || continue
            u="${b}${u#$a}"
            return
        fi
    done
    return 1
}

error() {
    local e=$?
    notify-send -t 3000 -a Dolphin Error "$@"
    exit $e
}

open_matching() {
    # notify-send -t 3000 -a Dolphin Ok "$u"
    get_app_instance
    
    # close split view and reopen it
    #qdbus "$app" /dolphin/Dolphin_1  org.kde.dolphin.MainWindow.slotSplitViewChanged
    #qdbus "$app" /dolphin/Dolphin_1/actions/split_view        org.qtproject.Qt.QAction.trigger
    
    # focus and select path, type and return
    qdbus "$app" /dolphin/Dolphin_1/actions/replace_location  org.qtproject.Qt.QAction.trigger
    
    # digit new path
    xdotool type --window "$win" --delay 0 --clearmodifiers -- "$u"
    # swap primary clipboard and paste
    #xsel -x
    #xsel -i -- <<<"$u"
    #xsel -x
    
    # close autocompletion and confirm
    xdotool key --window "$win" --delay 0 --clearmodifiers -- Escape Return
}


u="$1"
normalize_path
find_matching || error 'No matching folder'
to_url
open_matching
