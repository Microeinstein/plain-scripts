#!/bin/bash

echo "javascript:eval(atob('$(minify --js-keep-var-names "$@" | base64 -w0)'))"
