#!/bin/bash

# https://doc.qt.io/qt-5/richtext-html-subset.html

#set -x
export LC_ALL=C
declare -n M=BASH_REMATCH
SELF="${BASH_SOURCE[0]}"
SELF="$(realpath "$SELF")"
SELFNAME="$(basename "$SELF")"
X=60

declare hour min sec
declare display


dbg() {
    echo "$*"
} >&2

dump() {
    for name in "$@"; do
        local -n ref="$name"
        printf '%s = %s\n'  "$name" "$ref"
        unset -n ref
    done
} >&2


base10() {
    local -n ref="$1"
    # bash base conversion is broken  ((10#$num))
    if [[ "$ref" =~ ^(-)?0+([0-9]+)$ ]]; then
        ref="${M[1]}${M[2]}"
    fi
}

zeropad() {
    local -n num="$1"
    if ((num >= 0)); then
        printf '%02d' "$num"
    else
        ((num = -num))
        printf '-%02d' "$num"
    fi
}

split_time() {
    local IFS
    IFS=: read -r hour min sec
} < <(cat "$@")

get_time() {
    if [[ -n "$1" ]]; then
        local -n ref="$1"
        split_time <<< "$ref"
    else
        split_time <(date '+%H:%M:%S')
    fi
    base10 hour
    base10 min
    base10 sec
}

time_display() {
    display="$(zeropad hour):$(zeropad min)"
    dump display
}


first_run_since_boot() {
    local f="/run/user/$(id -u)/${SELFNAME%.*}.run"
    [[ -e "$f" ]] && return 1
    touch "$f"
    return 0
}

wait_next() {
    local mticks=(10 15 20  30  40 45 50  60)
    local hour min sec
    get_time
    
    local tot_s
    ((tot_s = min * 60 + sec))
    
    local t
    for t in "${mticks[@]}"; do
        #t="$(base10 t)"
        ((t *= X))
        ((t -= tot_s))
        ((t <= 0)) && continue
        ((sec = t % X))
        ((min = (t - sec) / X))
        #echo "Waiting for ${min}m ${sec}s..." >&2
        # sleeping just for minutes lacks of precision
        sleep "$t"
        if (($? >= 128)); then
            exec "$0" now
        fi
        return
    done
}


alarm_display() {
    if ((hour >= 22 || hour <= 6)); then
        ((min += 20))  # bathroom
        ((min += 20))  # going asleep
        ((min += 30))  # 5 REM phases
        ((hour += 7))

        ((hour = (hour + (min / X)) % 24))
        ((min %= X))
        time_display
        display='⏰ <font color="#FFDC38" size="1">'"$display"'</font>'
    fi
}


remain_time() {
    dbg remain_time
    local h2=22  m2=30
    local delta  tot_s
    ((delta = ((24-h2) * X*X) + ((-m2) * X)))
    dump delta
    ((tot_s = (hour * X*X) + (min * X) + sec + delta))
    dump tot_s
    ((tot_s %= X*X*24))
    dump tot_s
    ((tot_s = X*X*24 - tot_s))
    dump tot_s

    ((sec = tot_s % X))
    ((tot_s = (tot_s - sec) / X))
    ((min = tot_s % X))
    dump sec tot_s min
    ((tot_s = (tot_s - min) / X))
    ((hour = tot_s))
    dump hour
    time_display
    #display="$(datediff -f '%H:%M' $h2:$m2 "$hour:$min")"
    #get_time display
}


percent_minutes() {
    dbg percent_minutes
    dump min sec
    ((min = (min * 60 + sec) * 100 / 3600))
    dump min sec
    time_display
}


percent_style() {
    display="$(zeropad hour).<font size='2'>$(zeropad min)</font>"
}


negate_style() {
    display="-$display"
}


add_today_display() {
    local dname day moname
    read -r dname day moname < <(LC_ALL= date '+%a %_d %b')
    moname="${moname:0:1}"  # first letter
    display="${dname,} <b>$day</b><font size='2'>/${moname^^}</font> &nbsp;$display"
}


base_style() {
    display='<font size="3">'"$display"'</font>'
}


main() {
    case "$1" in
        force)
            set -x
            pkill -P "$(pgrep --oldest "$SELFNAME")" sleep
            return
            ;;
        
        notify)
            notify-send       \
                -a 'Orologio' \
                -i 'clock' \
                'Adesso'  \
                "$(LC_ALL= date +'sono le — <b>%T</b><br>del giorno — <b>%A %_d %B %Y</b> ')"
            return
            ;;

        now) ;;

        *) first_run_since_boot || wait_next ;;
    esac

    get_time
    time_display

    # alarm_display
    remain_time
    percent_minutes
    percent_style
    negate_style
    add_today_display
    base_style

    echo "$display"
}

main "$@"
