#!/bin/bash

SELF="${BASH_SOURCE[0]}"
SELF="$(realpath -ms "$SELF")"
cd "$(dirname "$SELF")" || exit

wget() { command wget --content-disposition --no-verbose --show-progress --continue "$@"; }

tags=(node backup compressedarchive windows linux macos)
IFS=','
wget -O '.gitignore' "https://www.toptal.com/developers/gitignore/api/${tags[*]}"
