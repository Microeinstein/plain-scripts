#!/bin/bash

# Command Line mediA Playlist
#
#       Author:  Microeinstein
#      License:  MIT
# Requirements:  dialog  mpv
# Optional Rq.:  youtube-dl  wget  hq
#    Arguments:  none


declare MENULEN LABELS=() ARGS=() EXTRARGS=() IGNORE=()
declare NEXT OUT LABEL
declare DEFITEM DIALOGCUSTOM=()
declare NEXTRA=() LEXTRA
declare STACKMENU=("quit c") STACKCHOICE=(-)
progpath="$(realpath "${BASH_SOURCE[0]}")"
shopt -s extglob


# common functions
print() {
    printf '%b\n' "$@"
}
pauseFancy() {
    printf '%b' '\e[93m[continue]\e[0m'
    read -r -s -N 1 "$@"
    printf '\e[G\e[2K'
}
debug() {
    printf '[%s]\n' "$@"
    pauseFancy -t 1
}


# dialog functions
clearOptions() {
    MENULEN=0
    LABELS=()
    ARGS=()
    EXTRARGS=()
    IGNORE=()
    DIALOGCUSTOM=()
    NEXTRA=()
    LEXTRA=""
}
pushArgs() {
    local enc=""
    if (($# > 0)); then
        enc=$(base64 <<< "${@@Q}") # quote every argument and merge them
    fi
    ARGS+=("$enc")
}
pushExtraArgs() {
    local enc=""
    if (($# > 0)); then
        enc=$(base64 <<< "${@@Q}") # quote every argument and merge them
    fi
    EXTRARGS+=("$enc")
}
pushLabel() {
    local IFS=' '
    LABELS+=("$*")
}
assignEntry() { # <label>
    ((MENULEN++))
    pushLabel "$1"
    IGNORE+=(0)
}
addEntry() { # <label> [arg1] [arg2] ...
    assignEntry "$1"
    shift
    pushArgs "$@"
}
addSeparator() {
    addEntry ""
    IGNORE[-1]=1
}
addLabel() {
    addEntry "${1:?Missing label text.}"
    IGNORE[-1]=1
}
setCancelLabel() { # <label>
    DIALOGCUSTOM+=(
        --cancel-label "${*:?Missing label.}"
    )
}
setExtraButton() { # <label> [nextra arg1] ...
    DIALOGCUSTOM+=(
        --extra-button
        --extra-label "${1:?Missing label.}"
    )
    shift
    NEXTRA=("$@")
}
dialogInfo() { # <text> [dialog options...]
    local text="${1:?Missing info text.}"
    shift
    if [[ "${text: -1}" != $'\n' ]]; then
        text+=$'\n'
    fi
    if ! command -v dialog; then
        echo "$text"
        return
    fi
    local width height
    IFS=' ' read -r height width <<< "$(wc -l -L <<< "$text")"
    dialog \
        --backtitle 'clap.sh' \
        --colors \
        --infobox "$text" $((height+1)) $((width+4)) \
        "$@"
}
dialogMenu() { # <desc> <next> [dialog options...]
    local desc="${1:?Missing description.}"
    local oldnext="$NEXT"
    NEXT="${2:?Missing next cmd.}"
    shift 2
    local i menuargs=()
    for ((i=0; i<MENULEN; i++)); do
        local txt="${LABELS[$i]}"
        local pre="${txt//*(\\Z?)}" # remove dialog color escapes
        #debug "$txt" "$pre"
        pre="${pre:0:1}"
        [[ "$pre" == "" ]] && pre="_"
        menuargs+=("${pre}$((i+1))" "$txt")
    done
    OUT=$(dialog \
        --backtitle 'clap.sh' \
        --scrollbar \
        --colors \
        ${DEFITEM:+--default-item "$DEFITEM"} \
        "${DIALOGCUSTOM[@]}" \
        "$@" \
        --menu "$desc" 0 0 0 \
        "${menuargs[@]}" \
        3>&2 2>&1 1>&3
    )
    local err=$?
    DEFITEM=""
    i="${OUT:1}"
    ((i--))
    [[ "$OUT" == "" ]] && err=1
    # debug "$i" "$nextargs"
    case "$err" in
        0|3)
            if ((IGNORE[i])); then        #separator
                NEXT="$oldnext"
                DEFITEM="$OUT"
            else                          #selection
                STACKMENU+=("$oldnext")
                STACKCHOICE+=("$OUT")
                if ((err == 0)); then
                    LABEL="${LABELS[$i]//*(\\Z?)}"
                    NEXT="${NEXT} $(base64 -d <<< "${ARGS[$i]}")"
                else                      #extra selection
                    LABEL="${LEXTRA:-${LABELS[$i]//*(\\Z?)}}"
                    NEXT="${NEXTRA:-$NEXT} $(base64 -d <<< "${EXTRARGS[$i]:-${ARGS[$i]}}")"
                    err=0
                fi
            fi
            ;;
    esac
    clearOptions
    return $err
}
require() {
    local notfound=()
    for pkg in "$@"; do
        if ! command -v "$pkg" &>/dev/null; then
            notfound+=("$pkg")
        fi
    done
    if ((${#notfound[@]} > 0)); then
        local msg="Unable to find these required executables:"
        local wait=0
        for missing in "${notfound[@]}"; do
            msg+=$'\n'" - $missing"
            ((wait++))
        done
        dialogInfo "$msg"
        sleep "$wait.7"
        return 1
    fi
    return 0
}


# mpv functions
mpvInstructions() {
    echo
    printf '  %b : %b\n' \
        "Space p"                     "Play/Pause" \
        "      m"                     "Mute" \
        "      i"                     "Info" \
        "      l"                     "A/B Loop ^(infinite)" \
        "Bkspace"                     "Reset speed" \
        "\e[4m[ ]\e[0m \e[4m{ }\e[0m" "-/+ Speed" \
        "\e[4m←_→\e[0m \e[4m↓_↑\e[0m" "-/+ Seek 5s 60s ^(1s 5s)" \
        "\e[4m/ *\e[0m \e[4m9 0\e[0m" "-/+ Volume" \
        "    \e[4m< >\e[0m"           "←/→ Playlist" \
        "  Enter"                     "  → Playlist"
    echo
}
# Arguments modes:
#  1. "- <mpvArgs...>"
#  2. "yta <videoID> [mpvArgs...]"
play() {
    clear
    print "\e[1mTitle: \e[36m$LABEL\e[0m"
    #debug "$@"
    local hint="$1" mpvargs=() mpvtarget
    shift
    case "$hint" in
        yta)
            local yturl="$1"
            shift
            mpvargs+=("--ytdl-format=bestaudio[ext=m4a]/best[ext=mp4]/best")
            mpvtarget="https://www.youtube.com/$yturl"
            ;;
        -)  ;;
        *)
            dialogInfo "Unknown hint: $hint"
            sleep 1.5
            return 1
            ;;
    esac
    if (($# > 0)); then
        mpvargs+=("$@")
    fi
    if [[ "$mpvtarget" != "" ]]; then
        mpvargs+=("$mpvtarget")
    fi
    #debug "${mpvargs[@]}"
    local last
    last="${mpvargs[@]: -1}"
    if [[ "$last" =~ ^http:\/\/ ]]; then
        print "\e[1;93mWarning: using HTTP\e[0m"
    fi
    mpvInstructions
    printf '%b' "(Please wait)\e[G"
    /usr/bin/mpv --hwdec=yes --volume=50 "${mpvargs[@]}" # 2>/dev/null
    local err=$?
    if (($err)); then
        pauseFancy
    fi
    return 1
}


# music for programming
mfp_error() {
    dialogInfo "Unable to fetch website content."
    sleep 1.7
    return 1
}
mfp() {
    if ! require hq wget; then return 1; fi
    dialogInfo "Fetching website content..."
    local page
    page=$(mktemp)
    if ! wget -q -O "$page" https://musicforprogramming.net/rss.xml &>/dev/null; then
        rm -f "$page"
        mfp_error
        return
    fi
    while IFS=$'\t' read -r title url; do
        addEntry "$title" "$url"
    done <<< "$(paste \
        <(hq -f "$page" 'item > title' text) \
        <(hq -f "$page" 'item > guid' text) \
        # | tac
    )"
    rm -f "$page"
    dialogMenu "musicforprogramming.net" 'play -' --no-tags
}
mfp_entry_old() {
    dialogInfo "Fetching website content..."
    local page
    page=$(mktemp)
    if ! wget -q -O "$page" \
        "https://musicforprogramming.net/${1:?Missing url part.}" \
        &>/dev/null; then
        mfp_error
        rm -f "$page"
        return
    fi
    local url
    url=$(hq -f "$page" '#player' attr src)
    NEXT="play - ${url@Q}"
    rm -f "$page"
}


# file explorer
localpath() {
    dialogInfo "Querying contents..."
    #debug "$1"
    #local hint="$1"
    local path="${1:?Missing path.}"
    shift 1
    #case "$hint" in
    #    p)
    #        label="$path" play - "$path" "$@"
    #        return # this call must not go in stackmenu
    #        ;;
    #    -)  ;;
    #    *)
    #        dialogInfo "Unknown hint: $hint"
    #        sleep 1.5
    #        return 1
    #        ;;
    #esac
    if [[ "$path" == "" ]]; then
        dialogInfo "Empty path."
        sleep 1.7
        return 1
    elif [[ -f "$path" ]]; then
        play - "$path"
        return # this call must not go in stackmenu
    elif ! [[ -e "$path" ]]; then
        dialogInfo "This path does not exists."
        sleep 1.7
        return 1
    elif ! [[ -d "$path" ]]; then
        dialogInfo "Unknown file type."
        sleep 1.7
        return 1
    fi
    addEntry "\Zb↑ Up" "$(realpath "${path}/..")"
    local type name
    while read -r line; do
        type=$(cut -d '/' -f 1 <<< "$line")
        name=$(cut -d '/' -f 2- <<< "$line")
        case "$type" in
            d) type=""    ;;
            f) type="\Z4" ;;
            *) type="\Z1" ;;
        esac
        addEntry "${type}${name}" "$(realpath "${path}/${name}")"
    done < <(
        find -O3 "$path" -nowarn -maxdepth 1 "$@" -printf '%y/%P\n' | \
        sort | tail -n+2
    )
    setCancelLabel  '← Back'
    setExtraButton  'Play' 'play -'
    dialogMenu "$path" 'localpath'
}


# menu
editscript() {
	"${EDITOR:-nano}" "$progpath"
	exec "$progpath"
	exit $?
	return 1
}
locallib() {
    # pushArgs      '/I_do_not_exists' -type d
    # pushExtraArgs '/I_do_not_exists'
    # assignEntry   "Edit me"
    pushArgs      '/mnt/files/Musica' -type d
    pushExtraArgs '/mnt/files/Musica'
    assignEntry   "Musica"
    setExtraButton 'Play' 'play - --shuffle'
    dialogMenu "Select your library" 'localpath'
}
radios() {
    addEntry "DnB / Trance"            radio_dnb_trance
    addEntry "Ambient / IDM"           radio_chill
    addEntry "Vaporwave / FutureFunk"  radio_vapor_ff
    addEntry "Various"                 radio_vary
    addSeparator
    addEntry "myNoise"                 radio_mynoise
    addEntry "m00_su"                  radio_m00_su
    addEntry "Anima Amoris"            radio_anima_amoris
    dialogMenu "Select radio" 'eval'
}
radio_dnb_trance() {
    addLabel "\Zb\Z3DnB:"
    addEntry "Different Drumz"     http://andromeda.shoutca.st:8031/stream
    addEntry "Bassdrive"           http://chi.bassdrive.co:80
    addEntry "Bassjunkees"         http://space.ducks.invasion.started.at.bassjunkees.com:8442
    addEntry "Sunshine Live"       http://sunshinelive.hoerradar.de/sunshinelive-dnb-mp3-hq
    addEntry "Uturn Radio"         http://listen.uturnradio.com:80/drum_and_bass
    addEntry "BrokenBeats"         http://brokenbeats.net:8000/radiosource
    addEntry "m00_su - DnB"        https://radio.m00.su:8000/drumandbass.mp3
    addEntry "Anima Amoris - DnB"  http://amoris.sknt.ru/dnb.mp3
    addSeparator
    addLabel "\Zb\Z3Trance:"
    addEntry "PlayTrance Uplifting"     http://s3.pprj.link:8000/playtrance-uplifting-high
    addEntry "PlayTrance Main"          https://streaming.playtrance.com/playtrance-main-high
    addEntry "PlayTrance Classics"      https://streaming.playtrance.com/playtrance-classics-high
    addEntry "PlayTrance Club"          https://streaming.playtrance.com/playtrance-club-high
    addEntry "Anima Amoris - Trance"    http://anima.sknt.ru/trance.mp3
    dialogMenu "Select stream" 'play -'
}
radio_chill() {
    addLabel "\Zb\Z3IDM:"
    addEntry "Another Music Project"       http://radio.anothermusicproject.com:8000/idm
    addEntry "m00_su - IDM"                https://radio.m00.su:8000/idm.mp3
    addEntry "Anima Amoris - IDM"          http://amoris.sknt.ru/idm.mp3
    addSeparator
    addLabel "\Zb\Z3Downtempo:"
    addEntry "Nordic Lodge Copenhagen"     https://larry.torontocast.com:2260/stream
    addEntry "Chill Lounge Florida"        http://c5.radioboss.fm:8149/autodj
    addEntry "Anima Amoris - Trip Hop"     http://amoris.sknt.ru/triphop.mp3
    addSeparator
    addLabel "\Zb\Z3Ambient:"
    addEntry "StillStream"                 http://forge.innerteapot.com:8000/stillstream
    addEntry "Cosmic Waves - Ambient"      http://stream.zeno.fm/9km09vwud5zuv
    addEntry "Cosmic Waves - Progressive"  http://stream.zeno.fm/d8cxprxud5zuv
    addEntry "m00_su - Ambient"            https://radio.m00.su:8000/ambient.mp3
    addEntry "Anima Amoris - Ambient"      http://amoris.sknt.ru/ambient.mp3
    dialogMenu "Select stream" 'play -'
}
radio_vapor_ff() {
    addEntry "Yumi Co. Radio"             http://yumicoradio.net:8000/stream
    addSeparator
    addEntry "Random VaporFunk Radio"     http://krelez.chris-the-tuner.de:15000/vaporradio_hqmp3
    addSeparator
    addEntry "Plaza One (opus)      96k"  https://radio.plaza.one/opus
    addEntry "Plaza One (vorbis)   128k"  https://radio.plaza.one/ogg
    addEntry "Plaza One (mp3)      128k"  https://radio.plaza.one/mp3
    dialogMenu "Select stream" 'play -'
}
radio_vary() {
    addLabel "\Zb\Z3Chiptune:"
    addEntry "Random Chiptune Radio"       http://krelez.chris-the-tuner.de:15000/chiptuneradio_hqmp3
    addEntry "CVGM.net"                    http://69.195.153.34/cvgm192
    addEntry "RolandRadio"                 http://streaming.rolandradio.net/rolandradio
    addSeparator
    addLabel "\Zb\Z3Other:"
    addEntry "HappyHardcore.com"           https://audio-edge-3mayu.fra.h.radiomast.io/0cef93cd-5974-43b1-868e-c739e81f4f2b
    addEntry "BoolOut.com"                 http://s6.citrus3.com:8058/stream
    addEntry "24dubstep.pl - Chillstep"    http://stream.24dubstep.pl:8010/mp3_best
    addEntry "24dubstep.pl - Main"         http://stream.24dubstep.pl:8000/mp3_best
    addEntry "FreakFloor"                  https://str2b.openstream.co/970
    addEntry "Jamendo Lounge"              http://streaming.radionomy.com/JamendoLounge
    addEntry "Radio Q37"                   http://nebula.shoutca.st:8159/autodj
    dialogMenu "Select stream" 'play -'
}

radio_mynoise() {
    addEntry "Pure Nature"   http://purenature-mynoise.radioca.st/stream
    addEntry "Rainy Day"     http://rainyday-mynoise.radioca.st/stream
    addEntry "Zen Garden"    http://zengarden-mynoise.radioca.st/stream
    addEntry "Ocean Waves"   http://oceanwaves-mynoise.radioca.st/stream
    addEntry "Siren Songs"   http://sirensongs-mynoise.radioca.st/stream
    addEntry "Space Odyssey" http://spaceodyssey-mynoise.radioca.st/stream
    dialogMenu "Select stream" 'play -'
}
radio_m00_su() {
    addEntry "Drum and Bass  128k" https://radio.m00.su:8000/drumandbass.mp3
    addEntry "IDM            128k" https://radio.m00.su:8000/idm.mp3
    addEntry "Psy            128k" https://radio.m00.su:8000/psy.mp3
    addEntry "Ambient        128k" https://radio.m00.su:8000/ambient.mp3
    addEntry "Dark Ambient   128k" https://radio.m00.su:8000/darkambient.mp3
    addEntry "Hardcore       128k" https://radio.m00.su:8000/hardcore.mp3
    addEntry "Techno         128k" https://radio.m00.su:8000/techno.mp3
    dialogMenu "Select stream" 'play -'
}
radio_anima_amoris() {
    addEntry "Drum and Bass        160k" http://amoris.sknt.ru/dnb.mp3
    addEntry "Trance               160k" http://anima.sknt.ru/trance.mp3
    addEntry "Trip Hop Lounge      160k" http://amoris.sknt.ru/triphop.mp3
    addEntry "Ambient              160k" http://amoris.sknt.ru/ambient.mp3
    addEntry "IDM                  160k" http://amoris.sknt.ru/idm.mp3
    addEntry "Goa Psy Trance       160k" http://amoris.sknt.ru/goa.mp3
    addEntry "Dub Techno Mix       160k" http://amoris.sknt.ru/dubtechnomix.mp3
    addEntry "Dub Techno           320k" http://amoris.sknt.ru/dubtechno.mp3
    #addEntry "Dub Techno            56k" http://amoris.sknt.ru/dubtechno.aac
    addEntry "Minimal Deep Techno  160k" http://amoris.sknt.ru/minimal.mp3
    addEntry "Eurodance            160k" http://anima.sknt.ru/eurodance.mp3
    addEntry "Dub Step             160k" http://amoris.sknt.ru/dubstep.mp3
    addEntry "Deep Tech House      160k" http://amoris.sknt.ru/deeptech.mp3
    addEntry "Electro              160k" http://amoris.sknt.ru/electro.mp3
    addEntry "Techno               160k" http://amoris.sknt.ru/techno.mp3
    addEntry "New Age              160k" http://amoris.sknt.ru/newage.mp3
    addEntry "Bible                128k" http://amoris.sknt.ru/bible.mp3
    dialogMenu "Select stream" 'play -'
}


direct() {
    addEntry "playnoise.com"                direct_playnoise
    addEntry "datassette.net/businessfunk/" direct_businessfunk
    dialogMenu "Select direct source" 'eval'
}
direct_playnoise() {
    addEntry "PlayNoise.com - Brown noise (ogg)" --loop https://playnoise.com/snd/brown_noise.ogg
    addEntry "PlayNoise.com - Pink noise  (ogg)" --loop https://playnoise.com/snd/pink_noise.ogg
    dialogMenu "Select stream" 'play -'
}
direct_businessfunk() {
    addEntry "Business Funk I"   http://datassette.net/content/datashat-businessfunk.mp3
    addEntry "Business Funk II"  http://datassette.net/content/datashat-businessfunk2.mp3
    addEntry "Business Funk III" http://datassette.net/content/datashat-businessfunk3.mp3
    dialogMenu "Select stream" 'play -'
}


ytaudio() {
    if ! require youtube-dl; then return 1; fi
    addLabel "\Zb\Z3Playlists:"
    addEntry "FreeForm Hardcore / Trancecore"                                    'playlist?list=PLFBZT3CIdFxKNy_oKus0E79kC_8s8U9VV'
    addEntry "Sonic Mania Reworked - Mykah"                                      'playlist?list=PLdnU7aJC-M8i_pLfSIcxfdYV_pY2ixFoH'
    addSeparator
    addLabel "\Zb\Z3Comfy:"
    addEntry "Spend The Night In An Exclusive Luxury Miami Apartment"            'watch?v=QUqhgZjrrsE'
    addEntry "Power Outage During Thunderstorm ASMR Ambience"                    'watch?v=nxWxC0DffG8'
    addEntry "Quiet Night in the Park with Relaxing Sounds of Rain Falling Down" 'watch?v=euWoxhUkf_w'
    addEntry "Relaxing Atmosphere of Raindrops Falling on the Leaves of Plants"  'watch?v=zKHJuEwzXPk'
    addEntry "Relaxing River Sounds - Peaceful Forest River"                     'watch?v=IvjMgVS6kng'
    addEntry "Minecraft Longplay part 1 //no commentary"                         'watch?v=Uk-sR0FGMjI'
    addEntry "Autumn Forest - Relaxing Nature & River Sounds"                    'watch?v=czCHvDY23fc'
    addEntry "Relaxation music 12 hours - Vol 3"                                 'watch?v=ebhoaxFyDuM'
    addSeparator
    addLabel "\Zb\Z3Liquid DnB:"
    addEntry "Liquid & Beyond #43 (Best of 2019)"                                'watch?v=hffu2JNcYV0'
    addEntry "Liquid Drum and Bass Mix #122"                                     'watch?v=zhiq5CCthg0'
    addSeparator
    addLabel "\Zb\Z3Games:"
    addEntry "Katamari Damacy - Katamari on the Rock (Extended)"              'watch?v=-gvuE46a_fg'
    addEntry "Mario Kart Wii - Select Medley (Mode, Character, Kart, Course)" 'watch?v=mlQmCfjXApM'
    addEntry "Mario Kart Wii - Select Medley (Character, Kart)"               'watch?v=La_Bz20Xb64'
    addEntry "Mario Kart Wii - DS Twilight House (Fast)"                      'watch?v=hCUJ8RQxd_w'
    addEntry "Mario Kart Wii - Coconut Mall"                                  'watch?v=Wje_bp0JiwU'
    addEntry "Wii Sports - Main Menu"                                         'watch?v=UNhsOboOtg0'
    addEntry "Wii News Channel - Tip Cat Music"                               'watch?v=D6APP5R6p74'
    addEntry "MVDK2:MotM - 1st Floor, Mushroom Mayhem I"                      'watch?v=T3x8m0b1P8A'
    addEntry "Earthbound Music Extended - File Select"                        'watch?v=M1bDxZS7tMM'
    addEntry "Earthbound Music Extended - Your Name, Please (No Crowd)"       'watch?v=2pCRuk3W0l4'
    addEntry "Earthbound Music Extended - Sanctuary Guardian"                 'watch?v=snKJPEVbQoE'
    addSeparator
    addLabel "\Zb\Z3Other:"
    addEntry "Vaporwave Furret 10 Hours"                                  'watch?v=tDBMnqEJYOA'
    addEntry "Duck Spinning To Geometry Dash Practice Mode Song 10 Hours" 'watch?v=lknzALc0NeA'
    addEntry "De Lorra - Vision"                                          'watch?v=J_LKBZlEHng' --loop
    addEntry "Photon - Cosmos"                                            'watch?v=Ytt1_ErIV34' --loop
    addEntry "HOME - Resonance"                                           'watch?v=8GW6sLrK40k' --loop
    addEntry "(1981) Tom Tom Club - Genius of Love"                       'watch?v=ECiMhe4E0pI'
    dialogMenu "Select video" 'play yta'
}


mmenu() {
    addEntry "Youtube Audio"           ytaudio
    addEntry "musicforprogramming.net" mfp
    addEntry "Radios"                  radios
    addEntry "Direct links"            direct
    addSeparator
    addEntry "Local library"           locallib
    addSeparator
    addEntry "Edit script"             editscript
    dialogMenu "Select source" 'eval'
}


quit() {
    ${1:+clear}
    exit
}
signal() { :; }


if ! require dialog mpv mktemp printf base64; then return 1; fi
trap signal SIGINT
#trap pauseFancy DEBUG
NEXT=mmenu
while true; do
    if ! eval "$NEXT"; then
        NEXT="${STACKMENU[-1]}"
        DEFITEM="${STACKCHOICE[-1]}"
        unset "STACKMENU[-1]"
        unset "STACKCHOICE[-1]"
    fi
done
