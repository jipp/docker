#!/bin/sh

STATUS=`/usr/bin/docker inspect --format='{{.State.Health.Status}}' minecraft`

echo minecraft server status: $STATUS

if [ $STATUS != "healthy" ]
then
	echo restarting ...
	/usr/bin/docker restart minecraft
	echo done
else
	echo nothing to be done
        /usr/bin/docker exec minecraft rcon-cli list
        /usr/bin/docker exec minecraft rcon-cli banlist
fi
