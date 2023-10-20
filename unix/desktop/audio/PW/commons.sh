#!/bin/bash

shopt -u expand_aliases  # disable for subshell `source` testing
set -o pipefail

_REQUIRED=(pactl  pw-cli  pw-metadata  jack_lsp  carla)


# -------------------- Utils

printlns() { printf '%s\n' "$@"; }
repeatn()  { yes "${@:2}" | head -n"$1"; }

# execute in a subshell
noreturn() { "$@"; exit; }
assert()   {
    "${@:2}" && return
    local e=$?
    echo "Error: $1"
    exit $e
}

bruteforce() (
    local msg err
    while true; do 
        msg="$(command "$@" 2>&1)"
        err=$?
        [[ "$msg" != *'failed'* ]] && break
        sleep .2
    done
    [[ "$msg" ]] && echo "$msg"
    return $err
)

run() (
    #command ...
    stdbuf -oL -eL "${@:?Undefined program.}" 2>&1 &
    disown
)

run_wait() (
    unset line
    # no timeout on first line
    while if [[ -v line ]]; then read -t .5 -r line; else read -r line; fi; do
        echo "$line"
    done < <(run "$@")
)

_check_required() {
    local miss=()
    for cmd in "${_REQUIRED[@]}"; do
        command -v "$cmd" &>/dev/null || miss+=("$cmd")
    done
    if ((${#miss[@]})); then
        echo "Missing tools:  ${miss[*]}"
    fi
} >&2
_check_required


# -------------------- PulseAudio

pa_add_sink() {
    local args=(
        load-module
        module-null-sink
        object.linger=1
        media.class="Audio/${1:?Undefined class.}"
        sink_name="${2:?Undefined name.}"
        channel_map=stereo
        monitor.channel-volumes=true
    )
    pactl "${args[@]}"
}

pa_del_sink() {
    local sid="$(pactl list short modules | grep sink_name="${1:?Undefined name.}" | cut -f 1)"
    pactl unload-module "$sid"
}

pa_del_all() {
    pactl unload-module module-null-sink
}

pa_set_default() {
    pactl set-default-${1,,:?Undefined type. (sink/source)} "${2:?Undefined name.}"
}


# -------------------- Jack

jack_lsp() { bruteforce jack_lsp "$@"; }
jack_connect() { bruteforce jack_connect "$@"; }

jack_grep_client() {
    jack_lsp | grep -i "${1:?Undefined client.}" | cut -d: -f1 | sort | uniq
}

jack_get_last_client() {
    # jack_lsp Carla | cut -d: -f1 | uniq | tail -n1
    #   is not effective to retrieve latest client
    declare -A _JACK_FILT_MEM
    local client="${1:?Undefined client.}"
    local lsp="$(jack_grep_client "$client")"
    echo "$(comm -13 <(echo "${_JACK_FILT_MEM["$client"]}") <(echo "$lsp"))"
    _JACK_FILT_MEM["$client"]="$lsp"
}

jack_count_channels() {
    tr '_-' ' ' | rev | uniq -c -f1 | tr -s ' ' | cut -d ' ' -f2
}

jack_channel_prefix() {
    tr '_-' ' ' | rev | tr -s ' ' | cut -d ' ' -f2- | rev | uniq
}

jack_link_prefixes() {
    local src=() dest=()
    mapfile -t src  < "${1:?Undefined source.}";  shift
    mapfile -t dest < "${1:?Undefined sink.}";    shift
    local na=${#src[@]}  nb=${#dest[@]}
    
    while IFS=$'\t' read -r a b; do
        jack_connect "$a" "$b"
    done < <(
        ((na==1))  && noreturn paste <(repeatn $nb "${src[0]}") <(printlns "${dest[@]}")
        ((nb==1))  && noreturn paste <(printlns "${src[@]}")    <(repeatn $na "${dest[0]}")
        ((na==nb)) && noreturn paste <(printlns "${src[@]}")    <(printlns "${dest[@]}")
        echo "Unsupported link operation: $na..$nb channels." >&2
        exit 2
    )
}


# -------------------- PipeWire

pw_get_default() {
    # actually it does not find just cards
    # alternative: pw-metadata
    local kind="${1:?Undefined kind. (sink/source)}"
    # playback capture ...
    local port="$2"
    local def="$(pactl info | grep -i "default $kind" | cut -d' ' -f3- | cut -d. -f 2-3)"
    local sid="$(pactl list short cards | grep "$def" | cut -f1)"
    local rule='/^\*?\s*alsa\.card_name = "(.+)"/!d;s//\1/g;p'
    local common="$(pw-cli info "$sid" | sed -En "$rule")"
    jack_lsp "$common" "$port" | cut -d: -f1 | sort | uniq
}

pw_add_sink() {
    local cls="${1:?Undefined class. (Sink | Source/Virtual)}"
    local name="${2:?Undefined name.}"
    local args=(
        create-node
        adapter {
            factory.name=support.null-audio-sink
            node.name="$name"
            node.description="${3:-${name^}}"
            media.class="Audio/$cls"
            object.linger=1
            audio.position=[FL,FR]
            monitor.channel-volumes=true
        }
    )
    printf '%s\n' "${args[@]}"
    pw-cli "${args[@]}"
}

pw_del_sink() {
    while read -r sid; do
        pw-cli destroy "$sid"
    done < <(pw-dump -N \
        | jq -Mc ".[] | select(.info.props[\"node.name\"] == \"${1:?Undefined name.}\") | .id"
    )
}

pw_set_default() {
    pw-metadata 0 \
        default.configured.audio.${1,,:?Undefined type. (sink/source)} \
        "{ \"name\": \"${2:?Undefined name.}\" }"
}


# -------------------- Carla

#carlaid() {
#    pw-cli dump short node | grep -i carla | tail -n1 | cut -d: -f1
#}

run_wait_carla() {
    local config="${1:?Undefined config.}"
    echo "> launching with '$config'"
    while read -r line; do
        # echo "$line"
        #if [[ ! "$line" =~ Carla\ .*?\ started ]]; then
        if [[ ! "$line" =~ libjack ]]; then
            continue
        fi
        sleep 1
        echo "> started"  # at $(now)
        last_carla="$(jack_get_last_client carla)"
        return 0
    done < <(run carla "$config")
    return 1
}


# -------------------- Calf

calf_rack_chain() {
    local client="${1:?Undefined client name.}";         shift
    local prefix_in="${1:?Undefined external input.}";   shift
    local prefix_out="${1:?Undefined external output.}"; shift
    local num_in="${1:?Undefined input channels.}";      shift
    local num_out="${1:?Undefined output channels.}";    shift
    
    while IFS=$'\t' read -r src dest; do
        #[[ "$src"  == : ]] && echo "[$dest]" && continue
        #[[ "$dest" == : ]] && echo "[$src]"  && continue
        [[ ! "$chain_first" ]] && chain_first="$dest"
        chain_last="$src"
        local nout="$num_in"
        [[ "$dest" == "$prefix_out" ]] && nout="$num_out"
        echo "[chain] ${num_in}x $src  -->  ${nout}x $dest"
        jack_link_prefixes     \
            <(jack_lsp "$src" | head -n "$num_in") \
            <(jack_lsp "$dest" | head -n "$nout")
    done < <( paste <(
        #printlns "virtual:monitor_"{FL,FR}
        echo "$prefix_in"
        jack_lsp | assert "no results!" grep -iE "^$client:.* out #[0-9]+\$" | jack_channel_prefix
    ) <(
        jack_lsp | assert "no results!" grep -iE "^$client:.* in #[0-9]+\$"  | jack_channel_prefix
        echo "$prefix_out"
        #printlns "card:out_"{FL,FR}
    ) )
}


# -------------------- Other

prepare() {
    # Workaround: disable autoconnect on edit
    pw_add_sink    Sink preparing Preparing...
    pw_set_default sink preparing Preparing...
}

prepare_end() {
    pw_del_sink preparing
}
