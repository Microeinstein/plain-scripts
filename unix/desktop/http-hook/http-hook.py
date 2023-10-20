#!/usr/bin/env python3

# Based on: dunstify mpv wget curl firefox chromium

import os
import sys
import io
import re
import subprocess
import shlex
import time
import logging
import traceback
import time


# CURR_DIR = os.path.abspath(os.path.dirname(__file__))
CURR_LOG = os.path.expanduser('~/.cache/http_hook.log')

logging.basicConfig(
    filename=CURR_LOG, level=logging.ERROR,
    format='%(asctime)s %(levelname)s %(name)s %(message)s'
)
logger = logging.getLogger(__name__)



HOOKS = []

def hook(cls):
    HOOKS.append(cls)
    
    def c(r):
        return re.compile(r) if isinstance(r, str) else r
    
    if not hasattr(cls, 'filters'):
        cls.filters = [r".+"]
    cls.filters = [c(f) for f in cls.filters]
    
    if not hasattr(cls, 'hints'):
        cls.hints = []
    cls.hints = [
        (
            (c(h[0]), h[1])
            if isinstance(h, tuple) else
            (c(h))
        ) for h in cls.hints
    ]
    
    def matches(cls, url):
        return any(f.match(url) for f in cls.filters)
    def hintsum(cls, url):
        def weight(r):
            m = r.match(url)
            if not m:
                return 0
            s = m.span()
            return (s[1] - s[0]) / len(url)
        return sum(
            (
                h[1] * weight(h[0])
                if isinstance(h, tuple) else
                weight(h)
            ) for h in cls.hints
        )
    cls.matches = classmethod(matches)
    cls.hintsum = classmethod(hintsum)
    cls.apply = classmethod(cls.apply)
    
    if not hasattr(cls, 'label'):
        cls.label = cls.__name__
    if not hasattr(cls, 'btnlabel'):
        cls.btnlabel = cls.label
    
    return cls


def launch_simple(cmd, **kwargs) -> bool:
    print("args:", cmd, file=sys.stderr)
    cmd = shlex.split(cmd)
    return subprocess.Popen(cmd, **kwargs)

def launch_capture(cmd, *args, **kwargs):
    print("args:", cmd, file=sys.stderr)
    cmd = shlex.split(cmd)
    return subprocess.run(cmd, *args, capture_output=True, **kwargs)



class Notification:
    id = None
    appname = "HTTP Hook"
    summary = "Status"
    body = None
    urgency = "normal"
    timeout = 1.5 #seconds
    block = False
    
    
    def __call__(self, *temp_cust, **kwargs):
        for k, v in kwargs.items():
            if v is not None:
                setattr(self, k, v)
        req_id = self.id is None
        arg_id = '-p' if req_id else f'-r {self.id}'
        arg_block = '-b' if self.block else ''
        app = shlex.quote(self.appname)
        summary = shlex.quote(self.summary)
        body = shlex.quote(self.body or '')
        cmd = ' '.join([
            f"dunstify -a {app} {arg_id} -u {self.urgency} {arg_block}",
            f"-i 'filter' -t {int(self.timeout * 1000)}",
            *temp_cust,
            summary,
            body
        ])
        logger.debug(cmd)
        proc = launch_capture(cmd)
        logger.debug(proc)
        out = proc.stdout.decode('utf8')
        if req_id:
            self.id, sep, out = out.partition('\n')
        logger.debug(out)
        return out.strip()
    
    def close(self):
        if self.id is None:
            return
        launch_simple(f"dunstify -C {self.id}")
        #self.id = None
    
    def log(self, body):
        if self.body is None:
            self.body = ''
        return self(body=(self.body + body))
    
    def ask(self, *choices):
        self.block = True
        #self.close()
        #time.sleep(1) #required
        args = [f"-A {c[0]},{shlex.quote(c[1])}" for c in choices]
        logger.debug(args)
        ret = self(*args)
        self.block = False
        return ret


class Youtube:
    filters = [
        r"^https?:\/\/(?:(?:www|m)\.)?youtube\.com\/",
        r"^https?:\/\/(?:(?:www|m)\.)?youtu\.be\/"
    ]

@hook
class MPV(Youtube):
    btnlabel = "🟣"
    def apply(cls, url) -> bool:
        launch_simple(f'mpv "{url}"')
        return True

@hook
class MPVAudio(Youtube):
    label = "MPV (audio)"
    btnlabel = "🎵"
    def apply(cls, url) -> bool:
        launch_simple(f'konsole -e mpv --no-video "--ytdl-format=bestaudio[ext=m4a]/best[ext=mp4]/best" "{url}"')
        return True

@hook
class Zoom:
    filters = [r"^https?:\/\/([0-9A-Za-z_\-]+\.)?zoom\.us\/j\/([0-9]+)"]
    btnlabel = "🎦"
    def apply(cls, url) -> bool:
        m = cls.filters[0].match(url)
        if not m:
            return False
        launch_simple(f'zoom --url="zoommtg://{m.group(1)}zoom.us/join?action=join&confno={m.group(2)}"')
        return True

"""
@hook
class FreeTube(Youtube):
    btnlabel = "🇳🇱"
    def apply(cls, url) -> bool:
        launch_simple(f'freetube "{url}"')
        return True
"""

class Browser:
    # filters = [r"^https?:\/\/.+"]
    # can be a local HTML file
    pass

# @hook
# class Falkon(Browser):
#     btnlabel = "🦅"
#     def apply(cls, url) -> bool:
#         launch_simple(f'falkon "{url}"')
#         return True


@hook
class Firefox(Browser):
    btnlabel = "🦊"
    def apply(cls, url) -> bool:
        launch_simple(f'firefox "{url}"')
        return True

@hook
class FirefoxPrivate(Browser):
    label = "Firefox (private)"
    btnlabel = "🟧"
    def apply(cls, url) -> bool:
        launch_simple(f'firefox --private-window "{url}"')
        return True

"""
@hook
class Chromium(Browser):
    btnlabel = "🔘"
    def apply(cls, url) -> bool:
        launch_simple(f'chromium "{url}"')
        return True
"""

@hook
class ChromiumPrivate(Browser):
    label = "Chromium (private)"
    btnlabel = "🟦"
    def apply(cls, url) -> bool:
        launch_simple(f'chromium --incognito "{url}"')
        return True


@hook
class Download:
    filters = [r"^(?!file)[^/]+?:\/\/"]
    hints = [r"^https?:\/\/cdn\.discordapp\.com\/attachments\/"]
    btnlabel = "💾"
    def apply(cls, url) -> bool:
        launch_simple(f'konsole -e wget --content-disposition --no-use-server-timestamps --quiet --show-progress --continue -P /mnt/files/Downloads -o /tmp/wget.log "{url}"')
        return True


@hook
class Clipboard:
    filters = [r"^(?!file)[^/]+?:\/\/"]
    hints = [(r".+", -2)]
    btnlabel = "📋"
    label = "Clipboard (text)"
    def apply(cls, url) -> bool:
        launch_simple('xclip -selection clipboard', stdin=subprocess.PIPE, text=True).communicate(url)
        return True

@hook
class ClipboardImage(Clipboard):
    hints = [r"^https?:\/\/cdn\.discordapp\.com\/attachments\/.+\.(?:jpg|jpeg|png|bmp)"]
    btnlabel = "📸"
    label = "Clipboard (image)"
    def apply(cls, url) -> bool:
        return subprocess.run(f"""\
            fname="$(curl -L --head -w '%{{url_effective}}' '{url}' 2>/dev/null | tail -n1)";
            fname="/tmp/$(basename "$fname")";
            curl '{url}' > "$fname";
            xclip -r -t text/uri-list -selection clipboard <<<'file://'"$fname";
            # doesn't work...
            # xclip -r -t application/x-kde-cutselection -selection clipboard <<<'1';
        """, shell=True)


# print() automatically writes in the body of the notification

def main(args, notif):
    url = args[1]
    print("url:", url, file=sys.stderr)
    urldisp = url
    spl = re.match(r"^(.+?:\/\/.+?\/)(.*\/)?(.+)$", url)
    if spl:
        urldisp = f"{spl.group(1)}...\n{spl.group(3)}"
    notif(summary=urldisp)
    matched = {h.__name__: h for h in HOOKS if h.matches(url)}
    print("<i>Waiting for choice...</i>")
    while True:
        logger.debug(matched)
        if not matched:
            print("No matches!")
            return 1
        matched = dict(sorted(
            matched.items(),
            key=lambda item: -item[1].hintsum(url)
        ))
        matched |= {h.__name__: h for h in HOOKS if h not in matched.values()}
        logger.debug(matched)
        layout = [(v[0], v[1].btnlabel) for v in matched.items()]
        logger.debug(layout)
        choice = notif.ask(*layout)
        if not choice:  # unknown error, open first
            choice = "1"
        if choice == "2":
            print("Manual interruption", file=sys.stderr)
            return 0
        if choice == "1":
            choice = next(iter(matched.keys()))
        hook = matched[choice]
        print("Hook:", hook.label, end='')
        if hook.apply(url):
            break
        print(" ...<b>failed</b>")
        del matched[choice]
    print(" ...<b>success</b>")
    
if __name__ == '__main__':
    # time.sleep(15)
    logger.info(sys.argv)
    notif = Notification()
    oldprint = print
    def magic(*args, **kwargs):
        if 'file' not in kwargs:
            with io.StringIO() as s:
                oldprint(*args, file=s, **kwargs)
                notif.log(s.getvalue())
        oldprint(*args, **kwargs)
    print = magic
    ret = 1
    try:
        ret = main(sys.argv, notif) or 0
    except RuntimeError as e:
        #traceback.print_exc(file=CURR_LOG)
        logger.error(exc_info=e)
        print('\nerror:', e.__class__.__name__)
        raise e
    finally:
        pass
    sys.exit(ret)
