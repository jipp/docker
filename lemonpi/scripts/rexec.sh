#!/bin/sh

USERNAME="woke"

ping -c 1 dyndns.wobilix.de > /dev/null 2>&1

if [ $? -eq 0 ]
then
	echo logging in
	ssh $USERNAME@dyndns.wobilix.de -p 1322 /home/$USERNAME/docker/lemonpi/scripts/minecraft.sh
else
	echo server is not reachable
fi 
