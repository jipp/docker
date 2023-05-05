#!/bin/sh

../docker.sh pull
../docker.sh prune
../docker.sh run
../docker.sh rm

FILE=$(../docker.sh list)
RESULT=$(grep "dry-run" $FILE | grep -v "#" | wc -l)

if [ $RESULT -eq 0 ]; then
	echo "copy"
	sudo cp -r /docker/certbot/etc/letsencrypt/archive/dyndns.wobilix.de /docker/homeassistant/config
fi
