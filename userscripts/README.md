## 📁 userscripts

Javascript utilities to improve browsing experience or just hack around. Note: if the `==UserScript==` header is present, the script should be loaded with an appropriate browser extension (ex. Greasemonkey).

<br>

### 🔖 embed-js.sh

Converts from javascript files to browser bookmarks through base64 encoding.

Usage — `embed-js.sh userscript.js`

Extra dependencies — `minify`

<br>

### ✍️ download-jamboard.js

On a Google Jamboard whiteboard, adds a button in the context menu to download all the pages as multiple PNG files. Since getting the original canvas from a different network context [is not allowed](https://developer.mozilla.org/en-US/docs/Web/API/HTMLCanvasElement/toDataURL#exceptions), all the elements are **redrawn by hand** — not all elements are supported (see console).

Extra dependencies — none

<br>

### ❓ univr-questionari.js

On UniVR course surveys, rewrites and simplify most questions and answers texts — by now, some of them may have changed.

Extra dependencies — none
