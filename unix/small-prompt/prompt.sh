setup_PS1() {
    local -A C=(
        [r]='0'    # reset
        [b]='1'    # bold
        [f]='2'    # faint
        [nb]='22'  # not bold/faint
        # fg dark colors
        [fdred]='31'
        [fdgre]='32'
        [fdwhi]='37'
        [fc256]='38;5;%s'
        # fg light colors
        [flbla]='90'
        [flred]='91'
        [flgre]='92'
        [flblu]='94'
        [flwhi]='97'
    )
    local -A B=(
        [user]='\u'
        [host]='\h'
        [euid]='\$'
        [path]='\w'
        [cdir]='\W'
    )
    
    CSI() {
        #  r b  ->  C[r];C[b]
        local a  IFS=';'  t=()
        for a in "$@"; do t+=("${C[$a]}"); done
        printf '\x01\e[%sm\x02' "${t[*]}"
    }
    CSI2() {
        #  b fmt 5  ->  C[b];C[fmt]%5
        local  t=("$@")
        printf  "$(CSI "${t[@]:0: $(( ${#t[@]} - 1))}")"  "${t[@]: -1}"
    }
    
    
    local rever=0  light=0  simple=0
    
    # KONSOLE_VERSION
    [[ -v XTERM_VERSION ]]                                       && rever=1
    [[ -v TERM_PROGRAM || -v TERMINAL_EMULATOR || -v KATE_PID ]] && simple=1
    [[ -v TERM_PROGRAM || -v TERMINAL_EMULATOR ]]                && light=1
    
    if ((rever)); then
        C[fdwhi]='30'
        C[flwhi]='90'
        printf '\e[?5h\e[?30h'  # reverse (all) video + show scrollbar
    fi
    if ((light)); then
        __RAINBOW=(
            160  166  172  178  142  106  70   71   72   73
            74   68   62   56   92   128  164  163  162  161
        )
    else
        __RAINBOW=(
            196  202  208  214  220  226  190  154  118  82
            46   47   48   49   50   51   45   39   33   27
            21   57   93   129  165  201  200  199  198  197
        )
    fi
    __RNBL=${#__RAINBOW[@]}
    
    
    if (($(id -u))); then  # user
        C[flusr]="${C[flgre]}"
        C[fdusr]="${C[fdgre]}"
        ((__RNBI= light ? 6 : 8))
    else                   # root
        C[flusr]="${C[flred]}"
        C[fdusr]="${C[fdred]}"
        __RNBI=-1
    fi
    
    
    __ABBR="$(CSI f)*$(CSI nb)"
    __OLDPWD=()  # cache
    __MYPWD() {
        local d="$PWD"
        [[ "${__OLDPWD[0]}" == "$d" ]] && {
            echo "${__OLDPWD[1]}"
            return
        }
        __OLDPWD[0]="$d"
        
        # reduce known
        case "$d" in
            "$HOME")        d='~'        ;;
            '/mnt/files/'*) d="${d: 11}" ;;
        esac
        ((${#d} < 11)) && { echo "$d"; return; }
        
        # reduce long
        local -n r=BASH_REMATCH
        local n
        for n in {1..20}; do
            [[ "$d" =~ /([^/*]{16,}) ]] || break
            d="${d//"${r[0]}"/"/${r[1]:0:7}*${r[1]: -7}"}"
        done
        
        # cut
        local cols="$(tput cols)"
        local cut=$((${#d} - (cols / 3 - ${#USER} - 4)))
        ((cut = cut < 2 ? 0 : cut))
        ((cut)) && d="*${d: $cut}"
        
        # pretty
        d="${d//'*'/"$__ABBR"}"
        __OLDPWD[1]="$d"
        echo "$d"
    }
    
    # ●
    shopt -s promptvars
    local IFS=''
    local anim='${__RAINBOW[ $((__RNBI = (__RNBI+1) % __RNBL)) ]}'
    if ((simple)); then
        local ps1=(
            $(CSI r)                 '$(__MYPWD) '
            $(CSI2 b fc256 "$anim")  ${B[euid]}
            $(CSI nb)                '>'
            $(CSI r)                 ' '
        )
    else
        local ps1=(
            $(CSI2 r b fc256 "$anim")  ${B[user]}
            $(CSI r)                   ') $(__MYPWD) '
            $(CSI flusr)               ${B[euid]}
            $(CSI fdusr)               '>'
            $(CSI r)                   ' '
        )
    fi
    PS0="$(CSI r)"
    PS1="${ps1[*]}"
    
    
    unset CSI CSI2
}

setup_PS1
