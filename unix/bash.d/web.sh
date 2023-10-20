
vencord() (
    cd /tmp
    local O=venc
    [[ -f "$O" ]] || \
    wget -qO "$O" "https://github.com/Vencord/Installer/releases/latest/download/VencordInstaller-x11"
    #wget -qO "$O" "https://github.com/Vencord/Installer/releases/latest/download/VencordInstallerCli-linux"
    chmod +x "$O"
    sudo -E "./$O" "$@"
)

urlencode() {
    local LC_COLLATE=C
    local str="$*"
    local length="${#str}"
    for ((i=0; i<length; i++)); do
        local c="${str:i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            *) printf '%%%02X' "'$c" ;;
        esac
    done
}

urldecode() {
    local url_encoded="${*//+/ }"
    printf '%b' "${url_encoded//%/\\x}"
}

# lynxfix() {
#     local args=("${@: 1: $(($# - 1))}") link="${@: -1}"
#     local tmp=$(mktemp --suffix=.html)
#     wget -O "$tmp" "$link" && lynx "${args[@]}" "$tmp"
#     local err=$?
#     rm "$tmp"
#     return $err
# }
# 
# wiki() {
#     local lang query url out err
#     lang="${1:?Missing language selection (en,it,fr,...).}"
#     shift
#     query=$(tr ' ' '_' <<< "$*")
#     query="${query,,}"
#     url="https://${lang}.wikipedia.org/wiki/$(urlencode $query)"
#     echo "$url"
#     sleep .8
#     lynxfix -accept_all_cookies -anonymous -scrollbar "$url"
# }

spider-ext() {
    local ext="${1:?[1] Missing extension}";
    local site="${2:?[2] Missing URL}";
    wget -r -l1 -H -t1 -nd -N -np -A "${ext}" -erobots=off "${site}"
}
