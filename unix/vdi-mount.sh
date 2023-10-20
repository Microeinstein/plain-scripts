#!/bin/bash

vdi="${1:?Missing VDI file}"; shift
mount="$1"


magic="$(head -n 1 "$vdi")"
case "$magic" in
    "<<< innotek VirtualBox Disk Image >>>")   ;;
    "<<< Sun VirtualBox Disk Image >>>")       ;;
    "<<< Oracle VM VirtualBox Disk Image >>>") ;;
    *) echo >&2 "$vdi: Bad magic, this is not a VDI image."
       exit 1
esac

offData="$(vboxmanage internalcommands dumphdinfo "$vdi" | grep -o -E "offData=.+$")"
eval "$offData"
#((offData+=32256))
echo "$offData"

losetup -o "$offData" -Pf "$vdi"
