#!/bin/bash
set -e

FILE=/etc/os-release

if [ -f "$FILE" ]; then
    source /etc/os-release
    echo $ID $VERSION_ID
    echo
fi

if [ $# -eq 0 ]; then
    cat help.txt
fi

exec "$@"
