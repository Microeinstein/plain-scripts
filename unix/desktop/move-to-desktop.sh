#!/bin/bash
# Only works with square-layout grid of desktops

rows=2
cols=2
relx="${1:?Missing X-relative movement}"
rely="${2:?Missing Y-relative movement}"
((relx %= cols))
((rely %= rows))
printf '[%s]\n' "$relx" "$rely"

read -r curr < <(xdotool get_desktop)
((currx = curr % cols + relx))
((curry = curr / rows + rely))
printf '[%s]\n' "$currx" "$curry"
((currx = (currx + (currx<0? cols : 0)) % cols))
((curry = (curry + (curry<0? rows : 0)) % rows))
printf '[%s]\n' "$currx" "$curry"
((curr = curry * rows + currx))
printf '[%s]\n' "$curr"

xdotool set_desktop "$curr"
