
shopt -s histappend              # append new history items to .bash_history
export HISTCONTROL='ignoreboth:erasedups'   # leading space hides commands from history
export HISTFILESIZE=10000        # increase history file size (default is 500)
export HISTSIZE=${HISTFILESIZE}  # increase history size (default is 500)

# ensure synchronization between bash memory and history file
export PROMPT_COMMAND+=("history -a; history -n;")

if command -v hstr &>/dev/null; then
    # HSTR configuration - add this to ~/.bashrc
    alias hh=hstr                    # hh to be alias for hstr
    export HSTR_CONFIG=hicolor,raw-history-view       # get more colors and sort by history
    # if this is interactive shell, then bind hstr to Ctrl-r (for Vi mode check doc)
    if [[ $- =~ .*i.* ]]; then bind '"\C-r": "\C-a hstr -- \C-j"'; fi
    # if this is interactive shell, then bind 'kill last command' to Ctrl-x k
    if [[ $- =~ .*i.* ]]; then bind '"\C-xk": "\C-a hstr -k \C-j"'; fi
fi
