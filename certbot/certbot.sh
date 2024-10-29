#!/bin/sh

docker compose pull
docker system prune -f
docker compose up
docker compose rm -f

FILE=.env
RESULT=$(grep "dry-run" $FILE | grep -v "#" | wc -l)

if [ $RESULT -eq 0 ]; then
	echo "copy"
	sudo cp -rL /docker/certbot/etc/letsencrypt/live/dyndns.wobilix.de /docker/nginx/conf.d
        echo "copy done"
	docker restart nginx
fi
