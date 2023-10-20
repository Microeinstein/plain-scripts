
__tweak_path() {
    local -n pathvar="${1:?Missing path variable name.}"
    shift
    local pathparts
    # cannot use -d ':' due to filter mechanism
    mapfile -t pathparts < <(
        # convert ':' in newlines and skip empty
        tr ':' $'\n' <<<"$pathvar" | \
        grep -v '^$'
    )
    "$@"  # eval
    local IFS=':'
    pathvar="${pathparts[*]}"
}

__prepend() { pathparts=( "$@" "${pathparts[@]}"); }

__append()  { pathparts+=("$@"); }

__dedup() {
    local i=0
    for p in "${pathparts[@]}"; do
        ((i++))
    done
}

__customization() {
    local now="$(date +%s)"
    
    # backup
    if [[ ! -v "__PATH_BKP" ]]; then
        export __CUST_PATH_DATE="$now"
        export __PATH_BKP="$PATH"
    else
        # __CUST_PATH_DATE="$__CUST_PATH_DATE"
        local self="${BASH_SOURCE[0]}"
        local last_modify="$(date --reference="$self" +%s)"
        ((__CUST_PATH_DATE > last_modity)) && return
        PATH="$__PATH_BKP"
    fi
    export CCDPATH=""
    __CUST_PATH_DATE="$now"

    local dirs
    local F="/mnt/files"
    
    # -O index:  do not clear array and Overwrite from index
    dirs=()
    dirs+=(
        "."
        "~/.local/bin"
        "~/.nimble/bin"
        "~/node_modules/.bin"
    )
    mapfile -t  -O "${#dirs[@]}" dirs < <(
        find "$F/Sv"*"/Plain" -type d
    )
    __tweak_path PATH __prepend "${dirs[@]}"
    
    dirs=()
    # mapfile -t  -O "${#dirs[@]}"  dirs < <(
    #     find "$F/Documenti/Università" -maxdepth 1 -type d
    # )
    dirs+=(
        "$F/Sv"*
    )
    mapfile -t  -O "${#dirs[@]}" dirs < <(
        find "$F/Sv"*"/Plain" -type d
    )
    dirs+=(
        "$F"
        "$HOME"
        "/run/media/$USER"
        "$F/Do"*  "$F/Wo"*  "$F/Co"*  "$F/Do"*  "$F/Im"*  "$F/Mu"*
        "$F/Vi"*  "$F/To"*  "$F/Gi"*  "$F/Mi"*  "$F/Pr"*  "$F/Ar"*
        "$F/An"*  "$F/Al"*  "$F/Em"*  "$F/Se"*  "$F/Le"*
        "/etc"
        "/"
    )
    __tweak_path CCDPATH __append "${dirs[@]}"
}

__customization
# unsetting last (only) dependent, can unset other functions
unset __customization  __tweak_path  __prepend __append __dedup


shopt -s autocd cdspell direxpand
