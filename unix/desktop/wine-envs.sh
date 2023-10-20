#!/bin/bash

set -u +H -x #-e

declare -n R=BASH_REMATCH


save_bool() {
    # inverts return code (use `((var))` to reevaluate after)
    (($?))
    local ret=$?
    local -n v="${1:?Missing variable.}"
    v="$ret"
}
_join() {
    local IFS="$1"; shift
    echo "$*"
}
join() {
    local vn="$1"
    local -n var="$1"; shift
    export var="$(_join "$@")"
    echo "$vn=${var@Q}"
    #unset 'p[@]'
}
prepend() {
    local -n arr="$1"; shift
    arr=("$@" "${arr[@]}")
}
map_append() {
    local -n arr="$1"; shift
    mapfile -t  -O "${#arr[@]}" "$@" arr
}
envs_from_dllovr() {
    [[ -v WINEDLLOVERRIDES ]] || return 0
    local old="$WINEDLLOVERRIDES"
    local new=()
    local cfg
    while read -d';' -r cfg; do
        if [[ "$cfg" =~ ^_ENV_([a-zA-Z0-9]+)=(.*)$ ]]; then
            declare -g "${R[1]}"="${R[2]}"
        else
            new+=("$cfg")
        fi
    done <<<"$old;"
    local IFS=';'
    WINEDLLOVERRIDES="${new[*]}"
}

# windir="${WINEPREFIX:-$HOME/.wine}/drive_c/windows"
RUN=("$@")
[[ "$PWD" == */Giochi/* ]]; save_bool hacks
envs_from_dllovr


if ((hacks)); then
    local_n=()
    foreign=()
    foreign_n=()
    
    
    # find local dlls and override-native them in wine
    map_append local_n  < <(find -L "$PWD" -maxdepth 1 -type f -iname '*.dll')
    [[ -d "$PWD/scripts" ]] && \
    map_append local_n  < <(find -L "$PWD/scripts"     -type f -iname '*.asi')
    (("${#local_n[@]}")) && \
    mapfile -t local_n  < <(basename -a -- "${local_n[@]}")
    echo '--local--'
    printf '[%s]\n' "${local_n[@]}"


    local_filt=( "$(IFS='|'; echo "${local_n[*]//\./\\\.}")" )
    if [[ "$local_filt" ]]; then
        local_filt=( grep -viE "$local_filt" )
    else
        local_filt=( cat )
    fi


    # find foreign dlls and override-native them in wine, except for local ones
    foreign_d=( /mnt/files/Programmi/Other/dgVoodoo2/{MS,3Dfx}/x86 )
    for d in "${foreign_d[@]}"; do
        map_append foreign  < <(
            find -L "$d" -maxdepth 1 -type f -iname '*.dll' | "${local_filt[@]}"
        )
    done
    ! (("${#foreign[@]}")); has_foreign=$?
    ((has_foreign)) && \
    map_append foreign_n  < <(basename -a -- "${foreign[@]}")  # -s .dll
    echo '--foreign--'
    printf '[%s]\n' "${foreign_n[@]}"


    ovr="$(_join , "${foreign_n[@]}" "${local_n[@]}")"
fi


join WINEDEBUG          ,  err+all  {warn,info}+module  fixme-all  # use q4wine console mode
#join WINEDLLPATH        :  "${foreign_d[@]}"                      # only works for BUILTIN dlls
#join WINEPATH          \;  "${foreign_d[@]}"
((hacks)) && [[ "$ovr" ]] && \
join WINEDLLOVERRIDES  \;  "${WINEDLLOVERRIDES:-}"  "$ovr=n"       # native  builtin  ''disabled
#join DXVK_HUD           ,  fps  opacity=0.3

#join LIBGL_DRIVERS_PATH :  /opt/mesa-20.1.4/lib{32,}/dri
#join LD_LIBRARY_PATH    :  /opt/mesa-20.1.4/lib{32,}
join __LIBGL_DEBUG      ,  verbose


run() {
    "${RUN[@]}"
    #read -N1 -s -r dummy
}

nvidia() {
    local a=(
        VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json
        # no prime
        #__NV_PRIME_RENDER_OFFLOAD=1
        #__VK_LAYER_NV_optimus=NVIDIA_only
        #__GLX_VENDOR_LIBRARY_NAME=nvidia
    )
    [[ -v a ]] && export "${a[@]}"
    "$@"
}

hack_dlls() {
    ln -vs -t "$PWD" -- "${foreign[@]}"  # no override
    
    #set +e
    "$@"
    local err=$?
    #set -e
    
    cd "$PWD"
    rm -v -- "${foreign_n[@]}"
    return $err
}

gamma() {
    # save old gamma values and restore them after execution
    read -r _ _ red _ green _ blue < <(xgamma |& tr -d ',')

    xgamma -gamma 0.9
    "$@"
    xgamma -rgamma $red  -ggamma $green  -bgamma $blue
}


chain=(nvidia run)
((hacks && has_foreign)) && prepend chain hack_dlls
[[ -v GAMMA ]]           && prepend chain gamma
"${chain[@]}"
