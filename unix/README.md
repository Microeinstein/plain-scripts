## 📁 unix

Utilities for unix environments — tested on Linux.

<br>

## 🔄 convert-tools.sh

Provides various convertion functions for some kinds of media — pictures, audio, video, documents. Paths of resulting files will be copied to clipboard as `text/uri-list`.

It can be sourced from `.bashrc` to set convenient wrappers for each action.

Usage — `OPT1="a" OPT2="b" ...  convert-tools.sh <ACTION> [FILE]...`

Extra dependencies — `xclip` `grep`<br>
Optional dependencies — `ffmpeg` `mpv` `imagemagick` `poppler` `ghostscript` `enscript`

<br>

## 🔦 lsusb-cust.sh

Pretty-printed table with more information than standard `lsusb` — enumeration is manually performed on `/sys/bus/usb/devices/`.

Extra dependencies — none

<br>

## 💾 make-backups.squashfs.sh

Build SquashFS images with Zstandard compression for backup purposes; most garbage will be automatically ignored. Profiles are stored within the script, which must be sourced. It's _intended_ to be edited for profile adding and removal.

Usage (example):
```console
$ source make-backups.squashfs.sh
$ from_running
$ to_workdir
$ bkp_root
```

Extra dependencies — `squashfs-tools`

Some comparison of archive formats:

|                                                                          | SquashFS | tar.gz  |   ISO    |   zip    |
|:------------------------------------------------------------------------ |:--------:|:-------:|:--------:|:--------:|
| **file deduplication**                                                   | **yes**  |   no    |    no    |    no    |
| **parallel build**                                                       | **yes**  |   no    |    no    |    no    |
| **mountable**                                                            | **yes**  |   no    | **yes**  |    no    |
| **readable _by kernel_**<br>(no external tools)   | **yes**  |   no    |    **yes**    |    no    |
| **tree walking**                                                         | **fast** |  slow   | **fast** | **fast** |
| [**solid compression**](https://en.wikipedia.org/wiki/Solid_compression) | **yes**  | **yes** |   n/a    |    no    |
| **symlinks & perms**                                                     | **yes**  | **yes** |    no    |    no    |
| **extended attributes**                                                     |  no  | **yes** |    no    |    no    |
| **editable**                                                             |    no    | **yes** |    no    | **yes**  |

Note: [DwarFS](https://github.com/mhx/dwarfs#comparison) is under consideration — in some contexts it appears to have compression times **6 times faster** than SquashFS.

<br>

## 📦 mesa20.sh

Downloads and installs Mesa 20.1.4 from [ALA](https://archive.archlinux.org) to `/opt` for ArchLinux. In my experience, this specific version of Mesa is the last compatible one with Wine games on older Intel HD Graphics cards.

Extra dependencies — `curl` `grep`

<br>

## 📶 monitor-connectivity.sh

Reads for `Connectivity` events and prints whether the system is connected to a network.

Extra dependencies — `dbus` `NetworkManager` `grep`

<br>

## 🌳 multimc-install-optifine.sh

Fakes a standard `.minecraft` installation where the [OptiFine](https://optifine.net) installer will run _interactively_, then moves the real mod and its `launchwrapper` into a ~~MultiMC~~ [PrismLauncher](https://prismlauncher.org/) instance of choice.

Usage (example):
```bash
# (setup and run a Minecraft instance once)
$ cd ~/.local/share/PrismLauncher/instances/1.13.2
$ multimc-install-optifine.sh  OptiFine_1.13.2_whatever.jar
# (follow the instructions)
# (reload your instance)
```

Extra dependencies — `unzip` `java` `grep`

<br>

## 📡 music-queue.sh

Interfacing with [MPRIS](https://wiki.archlinux.org/title/MPRIS), save basic tags of your currently playing songs to a markdown file at a given line — very useful for queuing web radio tracks for later retrieval, while keeping my attention span untouched. Checks for duplicates.

Output format — ```- [ ] `url` artist - title (album)```

Usage — `music-queue.sh` (best with desktop widget / global shortcut)

Extra dependencies — `playerctl` `grep` (compatible players, even KDE connect)

<br>

## 🔗 sed-symlinks.sh

Edit multiple symbolic links targets with sed — intended for quick repairing.

Usage — `sed-symlinks.sh <SED-ARGS> -- <LINK> [LINK]..` (`--` is mandatory)

Extra dependencies — `sed`

<br>

## 🔌 startarch.sh

Launch userland ArchLinux using Termux' [proot-distro](https://github.com/termux/proot-distro) with some enhancements:

- login with specific user via `LUSER` env var

- exports some environment variables into the rootfs, namely `TERM`  `TERMUX_VERSION`  `SSH_CLIENT` — done via profile script `etc/profile.d/termux-proot-ext.sh`

- rewrites `su -c` into `su --session-command` to allow job control into the new shell — done by wrapping real `proot` executable

Usage — `LUSER=nonroot  [exec] startarch.sh [COMMAND]`

- `~/.shortcuts/Minecraft` — example
    ```bash
    #!/data/data/com.termux/files/usr/bin/bash
    export LUSER=user
    exec tmux new -s mc ~/startarch -- 'cd /w/mc; ./launch.sh'
    ```

Extra dependencies — `proot-distro` (Termux)

<br>

## 🧊 vdi-mount.sh

Mount VirtualBox Virtual Disk Images on Linux, by setting up a loop device skipping the initial header.

Usage — `vdi-mount.sh <DISK.VDI>`

Extra dependencies — `virtualbox` `util-linux` `grep`

<br>

## 💿 virtual-iso.sh

Setup loop devices with ISO images and mount them _without root_ in a single command — the same logic applies in reverse.

Usage — `virtual-iso.sh <open|close> <IMAGE.iso> [UDISKS OPTIONS]..`

Extra dependencies — `udisks2` `util-linux`<br>
Optional dependencies — `xdg-utils`

<br>

## 🍢 vmusb.sh

Passthrough a physical USB device to a running virtual machine that's currently operating with libvirt. The same command toggles attach/detach.

Usage — `vmusb.sh [--help]  <VENDOR> <PRODUCT>  <VM>`

Extra dependencies — `libvirt` (and running VM)
