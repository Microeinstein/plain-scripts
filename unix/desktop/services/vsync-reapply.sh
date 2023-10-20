#!/bin/bash


vsync() {
    # #local resol="$(xrandr --listmonitors | grep '*')"
    # #resol=($resol)
    # #xrandr --setmonitor vsyncing "${resol[2]}" none
    # [[ "$(xdotool getmouselocation)" =~ ^x:([0-9]+)\ y:([0-9]+)\ .* ]]
    # local x="${BASH_REMATCH[1]}"
    # local y="${BASH_REMATCH[2]}"
    # xrandr --nograb --output LVDS1 --off
    # xrandr --nograb --output LVDS1 --auto
    # xrandr --nograb --dpi 95
    # #xrandr --delmonitor vsyncing
    # xdotool mousemove "$x" "$y"
    xset dpms force off
    xset dpms force on
    echo "Vsync applied"
}


monitor_lock() {
    while read -r line; do
        [[ ! "$line" == *"'LockedHint': <false>"* ]] && continue
        vsync
    done < <(gdbus monitor -y -d org.freedesktop.login1)
}


BLACKLIST=(ksmserver ksmserver-logout-greeter spectacle  virt-manager  telegram-desktop discord zoom firefox obsidian krita exe)
is_blacklisted() {
    local ret
    ret="$(xprop -id "${1:?Missing id.}" 'WM_CLASS')"
    for class in "${BLACKLIST[@]}"; do
        [[ "$ret" == *"$class"* ]] && return 0
    done
    return 1
}

is_fullscreen() {
    local ret
    ret="$(xprop -id "${1:?Missing id.}" '_NET_WM_STATE')"
    #echo "$ret"
    [[ "$ret" == *'_NET_WM_STATE_FULLSCREEN'* ]]
}

something_fullscreen() {
    local id
    while read -r part; do
        [[ ! "$part" =~ ^(0x[0-9a-fA-F]+) ]] && continue
        id="${BASH_REMATCH[1]}"
        is_blacklisted "$id" && continue
        is_fullscreen "$id"  && return 1
    done < <(tr '# ' '\n' <<<"$1" | tac)
    return 0
}

monitor_fullscreen() {
    local full0 full1=0
    while read -r line; do
        something_fullscreen "$line"
        full0=$?
        #echo "ok"
        if ((full0 != full1)); then
            echo "fullscreen: $full0"
            if ((!full0)); then
                vsync
            fi
        fi
        ((full1 = full0))
    done < <(xprop -root -spy '_NET_CLIENT_LIST_STACKING')
}


exec 2>/dev/null  # ignore stderr
vsync  # initial
monitor_fullscreen &
monitor_lock &
wait
