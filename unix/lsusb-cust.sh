#!/bin/bash

# Elenca dispositivi usb decentemente
{
    printf '\e[0m'
    while read -r device; do
        if [[ ! -e "$device/product" ]]; then
            continue;
        fi
        printf '%s|'  \
            "$device" \
            "$(cat "$device/idVendor"):$(cat "$device/idProduct")" \
            "$(cat "$device/product")" \
            "$(cat "$device/manufacturer")"
        echo
    done
} < <(find "/sys/bus/usb/devices/" -type l | sort) \
  | column -t -s'|' -N $'\e[1;4mPath,vend:prod,Product,Manufacturer'

# Disattiva driver
#echo '1-2.3.4...' > /sys/bus/usb/drivers/usb/unbind

# Riattiva driver
#echo '1-2.3.4...' > /sys/bus/usb/drivers/usb/bind
