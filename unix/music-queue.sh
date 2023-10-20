#!/bin/bash


# print gray to stderr without commands
_dbg() ( set +x;  echo -n $'\e[90m';  "$@";  echo -n $'\e[0m'; ) >&2


# self-knowledge
SELF="${BASH_SOURCE[0]}"
REALSELF="$(realpath -s "$SELF")"


# script is sourced?
if [[ "$0" != "$BASH_SOURCE" ]]; then
    # debug
    set -x
else
    # change directory (must exists) without following symlinks
    cd "$(dirname "$REALSELF")" || exit
    #_dbg echo "WorkDir: $PWD"
fi

TMP="/run/user/$(id -u)/$$"


# dependencies
DEPS=(bash playerctl)
if ! command -V "${DEPS[@]}" &>/dev/null; then  # no output if successful
    command -V "${DEPS[@]}"                     # output if failure
    exit 1
fi


suffix() {
    [[ "$kk" == *"$v" ]] || return
    kk="${kk:0:-$l}"
}

check() {
    local f="${1:?Missing function.}"; shift
    #local c="${1:?Missing context.}"; shift
    local k="${1:?Missing key.}"; shift
    local v="${1:?Missing value.}"; shift
    local l="${#v}"
    local -n kk="$k"
    "$f" || return
    #i[ctx]="$c"
}

get_info() {
    for p in $(playerctl -l); do
        [[ "${p,,}" =~ gwenview ]] && continue
        
        # local -A i=()
        # local -n key=R[1] value=R[2]
        # while read -r line; do
        #     [[ "$line" =~ ^[^\ ]+\ [^\ :]+:([^\ ]+)\ +(.*)$ ]] || continue
        #     [[ "$key" == artUrl ]] && continue
        #     i["$key"]="$value"
        # done < <(playerctl -p "$p" metadata)
        
        # get metadata
        IFS=$'\t'
        read -r status  url  artist  title  album < <(
            playerctl -p "$p"  metadata  --format \
            "$(printf '{{%s}}'"$IFS"  status  xesam:url  artist  title  album )"
        )
        
        # check if good player
        [[ "${status,,}" == playing ]] || continue
        
        # clean url
        [[ "$url" =~ ^([^:]+://)?([^/:]+)(:[0-9]+)?/(.+)$ ]] && url="${R[2]} ${R[4]}"
        url="$(sed <<<"$url" -E '
            s/stream(ing)?|listen|mp3|aac|ogg|opus//g;
            s/([^0-9A-Za-z])+/\1/g;
            s/^[^0-9A-Za-z]+|[^0-9A-Za-z]+$//g;
        ')"
        
        # check for known garbage text
        check suffix title '* anima.sknt.ru'
        check suffix title 'on www.playtrance.com'
        title="${title%% }"
        
        # bake content
        local text="${url:+\`${url}\` }$artist - $title${album:+ (${album})}"
        info+=("$text")
    done
}

QUEUE='/mnt/files/Documenti/Org/Journal/Liste/Code/Musica.md'
QUEUE_START=5  # 1-based
write_info() {
    local np=()
    for i in "${info[@]}"; do
        echo "$i"
        if grep -qF "$i" "$QUEUE"; then
            _dbg echo "(already exists)"
            continue
        fi
        np+=("$i")
    done
    if [[ ! "$np" ]]; then
        _dbg echo "Wrote nothing."
        return 2
    fi
    ( # WARNING shared file descriptors
        head -$QUEUE_START
        printf -- '- [ ] %s\n' "${np[@]}"
        # tail -$((QUEUE_START+1))
        cat
    ) <"$QUEUE" >"$TMP"
    mv "$TMP" "$QUEUE"
}

main() {
    local -n R=BASH_REMATCH
    local info=()
    get_info
    if [[ ! "$info" ]]; then
        _dbg echo 'No playing music.'
        return 1
    fi
    write_info
}


main "$@"
