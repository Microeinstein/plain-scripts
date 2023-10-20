#!/bin/bash


deps() {
    if ! command -V "$@" &>/dev/null; then
        command -V "$@"
        return 1
    fi
}

deps pgrep pkill  lualatex biber || exit
    
#set -x

# new process session id
# if ! pgrep -s $$; then
#     echo "Using new session ID..."
#     sleep 1
#     trap 'echo AA; kill -TERM -- $(jobs -p)' SIGINT SIGTERM
#     setsid -w "$0" "$@" &
#     while [[ "$(jobs)" ]]; do wait; done
#     exit
# fi

SELF="${BASH_SOURCE[0]}"
cd "$(dirname "$(realpath -s "$SELF")")" || exit
echo "WorkDir: $PWD"

TMP="/run/user/$(id -u)/$$"

epoch() { date '+%s'; }


# activate_wnd() {
#     local ids=( $(wmctrl -l | grep -i "${1:?Missing window name.}" | cut -d' ' -f1) )
#     for i in "${ids[@]}"; do
#         # cut 0x, convert to base 10
#         i=$((16#${i:2}))
#         if ! xwininfo -id "$i" | grep IsUnMapped; then
#             wmctrl -i -a "$i"
#             return
#         fi
#     done
# }
# replaced by xdg-open + dbus support from reader app


# all_procs() {
#     local child=($(ps -o pid= --ppid "${1:-$$}"))
#     for pid in "${child[@]}"; do
#         all_procs "$pid"
#     done
#     echo "${child[*]}"
# }

set -m  # job control
_propag() {
    local jid;
    trap "$1" SIGINT SIGTERM
    "${@:2}" &
    jid="$!"
    wait -n -f "$jid"
    local err=$?
    return $err
}
propag()     { _propag 'kill -TERM $jid'     "$@"; }
propag_all() { _propag 'pkill -TERM -P $jid' "$@"; }

_run() { "$@"; } &>"$TMP.step"

step() {
    local label="($2) $1"
    echo -n "$label "
    printf "%$((40-${#label}))s" | tr ' ' '.'
    echo -n ' '
    # `local` command does not preserve exit status
    propag_all _run "${@:2}"
    local err=$?
    if ((err)); then
        ((err >= 128)) && echo "ABORTED" || echo "FAILURE"
        {
            echo
            echo
            cat "$TMP.step"
            echo
            echo
        } >/dev/null #>&2
    else
        echo "SUCCESS"
    fi
    rm -f "$TMP.step"
    return $err
}

engine=(
    lualatex
    --file-line-error
    --halt-on-error
    --shell-escape
    --interaction=nonstopmode
)
mkaux=("${engine[@]}" --draftmode)
mkpdf=("${engine[@]}" --synctex=12)


bib="pages/refs.bib"
frn="pages/frontespizio.tex"
name="doc"
tex="$name.tex"
pdf="$name.pdf"
log="$name.log"
frn_out="$name-frn"


rm_pdf() { rm -fv "./$pdf"; }

clean() {
    local a=(-type f \(
        -iname '*.aux'  -o  -iname '*.log'  -o  -iname '*.out'
    \))
    find . "${a[@]}" -exec rm -v '{}' +
}

clean_more() {
    clean
    local a=(-type f \(
        -iname '*.bbl'  -o  -iname '*.bcf'  -o  -iname '*.blg'  -o
        -iname '*.xml'  -o  -iname '*.synctex.*'  -o
        -iname "$frn_out.tex"  -o  -iname "$frn_out.pdf"
    \))
    find . "${a[@]}" -exec rm -v '{}' +
}

reset() {
    clean_more
    rm_pdf
}

bake_inner() {
    # [latex options]
    local cust="\def\docopts{$1}\input{$tex}"
    local arg="${1:+$cust}${1:-$tex}"
    
    # [[ -e "$log" ]] \
    #     && rm_pdf
    [[ "$frn" -nt "$frn_out.pdf" ]] \
        && rm -fv "$frn_out."{tex,pdf}
    
    if [[ "$bib" -nt "$name.bbl" ]]; then
        propag step 'compiling bib aux' "${mkaux[@]}" "$arg" || return
        propag step 'bibliography'  biber "$name" || return
    fi
    
    propag step 'baking pdf' "${mkpdf[@]}" "$arg" || return
    if [[ "$1" == "final" ]] && grep -qEi 'undefined references|file.*has changed' "$log"; then
        propag step 'fixing refs' "${mkpdf[@]}" "$arg" || return
    fi
}

bake() {
    # [latex options]
    local ta="$(epoch)"
    propag bake_inner "$1"
    local err=$?
    
    local tb="$(epoch)"
    local filt=(
        -B 1  -A 1  --group-separator="_______________________"
        -i -E '\b(underfull|overfull|forgotten|undefined|warning|error)\b|^!'
    )
    {
        echo "EXCERPT:"
        tail -n+4 "$log" | sed -zE 's/\n+/\n/g;s/\n([a-z])/\1/g' \
        | sort | uniq | grep -v 'infwarerr' | sed -E 's|^(.*at lines )([0-9]+)(.*)$|/dev/stdin:\2: \1\2\3|g' | grep "${filt[@]}" | head -n2000 | tac
        ((err)) & {
            echo
            echo "LAST LINES:"
            sed -zE 's/\n+/\n/g;s/\n([a-z])/\1/g' "$log" | uniq | tail -n13
        }
    } >"$TMP.log"
    
    ((err)) && { rm_pdf; :; } # || step 'garbage collect' clean
    {
        echo "Total: $((tb - ta)) seconds"
        echo
        cat "$TMP.log"
    } >&2
    rm -f "$TMP.log"
    sleep .4
    ((err)) || xdg-open "$pdf"
    return $err
}

zip() {
    command zip -o -r "$name" . -i 'build' '*.sh' '*.md' '*.tex' '*.sty'
}


target=("${1:-bake}" "${@:2}")
echo "> ${target[*]}"
propag "${target[@]}"
