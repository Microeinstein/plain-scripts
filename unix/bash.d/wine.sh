
winc() (
	WINEPREFIX="${1:?Missing prefix name}"; shift
	WINEARCH="${1:?Missing architecture}"; shift
	
	if [[ "$WINEPREFIX" != "." ]]; then
		WINEPREFIX="$HOME/.local/share/wineprefixes/$WINEPREFIX"
		echo "prefix: $WINEPREFIX"
	else
		WINEPREFIX=""
	fi
	
	if [[ "$WINEARCH" != "." ]]; then
		echo "  arch: $WINEARCH"
	else
		arch=""
	fi
	
	export WINEPREFIX WINEARCH
	"$@"
)

win() {
	local a="$1"
	local b="$2"
	shift 2
	winc "$a" "$b" "wine" "$@"
} 
