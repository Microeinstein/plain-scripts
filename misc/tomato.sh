#!/bin/bash

# Tomato Timer v1
# Author: Microeinstein
# Date:   2020-02-11
# Dependencies:
#   bc  glib2
# Optionals:
#   notification sounds: sound-theme-freedesktop  vorbis-tools
#   notification icons:  papirus-icon-theme
# In case of no sound: https://bbs.archlinux.org/viewtopic.php?id=225440

# Code style:
#   UPPERCASE   settings
#   lowercase   globals, locals
#   undr_scre   variables
#   camelCase   functions
#   abbrev      locals

# [Settings]
SETTINGS_FILE="$HOME/.config/tomato.config.sh"
DEFAULT_EDITOR="nano"
defaultSettings() {
    cat <<EOF
#!/bin/bash

# Tomato Timer settings file

# [Tomato tecnique] =145m
# MIN_POMODORO=25
# MIN_SHORT=5
# MIN_LONG=20
# LONG_EVERY=4

# [Melon tecnique] =90m
MIN_POMODORO=34
MIN_SHORT=6
MIN_LONG=16
LONG_EVERY=2

MIN_PAUSE_WARN=3
MIN_INVALID_PAUSE=17
MANUAL_POMODORO=1
SECONDS_TICK=.1

LOG=1
LOGFILE="\$HOME/.cache/tomato.log"

NOTIFY_ON_SKIP=1
SOUND_COMMAND='ogg123'
NS_POMODORO="/usr/share/sounds/freedesktop/stereo/service-login.oga"
NS_BREAK="/usr/share/sounds/freedesktop/stereo/service-logout.oga"
NS_PAUSE_WARN="/usr/share/sounds/freedesktop/stereo/message-new-instant.oga"

EOF
}
eval "$(defaultSettings)"
if ! [[ -e "$SETTINGS_FILE" ]]; then
    if ! defaultSettings > "$SETTINGS_FILE"; then
        echo "Unable to save default config, closing..."
        exit 1
    fi
fi
if ! source "$SETTINGS_FILE"; then
    echo "Unable to load config, closing..."
    exit 2
fi
loglock="${LOGFILE}.lock"


# [Colors]
COLOR_MAIN="\e[38;5;15m"
COLOR_ALT="\e[38;5;248m"
COLOR_POMODORO="\e[1;38;5;214m"
COLOR_SHORT_BREAK="\e[1;38;5;154m"
COLOR_LONG_BREAK="\e[1;38;5;50m"
COLOR_SKIPPED="\e[38;5;177m"
COLOR_INVALID="\e[38;5;160m"


# [Arguments]
arg_log=0
arg_lock=0
arg_settings=0
arg_edit_settings=0
arg_edit_log=0
arg_warnings=0
arg_debug=0

printHelp() {
    printf '%b\n' "$(cat <<-EOF
\e[1;91mTomato Timer\e[0m v.1
Author: Microeinstein

\e[1;92mUsage\e[0m: \e[1m$0\e[0m [options]

\e[1;93mOptions\e[0m:
  \e[1m-h --help      \e[0m  Show this help and exit
  
  \e[1m-l --log-file  \e[0m  Print LOGFILE and exit
  \e[1m-k --lock-file \e[0m  Print LOGFILE.lock and exit
  \e[1m-s --settings  \e[0m  Print SETTINGS_FILE and exit
  
  \e[1m-e --edit      \e[0m  Open the settings file with "\$EDITOR" (${EDITOR:-unset, use nano})
  \e[1m-t --track     \e[0m  Open the log file with "\$EDITOR" (${EDITOR:-unset, use nano})
  
  \e[1m-n --testnotify\e[0m  Tries to send a notification
                     and to play an audio file, then exit
  \e[1m-w --warnings  \e[0m  Enable warnings during execution
  \e[1m-d --debug     \e[0m  Very fast time and something else

\e[1;95mSettings\e[0m:
  Currently, this settings are located at the head of the script.

  \e[1mMIN_POMODORO     \e[0m  Minutes for one pomodoro
  \e[1mMIN_SHORT        \e[0m  Minutes for one short break
  \e[1mMIN_LONG         \e[0m  Minutes for one long break
  \e[1mLONG_EVERY       \e[0m  Do a long break after Nth pomodoro
  
  \e[1mMIN_PAUSE_WARN   \e[0m  Keep sending a warning if paused for this much,
                          zero to deactivate
  \e[1mMIN_INVALID_PAUSE\e[0m  Automatically skips if paused for this much,
                          zero to deactivate
  \e[1mMANUAL_POMODORO  \e[0m  Pomodoros requires manual start
  \e[1mSECONDS_TICK     \e[0m  Ticks for every second
  
  \e[1mLOG              \e[0m  Track your progress
  \e[1mLOGFILE          \e[0m  Filepath for progress tracking
  
  \e[1mNOTIFY_ON_SKIP   \e[0m  Send a notification on skips
  \e[1mSOUND_COMMAND    \e[0m  Command used to reproduce audio
  \e[1mNS_POMODORO      \e[0m  Filepath for pomodoro notification sound
  \e[1mNS_BREAK         \e[0m  Filepath for break notification sound
  \e[1mNS_PAUSE_WARN    \e[0m  Filepath for pause warning notification sound
 
EOF
)"

}

for arg in "$@"; do
    case "$arg" in
        -h|--help)
            printHelp
            exit
            ;;
        -l|--log-file)
            arg_log=1
            ;;
        -k|--lock-file)
            arg_lock=1
            ;;
        -s|--settings)
            arg_settings=1
            ;;
        -e|--edit)
            arg_edit_settings=1
            ;;
        -t|--track)
            arg_edit_log=1
            ;;
        -n|--testnotify)
            gdbus call \
                --session \
                --dest org.freedesktop.Notifications \
                --object-path /org/freedesktop/Notifications \
                --method org.freedesktop.Notifications.Notify \
                "Title" \
                "012345" \
                "gtk-info" \
                "Summary" \
                "<i>Body" \
                "[]" "{}" \
                5000
            echo "Exit code: [$?]"
            "$SOUND_COMMAND" "$NS_POMODORO"
            echo "Exit code: [$?]"
            exit 0
            ;;
        -w|--warnings)
            arg_warnings=1
            ;;
        -d|--debug)
            arg_debug=1
            ;;
        *)
            echo "Unknown argument: $arg"
            echo
            printHelp
            exit 1
            ;;
    esac
done
if let 'arg_log || arg_lock || arg_settings || arg_edit_settings || arg_edit_log'; then
    if let 'arg_edit_settings'; then 
        "${EDITOR:-$DEFAULT_EDITOR}" "$SETTINGS_FILE"
    fi
    if let 'arg_edit_log'; then 
        "${EDITOR:-$DEFAULT_EDITOR}" "$LOGFILE"
    fi
    arr=()
    if let 'arg_log';      then arr+=("$LOGFILE");       fi
    if let 'arg_lock';     then arr+=("$loglock");  fi
    if let 'arg_settings'; then arr+=("$SETTINGS_FILE"); fi
    if let "${#arr[@]} > 0"; then
        printf '%s ' "${arr[@]}"
        echo
        # | tee >(cat >&2)
    fi
    exit
fi


# [Globals]
inchar=""
pause=0
skipped=0
skips=0
phase=-1
breaks=0
tomatoes=0
now=""
pstart_txt=""
pend=(0 0)
pend_txt=""
pname="Pomodoro"
# SECONDS_TICK .1 → N.DIGITS → INTEGER CALCULATIONS
dec_reset=$(bc <<< "1/${SECONDS_TICK} - 1")
# (min sec dec)
time=(0 0 ${dec_reset})
time_reset=(0 59 ${dec_reset})
# (mintot minwarn sec dec)
time_pause=(0 0 0 0)
notify_id="${RANDOM}${RANDOM}"
if (( $LOG )) && [[ -e "$loglock" ]] && [[ -e "$LOGFILE" ]]; then
    echo
    echo "Sorry, this log file is already used from another instance!"
    echo "Lock: \"$loglock\""
    echo
    exit 3
fi
touch "$loglock"
touch "$LOGFILE"
if ! last_line=$(tail -n-1 "$LOGFILE"); then
    echo "Unable to read log file, closing..."
    exit 4
fi
IFS=':' read -r last_date last_tomatoes <<< "$last_line"
last_tomatoes=$(( ${#last_tomatoes} / 2 ))


# [Functions]
init() {
    printf '\e[?1049h\e[2J\e[H\e[?25l' #enable ASB, clear, hide cursor
    trap "signal" SIGINT SIGTERM
    if let 'arg_debug'; then
        MIN_INVALID_PAUSE=4
        MIN_PAUSE_WARN=2
        MIN_POMODORO=2
        MIN_SHORT=1
        MIN_LONG=3
        time_reset=(0 4 4)
    fi
    updateNow
    if [[ "$last_date" == "$now" ]]; then
        tomatoes="$last_tomatoes"
    fi
    printHeader
    nextPhase
    printInfo
}
quit() {
    if (( ${1:-1} )); then
        printf '\n\n  ~Take care of yourself~ ❤️'
        sleep 1
    fi
    printf '\e[?25h\e[2J\e[?1049l' #show cursor, clear, disable ASB
    if (( ${1:-1} )); then
        exit
    fi
}
signal() {
    quit 0
    echo '(Signal received)'
    exit
}
exit() { #Redefinition
    rm "$loglock"
    builtin exit
}

updateNow() {
    now=$(date --rfc-3339=date)
}
appendLog() {
    let 'arg_debug' && return
    updateNow
    if [[ "$last_date" != "$now" ]]; then
        if [[ "$last_date" != "" ]]; then
            echo >> "$LOGFILE"
        fi
        printf '%s' "${now}:" >> "$LOGFILE"
        last_date="$now"
    fi
    printf '%s' ' *' >> "$LOGFILE"
}
printHeader() {
    printf ' %b\e[0m\n'               \
        ''                            \
        '\e[1;31mTomato Timer 🍅'     \
        ' P Space  - Pause'           \
        ' S        - Skip'            \
        ' 1        - New pomodoro'    \
        ' 2        - New short break' \
        ' 3        - New long break'  \
        ' Q CtrlC  - Quit'
}
printInfo() {
    local ptxt="" pptxt=""
    if let 'pause'; then
        ptxt+=" \e[5m(Paused \e[91m${time_pause[0]}m\e[0;5m)"
    fi
    case "$skipped" in
        1) ptxt+=" ${COLOR_SKIPPED}(Skipped)";;
        2) ptxt+=" \e[1m${COLOR_INVALID}(Invalid)";;
    esac
    #if let 'MIN_INVALID_PAUSE > 0'; then
    #    local a="${time_pause[0]}" b="$MIN_INVALID_PAUSE"
    #    pptxt=$(printf '%3d%% %02d/%02d' $((a*100/b)) "$a" "$b")
    #fi
    printf "$(printf '%b'               \
        "\e[2K\e[G "                    \
        "\e[0m${COLOR_ALT}%s/%s"        \
        "\e[0m  ${COLOR_MAIN}%02d:%02d" \
        "  %b\e[0m\t%b\e[0m"            \
    )"  "$pstart" "$pend_maybe"         \
        "${time[0]}" "${time[1]}"       \
        "$pname" "$ptxt" >&2
}

playSound() {
    "$SOUND_COMMAND" "${1:?Missing file.}" 2>/dev/null 1>/dev/null
    local err=$?
    if let 'err && arg_warnings'; then
        echo "Warning: unable to play sound effect (exit code: $err)"
    fi
}
notify() {
    updateNow
    local body="" # "<i>${2:?Missing body.}"
    gdbus call \
        --session \
        --dest org.freedesktop.Notifications \
        --object-path /org/freedesktop/Notifications \
        --method org.freedesktop.Notifications.Notify \
        "Tomato Timer ~ ${now}" \
        "$notify_id" \
        "${3:?Missing icon.}" \
        "${1:?Missing summary.}" \
        "$body" \
        "[]" "{}" \
        5000 \
        2>/dev/null 1>/dev/null
    local err=$?
    if let 'err && arg_warnings'; then
        echo "Warning: unable to notify (exit code: $err)"
    fi
    playSound "${4}" &
}
notifyPhase() {
    local psumm pbody picon sound
    case "$phase" in
        0)  psumm="Pomodoro"
            pbody="Train your concentration, resist temptations."
            picon="tomato"
            sound="$NS_POMODORO"
            ;;
        1)  psumm="Short break"
            pbody="Loosen your grip, take a breath ~"
            picon="gbrainy"
            sound="$NS_BREAK"
            ;;
        2)  psumm="Long break"
            pbody="It' s time to walk away from the desk."
            case "$skips" in
                0) picon="trophy-gold";;
                1) picon="trophy-silver";;
                2) picon="trophy-bronze";;
                *) picon="sportstracker";;
            esac
            sound="$NS_BREAK"
            ;;
    esac
    psumm="$(printf '%02d:%02d' "${time[0]}" "${time[1]}") - ${psumm}"
    if let 'phase == 0'; then
        psumm+=" #$((tomatoes+1))"
    fi
    if let 'pause'; then
        psumm+=" (Manual start)"
    fi
    notify "$psumm" "$pbody" "$picon" "$sound"
}
warnPause() {
    local s="s"
    if let 'time_pause[0] == 1'; then
        s=""
    fi
    notify "Are you still there?"                                    \
        "The timer is paused from ${time_pause[0]} minute${s}." \
        "state_paused"                                               \
        "$NS_PAUSE_WARN" 
}
resetPauseWarn() {
    let "time_pause[3] = time_reset[2]";
    let "time_pause[2] = time_reset[1]";
    let "time_pause[1] = 0";
}

initPhase() {
    echo
    declare shour smin dfmt refmt='+%H:%M'
    IFS=':' read -r shour smin dfmt <<< $(date '+%-H:%-M:%P') # 00..24 00..59 [AM/PM]
    pend[0]="$shour"
    pend[1]="$smin"
    if [[ "$dfmt" != "" ]]; then
        refmt='+%I:%M%P'
    fi
    pstart=$(date --date="${shour}:${smin}" "$refmt")
    time[2]=0
    time[1]=0
    case "$phase" in
        0)
            pname="${COLOR_POMODORO}Pomodoro"
            time[0]="$MIN_POMODORO"
            ;;
        1)
            pname="${COLOR_SHORT_BREAK}Short break"
            time[0]="$MIN_SHORT"
            ;;
        2)
            pname="${COLOR_LONG_BREAK}Long break"
            time[0]="$MIN_LONG"
            ;;
    esac
    let 'emin += time[0]'
    let 'ehour += emin / 60'
    let 'emin %= 60'
    let 'ehour %= 24'
    pend_maybe=$(date --date="${ehour}:${emin}" "$refmt")
    if let 'phase == 0'; then
        pname="${pname}\e[0m #$((tomatoes+1))"
        if let 'MANUAL_POMODORO'; then
            pause=1
            printInfo
        fi
    fi
    let 'time_pause[0] = 0'
    resetPauseWarn
    if let '!skipped || NOTIFY_ON_SKIP'; then
        notifyPhase
    fi
}
nextPhase() {
    if let '!skipped && phase == 0'; then
        let 'tomatoes++'
        appendLog
    fi
    let "phase = ${1:-phase>=1 ? 0 : phase+1}"
    if let 'phase > 0'; then
        let 'breaks++'
        if let 'breaks >= LONG_EVERY'; then
            phase=2
        fi
    fi
    initPhase
    skipped=0
    if let 'phase == 2'; then
        skips=0
        breaks=0
    fi
}
skipToPhase() {
    local mode="${1:?Missing mode.}"
    skipped=${2:-1}
    pause=0
    let 'skips++'
    printInfo
    if [[ "$mode" == "s" ]]; then
        nextPhase
    else
        breaks=0
        nextPhase $((mode-1))
    fi
    printInfo
}

timerTick() {
    # countdown to 00:00 for pomodoros
    for pt in {2..0}; do
        let 'time[pt]--'
        if let 'time[pt] >= 0'; then break; fi
        # time == -1
        if let 'pt == 0'; then
            nextPhase
            break
        fi
        let 'time[pt] = time_reset[pt]'
        # decrease next part
    done
    printInfo
}
timerPauseTick() {
    if let 'arg_debug'; then
        printf '\e[s\n\e[2K(%d %d):%d.%d\e[u' "${time_pause[@]}"
    fi
    # countdown to --:00 then countup minutes
    for pt in {3..2}; do
        let 'time_pause[pt]--'
        if let 'time_pause[pt] >= 0'; then break; fi
        let 'time_pause[pt] = time_reset[pt-1]'
        # time == -1
        if let 'pt == 2'; then
            let 'time_pause[1] += 1'
            let 'time_pause[0] += 1'
            if let 'MIN_INVALID_PAUSE > 0 
                    && time_pause[0] >= MIN_INVALID_PAUSE'; then
                skipToPhase 1 2
                break
            fi
            if let 'MIN_PAUSE_WARN > 0
                    && time_pause[1] % MIN_PAUSE_WARN == 0'; then
                warnPause
            fi
        fi
        # decrease next part
    done
    printInfo
}
input() {
    case "$inchar" in
        p|\ )
            #if let 'phase == 0'; then
            let 'pause = !pause'
            resetPauseWarn
            printInfo
            #fi
            ;;
        s|1|2|3)
            skipToPhase "$inchar"
            ;;
        q)
            quit
            ;;
    esac
}


# [Main]
init
while true; do
    # put to prevent timer ticking on user input (faster ticking),
    # this will cause no ticking instead.
    if [[ "$inchar" == "" ]]; then
        if let '!pause'; then
            timerTick
        else
            timerPauseTick
        fi
    fi
    inchar=""
    if read -N 1 -t "$SECONDS_TICK" -s inchar; then
        input
    fi
done
