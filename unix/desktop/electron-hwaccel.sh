#!/bin/bash

# Arguments
#   <binary name|path>  <title>  [binary_alt]  [desktop name|path]
#
# Cases
#   - system:    "losslesscut"  "LosslessCut"  ["losslesscut"]  ["losslesscut-bin"]
#   - appimage:  "obsidian"     "Obsidian"     ["obsidian"]     ["Obsidian"]


set -uo pipefail


pinfo() { printf '%10s : %s\n' "$@"; }


app="${1:?Missing binary name or path.}" ; shift
title="${1:?Missing app title.}"         ; shift
app_alt="${1:-$app}"                     ; shift
desktop="${1:-$app}"                     ; shift

[[ "$app_alt" == '-' ]] && app_alt="$app"
[[ "$desktop" == '-' ]] && desktop="$app"


read -r app_full < <(  # priority to non-wrappers
    find "$HOME/Applications" -type f -iname "*$app*"                 # local AppImages
    env -i bash -c "source /etc/profile; which ${app@Q}" 2>/dev/null  # system binaries
    which "$app" 2>/dev/null                                          # local binaries
    realpath -ms "$app"                                               # fallback
)
pinfo binary "$app_full"


app_name="$(basename "$app_full")"
app_alt="${app_alt:-$app_name}"
wrapper="$HOME/.local/bin/$app_alt"
gconfig="$HOME/.config/gpuflags.sh"
pinfo wrapper "$wrapper"


wrap_bin='/usr/bin/$(basename "$0")'
[[ "$app_full" =~ ^/usr/bin/ && "$app_alt" == "$app_name" ]] || wrap_bin="$app_full"
pinfo wrapping "$wrap_bin"


[[ -f "$gconfig" ]] || cat <<EOF  >"$gconfig"
#!/bin/bash

myenv=(
    # LIBVA_DRIVER_NAME=i915
    # LIBVA_DRIVER_NAME=nvidia
    # VDPAU_DRIVER=nvidia
    # __NV_PRIME_RENDER_OFFLOAD=1
    # __VK_LAYER_NV_optimus=NVIDIA_only
    # __GLX_VENDOR_LIBRARY_NAME=nvidia
)
[[ "\$myenv" ]] && export "\${myenv[@]}"

# some flags are repeated for compatibility reasons
flags=(
    --use-gl=desktop
    --ignore-gpu-blacklist
    --ignore-gpu-blocklist
    #--in-process-gpu
    --disable-gpu-driver-bug-workarounds
    --disable-features=UseChromeOSDirectVideoDecoder,UseOzonePlatform
    #--enable-unsafe-webgpu
    --enable-features=VaapiIgnoreDriverChecks,VaapiVideoDecoder,VaapiVideoEncoder,Vulkan,RawDraw
    --enable-accelerated-video-decode
    --enable-zero-copy
    --enable-vulkan
    --enable-raw-draw
    --enable-gpu-rasterization
    --enable-oop-rasterization
    --enable-smooth-scrolling
    #--enable-experimental-web-platform-features
)
EOF
chmod +x "$gconfig"


cat <<EOF  >"$wrapper"  #>/dev/null
#!/bin/bash
bin="$wrap_bin"
source "$gconfig"
exec "\$bin" "\${flags[@]}" "\$@"
EOF
chmod +x "$wrapper"


dsks="share/applications"
desktop_full="$desktop"
[[ "$desktop" == */* ]] \
|| read -r desktop_full < <(
    find "$HOME/.local/$dsks" -type f -iname "*$desktop*"
    find         "/usr/$dsks" -type f -iname "*$desktop*"
)
desktop2="$HOME/.local/$dsks/$(basename "$desktop_full")"
pinfo desktop "$desktop_full"
pinfo desktop2 "$desktop2"


tmp="$(mktemp)"
sed -E "
    s>^Name=.*\$>Name=$title (hwaccel)>
    s>^Exec=['\"]?($app_full|$app_name)['\"]?>Exec=\"$wrapper\">g
" "$desktop_full" | uniq > "$tmp"
(($?)) && exit

rm -vf "$desktop2"  # required to make KDE notice the change...
mv "$tmp" "$desktop2"
