#!/bin/bash

set -e

FILEURL="file://"


declare -n ME=BASH_SOURCE
EXE="$ME"  # avoid $0
# script is sourced from regular file?  ($0 == bash)
if [[ "$0" != "$ME" ]]; then
    unalias -a  # WARNING please source in a subshell: (set -x; source my_script.sh)
    if [[ ! -L "$ME" ]]; then
        EXE="$1"  # first argument is program name
        shift
    fi
fi
EXE="$(basename "$EXE")"
BIN="/usr/bin/$EXE"


if ! [[ "$EXE" =~ kwrite|dolphin ]]; then
    echo "Unsupported program: $EXE"
    exit 1
fi


# dependencies
DEPS=(xdotool qdbus)
if ! command -V "${DEPS[@]}" &>/dev/null; then  # no output if successful
    command -V "${DEPS[@]}"                     # output if failure
    exit 1
fi


get_cur_desk() {
    # qdbus org.kde.KWin /KWin org.kde.KWin.currentDesktop
    xdotool get_desktop
}

get_app_instances() {
    qdbus | grep "$EXE" | tr -d ' '
}

declare -A _APP_WINID=(
    [kwrite]=/kwrite/MainWindow_1
    [dolphin]=/dolphin/Dolphin_1
)
get_desk_of_app() {
    # qdbus "$app" /MainApplication org.kde.Kate.Application.desktopNumber  # 1-based
    # global win
    win="$(qdbus "$app" "${_APP_WINID[$EXE]}" org.kde.KMainWindow.winId)"
    adesk="$(xdotool get_desktop_for_window "$win")"
}

normalize_url() {
    [[ "$u" =~ ^[a-zA-Z]+:(//[^/]+)?(/.*) ]] && return
    u="${u#$FILEURL}"
    u="$(realpath -ms -- "$u")"
    u="${FILEURL}$u"
}


get_last_app_same_desk() {
    local cur="$(get_cur_desk)"
    # global app
    local adesk
    while read -r app; do
        get_desk_of_app
        ((cur == adesk)) && return
    done < <(get_app_instances | sort -ru)
    app=''
    win=''
}

declare -A _APP_NEW=(
    [kwrite]=''
    [dolphin]='--new-window'
)
declare -A _APP_URL=(
    [kwrite]='/MainApplication org.kde.Kate.Application.openUrl'
    [dolphin]='/dolphin/Dolphin_1 org.kde.dolphin.MainWindow.openDirectories'
)
app_open_path() {
    if ! [[ "$app" ]]; then
        exec "$BIN" ${_APP_NEW[$EXE]} "$@"  # will block
        return  # actually unreachable
    fi
    
    # won't block
    local u
    for u in "$@"; do
        normalize_url
        qdbus "$app" ${_APP_URL[$EXE]} "$u" ''
    done
    
    #qdbus "$app" /MainApplication org.kde.Kate.Application.activate
    xdotool windowactivate "$win"
}


# [[ -v AS_LIBRARY ]] && return 0
get_last_app_same_desk
app_open_path "$@"
