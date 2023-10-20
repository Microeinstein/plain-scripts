#!/bin/bash

# repeat 3600'000


#sedc='s/\x1b\[[0-9]+?m( *[0-9]+)\x1b\[[0-9]+?m/\x1b[97m<b>\1<\/b>\x1b[m/;'
sedc='s|\x1b\[[0-9]+?m( *[0-9]+)\x1b\[[0-9]+?m|<b>\1<\/b>\x1b[m|;'

if [[ "$TERM" == 'dumb' ]]; then
    echo -n $'\e[0m'  # enables HTML parsing on widget
    sedc+='s/ /\&nbsp;/g;'
fi


export TERM=xterm

c() { cal --color=always "$@"; }
d() { date -d "$(date '+%+4Y-%m-01') $*" '+%m %Y'; }


{
    c $(d '-1 month')
    c
    c $(d '+1 month')
} \
| sed -E "$sedc"
