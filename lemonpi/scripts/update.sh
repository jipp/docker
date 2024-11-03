#!/bin/sh

MCUSER=`docker exec minecraft rcon-cli list | cut -d' ' -f3`

echo "\n\n-> docker: lemonpi"
cd /home/$USER/docker/lemonpi && docker compose pull

if [ $MCUSER -eq 0 ]
then
	docker compose up -d
else
	echo skipping minecraft
	docker compose up -d nginx homeassistant octoprint -d
fi

echo "\n\n-> docker: esphome"
cd /home/$USER/docker/esphome && docker compose pull

echo "\n\n-> docker: certbot"
cd /home/$USER/docker/certbot && docker compose pull

echo "\n\n-> docker: clean-up"
docker system prune -f
docker image ls
docker ps -a


echo "\n\n-> apt: update"
sudo apt update && sudo apt list --upgradable && sudo apt upgrade

echo "\n\n-> apt: clean-up"
sudo apt autoremove -y

