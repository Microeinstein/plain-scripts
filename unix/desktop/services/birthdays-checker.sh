#!/bin/bash


joinByChar() {
    local IFS="$1"
    shift
    echo "$*"
}
yearWord() {
    (( $1 < 2 )) && echo "anno" || echo "anni"
}


# [Arguments]
notify="$IS_DAEMON"
file=""
for a in "$@"; do
    #printf '%s\n' "$a"
    case "$a" in
        # -n) notify=1;;
        *)  file="$a";;
    esac
done


# [Globals]
scriptDir="${BASH_SOURCE[0]}"
scriptDir=$(dirname "$scriptDir")
scriptDir=$(realpath "$scriptDir")
file="/mnt/files/Documenti/Org/birthdays.csv"
if ! [[ -f "$file" ]]; then
    echo "Missing file: '$file'"
    exit 1
fi
logfile="${HOME}/.cache/birthdays-checker.log"
tday=$((60*60*24))
tweek=$((60*60*24*7))
tmonth=$((60*60*24*30))
tyear=$((60*60*24*365))
IFS='-' read -ra now <<< $(date +'%Y-%m-%d')
#echo "${clockdate[0]}"
tnow=$(date --date="$now" +'%s')


# [Calculate table]
entries=()
elength=0
while IFS="," read -ra csv; do
    # blank line or comment in config
    if [[ "${csv[0]}" =~ ^# ]]; then
        continue
    fi
    if (( ${#csv} < 2 )); then
        entries+=("")
        continue
    fi

    tbirth=$(date --date="${csv[0]}" +'%s')
    tdiff=$((tnow - tbirth))
    age=$((tdiff / tyear))
    nextage=$((age + 1))

    IFS='-' read -ra near <<< "${csv[0]}"
    near[0]=${now[0]}
    IFS='-' tnear=$(date --date="${near[*]}" +'%s')
    tdiff=$((tnear - tnow))
    phase=0
    if (( tdiff <= 0 )); then
        near[0]=$((now[0] + 1))
        IFS='-' tnear=$(date --date="${near[*]}" +'%s')
        tdiff2=$tdiff
        tdiff=$((tnear - tday - tnow))
        # 10# means "use base 10 for next constant"
        near[1]=$((10#${near[1]}))
        near[2]=$((10#${near[2]}))
        now[1]=$((10#${now[1]}))
        now[2]=$((10#${now[2]}))
        if ((near[1] == now[1] && near[2] == now[2])); then
            phase=4
        elif ((-tdiff2 <= tweek)); then
            phase=5
        fi
    elif (( tdiff <= tday )); then
        phase=3
    elif (( tdiff <= tweek )); then
        phase=2
    elif (( tdiff <= tmonth )); then
        phase=1
    fi
    near=$(date --date="@${tdiff}" +'%j')
    near=$((10#$near))
    near="-${near}"

    #first=1
    for person in "${csv[@]:1}"; do
        entries+=("${phase}|${person}|${age}|${csv[0]}|${near}")
        ((elength++))
        #if [[ $first == 1 ]]; then
        #    age="//"
        #    csv[0]="//"
        #    near="//"
        #fi
        #first=0
    done
done < "$file"


# [CLI print]
if (( notify == 0 )); then
    {
        printf "\e[0000mNome|Età|Nascita|Rimanenti\n"
        for e in "${entries[@]}"; do
            if [[ "$e" == "" ]]; then
                echo ""
                continue
            fi
            #IFS='|' read -ra parts <<< "$e"
            #phase="${parts[0]}"
            #other=$(joinByChar '|' "${parts[@]:1}")
            phase="${e:0:1}"
            other="${e:2}"
            case $phase in
                0) format="\e[0;37m";;  #not important
                1) format="\e[0000m";;  #in month
                2) format="\e[0;92m";;  #in week
                3) format="\e[1;33m";;  #in day
                4) format="\e[1;95m";;  #IN PROGRESS
                5) format="\e[0;36m";;  #just happened
            esac
            printf "${format}${other}\n"
        done
    } | column --separator '|' -t -L
    printf "\e[0m"


# [Service notification]
else
    logrev=$(mktemp)
    touch "$logfile"
    tac "$logfile" > "$logrev"
    readarray lastlog < "$logrev"
    rm "$logrev"
    appendLog() {
        echo "$*|$oldPhase"
        echo "$*" >> "$logfile"
    }
    findRecent() {
        for entry in "${lastlog[@]}"; do
            IFS='|' read -ra logparts <<< "$entry"
            #printf '%s\n' "${logparts[@]}" >&2
            if [[ "${logparts[0]}" == "$1" ]]; then
                echo "${logparts[1]}"
                return 0
            fi
        done
        return 1
    }
    icon=$(realpath birthdayIcon.png)
    notify() {
        notify-send -u critical -i "$icon" "$@"
    }
    monthly=""
    monthlyEmpty=1
    for e in "${entries[@]}"; do
        if [[ "$e" == "" ]]; then
            continue
        fi
        IFS='|' read -ra parts <<< "$e"
        id="${parts[3]},${parts[1]}"
        phase="${parts[0]}"
        oldPhase=$(findRecent "$id")
        if (( $? != 0 )); then
            oldPhase=0
        fi
        if (( phase != oldPhase )); then
            appendLog "$id|$phase"
        fi
        y=${parts[2]}
        r=${parts[4]:1}
        #y="${y##*(0)}"
        if (( phase == oldPhase )); then
            continue
        fi
        case "${phase}" in
            1)
                ((y+=1))
                if (( monthlyEmpty == 0 )); then
                    monthly+=",\n"
                fi
                monthly+="${parts[1]} (→${y}, -${r})"
                monthlyEmpty=0
                ;;

            2)
                ((y+=1))
                notify -a "Compleanni" \
                "Evento in settimana." \
                "${parts[1]} compirà ${y} $(yearWord $y) fra ${r} giorni."
                ;;

            3)
                # ((y+=1)) already incremented
                notify -a "Compleanni" \
                "Evento imminente!" \
                "${parts[1]} sta per compiere ${y} $(yearWord $y)!"
                ;;

            4)
                notify -a "Compleanni" \
                "Evento in corso!" \
                "${parts[1]} ha appena compiuto ${y} $(yearWord $y)!"
                ;;

            5)
                if (( $oldPhase != 3 && $oldPhase != 4 )); then
                    notify -a "Compleanni" \
                    "Ti sei perso un compleanno?" \
                    "${parts[1]} ha compiuto ${y} $(yearWord $y) qualche giorno fa."
                fi
                ;;
        esac
    done
    if (( monthlyEmpty == 0 )); then
        notify -a "Compleanni" \
        "Eventi questo mese:" \
        "$monthly"
    fi

    tail -n $((elength*3)) "$logfile" > "${logfile}.2"
    mv "${logfile}.2" "$logfile"
fi



