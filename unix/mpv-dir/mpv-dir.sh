#!/bin/bash

case "$1" in
    name) s="v"  ;;
    date) s="tr" ;;
    *)    s=""   ;;
esac

cd "$2"
IFS=$'\n' pl=($(ls --color=never -1"$s"R))
mpv --player-operation-mode=pseudo-gui "${pl[@]}"

