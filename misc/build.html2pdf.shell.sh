#!/bin/bash


clear_stdin() {
    local discard
    while read -r -t .1 -n 10000 discard; do :; done
    # echo cleared
    return 0
}


SLIDES="slides"
OUT="output.pdf"


convert_monitor() {
    while clear_stdin; read -r evt; do
        echo "[$evt]"
        if chromium --headless  --disable-gpu --print-to-pdf template.html &>/dev/null; then
            echo "PDF ok."
        else
            echo "PDF fail."
        fi
    done < <(
        inotifywait -m -e modify -r --include '.*\.(html|css|js)$' .
    )
}


input_loop() {
    sleep 1
    cat <<EOF

Keyboard:
- B    bake slides
- Z    create ZIP of slides
- O    open PDF
- S    make backup
- R    reload script
- Q    quit

EOF
    local cmd
    while read -n1 -r -p '> ' cmd; do
        if [[ -z "$cmd" ]]; then
            echo -n $'\e[F\e[K'
            continue
        fi
        cmd="${cmd,,}"
        echo
        case "$cmd" in
            b) mkdir -p "$SLIDES";  pdftoppm -png -r 95.95  "$OUT" "$SLIDES"/slide ;;
            z) zip -j "$SLIDES/$(basename "$PWD")" "$SLIDES"/*.png ;;
            o) xdg-open "$OUT" ;;
            r) clear;  exec "$0" ;;
            s) zip -r  project  .  -x .\* "$SLIDES/*" \*.zip ;;
            q) exit ;;
            *) echo "unknown command"; continue ;;
        esac
        local err=$?
        ((err)) && echo "[error $err]" || echo "[ok]"
    done
}


convert_monitor &
input_loop
