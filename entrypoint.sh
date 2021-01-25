#!/bin/bash
set -e

if [ $# -eq 0 ]; then
    echo "command missing"
fi

exec "$@"
