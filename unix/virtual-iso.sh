#!/bin/bash

main() {
    local usage="Usage: ${FUNCNAME[0]} <open|close> filepath.iso [options]"
    if (($# == 0)); then
        echo "$usage" >&2
        return 1
    fi
    local action="$1"
    shift
    case "$action" in
        "open")
            if ! [[ -f "${1:?Missing filepath argument.}" ]]; then
                echo "Provided file is missing: $1" >&2
                return 1
            fi
            local msg="$(udisksctl loop-setup -f "$1")"
            
            if ! [[ "$msg" =~ (/dev/.+?)\.$ ]]; then
                echo "Unknown udisksctl message format:" >&2
                echo "$msg"
                return 2
            fi
            local blk="${BASH_REMATCH[1]}"
            echo "> $blk" >&2
            shift
            echo "> ${@:-No other arguments}" >&2
            
            local msg="$(udisksctl mount -b "$blk" "$@")"
            echo "$msg"
            if ! [[ "$msg" =~ \ at\ (/.+?)$ ]]; then
                echo "Unknown udisksctl mount message format..."
                return 3
            fi
            local path="file://${BASH_REMATCH[1]}"
            echo "> ${path}"
            command -V xdg-open &>/dev/null && xdg-open "${path}"
            ;;

        "close")
            if ! [[ -f "${1:?Missing filepath argument.}" ]]; then
                echo "Provided file is missing: $1" >&2
                return 1
            fi
            local msg="$(losetup -j "$1")"
            
            echo "$msg"
            if ! [[ "$msg" =~ ^(/.+?):\ .+:\  ]]; then
                echo "Unknown losetup mount message format..."
                return 2
            fi
            local dev="${BASH_REMATCH[1]}"
            
            udisksctl unmount -b "$dev" && udisksctl loop-delete -b "$dev"
            ;;

        *)
            echo "$usage" >&2
            return 1
            ;;
    esac
}

main "$@"
