#!/bin/bash

# Code style:
#   UPPERCASE   settings, globals
#   lowercase   locals
#   undr_scre   variables
#   camelCase   functions
#   abbrev      locals

COLOR_MAIN="\e[38;5;15m"
COLOR_ALT="\e[38;5;248m"
COLOR_SKIPPED="\e[1;38;5;177m"
COLOR_WRONG="\e[1;38;5;160m"
COLOR_CORRECT="\e[1;38;5;154m"

QUIZFILE="${1:?Missing quiz file.}"
ANSWERS=()
QUESTIONS=()
LENGTH=0
TIME_PRECIS=10
TIME_MAX=$((1*60 + 30))  # seconds
TIME=0
TIME_HIDE=0
QUEST_ORDER=()
QUESTNUM=-1
QUESTANS=0
QUESTOK=0
QUESTION=""
QUESTION_LINES=0
EXPECTED=""
ANSWER=""
RANDOM_IN=""
RANDOM_OUT=""

x=('%b' "\e[0m${COLOR_ALT}")
if ! ((TIME_HIDE)); then
    x+=(" %02d:%02d ")
fi
x+=(
    " #%d\e[0m\n"
    " ${COLOR_MAIN}%b%b"
)
INFO_FORMAT="$(printf "${x[@]}")"
TIME_MAX=$((TIME_MAX * TIME_PRECIS))
SECONDS_TICK="$(bc -l <<<"1 / $TIME_PRECIS")"


# [Functions]
pauseFancy() {
    printf '%b' '\e[93m[continue]\e[0m'
    read -s -N 1 "$@"
    printf '\e[G\e[2K'
}

debug() {
    printf '[%s]\n' "$@"
    pauseFancy -t 1
}

loadQuiz() {
    printf "Loading questions... \e[s"
    local linenum=0
    while read -r line; do
        ((linenum++))
        if [[ "$line" =~ ^\ *$ ]]; then
            continue
        fi
        local ans=$(cut -d ' ' -f 1 <<< "$line")
        ans="${ans,,}" # to lowercase
        if [[ "$ans" != "t" ]] && [[ "$ans" != "f" ]]; then
            echo
            echo "→ \"$line\""
            echo "Error: Only \"t\" and \"f\" answers are accepted (line $linenum)."
            exit 1
        fi
        ANSWERS+=( "$ans" )
        local quest=$( cut -d ' ' -f 2- <<< "$line" )
        local quest="$(
            printf '%b\n' "$quest"             | \
            sed -e '$!b; /[\.\?]$/!s/ *$/\./g' | \
            fold -w 75 -s                      | \
            sed -e '1!s/^/ /g'
        )"
        QUESTIONS+=( "$quest" )
        ((LENGTH++))
        printf '\e[u\e[K%d' "$LENGTH"
    done < "$QUIZFILE"
    if ((LENGTH == 0)); then
        echo "This file does not contain any question."
        exit 1
    fi
    echo
    echo "Done."
    #debug "${QUESTIONS[@]}"
    #debug "${ANSWERS[@]}"
}

printHeader() {
    printf ' %b\e[0m\n'         \
        ''                      \
        '\e[1;32mClosed Quiz'   \
        ' → T V Y S   - True'      \
        ' ← F N       - False'     \
        ' U           - Unknown'   \
        ' Q CtrlC Esc - Quit'
}

printInfo() {
    local txt2=""
    if [[ "$ANSWER" != "" ]]; then
        #debug "$QUESTOK" "$QUESTNUM"
        txt2="\n ${COLOR_ALT}> ${COLOR_MAIN}"
        case "$ANSWER" in
            t) txt2+="true " ;;
            f) txt2+="false" ;;
            u) txt2+="unk  " ;;
            *) txt2+=""      ;;
        esac
        txt2+=" "
        local check=""
        case "$ANSWER" in
            t|f)
                if [[ "$ANSWER" == "$EXPECTED" ]]; then
                    check+="${COLOR_CORRECT}(Correct)"
                else
                    check+="${COLOR_WRONG}(Wrong)"
                fi
                ;;
            u)
                check+="${COLOR_SKIPPED}(was "
                case "$EXPECTED" in
                    t) check+="true" ;;
                    f) check+="false" ;;
                esac
                check+=")"
                ;;
        esac
        txt2+="$(printf '%-26s' "$check") ${COLOR_ALT}$((QUESTOK*100/QUESTANS))% \n"
    fi
    if [[ "$1" != "1" ]]; then
        printf '\e[G' # reset horizontal
        for l in $(eval "echo {1..$((QUESTION_LINES+1))}"); do
            printf '\e[2K\e[A' # clear line, go up
        done
        printf '\e[B' # go down
    fi
    local y=("$INFO_FORMAT")
    if ! ((TIME_HIDE)); then
        local t=$(( (TIME + (TIME_PRECIS - TIME % TIME_PRECIS) % TIME_PRECIS) / TIME_PRECIS ))
        #local t=$TIME
        y+=( $((t / 60))  $((t % 60)) )
    fi
    y+=("$((QUESTNUM + 1))" "$QUESTION" "$txt2")
    printf "${y[@]}" >&2
}

nextQuestion() {
    case "$1" in
        t|v|y|s) ANSWER="t"  ;;
        f|n)     ANSWER="f"  ;;
        u)       ANSWER="$1" ;;
    esac
    if [[ "$1" != "i" ]]; then
        [[ "$ANSWER" == "$EXPECTED" ]] && ((QUESTOK < LENGTH/2)) && ((QUESTOK++))
        [[ "$ANSWER" != "$EXPECTED" ]] && ((QUESTOK > 0)) && ((QUESTOK--))
        printInfo
    fi
    # TIME="$TIME_MAX"
    ANSWER=""
    if ((QUESTANS < LENGTH/2)); then
        ((QUESTANS++))
    fi
    local qoi qi
    
    #if ((${#QUEST_ORDER[@]} <= 0)); then
    if ((QUESTNUM == -1)); then
        #echo "<GEN>"
        QUEST_ORDER=( $(printf '%d\n' $(eval "echo {0..$((LENGTH-1))}") | shuf) )
    elif ((QUESTNUM == LENGTH - 1)); then
        # little shuffle
        local a b vb
        for ((a=0; a<$LENGTH; a+=2)); do
            ((b = a + $RANDOM % 4))
            if ! ((b<$LENGTH && b!=a)); then
                continue
            fi
            #echo "$a -> $b"
            vb="${QUEST_ORDER[$b]}"
            QUEST_ORDER[$b]="${QUEST_ORDER[$a]}"
            QUEST_ORDER[$a]="$vb"
        done
    fi
    #fi
    
    #qoi="${#QUEST_ORDER[@]}"
    #((qoi--))
    #qi="${QUEST_ORDER[$qoi]}"
    #unset QUEST_ORDER[$qoi]
    #((qi--))
    ((QUESTNUM = (QUESTNUM + 1) % LENGTH))
    qi="${QUEST_ORDER[$QUESTNUM]}"
    #debug "$qi"
    QUESTION="${QUESTIONS[$qi]}"
    EXPECTED="${ANSWERS[$qi]}"
    IFS=' ' read -r QUESTION_LINES <<< $(
        wc -l < <(printf '%b\n' "$QUESTION")
    )
    echo
    echo
    printInfo 1
}

quit() {
    kill -9 $(jobs -p)
    wait 2>/dev/null
    printf '\e[?25h' #show cursor, 
    printf '\e[2J\e[?1049l' #clear, disable ASB
    exit
}

signal() {
    quit
    #echo '(Signal received)'
    exit
}

init() {
    loadQuiz
    # give time to read number of questions
    sleep .3
    printf '\e[?1049h\e[2J\e[H' #enable ASB, clear
    printf '\e[?25l' #, hide cursor
    trap "signal" SIGINT SIGTERM
    printHeader
    nextQuestion i
    # clear input
    read -r -s < <(cat <(echo))
}

timerTick() {
    # count up
    ((TIME++))
    # # countdown to 00:00
    # ((TIME--))
    # if ((TIME <= 0)); then
    #     nextQuestion u
    #     return
    # fi
    printInfo
}

input() {
    inchar="${inchar,,}"
    case "$inchar" in
        t|v|y|s|f|n|u)
            nextQuestion "$inchar"
            ;;
        q)
            quit
            ;;
    esac
}

keyboard() {
    read -N 1 -t "$SECONDS_TICK" -s inchar
    if (($?)); then
        return $?
    fi
    if [[ "$inchar" != $'\e' ]]; then
        return 0
    fi
    read -t .1 -s inchar
    case "$inchar" in
        # escape
        '') inchar=q ;;
        # right arrow
        [C) inchar=y ;;
        # left arrow
        [D) inchar=n ;;
        # other
        *) inchar='' ;;
    esac
}


# [Main]
init
while true; do
    inchar=""
    if keyboard; then
        input
    fi
    if [[ "$inchar" == "" ]]; then
        timerTick
    fi
done
