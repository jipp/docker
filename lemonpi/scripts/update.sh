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

User () {
	MCUSER=`docker exec $1 rcon-cli list | cut -d' ' -f3`

	return $MCUSER
}

Docker () {
	echo -e "\n\n${SECTION}docker${END}"

	echo -e "\n-> ${TOPIC}docker:${END} ${CONTENT}lemonpi pull${END}"
	cd /home/$USER/docker/lemonpi && docker compose pull

	echo -e "\n-> ${TOPIC}docker:${END} ${CONTENT}lemonpi up${END}"
	for i in minecraft minecraft-small
	do
		User $i
		RES=$?
		if [ $RES -eq 0 ]; then
			docker compose up -d $i
		fi
	done
	docker compose up -d nginx homeassistant octoprint minecraft-backup -d

	echo -e "\n-> ${TOPIC}docker:${END} ${CONTENT}esphome pull${END}"
	cd /home/$USER/docker/esphome && docker compose pull

	echo -e "\n-> ${TOPIC}docker:${END} ${CONTENT}certbot pull${END}"
	cd /home/$USER/docker/certbot && docker compose pull

	echo -e "\n-> ${TOPIC}docker:${END} ${CONTENT}prune${END}"
	docker system prune -f

	echo -e "\n-> ${TOPIC}docker:${END} ${CONTENT}repositories${END}"
	docker image ls

	echo -e "\n-> ${TOPIC}docker:${END} ${CONTENT}status${END}"
	docker ps -a
}

Apt () {
	echo -e "\n\n${SECTION}apt${END}"

	echo -e "\n-> ${TOPIC}apt:${END} ${CONTENT}update${END}"
	sudo apt update && sudo apt list --upgradable && sudo apt upgrade

	echo -e "\n-> ${TOPIC}apt:${END} ${CONTENT}clean-up${END}"
	sudo apt autoremove -y
}

Health () {
	echo -e "\n\n${SECTION}health${END}"

	echo -e "\n-> ${TOPIC}health:${END} ${CONTENT}dmesg${END}"
	dmesg -e -l emerg --level=alert,crit,err,warn,notice
}

Apt
Docker
Health

echo -e "\n"
