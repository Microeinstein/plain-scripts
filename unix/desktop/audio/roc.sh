#!/bin/bash


pa_add_sink() {
    local name="${1:?Undefined name.}"
    local desc="${2:-${name^}}"
    local args=(
        load-module
        #module-null-sink
        #object.linger=1
        #media.class="Audio/${1:?Undefined class.}"
        #sink_name="${2:?Undefined name.}"
        #channel_map=stereo
        #monitor.channel-volumes=true
        module-roc-sink
        remote_ip=192.168.1.69
        sess_latency_msec=50
        sink_properties=device.description="$desc"
    )
    printf '%s\n' "${args[@]}" >&2
    pactl "${args[@]}"
}

pa_del_sink() {
    local sid="$(pactl list short modules \
        | grep device.description="${1:?Undefined name.}" \
        | cut -f 1)"
    pactl unload-module "$sid"
}



#pw_add_sink android-sink 'Android sink'
sid="$(pa_add_sink android-sink 'Android sink')"
echo error $?

read -r -p 'Press a key to terminate...' -N 1

#pw_del_sink android-sink
#pa_del_sink 'Android sink'
pactl unload-module "$sid"
echo error $?
