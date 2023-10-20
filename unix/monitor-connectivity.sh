#!/bin/bash

# packages required: NetworkManager, dbus

monitor_connectivity() {
    dbus-monitor --system 2>/dev/null | \
    grep -A 1 --line-buffered '"Connectivity"' | \
    while {
        for ((i=0; i<11; i++)); do
            read -r line
        done
    }
    do
        msg="unknown"
        if [[ "$line" =~ [0-9]+$ ]]; then
            msg="connected"
            (( $BASH_REMATCH <= 1 )) && msg="dis"$msg
        fi
        echo "$msg"
        read -r garbage
    done
}

echo Try connecting to some networks and disconnecting from everything.
monitor_connectivity
