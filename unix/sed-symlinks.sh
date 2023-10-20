#!/bin/bash


PROGNAME="$(basename "$0")"
ESC=$'\e'
STLRESET="$ESC[0m"
STLBOLD="$ESC[1m"
STLRED="$ESC[31m"
STLGREEN="$ESC[32m"
STLGRAY="$ESC[90m"


run() {
    local path="$1"
    local target="$(readlink "$path")"
    if (($?)); then
        printf ' @ %s\n   (not a symlink)\n\n' "$path"
    fi
    local target2="$(sed "${sed_flags[@]}" -- <<< "$target")"
    #if [[ "$target2" == "$target" ]]; then
    if [[ -z "$target2" ]]; then
        # compatibility with  sed -n 's|...|...|p'
        # (print on change only)
        return
    fi
    local ok="$STLGREEN(ok)"
    ! [[ -e "$target2" ]] && ok="$STLRED(broken)"
    local realt2="$(realpath -ms "$target2")"
    
    printf ' @ %s\n-> %s\n = %s %s\n\n' \
        "$STLBOLD$path$STLRESET"  "$target2"  "$ok$STLRESET"  "$STLGRAY$realt2$STLRESET"
    ln -sf "$target2" "$path"
}


help() {
    cat <<EOF
${STLBOLD}Usage${STLRESET}: $PROGNAME <sed args> -- path1 [path2 ...]

This script will pipe the symlink destination to sed.
EOF
}


main() {
    if ! (($#)); then
        help
        return 2
    fi

    local sed_flags=()
    for a in "$@"; do
        shift
        if [[ "$a" == "--" ]]; then
            break
        fi
        sed_flags+=("$a")
    done
    local paths=("$@")  # remaining
    
    if ! (("${#paths[@]}")); then
        help
        return 3
    fi
    
    for p in "${paths[@]}"; do
        run "$p"
    done
}

main "$@"
