#!/bin/bash

set -x

NAME="$(basename -s .sh "${BASH_SOURCE[0]}" )"
DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}" )" )"

export -n PYTHONPATH PYTHONHOME
exec /usr/bin/python3 "$DIR/$NAME.py" "$@"
