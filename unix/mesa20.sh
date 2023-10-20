#!/bin/bash

# credits: https://github.com/archlinux-downgrade/downgrade

fail() {
    printf '%s\n' "Failed to $*"
    exit 1
} >&2


DOWNGRADE_ARCH="$(pacman-conf Architecture | head -n 1)"
DOWNGRADE_ALA_URL="https://archive.archlinux.org"

sed_msg() {
    local msg="$1"
    shift
    sed "$@" 2>/dev/null || fail "$msg"
}

get_ala_index() {
    local name=$1 pkgfile_re index
    
    pkgfile_re="$name-[^-]+-[0-9.]+-(any|$DOWNGRADE_ARCH)\\.pkg\\.tar\\.(gz|xz|zst)"
    index="$DOWNGRADE_ALA_URL/packages/${name:0:1}/$name/"
    
    curl --fail --silent "$index" \
    | sed_msg "parse A.L.A." -E '
      /.* href="('"$pkgfile_re"')".*/!d;
      s||'"$index"'\1|g; s|\+| |g; s|%|\\x|g' \
    | xargs -0 printf "%b"
}

get_ala_pkgurl() {
    local url
    echo "$1..." >&2
    url="$(get_ala_index "$1" | grep -E "$2.*\.pkg" | tail -n1)" \
    || fail "get url for $1"
    echo "$url"
}


ROOTDIR='/opt/mesa-20.1.4'
TMP='/tmp/mesa20'
mkdir -p "$TMP"


download() {
    local URLS PKGS
    URLS=()

    PKGS=(
        mesa               lib32-mesa
        mesa-vdpau         lib32-mesa-vdpau
        opencl-mesa        lib32-opencl-mesa
        libva-mesa-driver  lib32-libva-mesa-driver
        vulkan-intel       lib32-vulkan-intel
    )
    for pkg in "${PKGS[@]}"; do
        URLS+=("$(get_ala_pkgurl "$pkg" 20.1.4)") || break
    done
    for pkg in {,lib32-}llvm-libs; do
        URLS+=("$(get_ala_pkgurl "$pkg" 10.0)") || break
    done
    for pkg in {,lib32-}libffi; do
        URLS+=("$(get_ala_pkgurl "$pkg" 3.3)") || break
    done

    wget -q --show-progress -c -P "$TMP" --content-disposition -i - < <(printf '%s\n' "${URLS[@]}")
}

unpack() {
    for p in "$TMP"/*; do
        tar -xvf "$p"  --strip-components=1  -C "$ROOTDIR"  usr
    done
}

final() {
    cat <<EOF

Done, remember to add the following environment variables to your wine commands - Q4Wine is suggested (put rightafter '%ENV_ARGS%' and on the same line); do NOT set them globally, or your desktop might fail.

    LIBGL_DRIVERS_PATH=$ROOTDIR/lib32/dri:$ROOTDIR/lib/dri
    LD_LIBRARY_PATH=$ROOTDIR/lib32:$ROOTDIR/lib

Also the folling if your game does not load because Mesa needs more libraries:

    LIBGL_DEBUG=verbose
EOF
}

main() {
    download
    unpack
    final
}

"${1:-main}"
