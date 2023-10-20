## 📁 unix/desktop

Utilities for unix desktops.

<br>

## 🧼 clean-keyboard.sh

Disable your keyboard and touchpad for some seconds, to clean your laptop without shutting it down / summoning a deamon. Other input devices are not disabled (mouse, pen, touchscreen, ...).

Usage — `clean-keyboard.sh [SECONDS]`

Extra dependencies — `xinput` `grep`

<br>

## 🖥 desktop-session.sh

Launch commonly used applications and services at login, plus other tweaks — can be customized for each DE. Installation must be done through `.desktop` entries in `~/.config/autostart/` (or KDE settings).

Usage — (started from desktop environment)

Extra dependencies — (see started apps) `xorg-xmodmap` `systemd` `grep`

<br>

## 🗃 dir-root-switch.sh

On Dolphin file manager, jump to the corresponding location of the current directory in a secondary root.<br>
(ex: `/usr` ⟷ `/run/media/user/backup/usr`)

Usage — (context menu handler)

Extra dependencies — `dolphin` `qt5-tools` `xdotool` `grep`

<br>

## ⚡️ electron-hwaccel.sh

Apply lots of chromium flags to enable or improve hardware acceleration on many electron apps. Global configuration is written to `~/.config/gpuflags.sh`. This is done by copying its `.desktop` launcher and wrapping the executable in `~/.local/bin/`.

Usage — `electron-hwaccel.sh <BIN> <TITLE> [BIN-ALT] [DESKTOP]`

Examples (notice the dot to avoid wrong matches):<br>
• `electron-hwaccel.sh  codium VSCodium  -  codium.`<br>
• `electron-hwaccel.sh  codium VSCodium  -  codium-uri-handler.`

Extra dependencies — none

<br>

## 🪟 move-to-desktop.sh

Move _yourself_ to a virtual desktop specified as 2D relative coordinates. Intended for usage with [easystroke](https://aur.archlinux.org/packages/easystroke) (unmantained but still working) or other pointer gestures tools.

Usage — `move-to-desktop.sh <±X> <±Y>`

Extra dependencies — `xdotool`

<br>

## 🗂 open-same-window.sh

With Dolphin and KWrite, open paths in new tabs **always** using the last opened window on the current desktop, spawning a new one otherwise.

Usage:
1. symlink this file from `~/.local/bin/<EXE>` thus replacing `$0`
2. create appropriate `.desktop` launchers (edit existing ones with KDE menu editor, or do in other ways)

Extra dependencies — `dolphin` `kwrite` `qt5-tools` `xdotool` `grep`

<br>

## ⌨️ retype.sh

Write every line from a text file in whatever application, as if the user were typing them. Useful for software blocking copy-paste functionality.

Usage — `retype.sh <FILE>`

Extra dependencies — `xdotool`

<br>

## 📹 screencapture-hwaccel.sh

Record your screen at 60fps through the framebuffer (`kmsgrab`) and use the GPU to encode in H264 (intel VAAPI). Sound is also recorded from the default output device (pulseaudio monitor) but on a different process to workaround [this bug](https://trac.ffmpeg.org/ticket/8377).

Sound effects are played before and after recording.

Usage — `screencapture-hwaccel.sh <start|stop>` (best with global shortcuts)

Extra dependencies — `ffmpeg` `oxygen-sounds` `xclip` `grep`

<br>

## ↪️ shortcut-creator.sh

Send anything to your desktop as `.desktop` shortcut icons, which behave mostly like on Windows. Real symlinks make other software work with wrong paths, and KDE shortcut widgets are... _well, widgets_.

KDE bookmarks are looked for appropriate icons and labels.

Usage — `shortcut-creator.sh [URL]..` (best with context menu handler)

Extra dependencies — `xdg-utils`

<br>

## 🍷 wine-envs.sh

Perform various operations before and after Windows executables are run:
- if the program is a game:
    - symlink all [dgVoodoo2](http://dege.freeweb.hu/dgVoodoo2/dgVoodoo2/)' dlls in its folder (no overwrite) and remove them afterwards
- force Vulkan to use the discrete \[optimus\] graphic card (nvidia)
    - note: DxVK is strongly suggested — [version 1.10.3](https://github.com/doitsujin/dxvk/releases/tag/v1.10.3) is the last compatible one with Vulkan API level 1.2

Usage — `wine-envs.sh [COMMAND]..`

To integrate in Q4Wine, use the following execution template string for each prefix (no newlines):
```py
%CONSOLE_BIN% %CONSOLE_ARGS% %ENV_BIN% %ENV_ARGS% /bin/bash -c "%WORK_DIR% source ~/.local/scripts/unix/desktop/wine-envs.sh  %SET_NICE% %WINE_BIN% %VIRTUAL_DESKTOP% %PROGRAM_BIN% %PROGRAM_ARGS% 2>&1 "
```

Extra dependencies — `grep` (dgVoodoo2)

<br>

## 👾 x11-add-lowres.sh

Add smaller screen resolutions that some drivers may not load, on all outputs. This is probably due to the screen actually supporting only its native resolution — to make this work, the GPU is asked to perform some adaptation (`Center` mode is set, so there will be black borders and no upscaling).

Useful with very old wine games that require this resolutions.

Usage — `x11-add-lowres.sh`

Extra dependencies — `xorg-xrandr` `libxcvt` 
