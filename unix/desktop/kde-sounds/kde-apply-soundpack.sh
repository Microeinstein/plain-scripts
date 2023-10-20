#!/bin/bash


_log() {
    echo -n "$*"$'\e[0m\n'
} >&2

_errlog() {
    _log $'\e[31mError: '"$*."
}


if [[ "$0" == "$BASH_SOURCE" ]]; then
    _errlog "script must be sourced"
    exit 1
fi


DEFAULTS='/usr/share/knotifications5/'
CUSTOMS="$HOME/.config/"

# See with command:  grep '^\[' /usr/share/knotifications5/*
#
# [CATEGORIES]
#    plasma_workspace         : standard + trash
#    ksmserver                : lockscreen
#    kwin                     : compositor
#    kaccess                  : accessibility
#    policykit1-kde           : auth
#    devicenotifications      : new device connected (only)?
#    bluedevil                : bluetooth
#    powerdevil               : battery
#    networkmanagement        : connections
#    freespacenotifier        : ...
#    kdeconnect               : phone
#    ksysguard                : sensors
#    spectacle                : screenshot
#    wacomtablet              : tablet {,dis}connect
#    kdg-desktop-portal-kde   : screencast
#    
#    kcm_touchpad             : touchpad
#    printmanager             : printer
#    diskmonitor              : SMART
#    konsole                  : tty activity
#    kwalletd5                : password
#    
#    proxyscout
#    kwrited
#    phonon
#    konversation
#    kdenlive
#    kteatime
#    kruler
#    gdrive
#    rsibreak



read_custom_sound() {
    local com=(
        --file  "${CUSTOMS}${1:?Missing category.}.notifyrc"
        --group "Event/${2:?Missing event.}"
        --key   'Sound'
    )
    kreadconfig5 "${com[@]}"
}

read_default_sound() {
    local com=(
        --file  "${DEFAULTS}${1:?Missing category.}.notifyrc"
        --group "Event/${2:?Missing event.}"
        --key   'Sound'
    )
    kreadconfig5 "${com[@]}"
}

use_sound() {
    local com=(
        --file  "${CUSTOMS}${1:?Missing category.}.notifyrc"
        --group "Event/${2:?Missing event.}"
    )
    local path="${3:?Missing path.}"
    
    local curr="$(kreadconfig5 "${com[@]}"  --key 'Action')"
    curr="${curr//Sound|/}"
    curr="${curr//|Sound/}"
    curr="${curr//Sound/}"
    if [[ -z "$curr" ]]; then
        curr="Sound"
    else
        curr="Sound|$curr"
    fi
    kwriteconfig5 "${com[@]}"  --key 'Action'  "$curr"
    kwriteconfig5 "${com[@]}"  --key 'Sound'  "$path"
}

reset_sound() {
    local com=(
        --file  "${CUSTOMS}${1:?Missing category.}.notifyrc"
        --group "Event/${2:?Missing event.}"
    )
    
    local curr="$(kreadconfig5 "${com[@]}"  --key 'Action')"
    curr="${curr//Sound|/}"
    curr="${curr//|Sound/}"
    curr="${curr//Sound/}"
    if [[ -z "$curr" ]]; then
        kwriteconfig5 "${com[@]}"  --key 'Action'  --delete
    else
        kwriteconfig5 "${com[@]}"  --key 'Action'  "$curr"
    fi
    kwriteconfig5 "${com[@]}"  --key 'Sound'  --delete
}


set_profile() {
    local category="${1:?Missing category name.}"
    local -n arr=sounds
    
    echo "[$1]"
    # convert in absolute paths and check existence
    [[ "$FROM" == /* ]] || FROM="$PWD/$FROM"
    for k in "${!arr[@]}"; do
        local -n v="arr[$k]"
        v="$(realpath -ms "$FROM/$v")"
        printf '%24s : %s\n'  "$k"  "$v"
        if [[ ! -f "$v" ]]; then
            echo "Unable to find file! Aborting..."
            echo
            return 1
        fi
    done
    
    # apply
    for k in "${!arr[@]}"; do
        local -n v="arr[$k]"
        use_sound "$1" "$k" "$v"
    done
    echo
}


profile_win7_android() {
    local FROM
    local -A sounds
    
    
    FROM="Win7/Media"
    
    sounds=(
            [Trash: emptied]='Windows Recycle.wav'
                  [startkde]='Windows Logon Sound.wav'
                   [exitkde]='Windows Logoff Sound.wav'
                      [beep]='Windows Ding.wav'
              [notification]='Windows Error.wav'
                   [warning]='Windows Exclamation.wav'
                [fatalerror]='Windows Critical Stop.wav'
          [applicationcrash]='Windows Critical Stop.wav'
        [messageInformation]='Windows Error.wav'
        [messageboxQuestion]='Windows Exclamation.wav'
            [messageWarning]='Windows Exclamation.wav'
           [messageCritical]='Windows Critical Stop.wav'
    #                   [catastrophe]='Windows .wav'
    #      [Textcompletion: rotation]='Windows .wav'
    #      [Textcompletion: no match]='Windows .wav'
    # [Textcompletion: partial match]='Windows .wav'
    #                  [cancellogout]='Windows .wav'
    #                    [printerror]='Windows .wav'
    #    [plasmoidInstallationFailed]='Windows .wav'
    #               [plasmoidDeleted]='Windows .wav'
    )
    set_profile plasma_workspace


    sounds=( [authenticate]='Windows User Account Control.wav' )
    set_profile policykit1-kde


    sounds=( [safelyRemovable]='Windows Hardware Remove.wav' )
    set_profile devicenotifications

    
    sounds=(
                  [lowbattery]='Windows Battery Low.wav'
             [criticalbattery]='Windows Battery Critical.wav'
                 [fullbattery]='Windows Print complete.wav'
        [lowperipheralbattery]='Windows Battery Low.wav'
                   [pluggedin]='Windows Hardware Insert.wav'
                   [unplugged]='Windows Hardware Remove.wav'
    )
    set_profile powerdevil

    
    sounds=(
                  [Authorize]='Windows User Account Control.wav'
        [RequestConfirmation]='Windows User Account Control.wav'
                 [RequestPin]='Windows User Account Control.wav'
           [ConnectionFailed]='Windows Hardware Fail.wav'
              [SetupFinished]='Windows Hardware Insert.wav'
    )
    set_profile bluedevil

    
    sounds=(
        [pairingRequest]='Windows User Account Control.wav'
            [batteryLow]='Windows Battery Low.wav'
          [pingReceived]='Windows Default.wav'
          [notification]='Windows Notify.wav'
    )
    set_profile kdeconnect
    

    FROM="Android_UI"

    sounds=(
          [locked]='Lock.ogg'
        [unlocked]='Unlock.ogg'
    )
    set_profile ksmserver
}


