__creset="\[\e[0m\]"
__ccl="\[\e[K\]"
__cgray="${__creset}\[\e[37m\]"
__cwhite="${__creset}\[\e[97m\]"
__cred="${__creset}\[\e[91m\]"
__cdarkred="${__creset}\[\e[31m\]"
__cgreen="${__creset}\[\e[92m\]"
__cdarkgreen="${__creset}\[\e[32m\]"
__cblue="${__creset}\[\e[94m\]"
#
#int color256rainbow[] = {
#	196, 202, 208, 214, 220, 226, 190, 154, 118, 82,  46,  47,  48,  49,  50,
#	51,  45,  39,  33,  27,  21,  57,  93,  129, 165, 201, 200, 199, 198, 197
#};
#int color256length = 30;
__crainbow=(
    196  202  208  214  220  226  190  154  118  82
    46   47   48   49   50   51   45   39   33   27
    21   57   93   129  165  201  200  199  198  197
)
__crainbowlight=(
    160  166  172  178  142  106  70   71   72   73
    74   68   62   56   92   128  164  163  162  161
)
__crainbowlen=${#__crainbow[@]}
if [[ "$(id -u)" == "0" ]]; then
    __PS1_CLIGHT="${__cred}"
    __PS1_CDARK="${__cdarkred}"
    __crainbowi=-1
else
    __PS1_CLIGHT="${__cgreen}"
    __PS1_CDARK="${__cdarkgreen}"
    __crainbowi=8
fi


_adapt_prompt() (
    username="\u"
    hostname="\h"
    shelltype="\\$"
    term_len=$(tput cols)
    currpath="\w"
    currpath="${currpath@P}"
    currpath="${currpath#/mnt/*/}"
    currdir="\W"
    if (( (${#currpath}+${#USER}+4) > (term_len/2) )) \
    || [[ "$KATE_PID" != "" ]] \
    || [[ "$TERM_PROGRAM" == "vscode" ]]; then
        _smpl
    else
        adapt_prompt_choice
    fi
    return $?
)
adapt_prompt() {
    #echo "[adapt_prompt] called by bash" >&2
    if [[ "$__PS1" != "" ]] && [[ "$PS1" != "$__PS1" ]]; then
        return
    fi
    ((__crainbowi = (__crainbowi + ${1:-0}) % __crainbowlen))
    local newps1
    if ! newps1=$(_adapt_prompt); then
        return
    fi
    export PS1="$newps1"
    export __PS1="$PS1"
    #trap - SIGWINCH
    #kill -s SIGWINCH "$$"
    #trap 'adapt_prompt' SIGWINCH
}
_smpl() {
    __PS1_CRLIGHT="${__creset}\[\e[1;38;5;${__crainbow[${__crainbowi}]}m\]"
    __PS1_CRDARK="${__creset}\[\e[38;5;${__crainbow[${__crainbowi}]}m\]"
    echo "${__cgray}${currdir} ${__PS1_CRLIGHT}${shelltype}${__PS1_CRDARK}>${__cwhite} "
}
_cmplx() {
    # export PS0="${cgray}"$(yes "⎺" | head -n $term_len | tr -d '\n')"${creset}\n"
    # export PS1="${cblue}[${cselect}${username}${cblue}@${cgray}${hostname}${cblue}]${cwhite}: ${cgray}${currpath}${cblue}>${cselect}${shelltype}${creset} "
    __PS1_CRLIGHT="${__creset}\[\e[1;38;5;${__crainbow[${__crainbowi}]}m\]"
    echo "${__PS1_CRLIGHT}${username}${__cwhite}) ${__cgray}${currpath} ${__PS1_CLIGHT}${shelltype}${__PS1_CDARK}>${__cwhite} "
}
smpl() {
    adapt_prompt_choice() {
        _smpl
    }
}
cmplx() {
    adapt_prompt_choice() {
        _cmplx
    }
}


unset __PS1
if [[ "$XTERM_VERSION" != "" ]]; then
    __cgray="${__creset}\[\e[30m\]"
    __cwhite="${__creset}\[\e[90m\]"
    printf "\e[?5h\e[?30h"
fi
if [[ "$TERM_PROGRAM" == "vscode" ]] || [[ "$TERMINAL_EMULATOR" == "JetBrains-JediTerm" ]]; then
    __cgray="${__creset}"
    __cwhite="${__creset}"
    unset __crainbow
    __crainbow=("${__crainbowlight[@]}")
    __crainbowlen=${#__crainbowlight[@]}
    __crainbowi=6
fi
# printf "\e[6 q"
cmplx
# trap 'adapt_prompt' SIGWINCH
# trap adapt_prompt DEBUG
_prompt_my() { adapt_prompt 1; }
PROMPT_COMMAND+=('_prompt_my')
export PS0="${__creset}"
