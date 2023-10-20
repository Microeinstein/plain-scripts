#/bin/bash


_dbg() ( set +x;  echo -n $'\e[90m';  "$@";  echo -n $'\e[0m'; ) >&2
_pwd() { _dbg echo "WorkDir: $PWD"; }
_args() { _dbg echo "Args:$(printf ' [%s]' "$@")"; }
cd() { command cd "$@" && _pwd; }


sortkeys() {
    local -n __c9M48a4="${1:?Missing array name.}"
    local -n __c9M48a4_b="$1_SK"
    local -n __c9M48a4_l="$1_LEN"
    
    __c9M48a4_l="${#__c9M48a4[@]}"
    mapfile -t __c9M48a4_b < <(printf '%s\n' "${!__c9M48a4[@]}" | sort -n)
}


enumerate() {
    local -n __fV1M9DQ="${1:?Missing array name.}"
    if [[ -v "$1_SK" ]]; then
        local -n __fV1M9DQ_k="$1_SK"
    else
        local __fV1M9DQ_k=( "${!__fV1M9DQ[@]}" )
    fi
    
    for __ci2n4f3 in "${__fV1M9DQ_k[@]}"; do
        echo "KEY=${__ci2n4f3@Q}  VAL=${__fV1M9DQ[$__ci2n4f3]@Q}"
    done
    echo "false"
}


# self-knowledge
SELF="${BASH_SOURCE[0]}"
REALSELF="$(realpath -s "$SELF")"


# script is sourced?
if [[ "$0" != "$BASH_SOURCE" ]]; then
    # debug
    set -x
else
    # change directory (must exists) without following symlinks
    # cd "$(dirname "$REALSELF")" || exit
    _pwd
fi

TMP="/run/user/$(id -u)/$$"


# dependencies
DEPS=(bash)
if ! command -V "${DEPS[@]}" &>/dev/null; then  # no output if successful
    command -V "${DEPS[@]}"                     # output if failure
    exit 1
fi


declare -A LEVELS=(  # [hour]=abs_percent
    [00]=40
    [03]=20
    [06]=45
    [09]=50
    [11]=60
    [12]=50
    [13]=40
    [15]=60
    [18]=50
    [21]=60
)
sortkeys LEVELS


# seconds
TRANS=$((60*20))
STEP=60


SYS="/sys/class/backlight"
mapfile -t DEVS < <(find "$SYS" -mindepth 1 -maxdepth 1)


set_brightness() {
    local dev="${DEVS[0]}"
    local cur="$(cat "$dev/brightness")"
    local max="$(cat "$dev/max_brightness")"
    local to="${1:?Specify desired brightness [delta] percentage. [+-][0-100]}"
    [[ "$to" =~ ^[+-] ]] && ((to = (cur * 100 / max) +$to))
    _dbg echo "to: $1 ($to)"
    ((to = max * to / 100))
    
    local delta=$((to - cur))
    local td=20 tstep=.01
    if ! ((FIRST)); then
        td=$((delta / (TRANS / STEP)))
        tstep=$STEP
    fi
    
    # seq does not generate sequence if A/B are reversed,
    # nor if A+D exceeds B
    for step in  $(seq $cur $td $to)  $(seq $cur -$td $to)  $to; do
        echo "$step" > "$dev/brightness"
        _dbg printf '%b\n\e[F' "$step"
        sleep $tstep
    done
}


get_absolute_brightness() (  # subshell
    local  v2  _k  _hh2
    ((_hh2 = 10#$hh2))
    
    local KEY VAL
    while read -r code; eval "$code"; do
        ((_k = 10#$KEY))
        
        if ((_hh2 < _k)); then
            [[ "$v2" ]] && break
            
            local li=$((LEVELS_LEN - 1))
            local lk="${LEVELS_SK[$li]}"
            echo "${LEVELS[$lk]}"
            return
        fi
        
        v2="$VAL"
    done < <(enumerate LEVELS)
    
    echo "$v2"
)


get_relative_brightness() {
    ((FIRST)) && return 1
    
    local a  b  c  i1  i2
    local _a  _b  _c  _hh2  _hh1=$hh1
    
    local len=${#LEVKP[@]}
    for i in $(seq 0 $((len-1)) ); do
        ((i1 = (i+1) % len))
        ((i2 = (i+2) % len))
        a=${LEVKP[$i]}
        b=${LEVKP[$i1]}
        c=${LEVKP[$i2]}
        _dbg echo "$a  $_hh1  $b  $hh2  $c"
        
        ((_a = 10#$a))
        ((_b = 10#$b))
        ((_c = 10#$c))
        ((_hh1 = 10#$_hh1))
        ((_hh2 = 10#$hh2))
        
        ((ii < i)) && ((_hh1 += 24))
        ((i2 < i)) && ((_hh2 += 24, _c += 24))
        
        if ((
            (_a <= _hh1 && _b <= _hh2 && _hh2 < _c)
        )); then
            echo "+$(( ${LEVELS[$b]} - ${LEVELS[$a]} ))"
            return
        fi
    done
}


test_seq() (
    set +x
    local hh1 hh2
    for hh2 in 23 $(seq 0 23) 0; do
        hh2="$(printf '%02d' "$hh2")"
        
        [[ "$hh1" ]]    # 0 if true
        local FIRST=$?  # 1 if true
        ((!FIRST)) && _dbg printf 'hh2: %2d    level: %3d\n' "$((10#$hh2))" "$("$@")"
        hh1="$hh2"
    done
)


main() {
    #set -x
    local time1=() time2=()
    local -n hh1='time1[0]' mm1='time1[1]' ss1='time1[2]'
    local -n hh2='time2[0]' mm2='time2[1]' ss2='time2[2]'
    
    while true; do
        IFS=':' read -r hh2 mm2 ss2 < <(date +%T)
        
        [[ "$hh1" ]]    # 0 if true
        local FIRST=$?  # 1 if true
        
        local blev
        if ((FIRST)); then
            blev="$(get_absolute_brightness)"
        elif [[ "$hh2" != "$hh1" ]]; then
            blev="$(get_absolute_brightness)"  # must fix relative first
        fi
        
        set_brightness "$blev"
        
        time1=( "${time2[@]}" )
        
        sleep $STEP
    done
}


# source from interactive shell? manual debug (unit-testing)
[[ $- != *i* ]] && main "$@"
