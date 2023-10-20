#!/bin/bash

activewnd() {
    sleep "${1:-2}"
    xdotool getactivewindow | tee /dev/stderr
}

main() {
    local opts=(
        --clearmodifiers
        --window "${1:?Missing window id.}"
    )

    while IFS= read -r line; do
        # echo "$line"
        xdotool type "${opts[@]}" --delay 0 "$line"
        xdotool key "${opts[@]}" Return
    done < <(sed 's/\t/  /g' "${2:?Missing filename.}")
}

main "$@"
