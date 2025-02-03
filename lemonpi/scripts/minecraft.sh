#!/bin/bash

Health () {
	echo Server: $1

	STATUS=`/usr/bin/docker inspect --format='{{.State.Health.Status}}' $1`

	if [ $STATUS != "healthy" ]
	then
		echo restarting ...
		/usr/bin/docker restart $1
		echo -e "done\n"
	else
		docker exec -i $1 rcon-cli list
		echo -e "nothing to be done\n"
	fi
}

for i in minecraft minecraft-small
do
	Health $i
done
