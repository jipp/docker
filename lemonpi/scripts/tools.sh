#!/bin/bash

RESET="0"

RED="31"
GREEN="32"
YELLOW="33"
BLUE="34"
MAGENTA="35"

BOLD="1"
UNDERLINE="4"

END="\e[${RESET}m"
SECTION="\e[${UNDERLINE};${MAGENTA}m"
TOPIC="\e[${UNDERLINE};${GREEN}m"
CONTENT="\e[${BOLD};${YELLOW}m"

FOLDER="/home/$USER/docker"

mc_user () {
	MCUSER=`docker exec $1 rcon-cli list | cut -d' ' -f3`

	return $MCUSER
}

docker_update () {
	echo -e "\n\n${SECTION}docker${END}"

	echo -e "\n-> ${TOPIC}docker:${END} ${CONTENT}lemonpi pull${END}"
	cd $FOLDER/lemonpi && docker compose pull

	echo -e "\n-> ${TOPIC}docker:${END} ${CONTENT}lemonpi up${END}"
	for i in minecraft minecraft-small
	do
		mc_user $i
		RES=$?
		if [ $RES -eq 0 ]; then
			cd $FOLDER/lemonpi && docker compose up -d $i
		fi
	done
	cd $FOLDER/lemonpi && docker compose up -d nginx homeassistant octoprint minecraft-backup minecraft-small-backup -d

	echo -e "\n-> ${TOPIC}docker:${END} ${CONTENT}prune${END}"
	docker system prune -f

	echo -e "\n-> ${TOPIC}docker:${END} ${CONTENT}repositories${END}"
	docker image ls

	echo -e "\n-> ${TOPIC}docker:${END} ${CONTENT}status${END}"
	docker ps -a
}

certbot () {
	if [ $# -eq 0 ]; then
		COMMAND="renew --dry-run"
	else
		COMMAND=$*
	fi

	echo -e "\n\n${SECTION}certbot${END}: $COMMAND"

	echo -e "\n-> ${TOPIC}certbot:${END} ${CONTENT}renew Certificate${END}"
	cd $FOLDER/lemonpi && docker compose run --rm -p 8080:80 certbot $COMMAND
#	cd $FOLDER/lemonpi && docker compose run --rm -p 8080:80 certbot renew --dry-run
#	cd $FOLDER/lemonpi && docker compose run --rm -p 8080:80 certbot renew
#	cd $FOLDER/lemonpi && docker compose run --rm -p 8080:80 certbot certonly --dry-run --standalone --agree-tos --expand --preferred-challenges=http --email wolfgang.keller@wobilix.de --domain dyndns.wobilix.de
#	cd $FOLDER/lemonpi && docker compose run --rm -p 8080:80 certbot certonly --standalone --agree-tos --expand --preferred-challenges=http --email wolfgang.keller@wobilix.de --domain dyndns.wobilix.de

	echo -e "\n-> ${TOPIC}certbot:${END} ${CONTENT}reload nginx${END}"
	cd $FOLDER/lemonpi && docker compose exec -it nginx nginx -s reload

	echo -e "\n-> ${TOPIC}certbot:${END} ${CONTENT}clean-up${END}"
	cd $FOLDER/lemonpi && docker compose down certbot
}

esphome () {
	if [ $# -eq 0 ]; then
		COMMAND="config"
	else
		COMMAND=$*
	fi

   echo -e "\n\n${SECTION}esphome${END}: $COMMAND"

	echo -e "\n-> ${TOPIC}esphome:${END} ${CONTENT}basement${END}"
	cd $FOLDER/lemonpi && docker compose run --rm esphome $COMMAND basement.yaml

	echo -e "\n-> ${TOPIC}esphome:${END} ${CONTENT}livingroom${END}"
	cd $FOLDER/lemonpi && docker compose run --rm esphome $COMMAND livingroom.yaml
}

apt_update () {
	echo -e "\n\n${SECTION}apt${END}"

	echo -e "\n-> ${TOPIC}apt:${END} ${CONTENT}update${END}"
	sudo apt update && sudo apt list --upgradable && sudo apt upgrade

	echo -e "\n-> ${TOPIC}apt:${END} ${CONTENT}clean-up${END}"
	sudo apt autoremove -y
}

health () {
	echo -e "\n\n${SECTION}health${END}"

	echo -e "\n-> ${TOPIC}health:${END} ${CONTENT}temperature${END}"
	vcgencmd measure_temp

	echo -e "\n-> ${TOPIC}health:${END} ${CONTENT}df${END}"
	df -h

	echo -e "\n-> ${TOPIC}health:${END} ${CONTENT}dmesg${END}"
	dmesg -e -l emerg --level=alert,crit,err,warn,notice
}

case $1 in
	update)
		apt_update
		;;
	docker)
		docker_update
		;;
	health)
		health
		;;
	certbot)
		shift
		certbot $*
		;;
	esphome)
		shift
		esphome $*
		;;
	*)
      echo -e "\n$0 [update|docker|health|certbot|esphome]"
      ;;
esac

echo -e "\n"
