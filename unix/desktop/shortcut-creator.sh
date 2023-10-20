#!/bin/bash


declare -n M=BASH_REMATCH


dbg() {
    echo "$*"
} >&2


dump() {
    for name in "$@"; do
        local -n ref="$name"
        dbg "$name=${ref@Q}"
        unset -n ref
    done
} >&2


get_property() {
    local key="${1:?Missing property name.}"
    local file="${2:?Missing .desktop file path.}"
    local line
    while read -r line; do
        if [[ "$line" =~ ^"$key"=(.*)$ ]]; then
            echo "${M[1]}"
            return 0
        fi
    done < "$file"
    return 1
}


get_mime_icon() {
    local mime="${1:?Missing mimetype.}"
    local line
    for cust in {"$HOME/.local","/usr"}"/share/mime/icons"; do
        [[ ! -f "$cust" ]] && continue
        while read -r line; do
            if [[ "$line" =~ ^"$mime":(.*)$ ]]; then
                echo "${M[1]}"
                return
            fi
        done < "$cust"
    done
    echo "${mime//\//-}"
}


get_file_mime() {
    xdg-mime query filetype "$1"
}

get_file_default() {
    local ret="$(xdg-mime query default "$(get_file_mime "$1" )" )"
    echo "${ret%.desktop}"
}


find_file_icon() {
    local dest="${1:?Missing path.}"
    
    if [[ -d "$dest" ]]; then
        local dd="$dest/.directory"
        if [[ -f "$dd" ]] && get_property Icon "$dd"; then
            return
        fi
        echo "inode-directory"
    
    elif [[ -f "$dest" ]]; then
        echo "$(get_mime_icon "$(get_file_mime "$dest" )" )"
    
    fi
}


read_dom() {
    IFS='>' read -r -d '<'  ENTITY CONTENT
    local ret=$?
    TAG="${ENTITY%% *}"
    if [[ "${ENTITY:0:1}" == '/' ]]; then
        unset ATTRS
    else
        ATTRS="$ENTITY"
        ATTRS="${ATTRS#* }"
        ATTRS="${ATTRS%/}"
    fi
    return $ret
}


read_attr() (
    eval unset "$1"
    eval local $ATTRS
    eval echo "\$$1"
)


find_kde_userplaces_title_icon() {
    local url="${1:?Missing url.}"
    local state=0
    local closing
    local ENTITY CONTENT TAG ATTRS
    while read_dom; do
        case "$state" in
        0)
            [[ "$TAG" != "bookmark" && "$TAG" != "separator" ]] && continue
            [[ "$(read_attr href)" != "$url" ]] && continue
            closing="/$TAG"
            dbg "userplaces match"
            ((state++)) ;;
        1)
            [[ "$TAG" == "$closing" ]] && break
            [[ "$TAG" == "title" ]] && title="$CONTENT"
            [[ "$TAG" == "bookmark:icon" ]] && icon="$(read_attr name)"
            ;;
        esac
    done < "$HOME/.local/share/user-places.xbel"
    return 0
}


FILEURL="file://"
is_path() {
    [[ "$url" =~ ^"$FILEURL" ]] && path="${url#$FILEURL}"
}

generate() {
    local url="${1:?Missing url.}"
    local dest="${2:?Missing directory.}"
    local path
    
    # make standard url
    dump url
    [[ "${url:0:1}" == '/' ]] && url="$FILEURL$url"
    dump url
    
    # get symlink path
    is_path && url="$FILEURL$(readlink -m "$path")"
    
    # copy .desktop content
    if is_path && [[ "$path" =~ \.desktop$ ]]; then
        dbg "is .desktop"
        cp -v --remove-destination "$path" "$dest"
        chmod -v 744 "$dest/$(basename "$path")"
        return
    fi
    
    # TODO search all  .local/share/remoteview/.*=Name.desktop
    # remote:/Name
    
    # search custom icon & label
    local title icon app
    find_kde_userplaces_title_icon "$url"
    
    # search default icon, label & app
    if [[ "$url" =~ ^"$FILEURL" ]]; then
        local path="${url#$FILEURL}"
        [[ ! "$title" ]] && title="$(basename "$path")"
        [[ ! "$icon" ]]  && icon="$(find_file_icon "$path")"
        if [[ -f "$path" ]]; then
            app="$(get_file_default "$path" )"
        fi
    fi
    
    # fallback icon & label
    [[ ! "$title" ]] && title="${url//\//-}"
    [[ ! "$icon" ]]  && icon="inode-symlink"
    dump title icon
    #return

    # generate shortcut
    local tnp="${title//\//-}"
    local filename="$tnp.desktop"
    local count=1
    local titlenum="$title"
    # do not overwrite
    while [[ -f "$dest/$filename" ]]; do
        ((count++))
        filename="$tnp ($count).desktop"
        titlenum="$title ($count)"
    done
    local d="$dest/$filename"
    #rm -v "$d"
    cat <<EOF >"$d"
[Desktop Entry]
Icon=$icon
Name=$titlenum
Type=Link
URL[\$e]=$url
${app:+X-KDE-LastOpenedWith=$app}
EOF
    # remove exclamation badge
    chmod -v 744 "$d"
}


source "$HOME/.config/user-dirs.dirs"
for url in "$@"; do
    generate "$url" "$XDG_DESKTOP_DIR"
done
