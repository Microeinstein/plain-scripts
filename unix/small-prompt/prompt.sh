#!/bin/bash
# 2023-07-10 - Microeinstein


bind 'set show-all-if-ambiguous on'
bind 'set completion-ignore-case on'


gen_rgb_rainbow() {
    # call by hand
    local py
    py="$(cat <<EOF
from sys import argv
from colorsys import hsv_to_rgb
l = 30
f = lambda n: str(round(n*255))
for n in range(0,l):
    c = map(f, hsv_to_rgb(n/l, float(argv[1]), float(argv[2])))
    c = ';'.join(c)
    # print(f"\x1b[0;30;48;2;{c}mlorem ipsum\x1b[0m")
    # print(f"'{c}'", end='  ')
    print(c)
EOF
)"
    mapfile -t __RAINBOW < <(python -c "$py" "$@")
    printf "'%s'  "  "${__RAINBOW[@]}" | fold -s
    echo
}


get_cursor_pos() {
    # prints sequence to stdout, terminal answers to stdin - very fragile
    # WILL reset previous stdin apparently?
    # based on a script from http://invisible-island.net/xterm/xterm.faq.html
    local __ oldstty
    oldstty="$(stty -g)"
    stty raw -echo min 0
    read -r -s -p$'\e[6n' -d\[ __ >/dev/tty
    IFS=';' read -r -s -dR row col >/dev/tty
    stty "$oldstty"
} </dev/tty


# desired: printf expansions, variables in single quotes, ecc...
# shellcheck disable=SC2016,SC2059
setup_PS1() {
    # basics
    local -A C=(
        [r]='0'    # reset
        [b]='1'    # bold
        [f]='2'    # faint
        [i]='7'    # inverse
        [nb]='22'  # not bold/faint
        [ni]='27'  # not inverse
        [fdbla]='30'  [fdred]='31'  [fdgre]='32'                [fdwhi]='37'
        [flbla]='90'  [flred]='91'  [flgre]='92'  [flblu]='94'  [flwhi]='97'
        [fc]='38;5;%s'  # 256
        [fr]='39'       # reset
        
        [bdbla]='40'  [bdred]='41'  [bdgre]='42'  [bdwhi]='47'
        [blbla]='100' [blred]='101' [blgre]='102'
        [bc]='48;5;%s'  # 256
        [br]='49'       # reset
    )
    local -A B=(
        [user]='\u'  [host]='\h'  [euid]='\$'  [path]='\w'  [cdir]='\W'  [cmdn]='\#'
    )
    
    CSI() { printf '\e[%s' "$*"; }  # do not use in PS1
    FMT() {
        #  r fmt=5=7 b  ->  C[r];C[fmt]='5=7';C[b]
        local k v  IFS=';'  t=()
        local -n r=BASH_REMATCH
        for k in "$@"; do
            if [[ "$k" =~ ^([^=]+)=(.+)$ ]]; then
                printf -v v "${C[${r[1]}]}" "${r[2]}"
            else
                v="${C[$k]}"
            fi
            t+=("$v")
        done
        printf '\x01\e[%sm\x02' "${t[*]}"
    }
    
    
    # tweaks
    local rever=0  rgb=0  light=0  basic=0  short=0
    
    [[ ! -v TERM || "$TERM" == dummy ]]                          && return  # terminal is too stupid
    [[ "$TERM" != xterm* ]]                                      && basic=1
    [[ -v KONSOLE_VERSION ]]                                     && rgb=1
    [[ -v XTERM_VERSION ]]                                       && { rever=1; basic=1; }
    [[ -v TERM_PROGRAM || -v TERMINAL_EMULATOR || -v KATE_PID ]] && short=1
    [[ -v TERM_PROGRAM || -v TERMINAL_EMULATOR ]]                && light=1
    
    if ((rever)); then
        C[fdwhi]='30'
        C[flwhi]='90'
        printf '\e[?5h\e[?30h'  # reverse (all) video + show scrollbar
    fi
    
    
    # rainbow and specific
    local gray
    if ((rgb)); then
        C[fc]='38;2;%s'  # truecolor
        C[bc]='48;2;%s'
        if ((light)); then
            __RAINBOW=(
                '178;89;89'   '178;107;89'  '178;125;89'  '178;143;89'  '178;161;89'
                '178;178;89'  '161;178;89'  '143;178;89'  '125;178;89'  '107;178;89'
                '89;178;89'   '89;178;107'  '89;178;125'  '89;178;143'  '89;178;161'
                '89;178;178'  '89;161;178'  '89;143;178'  '89;125;178'  '89;107;178'
                '89;89;178'   '107;89;178'  '125;89;178'  '143;89;178'  '161;89;178'
                '178;89;178'  '178;89;161'  '178;89;143'  '178;89;125'  '178;89;107'
            )
            gray='218;218;218'
        else
            __RAINBOW=(  #  .5 .95
                '242;121;121'  '242;145;121'  '242;170;121'  '242;194;121'  '242;218;121'
                '242;242;121'  '218;242;121'  '194;242;121'  '170;242;121'  '145;242;121'
                '121;242;121'  '121;242;145'  '121;242;170'  '121;242;194'  '121;242;218'
                '121;242;242'  '121;218;242'  '121;194;242'  '121;170;242'  '121;145;242'
                '121;121;242'  '145;121;242'  '170;121;242'  '194;121;242'  '218;121;242'
                '242;121;242'  '242;121;218'  '242;121;194'  '242;121;170'  '242;121;145'
            )
            gray='78;78;78'
        fi
    else
        if ((light)); then
            __RAINBOW=(
                160  166  172  178  142  106  70   71   72   73
                74   68   62   56   92   128  164  163  162  161
            )
            gray='253'
        else
            __RAINBOW=(
                196  202  208  214  220  226  190  154  118  82
                46   47   48   49   50   51   45   39   33   27
                21   57   93   129  165  201  200  199  198  197
            )
            gray='239'
        fi
    fi
    __RNBL=${#__RAINBOW[@]}
    ((__RNBL)) || return 1
    
    
    # user is not root?
    if (($(id -u))); then
        C+=(
            [fdusr]="${C[fdgre]}"
            [flusr]="${C[flgre]}"
            [bdusr]="${C[bdgre]}"
            [blusr]="${C[blgre]}"
        )
        ((__RNBI= light ? 6 : 8))
    else
        C+=(
            [fdusr]="${C[fdred]}"
            [flusr]="${C[flred]}"
            [bdusr]="${C[bdred]}"
            [blusr]="${C[blred]}"
        )
        __RNBI=-1
    fi
    
    
    # ps1 delayed expansions + functions
    # all functions will be executed in subshell, so will exploit PROMPT_COMMAND
    shopt -s promptvars
    local excd='${__[ $((__IRET=$?)) ]:+}'
    local lcmd='${__[ $((__MYV[lastcmd]=304249144)) ]:+}'  # *reset*
    local anim='${__[ $((__RNBI=(__RNBI+1) % __RNBL)) ]:+}'
    local stil='${__RAINBOW[ $__RNBI ]}'
    declare -gA __MYV
    
    __MYV[abbr]="$(FMT f)*$(FMT nb)"
    __MYPWD() {
        local d="$PWD"
        # [[ "${__MYV[dir]}" == "$d" && "${__MYV[cols]}" == "$cols" ]] && {
        #     echo "${__MYV[pdir]}"
        #     return
        # }
        # __MYV[dir]="$d"
        # __MYV[cols]="$cols"
        
        # reduce known
        d="${d/"$HOME"/'~'}"
        d="${d#"/mnt/files/"}"
        ((${#d} < 11)) && {
            # __MYV[pdir]="$d"
            echo "$d"
            return
        }
        
        # reduce long
        local -n r=BASH_REMATCH
        local __
        for __ in {1..20}; do
            [[ "$d" =~ /([^/*]{16,}) ]] || break
            d="${d//"${r[0]}"/"/${r[1]:0:7}*${r[1]: -7}"}"
        done
        
        # cut
        local cols
        cols="$(tput cols)"
        local cut=$((${#d} - (cols / 3 - ${#USER} - 4)))
        ((cut = cut < 2 ? 0 : cut))
        ((cut)) && d="*${d: $cut}"
        
        # pretty
        d="${d//'*'/"${__MYV[abbr]}"}"
        #__MYV[pdir]="$d"
        echo "$d"
    }
    
    __MYV[ok]="$(FMT fdgre)●$(FMT r)"
    __MYV[err]="$(FMT fdred)●$(FMT r)"
    __MYEXIT() {
        if ((__IRET)); then
            echo "${__MYV[err]}"
        else
            echo "${__MYV[ok]}"
        fi
    }

    __MYV[up]="$(CSI F)"  # $(CSI 2K)
    __MYDEBUG() {
        local cur="$BASH_COMMAND"
        trap - DEBUG      # only trap first time, save resources
        eval -- "${__MYV[tdebug]}"
        [[ "${PROMPT_COMMAND[*]}" == *"$cur"* ]] && return
        __MYV[lastcmd]="$cur"  # save actual last command
    }
    __MYUPWR() {
        local cmdn='\#'
        cmdn="${cmdn@P}"  # expand as if prompt
        local -n last='__MYV[lastcmdn]'
        if [[ "$cmdn" == "$last" ]]; then
            printf "${__MYV[up]}"
            return 0
        fi
        last="$cmdn"
        ((cmdn)) || return 0
        
        # do not detect command output (by cursor position) if bound to some shortcut,
        # potentially changing READLINE_LINE or READLINE_POINT
        # https://github.com/dvorka/hstr/blob/4dca4c72d7db104b2c1043551d0d8dc611e0e260/test/sh/tiotcsi-function-bash.sh#L174
        if [[ "$(bind -S)" != *"${__MYV[lastcmd]}"* ]]; then
            local row  col
            get_cursor_pos
            ((col>1)) && printf ' \e[1;90m↩\e[0m'
        fi
        echo
    }
    __MYPROMPT() {
        __MYUPWR
        __MYV[tdebug]="$(trap -p DEBUG)"
        trap '__MYDEBUG' DEBUG
    }

    [[ "${PROMPT_COMMAND[*]}" == *__MYPROMPT* ]] \
    || PROMPT_COMMAND+=('__MYPROMPT')
    
    
    # ps1 building
    # https://starship.rs/presets/pastel-powerline.html
    # https://www.nerdfonts.com/cheat-sheet  (must use patched font)
    # https://github.com/powerline/fonts/issues/31#issuecomment-1023622834
    #   half_circle_thick 
    #   hard_divider      
    local ps1=("${excd}${anim}" '$(__MYEXIT) '  "$lcmd"  "$(FMT r)" )
    #ps1+=("${B[cmdn]} ")  # debug
    if ((basic)); then
        if ((short)); then
            # workdir $>
            ps1+=(                     '$(__MYPWD) '
                "$(FMT b fc="$stil")"  "${B[euid]}"
                "$(FMT nb)"            '>'
            )
        else
            # user) workdir $>
            ps1+=(
                "$(FMT b fc="$stil")"  "${B[user]}"
                "$(FMT r flwhi)"       ') $(__MYPWD) '
                "$(FMT flusr)"         "${B[euid]}"
                "$(FMT fdusr)"         '>'
            )
        fi
    elif ((short)); then
        # (( workdir >>
        ps1+=(
            "$(FMT fc="$gray"           )"  ''
            "$(FMT bc="$gray" fr        )"  ' $(__MYPWD) '
            "$(FMT fc="$gray" bc="$stil")"  ''
            "$(FMT br         fc="$stil")"  ''
        )
    else
        # (( user )) workdir >>
        ps1+=(
            "$(FMT fc="$stil"           )"  ''
            "$(FMT bc="$stil" fdbla     )"  "${B[user]}"
            "$(FMT fc="$stil" bc="$gray")"  ''
            "$(FMT fr                   )"  ' $(__MYPWD) '
            "$(FMT bdusr      fc="$gray")"  ''
            "$(FMT fdusr      br        )"  ''
        )
    fi
    ps1+=("$(FMT r)"  ' ')
    ((basic)) && ps1+=("$(FMT flwhi)")
    
    local IFS=''
    PS0="$(FMT r)"
    PS1="${ps1[*]}"
    
    
    # cleaning
    unset CSI FMT FMT2
}

setup_PS1
