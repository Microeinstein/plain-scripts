# simple operations
swap() {
    local tmp="$(mktemp -u XXXXXXXX)"
    mv "${1:?Missing file 1.}" "$tmp" || return
    mv "${2:?Missing file 2.}" "$1" || return
    mv "$tmp" "$2" || return
}

hide() {
	local f
	for f in "$@"; do
        [[ -e "$f"    ]] || { echo "> $f (missing)"; continue; }
        [[ "$f" == .* ]] && { echo "> $f (already hidden)"; continue; }
        echo "> $f"
        mv -i "$f" ".$f"
    done
}

unhide() {
	local f
	for f in "$@"; do
        [[ -e "$f"    ]] || { echo "> $f (missing)"; continue; }
        [[ "$f" == .* ]] || { echo "> $f (already visible)"; continue; }
        echo "> $f"
        mv -i "$f" "${f#.}"
    done
} 

# run .desktop launcher
launch() {
    local desktop="${1:?Missing ".desktop" file argument.}"
    if [[ "$desktop" != *.desktop ]]; then
        echo 'Missing ".desktop" suffix.'
        return 1
    fi
    if ! [[ -f "$desktop" ]]; then
        echo "Not a file."
        return 1
    fi
    cmd="$(command grep '^Exec=' "$desktop" | tail -c+6)"
    echo "$cmd"
    $cmd
}

# open file (PWD, CCDPATH, PATH)
f() {
    local arg fld apath combo found
    #IFS=':' read -ra apath <<< "${PWD}:${CCDPATH}:${PATH}"
    for arg in "$@"; do
        if [[ "$arg" =~ ^(.+?):\/\/ ]]; then
            echo "Protocol found (${BASH_REMATCH[1]})."
            xdg-open "$arg"
            continue
        fi
        found=0
        while read -r fld; do
        #for fld in "${apath[@]}"; do
            if ! [[ -d "$fld" ]]; then
                continue
            fi
            combo="${fld}/${arg}"
            if [[ -a "$combo" ]]; then
                echo "$combo"
                found=1
                xdg-open "$combo"
                break
            fi
        #done
        done < <(tr ':' '\n' <<<"${PWD}:${CCDPATH}:${PATH}")
        if ((!found)); then
            echo "Not found: ${arg@Q}"
        fi
    done
}


# edit executables (PATH)
d() {
    local what="${1:?Missing file to follow.}"
    local loc="$(command -v "$what")"
    if (($?)); then
        echo "File not found in PATH." >&2
        return 1
    fi
    cd "$(dirname "$loc")"
    "${EDITOR:-micro}" "$what"
} && complete -c d


# jump to directory (CCDPATH)
j() {
    # always-existing dependent will redefine functions at every call, must unset at return
    __atexit() { unset __atexit compl not_found; }
    trap __atexit RETURN
    
    #set -x
    
    local arg="$*"
    local real="$(realpath -m "/$arg")"
    #echo "$real"
    local count_slashes="$(tr -dc '/' <<<"$real" | wc -c)"

    compl() {
        find "$line" -maxdepth "$count_slashes" -type "$1" -ipath "$filter" 2>/dev/null \
        | head -n1  # sed -n '1p;2q'
    }
    not_found() {
        (($?)) || [[ "$target" == "" ]]
    }
    
    local line
    while read -r line; do
        if ! [[ -d "$line" ]]; then
            continue
        fi
        local filter cmd
        local target="$line/$arg"
        if ! [[ -d "$target" ]]; then
            filter="$line/$arg*"
            # ... ${arg:0:-2}*
            #echo "$arg $slashes $combo"
            target="$(compl d)"
            #echo "$target"
            if not_found; then
                target="$(compl f)"
                if not_found; then
                    continue
                fi
                target="$(dirname "$target")"
            fi
        fi
        target="$(realpath "$target")"
        cmd="cd -- ${target@Q}"
        echo "$cmd"
        eval "$cmd"
        return
    done < <(tr ':' '\n' <<<"$CCDPATH")
    echo "Not found: ${arg@Q}"
}

# _j() {
#     local cmd="$1" cur="$2" pre="$3"
#     local _cur compreply
# 
#     _cur="$g_proj_dir/$cur"
#     mapfile -t  compreply < <(IFS=':' compgen -d -W "$CCDPATH" "$_cur");
#     COMPREPLY=( "${compreply[@]#$g_proj_dir/}" )
#     if [[ "${#COMPREPLY[@]}" -eq 1 ]]; then
#         COMPREPLY[0]="${COMPREPLY[0]}/"
#     fi
# }
# complete -F _j j
