#!/bin/bash

CLASS="/sys/class/power_supply"
BATTERIES=("$CLASS/BAT"*)

STATUS_BAT="Discharging"
STATUS_AC="Charging"
STATUS_MAX="Full"

MON_SEC=60
THRESH_MIN=20
THRESH_MAX=90

# if missing: consider "battery"
ICON_LOW=battery-level-20-symbolic
ICON_HIGH=battery-level-80-charging-symbolic


check_battery() {
    for b in "${BATTERIES[@]}"; do
        local status="$(cat "$b/status")"
        local level="$(cat "$b/charge_now")"
        local full="$(cat "$b/charge_full")"
        local perc="$((level * 100 / full))"
        #echo "timer:$b:$status"

        case "$status" in
            "$STATUS_BAT")  ((perc <= THRESH_MIN)) && echo low_bat:"$b":"$perc"  ;;
            "$STATUS_AC")   ((perc >= THRESH_MAX)) && echo high_bat:"$b":"$perc" ;;
            "$STATUS_FULL") echo high_bat:"$b" ;;
        esac
    done
}


monitor_battery() {
    while true; do
        check_battery
        sleep $MON_SEC
    done
}

monitor_udev() {
    while read -r event; do
        #echo "$event"
        #printf '[%s]\n' "${BATTERIES[@]}"
        for b in "${BATTERIES[@]}"; do
            local status="$(cat "$b/status")"
            #echo "udev:$b:$status"
            case "$status" in
                "$STATUS_BAT")               echo unplug:"$b"; check_battery ;;
                "$STATUS_AC"|"$STATUS_FULL") echo plug:"$b";   check_battery ;;
            esac
        done
    done < <(
        udevadm monitor -k -s power_supply | \
        stdbuf -oL tail -n+4
    )
}


handle_events() {
    declare -A nids_hi nids_lo
    while IFS=: read -ra event; do
        printf '[%s]\n' "${event[@]}"
        #echo
        local kind="${event[0]}"
        local bat="${event[1]}"
        local perc
        local na nidB

        case $kind in
            low_bat)
                perc="${event[2]}"
                na=(
                    "$ICON_LOW"
                    "Batteria $perc%"
                    "Collega l'alimentatore"
                )
                nidB="${nids_lo["$bat"]}"
                [[ -n "$nidB" ]] && rem_notification "$nidB"
                nids_lo["$bat"]="$(add_notification "${na[@]}")"
                ;;

            high_bat)
                perc="${event[2]}"
                na=(
                    "$ICON_HIGH"
                    "Batteria $perc%"
                    "Scollega l'alimentatore"
                )
                nidB="${nids_hi["$bat"]}"
                [[ -n "$nidB" ]] && rem_notification "$nidB"
                nids_hi["$bat"]="$(add_notification "${na[@]}")"
                ;;

            unplug)
                nidB="${nids_hi["$bat"]}"
                [[ -n "$nidB" ]] && rem_notification "$nidB"
                nids_hi["$bat"]=
                ;;

            plug)
                nidB="${nids_lo["$bat"]}"
                [[ -n "$nidB" ]] && rem_notification "$nidB"
                nids_lo["$bat"]=
                ;;
        esac
    done
}


add_notification() {
    local i="${1:?Missing icon.}"
    local s="${2:?Missing summary.}"
    shift 2
    local args=(
        --printid
        --appname="Livello batteria"
        --urgency=critical
        --icon="$i"
        "$s"
        "$@"
    )
    dunstify "${args[@]}"
    sleep 1
}

rem_notification() {
    local args=(
        --close="${1:?Missing ID.}"
    )
    dunstify "${args[@]}"
}


dependencies() {
    command -V dunstify  # ...
}

debug() {
    local bat1="${BATTERIES[0]}"
    while read -r -s -N1 key; do
        case "$key" in
            h) echo high_bat:"$bat1":"$THRESH_MAX" ;;
            l) echo low_bat:"$bat1":"$THRESH_MIN"  ;;
            u) echo unplug:"$bat1" ;;
            p) echo plug:"$bat1"   ;;
        esac
    done
}

main() {
    if ! dependencies >/dev/null; then
        return 1
    fi
    echo "Monitoring..."
    {
        monitor_battery &
        monitor_udev    &
        debug           &
    } | handle_events
}


# execute only when non-interactive shell
[[ $- != *i* ]] && main "$@"
