#!/bin/bash

set -e

#sudo modprobe v4l2loopback video_nr=4 card_label="Screen Source" exclusive_caps=1

SOUNDS="/usr/share/sounds"
PROCNAME="hwaccel_recording"

declare -n R=BASH_REMATCH
[[ "$(xrandr)" =~ current\ ([0-9]+)\ x\ ([0-9]+) ]]
width="${R[1]:-1366}"
height="${R[2]:-768}"


concat() {
    local IFS="$1"; shift
    echo "$*"
}

concat_arr() {
    local IFS="$1"; shift
    local -n arr="$1"; shift
    echo "${arr[*]}"
}

job() {
    exec -a "$PROCNAME" "$@" &
}

# getvar() { # (line, filter, varname)
#     if eval "[[ '$1' =~ ^\\ *${2// /\\ }:\\ *(.*)\$ ]]"; then
#         #echo "$1"
#         eval "$3=\${BASH_REMATCH[1]}"
#     fi
# }


# rectselect() {
#     echo "Select a window..."
#     while read -r line; do
#         getvar "$line" 'Absolute upper-left X' posx
#         getvar "$line" 'Absolute upper-left Y' posy
#         getvar "$line" 'Width'  width
#         getvar "$line" 'Height' height
#     done < <(xwininfo)
# }


start() {
    read -r YY MM DD hh mm ss __ __ < <(date -Iseconds | tr -- 'T:+-' '    ')
    now="${YY}-${MM}-${DD}_${hh}.${mm}.${ss}"
    odir="/mnt/files/Video/Recording"
    vout="${odir}/tmp.mkv"
    aout="${odir}/tmp.mka"
    #vout="/run/user/$(id -u)/tmp.mkv"
    #aout="/run/user/$(id -u)/tmp.mka"
    out="${odir}/screen-$now.mp4"
    
    xgrab=(
        -f  x11grab
        -framerate  60
        -s  "${width}x${height}"
        -i  ":${display:-0}.${screen:-0}+${posx:-0},${posy:-0}"
    )
    kgrab=(
        -f  kmsgrab
        -framerate  60
        -i  -
    )
    
    # postprocess (brightness, hue, contrast, saturation)
    vfilt='procamp_vaapi=b=11:h=1:c=0.9:s=1'
    xfilt=(
        hwupload
        scale_vaapi=format=nv12
        "$vfilt"
    )
    kfilt=(
        hwmap=derive_device=vaapi
        scale_vaapi=w="${width}":h="${height}":format=nv12
        "$vfilt"
    )
    
    all_args=( -hide_banner  -loglevel  info  -nostdin )
    video_args=( "${all_args[@]}"
        -hwaccel  vaapi
        -hwaccel_output_format  vaapi
        -init_hw_device  vaapi=foo:/dev/dri/renderD128  # intel
        -hwaccel_device  foo
        
        # audio causes stutter with kmsgrab
        #-f  pulse
        #-i  listen.monitor
        
        -thread_queue_size 4096
        #-re
        "${kgrab[@]}"
        -vf       "$(concat_arr , kfilt)"
        
        #-c:v      hevc_vaapi
        -c:v      h264_vaapi
        -b:v      9M
        -rc_mode  CQP  #CBR QVBR
        -qp       20  # h264:  18=excellent  20=small loss  31=min quality
        
        #-movflags frag_keyframe+empty_moov  # allows mp4 piping
        #-f        mp4
        -f        matroska
        #-f        nut
        -y
        "$vout"
        #-  # stdout
    )
    audio_args=( "${all_args[@]}"
        -thread_queue_size 4096
        -f        pulse
        -i        "$(pactl get-default-sink).monitor"
        
        #-f        lavfi
        #-i        'anullsrc=channel_layout=stereo:sample_rate=44100'
        #-shortest  # output something in case of no audio
        
        -c:a      aac
        -b:a      196K
        -y
        -f        matroska
        #-f        nut
        "$aout"
        #-  # stdout
    )
    merge_args=(
        "${all_args[@]}"
        -thread_queue_size 4096
        -i        "$vout"
        -thread_queue_size 4096
        -i        "$aout"
        
        # will get in the way of merging standalone files
        #-shortest
        #-fflags   shortest  # lower level, more precise
        
        -c:v      copy
        -c:a      copy
        #-bsf:a    aac_adtstoasc
        -f        mp4
        -tune      zerolatency
        -movflags  +faststart
        -y
        "$out"
    )
    
    #local cores="$(grep -c ^processor /proc/cpuinfo)"
    #taskset -p -c "$((cores - 1))" "$$"  # set self affinity to last core (will propagate)
    
    # sfx
    LC_ALL=C  ogg123 --end '0.5' "$SOUNDS"/Oxygen-Im-Contact-In.ogg
    
    trap 'stop' SIGINT  # ctrl-c will call stop function
    
    #mkfifo "$vout" "$aout" 2>/dev/null || :
    job /builds/software-cursor/softwarecursor-x11
    job ffmpeg "${video_args[@]}"
    job ffmpeg "${audio_args[@]}"
    #sleep 1
    wait
    ffmpeg "${merge_args[@]}"
    rm "$vout" "$aout"
    
    echo "file://$out" | xclip -i -selection clipboard -t "text/uri-list"
}


stop() {
    pkill -2 -f "^$PROCNAME\\b"
    LC_ALL=C  ogg123 --end '0.5' "$SOUNDS"/Oxygen-Im-Contact-Out.ogg
}


case "$1" in
    start) ;;
    stop) ;;
    *) exec echo 'Available commands:  start  stop';;
esac

"$@"
