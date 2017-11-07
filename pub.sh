#!/bin/sh

hugo && rsync -avz --delete ./public/ nagedk@106.15.0.240:~/blog/
