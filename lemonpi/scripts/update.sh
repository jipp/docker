#!/bin/sh

echo "\n\n-> docker: lemonpi"
cd /home/pi/docker/lemonpi && docker compose pull && docker compose up -d

echo "\n\n-> docker: esphome"
cd /home/pi/docker/esphome && docker compose pull

echo "\n\n-> docker: certbot"
cd /home/pi/docker/certbot && docker compose pull

echo "\n\n-> docker: clean-up"
docker system prune -f
docker image ls
docker ps -a


echo "\n\n-> apt: update"
sudo apt update && sudo apt list --upgradable && sudo apt upgrade

echo "\n\n-> apt: clean-up"
sudo apt autoremove -y

