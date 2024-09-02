#!/bin/sh

#docker compose -f certbot.yml run certbot certonly -d dyndns.wobilix.de --manual --preferred-challenges dns --email wolfgang.keller@wobilix.de --dry-run
#docker compose -f certbot.yml run certbot certonly -d dyndns.wobilix.de --manual --preferred-challenges dns --email wolfgang.keller@wobilix.de

../docker.sh pull
../docker.sh prune
../docker.sh up
../docker.sh rm -f

FILE=.env
RESULT=$(grep "dry-run" $FILE | grep -v "#" | wc -l)

if [ $RESULT -eq 0 ]; then
	echo "copy"
	sudo cp -rL /docker/certbot/etc/letsencrypt/live/dyndns.wobilix.de /docker/nginx/conf.d
        echo "copy done"
	docker restart nginx
fi
