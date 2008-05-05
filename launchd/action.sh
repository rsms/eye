#!/bin/sh
env > /Users/rasmus/src/image-hg-repo/env
echo $@ > /Users/rasmus/src/image-hg-repo/args
/usr/local/bin/hg -v st > /Users/rasmus/src/image-hg-repo/status