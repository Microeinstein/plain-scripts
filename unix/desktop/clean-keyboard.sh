#!/bin/bash

# this script can be sourced from .bashrc, from outer scripts as library, and yet be executable

# is interactive shell? (imply sourced)
if [[ $- == *i* ]]; then
    # set wrappers (exports) to run this file as
    for exp in clean-keyboard; do
        eval "$exp() ( exec -a ${exp@Q} ${BASH_SOURCE@Q} \"\$@\" )"
    done
    return
fi


clean-keyboard() {
    #local kid="$(xinput list --short | sed -nE '/translated/Ibi; d; :i s/.*\bid=([0-9]+)\b.*/\1/g; p')"
    local devnames=() devids=()
    mapfile -t devnames < <(xinput list --name-only | grep -iE '\bat\b|\btouchpad\b')
    mapfile -t devids < <(for n in "${devnames[@]}"; do xinput list --id-only "$n"; done)
    echo "Devices:"
    for i in "${!devnames[@]}"; do
        printf '  %2d: %s\n'  "${devids[$i]}"  "${devnames[$i]}"
        xinput disable "${devids[$i]}"
    done
    
    local sec="${1:-20}"
    for s in $(seq 1 $sec); do
        sleep 1
        printf '\n\e[A\e[2K%02d/%02d' "$s" "$sec"
    done
    echo
    
    for i in "${!devnames[@]}"; do
        xinput enable "${devids[$i]}"
    done
}


return &>/dev/null  # do not run when sourced
set -euo pipefail
"$(basename "${0%.*sh}")" "$@"
