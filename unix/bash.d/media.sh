
alias ffmpeg='ffmpeg -hide_banner'
alias ffprobe='ffprobe -hide_banner'

alias mpa='mpv --no-video "--ytdl-format=bestaudio[ext=m4a]/best[ext=mp4]/best"'

alias youtube='ytfzf -t -s'
alias yt-audio='yt-dlp -f bestaudio --extract-audio -o "./%(title)s.%(ext)s"'


mpvs() { streamlink -p mpv "$1" "${2:-best}"; }

brainaural() {
    local args=(
        mod0=19  car0=436  noi0=10  iso0=33  bin0=100  bil0=50  fm0=0  lvl0=50
        mod1=48  car1=190  noi1=10  iso1=33  bin1=100  bil1=50  fm1=0  lvl1=50
    )
    local IFS='&'
    xdg-open "https://brainaural.com/play.php?${args[*]}"
}
