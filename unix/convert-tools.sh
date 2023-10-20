#!/bin/bash
# 2023-10-22, Microeinstein

# this script can be sourced from .bashrc, from outer scripts as library, and yet be executable

declare -A __ACTIONS=(
    [adapt-lanczos]=1
    [adapt-wallpaper]=1
    [pdf2jpg]=1
    [source2pdf]=1
    [to-sticker]=1
    [ffmpeg-mp3-320]=1
    [ffmpeg-opus-256]=1
    [ffmpeg-flac]=1
    [ffmpeg-wav2mp3-hq]=1
    [mpv-any2mp4]=1
    [ffmpeg-no-audio]=1
    [ffmpeg-silent-audio]=1
    [ffmpeg-extract-aac]=1
    [ffmpeg-gif]=1
)

# is interactive shell? (imply sourced)
if [[ $- == *i* ]]; then
    # set wrappers (exports) to run this file as
    for exp in "${!__ACTIONS[@]}"; do
        eval "$exp() ( ${BASH_SOURCE[0]@Q} ${exp@Q} \"\$@\" )"
    done
    unset __ACTIONS
    return
fi


# UTILS
errlog() {
    printf '%b' '\e[38;5;211m'
    if [[ "$*" ]]; then "$@"; else echo; fi
    printf '%b' '\e[0m'
} >&2

deps() {
    if ! command -V "$@" &>/dev/null; then
        errlog command -V "$@"
        return 1
    fi
}

eval() { command eval "${@@Q}"; }  # fix arguments quoting

ffmpeg() { command ffmpeg -hide_banner "$@"; }

pause() { read -s -r -p 'Press Enter to continue...'; echo; }

clip_get_type()    { xclip -o -selection clipboard -t "${1:?Missing type.}"; }
clip_get_targets() { clip_get_type 'TARGETS'; }
clip_set_type()    { xclip -i -selection clipboard -t "${1:?Missing type.}"; }
clip_set_uri()     { printf 'file://%s\n' "$@" | clip_set_type "text/uri-list"; }


# IMAGES
adapt-lanczos() {
    fout="${fout}_adapted.$fext"
    deps convert || return
    local a=(
        "$fin"
        -filter Lanczos
        -resize "${RES:?Missing option (RES=\'1920x1080^\').}"
        -quality 100
        "$fout"
    )
    convert "${a[@]}"
}

adapt-wallpaper() {
    read -r w x h < <(
        LC_ALL=C xrandr -q \
        | sed -E '1!d;s/.*current (.*),.*/\1/g'
    )
    RES="${w}x${h}^" 
    adapt-lanczos
}

pdf2jpg() {
    # extension is automatic
    deps pdftoppm || return
    pdftoppm "$fin" "$fout" -jpeg -f 1 -singlefile
    fout="$fout.jpg"
}

source2pdf() {
    fout="$fout.pdf"
    deps enscript ps2pdf || return
    
    local -n  lang=flags[0]  fs=flags[1]  color=flags[2]
    : "${lang:?Missing language.}"
    : "${fs:?Missing font size (float).}"
    : "${color:?Missing colors option (0/1).}"
    [[ "$color" == "1" ]] || color=""
    color="${color:+--color=$color}"
    
    local ps="$(mktemp)"
    # -i2
    # oneColumn, font, syntax, title, portrait, tabSize, color, out, in
    enscript -1 -f "Courier${fs}" "-E${lang}" -J -R -T 2 "$color" -o "$ps" "$fin"
    ps2pdf "$ps" "$fout"
    echo
    rm "$ps"
}

to-sticker() {
    local targs fmt;
    deps convert || return
    
    # svg is broken on xournalpps
    targs="$(clip_get_targets)"
    for pt in '^image/png$' '^image'; do
        fmt="$(grep -i "$pt" <<<"$targs" | head -n1)" && break
    done
    
    if ! [[ "$fmt" ]]; then
        echo "No image found in clipboard."
        return 1
    fi
    [[ "$fmt" =~ /([^+]+).*$ ]]
    fext="${BASH_REMATCH[1]}"
    
    echo "Clipboard contains $fmt"
    fin="$(mktemp "/tmp/tmp.XXXXXXXX.$fext")"
    fout="$(mktemp "/tmp/tmp.XXXXXXXX.webp")"
    clip_get_type "$fmt" > "$fin"
    
    local a=(
        "$fin"
        -quality 100
        -define webp:lossless=true
        -background none
        #-gravity center
        #-resize 512x512
        #-extent 512x512
        "$fout"
    )
    convert "${a[@]}"
}


# AUDIO
ffmpeg-mp3-320() {
    fout="$fout.mp3"
    deps ffmpeg || return
    ffmpeg -i "$fin" -b:a 320k "$fout"
}

ffmpeg-opus-256() {
    fout="$fout.opus"
    deps ffmpeg || return
    ffmpeg -i "$fin" -b:a 256k "$fout"
}

ffmpeg-flac() {
    fout="$fout.flac"
    deps ffmpeg || return
    ffmpeg -i "$fin" -compression_level 8 "$fout"
}

ffmpeg-wav2mp3-hq() {
    local tmp="$(mktemp /tmp/tmp.XXXXXXXXXX.wav)"
    deps ffmpeg || return
    ffmpeg -i "$fin" -sample_fmt s16p -ar 44100 -map_metadata -1 -y "$tmp"
    fin="$tmp"
    ffmpeg_mp3_320
    rm -v "$tmp"
}


# VIDEO
mpv-any2mp4() {
    fout="$fout.mp4"
    deps mpv || return
    mpv "$fin" -o "$fout"
}

ffmpeg-no-audio() {
    fout="$fout.noAudio.$fext"
    deps ffmpeg || return
    ffmpeg -i "$fin" -c:v copy -an "$fout"
}

ffmpeg-silent-audio() {
    fout="$fout.silent.$fext"
    deps ffmpeg || return
    local a=(
        -f lavfi
        -i 'anullsrc=channel_layout=stereo:sample_rate=44100'
        -i "$fin"
        -shortest
        -c:v copy
        -c:a aac
        "$fout"
    )
    ffmpeg "${a[@]}"
}

ffmpeg-extract-aac() {
    fout="$fout.aac"
    deps ffmpeg || return
    ffmpeg -i "$fin" -c:a copy -vn "$fout"
}

ffmpeg-gif() {
    fout="$fout.gif"
    deps ffmpeg || return
    local filt=(
        'scale=320:-1:flags=lanczos,split[s0][s1]'
        '[s0]palettegen[p]'
        '[s1][p]paletteuse'
    )
    local IFS=';'
    ffmpeg -i "$fin" -an -vf "${filt[*]}" -loop 0 "$fout"
}


help() {
    errlog cat <<EOF
Usage: [env=value]..  $(basename "${BASH_SOURCE[0]}")  file [file]..

Actions:
EOF
    errlog printf '• %s\n' help "${!__ACTIONS[@]}"
    exit "$1"
}

convert-tools() {
    # errlog echo "--arguments--"
    # errlog printf '[%s]\n' "$@"
    # errlog
    
    # local -A actions
    # while read -r f; do
    #     actions["$f"]=1
    # done < <(declare -F | cut -d' ' -f3)


    # common dependencies
    deps mktemp xclip || return
    
    if ! (($#)); then
        errlog echo "Missing action."
        help 1
    fi
    local action="$1"; shift
    
    local typ="$(type -t "$action")"
    if [[ "$typ" != "function" ]]; then
        errlog echo "'$action' is not an action."
        return 1
    fi
    [[ "$action" == "help" ]] && help 0
    if [[ ! "${__ACTIONS["$action"]}" ]]; then
        errlog echo "'$action' is not a known action."
        return 1
    fi
    
    
    # local opts=()
    # for o in "$@"; do
    #     shift
    #     if [[ "$o" == "--" ]]; then
    #         break
    #     fi
    #     opts+=("$o")
    # done
    local files=("$@")  # remaining
    
    # errlog echo "--opts--"
    # errlog printf '[%s]\n' "${opts[@]}"
    errlog echo "--files--"
    errlog printf '[%s]\n' "${files[@]}"
    errlog
    
    local outlist=()
    local fin fout fext
    # set -x
    for fin in "${files[@]}"; do
        echo "> $fin"
        
        cd "$(dirname "$fin")"
        fin="$(basename "$fin")"
        fout="./${fin%.*}"  # no extension
        fext="${fin##*.}"  # no dot
        # inherited vars: action fin fout fext opts
        "$action"
        local err=$?
        fout="$(realpath -ms "$fout")"
        
        if ((err)); then
            errlog echo "Error $err"
            return $err
        fi
        outlist+=("$fout")
        echo
    done
    clip_set_uri "${outlist[@]}"
    # set +x
    errlog echo "Done"
}


return &>/dev/null  # do not run when sourced
set -euo pipefail
"$(basename "${0%.*sh}")" "$@"
