#!/data/data/com.termux/files/usr/bin/bash

set -e -u

exp=()
for e in TERM  TERMUX_VERSION  SSH_CLIENT  "${LEXP[@]}"; do
    declare -n v="$e"
    [[ -v v ]] && exp+=("$e=${v@Q}")
    unset -n v
done


DISTRO="archlinux"
DISTROOT="$PREFIX/var/lib/proot-distro/installed-rootfs/$DISTRO"
printf 'export %s\n' "${exp[@]}" > "$DISTROOT/etc/profile.d/termux-proot-ext.sh"


: ${LUSER:='root'}
#: ${LCMD:='exec "$(getent passwd micro | cut -d: -f7)" --login'}
#: ${LCMD:="exec su $LUSER"}


export PATH="$PREFIX/tmp:$PATH"
patch="$PREFIX/tmp/proot"
touch "$patch"
chmod +x "$patch"


args_rewrite() {
	local a=("$@")
	local l=$#
	local i=0
	local -n t=a[i]
	declare -g args=()
	go()   { ((i < l));                }
	is()   { [[ "$t" == "$1" ]];       }
	next() { args+=("$t"); ((i++, 1)); }
	loops() {
		while go; do
			is '/bin/su' || { next; continue; }
			while go; do
				case "$t" in
					#-l) t='-m' ;;
					-c) t='--session-command' ;;
				esac
				next
			done; return
		done; return
	}
	loops
	unset -f go is next loops
}
export -f args_rewrite


cat <<'EOF' >"$patch"
#!/data/data/com.termux/files/usr/bin/bash
set -e -u
args_rewrite "$@"
#printf '%s\n' "${args[@]}"
#read
exec "$PREFIX/bin/proot" "${args[@]}"
EOF


exec proot-distro login  --user "$LUSER"  "$DISTRO" "$@"


# find_key() {
# 	local -n arr="${1:?Missing array name.}"; shift
# 	local match="${1:?Missing match.}"; shift
# 	for i in "${!arr[@]}"; do
# 		local -n v="arr[$i]"
# 		#printf '%s = %s\n' "$i" "$v"
# 		if [[ "$v" == "$match" ]]; then
# 			ni=$((${#arr[@]} - i - 2))
# 			return 0
# 		fi
# 	done
# 	return 1
# }
# export -f find_key
# 
# 
# unset_last_n() {
# 	local -n arr="${1:?Missing array name.}"; shift
# 	local from="${1:?Missing negative start index.}"; shift
# 	for t in $(seq $from -1); do unset arr[-1]; done
# }
# export -f unset_last_n


#args=( "\$@" )
#find_key  args  '/bin/su'
#last=( "\${args[@]: ni}" )
#unset_last_n  args  ni
#args+=( ${exp[@]}  /bin/su -m "\$user" --session-command ${LCMD[@]} )
#args+=( /bin/su -m "\$user" --session-command ${LCMD[@]} )
#[[ -v PROOT_DEBUG ]] && printf '%s\n' "\$PREFIX/bin/proot"
