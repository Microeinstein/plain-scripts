## 📁 misc

Various scripts that don't fit in other categories for their purposes.

<br>

### 🧹 gen-gitignore.sh

Automatic `.gitignore` generation using well-known [templates](https://github.com/toptal/gitignore) and toptal's free API endpoint.

Extra dependencies — `wget` (toptal.com)

<br>

### 🧮 partcalc.py

Size calculator for partition schemes with recursive factors and fixed amounts.

Protip — Always sort the partitions in order from largest to smallest. This is
because it can be extremely tedious to extend a partition to the left, as it
requires copying ALL data and then extend to the right.

Usage — `partcalc.py [-B|--help]  <TOTALSIZE>  ...[<NAME> <SIZE>]  <NAME> <SIZE>`

Extra dependencies — none

<br>

### ▶️ clap.sh

**C**ommand **L**ine medi**A** **P**laylist — provides an interactive music listening experience for the terminal. Every playlist is stored directly into the script.

Extra dependencies — `dialog` `mpv` `yt-dlp` `wget` `hq`

<br>

### 🍅 tomato.sh

Terminal tomato timer with configurable periods, notifications and sounds.

Extra dependencies — `bc` `glib2`<br>
Optional dependencies — `sound-theme-freedesktop` `vorbis-tools` `papirus-icon-theme`

<br>

### 🔨 build.latex.sh

Latex build tool intended for use in Kate. Some features:
- compiles frontispiece (`frontespizio`), bibliography
- extra parameters (`draft`, `final`, any; through `\def\docopts{...}`)
- fixes references
- detects and skims warnings
- project zipping
- cache clearing

Usage — `build.latex.sh <bake [docopts] | zip | clean | clean_more | reset>`

Extra dependencies — `procps-ng` `grep` `sed` `lualatex` `biber` `xdg-open`
