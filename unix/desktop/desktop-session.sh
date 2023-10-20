#!/bin/bash

export PATH="$HOME/.local/bin:$PATH"

svc() {
	echo "svc $*" >&2
	systemctl --user restart "$@"
	sleep .1
}

run() {
    #local desk
    #desk="$(\grep -ilE '^name=.*\b'"$1"'\b.*' "$HOME/.local/share/applications/"*.desktop | head -n1)"
    #if [[ "$desk" ]]; then
    #    local runpath="$(\grep -ihE '^exec='
    #fi
	echo "run $*" >&2
	"$@" &
	disown
	sleep .1
}

set_brightness() {
	# set write permissions through udev rules
	local SYS="/sys/class/backlight"
	local BL
	mapfile -t BL < <(find "$SYS" -mindepth 1 -maxdepth 1)
	local -n dev=BL[0]
	local max="$(cat "$dev/max_brightness")"
	local to="$1"
	((to = to * max / 100))
	echo "$to" > "$dev/brightness"
}


all_desktops() {
#	svc no-middle-mouse-paste
#	svc simple@battery-monitor
#	svc simple@backlight-autotune
#	svc simple@vsync-reapply
	:
}


plasma() {
	run krunner -d
	run easystroke
	run keepassxc
	run audacious
	run telegram-desktop -startintray -noupdate
	run discord --start-minimized
	run obsidian --no-sandbox "obsidian:///mnt/files/Documenti/Org/Journal"
#	run /opt/freefilesync/RealTimeSync '/mnt/files/Documenti/FreeFileSync/sd-sync.ffs_real'

	svc pw-profile@SADES_SA903_nomic
#	svc presence-sorter
#	ksuperkey -t 0
	:
}


systemctl --user is-active default.target  # systemd fix
sleep 3

# sudo tee /proc/acpi/call <<<'\_SB.PCI0.RP05.PXSX._OFF'

set_brightness 60

xsetroot -cursor_name left_ptr             # cursor theme fix
setxkbmap -option compose:lctrl-altgr
if [[ -f /etc/Xmodmap ]]; then xmodmap /etc/Xmodmap; fi
if [[ -f ~/.Xmodmap ]]; then xmodmap ~/.Xmodmap; fi

all_desktops
case "$DESKTOP_SESSION" in
    plasma*) plasma;;
esac

exit 0
