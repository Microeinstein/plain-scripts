#!/bin/bash

#NS_PAUSE_WARN="/usr/share/sounds/Oxygen-Sys-Question.ogg"
NS_SMS="/usr/share/sounds/Oxygen-Im-Sms.ogg"
SOUND_COMMAND='ogg123'
N_ICON='/usr/share/icons/Papirus/64x64/apps/kscreensaver.svg'

old_msg() {
    N_TITLE='NON ROVINERESTI MAI I RITMI'
    N_SUMM="Preferiresti dormire la mattina..."
    N_BODY="...o dormire ora ed essere alzato per le 7?<br>Il tempo che consumi è lo stesso."
}

KWS_NO_CONFIRM=0
KWS_SHUTDOWN=2
KWS_FORCE_NOW=2


playSound() {
    "$SOUND_COMMAND" "${1:?Missing file.}" &>/dev/null
    local err=$?
    if ((err)); then
        echo "Warning: unable to play sound effect (exit code: $err)" >&2
    fi
}

notify() {
    notify-send \
        -u critical \
        -a "$N_TITLE" \
        -i "${3:?Missing icon.}" \
        "${1:?Missing summary.}" \
        "${2:?Missing body.}" \
        &>/dev/null
    local err=$?
    if ((err)); then
        echo "Warning: unable to notify (exit code: $err)" >&2
    fi
}

dunstify() {
    command dunstify \
        -I "$N_ICON" \
        -a 'Sleep saver' \
        "$@"
    local err=$?
    if ((err)); then
        echo "Warning: unable to dunstify (exit code: $err)" >&2
    fi
}

kde_logout() { # Needed to save session properly
    # https://askubuntu.com/a/1876
    qdbus org.kde.ksmserver /KSMServer logout \
        "${1:?Missing confirmation. [0,1]}" \
        "${2:?Missing type. [0..3]}" \
        "${3:?Missing mode. [0..3]}"
}

calc_wake_up() {
    h="${1:?hour}" m="${2:?minute}"
    p="${3:?phases}" # do not go under 4!
    ((h = 10#$h)); ((m = 10#$m)) # use base 10
    # (times * rem phase time) + (falling asleep time) + (margin)
    ((m += p * (60 + 30) + 15 + 20))
    ((h += m / 60))
    ((h %= 24)); ((m %= 60))
    printf '%02d ' "$h" "$m"
}
show_wake_time() {
    local args choice
    IFS=':' read -r h m s < <(date '+%T')
    IFS=' ' read -r h4 m4 < <(calc_wake_up $h $m 4)
    IFS=' ' read -r h5 m5 < <(calc_wake_up $h $m 5)
    #playSound "$NS_SMS" &
    args=(
        dunstify -t 30000
        #-A 'no,🔵 Dai...'
        #-A 'ok,🔴 Spegni'
        "Wake-up time   → $h5:$m5   → $h4:$m4"
        #"cosa sceglierai di fare?"
    )
    choice="$("${args[@]}")"
    echo "$choice"
    case "$choice" in
        1) ;; # timeout
        2) ;; # explicit close
    esac
        #"ok") kde_logout "$KWS_NO_CONFIRM" "$KWS_SHUTDOWN" "$KWS_FORCE_NOW" ;;
}

echo "Begin notification loop..."
while true; do
    hour="$(date +%H)"
    hour=$((10#$hour))
    if ((hour >= 6 && hour < 18)); then
        exit
    fi
    show_wake_time &
    echo "Sleeping..."
    sleep 20m
done

#notify "$N_SUMM" "$N_BODY" "$N_ICON"
#echo "Sleeping..."
#sleep 5m
#echo "Shutting down..."
#kde_logout "$KWS_NO_CONFIRM" "$KWS_SHUTDOWN" "$KWS_FORCE_NOW"
