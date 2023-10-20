#!/bin/bash

cd "$(dirname "$(realpath $0)")"
source commons.sh


# use systemd journal
## redirect all output & error to file
#LOGFILE="latest-start-after.log"
#exec &> "$LOGFILE"
#echo "-------------------------------"


#set -o xtrace

#now() {
#    date +%T.%N
#}

test_default() {
    # jack_lsp >/dev/null
    # INITIAL_DEFAULT_SINK="$(get_default sink playback)"
    # INITIAL_DEFAULT_SOURCE="$(get_default source capture)"
    # echo "$INITIAL_DEFAULT_SINK"
    # echo "$INITIAL_DEFAULT_SOURCE"
    :
}

virtual_sinks() {
    echo "Virtual sinks are defined system-wide."
    # Sink, Source/Virtual, Duplex
    #add_sink2 Sink           Listen
    #add_sink2 Sink           People
    #add_sink2 Sink           Loop
    #add_sink2 Source/Virtual Speak
    jack_connect  "Loop:monitor_FL"  "Speak:input_FL"
    jack_connect  "Loop:monitor_FR"  "Speak:input_FR"
    :
}


carla_filter_output() {
    #echo "Output must be equalized."
    local last_carla
    run_wait_carla "${1:?Undefined profile.}" || return
    for sink in  Listen  People  Loop; do
        jack_connect  "$sink:monitor_FL"  "$last_carla:audio-in1"
        jack_connect  "$sink:monitor_FR"  "$last_carla:audio-in2"
    done
    jack_connect  "$last_carla:audio-out1"  "$CARD_SINK:playback_FL"
    jack_connect  "$last_carla:audio-out2"  "$CARD_SINK:playback_FR"
}

carla_filter_input() {
    #echo "Input must be equalized."
    local last_carla
    run_wait_carla "${1:?Undefined profile.}" || return
    jack_connect  "$CARD_SOURCE:capture_MONO"  "$last_carla:audio-in1"
    jack_connect  "$last_carla:audio-out1"  "Speak:input_FL"
    jack_connect  "$last_carla:audio-out1"  "Speak:input_FR"
}


calf_filter_output() {
    local client='FilterEars'
    local chain_first  chain_last
    run_wait calfjackhost --client "$client" "${@:?Undefined parameters.}" || return
    calf_rack_chain  "$client"  "Listen:monitor"  "$CARD_SINK:playback"  2 2
    for sink in  People  Loop; do
        jack_link_prefixes  <(jack_lsp "$sink:monitor")  <(jack_lsp "$chain_first")
    done
    pw_set_default sink  listen
}

calf_filter_input() {
    if ((mic)); then
        local client='FilterVoice'
        local chain_first  chain_last
        run_wait calfjackhost --client "$client" "${@:?Undefined parameters.}" || return
        calf_rack_chain  "$client"  "$CARD_SOURCE:capture"  "Speak:input"  1 2
    else
        jack_link_prefixes  <(jack_lsp "$CARD_SOURCE:capture")  <(jack_lsp "Speak:input")
    fi
    pw_set_default source  speak
}


echo "Directory: $PWD"
echo "Profile: $1"
mic=1
name="$1"
[[ "$name" == *_nomic* ]] && { mic=0; name="${name//_nomic/}"; }
config="config_$name.sh"
if [[ ! -f "$config" ]]; then
    echo "$config does not exists!"
    exit 1
fi

mapfile -t otherd < <(
    systemctl --user list-units --legend=no --state=running \
    | grep -Eio "[^ ]+$name[^ ]*\.service"
)
printf '[%s]\n' "${otherd[@]}"
systemctl --user stop "${otherd[@]}"

#now
test_default
prepare
virtual_sinks
#now
source "$config"
prepare_end
