#!/bin/sh

ping -c 1 dyndns.wobilix.de > /dev/null 2>&1

if [ $? -eq 0 ]
then
	echo logging in
	ssh pi@dyndns.wobilix.de -p 1322 /home/pi/docker/lemonpi/scripts/minecraft.sh
else
	echo server is not reachable
fi 
