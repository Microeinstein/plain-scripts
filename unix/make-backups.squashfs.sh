#!/bin/bash


_log() {
    echo -n "$*"$'\e[0m\n'
} >&2

_errlog() {
    _log $'\e[31mError: '"$*."
}


if [[ "$0" == "$BASH_SOURCE" ]]; then
    _errlog "script must be sourced"
    exit 1
fi

if (($(id -u))); then
    _errlog "root is required to read system' protected files"
    return 1
fi


RAM_SIZE=$(sed -En 's|direct.*: *([0-9]+).*|\1|igp' /proc/meminfo | xargs | tr ' ' '+')
((RAM_SIZE /= 1024))
BKP_RAM=$((RAM_SIZE / 2 + 100))
_log "Total RAM size: ${RAM_SIZE}M"
_log "  will be used: ${BKP_RAM}M"

cat <<EOF >&2

Hints:
    - close other programs
    - drop system cache before backup
        $ sysctl vm.drop_caches=3

EOF

_backup() {
    local args=(
        "${files_include[@]}"   # sources
        "${output_path}.sqsh"   # output
        
        -comp zstd              # compression kind
        # -X 15                 # zstd compression level (default 15)
        
        -one-file-system        # do not traverse to other ones
        
        # (defaults):
        #   * detects duplicate files
        #   * block size = 128K compared to filesystem' 4K
        
        -info -progress         # verbosity
        -mem "${BKP_RAM}M"      # performance
        
        # do not compress pictures, already-compressed or big files
        -action "uncompressed @ \
               name(*.jpg)      \
            || name(*.jpeg)     \
            || name(*.7z)       \
            || name(*.zip)      \
            || name(*.rar)      \
            || name(*.gz)       \
            || name(*.gzip)     \
            || name(*.tgz)      \
            || name(*.bzip)     \
            || name(*.bzip2)    \
            || name(*.bz2)      \
            || name(*.xz)       \
            || name(*.lzma)     \
            || name(*.cab)      \
            || name(*.xar)      \
            || name(*.zst)      \
            || name(*.zstd)     \
            || filesize(+1G)    \
        "
        
        "${cust_options[@]}"
        
        # excluded files
        -wildcards
        # -regex                # POSIX
        "${files_exclude:+-e}"
        "${files_exclude[@]}"
        #  "..." pattern prefix means to consider subdirectories
    )

    time mksquashfs "${args[@]}"
}


# cool ignore patterns
# https://github.com/github/gitignore/tree/main/Global
COMMON_EXCLUDE=(
    '... .cache'
    '... .DS_Store'
    '... Thumbs.db'
    '... $RECYCLE.BIN'
    '... *.bak'
    '... *.gho'
    '... *.ori'
    '... *.orig'
    '... *.tmp'
    '... *~'
    '... .fuse_hidden*'
    '... .Trash-*'
    '... .nfs*'
    '... .~lock.*'
    '... *.retry'
)
TODAY="$(date --iso-8601)"
BKP_SRC=''
BKP_DEST=''
BKP_DEST_COMMON='/Ridondanza'
USE_SNAPSHOTS=''
SNAP_ROOT="@archlinux"
SNAP_HOME="@home"


from_running() {
    BKP_SRC='/'
    USE_SNAPSHOTS=''
    _log "From: $BKP_SRC"
}

from_rescue() {
    BKP_SRC='/run/media/rescue/Main'
    USE_SNAPSHOTS=''
    _log "From: $BKP_SRC"
}

from_snapshots() {
    local p='/.../@snapshots'
    if ! [[ -d "$p" ]]; then
        _errlog "snapshots directory not found"
        return 1
    fi
    pushd "$p" &>/dev/null
    local dates=( * )
    if ! ((${#dates[@]})); then
        _errlog "no snapshots found, please make one"
        popd &>/dev/null
        return 1
        # pushd /.../@snapshots/;
        # mkdir -p "$TODAY";
        # btrfs subvolume snapshot    /.../@     "$TODAY/$SNAP_ROOT";
        # btrfs subvolume snapshot -r /.../@home "$TODAY/$SNAP_HOME";
        # popd;
    fi
    echo "Please select a date:"
    printf ' > %s\n' "${dates[@]}"
    local date
    while true; do
        read -r -e -p 'choice: ' date
        if [[ -d "$p/$date" ]]; then
            break
        fi
        _errlog "invalid choice"
    done
    popd &>/dev/null
    BKP_SRC="$p/$date"
    USE_SNAPSHOTS='1'
    _log "From: $BKP_SRC"
} >&2


to_running() {
    BKP_DEST='/mnt/files'"$BKP_DEST_COMMON"
    _log "To: $BKP_DEST"
}

to_rescue() {
    BKP_DEST='/run/media/rescue/Files'"$BKP_DEST_COMMON"
    _log "To: $BKP_DEST"
}

to_workdir() {
    BKP_DEST='.'
    _log "To: $BKP_DEST"
}


_check_paths() {
    ! [[ -z "$BKP_SRC" ]]
    local miss_src=$?
    
    ! [[ -z "$BKP_DEST" ]]
    local miss_dest=$?
    
    if ((miss_src)); then
        _errlog "please specify source path"
    fi
    if ((miss_dest)); then
        _errlog "please specify destination path"
    fi
    
    ! ((miss_src || miss_dest))
}

_ask_correct() {
    echo "Selected backup configuration:"
    printf ' + %s\n' "${files_include[@]}"
    printf ' - %s\n' "${files_exclude[@]}"
    printf ' $ %s\n' "${cust_options[@]}"
    printf ' = %s\n' "${output_path}"
    echo
    local ans
    read -r -t 10 -p "Are these correct? [Y/n 10s..] " ans
    ans="${ans,,}"
    if [[ "${ans:=y}" != 'y' ]]; then
        echo 'Aborting...'
        return 1
    fi
    return 0
} >&2


bkp_root() {
    _check_paths || return 1
    local files_include=(
        "${BKP_SRC}/${USE_SNAPSHOTS:+$SNAP_ROOT}"  # (all)
        #  /etc /usr /opt /mnt /root /srv /var
    )
    local files_exclude=(
        "${COMMON_EXCLUDE[@]}"
        'var/cache/pacman/pkg/*'
        'var/lib/docker'
        'var/lib/machines'
        'home/*'
        'builds/*'
        'containers/*'
        'virtual/*'
    )
    local cust_options=( )
    local output_path="${BKP_DEST}/${TODAY}_root"
    _ask_correct || return 2
    _backup
}


bkp_home() {
    # params: [user]
    _check_paths || return 1
    local specific="$1"
    local home="home"
    ((USE_SNAPSHOTS)) && { home="$SNAP_HOME"; :; } || { :; }
    local files_include=(
        "${BKP_SRC}/$home/$specific"
    )
    local files_exclude=(
        "${COMMON_EXCLUDE[@]}"
        '... .cache/paru'
        '... .cache/mozilla/firefox'
        '... .config/discord/Cache/*'
        '... .config/VSCodium/Cache/*'
        '... .local/share/TelegramDesktop/tdata/user_data/media_cache/*'
        '... .local/share/Trash'
        '... .local/share/Steam'
        '... .local/share/bottles'
    )
    local cust_options=( )
    local output_path="${BKP_DEST}/${TODAY}_${specific:-home}"
    _ask_correct || return 2
    _backup
}


cat <<EOF >&2
Usage: run these commands    Valid options:
1. from_<location>             running, rescue, snapshots
2.   to_<location>             running, rescue, workdir
3.  bkp_<kind>                 root, home

4. you'll be asked to check for correctness

Enjoy
EOF
