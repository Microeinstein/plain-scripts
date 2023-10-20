#!/bin/bash

time="${1:-"$(date +'%T')"}"
IFS=':' read -r h m s <<<"$time"
h=$((10#$h))
m=$((10#$m))
s=$((10#$s))
printf '%02d.%02d\n' $h $(bc <<EOF
scale = 2;
s = $s / 60;
m = (s+$m) / 60;
scale = 0;
m = m * 100 / 1;
print m,"\n" 
EOF
)
