#!/bin/bash

#echo 'Arguments:'
#printf '> %s\n' "$@"
#echo

SELF="$(basename "${BASH_SOURCE[0]}")"

if ! (($#)) || [[ "$*" == *"--help"* ]]; then
    lsusb
    echo
    virsh list
    echo "Usage: (sudo) $SELF  <USB Vendor> <USB Product>  <VM domain>"
    exit 0
fi

ensure-root() {
    # pass launch arguments to this function and check for $0
    (($(id -u))) || return 0
    exec sudo bash "$(realpath "${BASH_SOURCE[0]}")" "$@"
}
ensure-root "$@"

# set -x

vend="${1:?Missing vendor hex (ex: 12CD).}"; shift
prod="${1:?Missing product hex (ex: 12CD).}"; shift
vmdom="${1:?Missing VM domain (id)}"; shift

devspec="/tmp/vmusb_device_${vend}_${prod}_${vmdom}.xml"

if ! [[ -f "$devspec" ]]; then
    cat <<EOF > "$devspec"
<hostdev mode="subsystem" type="usb" managed="yes">
    <source>
        <vendor id="0x$vend"/>
        <product id="0x$prod"/>
    </source>
</hostdev>
EOF
    virsh attach-device "$vmdom" "$devspec"
else
    virsh detach-device "$vmdom" "$devspec"
    rm "$device"
fi
