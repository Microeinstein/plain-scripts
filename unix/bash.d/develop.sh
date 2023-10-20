
alias man='man -Len'
alias make='make -j4'

condaa() {
    local v='./venv'
    [[ -d "$v" ]] || v="/mnt/files/Sv"*"/Venv/$(basename "$PWD")"
    conda activate "$v"
}

android-sdk-manage() {
    local action="${1:-install}"; shift
    local ver="$1"; shift
    local sub="${1:-0.0}"; shift
    local a=(
        "--${action}"
        "system-images;android-${ver};default;x86_64"
        "platform-tools"
        "build-tools;${ver}.${sub}"
        "platforms;android-${ver}"
    )
    /opt/android-sdk/tools/bin/sdkmanager "${a[@]}"
}

adb-grant-secure() {
    local n="${1:?Missing package name.}"
    adb shell pm grant "$n" android.permission.WRITE_SECURE_SETTINGS
    adb shell pm grant "$n" android.permission.DUMP
}

run-container() {
    local a=(
        -b -n
        --network-bridge="virbr0"
        -D "/containers/${1:?Missing container name.}"
        --bind="/builds"
    )
    systemd-nspawn "${a[@]}"
}

# search-bin() {
#     bbe -s -b "${1:?Missing block to search.}" -e 'F D; A \x0A; p A' "${2:?Missing filename.}";
# }
