#!/bin/bash
set -e

if [ $# -eq 0 ]; then
    /cat help.txt
fi

exec "$@"
