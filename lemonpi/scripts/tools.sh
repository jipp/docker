#!/bin/bash

trap ctrl_c SIGINT

RESET="0"

RED="31"
GREEN="32"
YELLOW="33"
BLUE="34"
MAGENTA="35"

BOLD="1"
UNDERLINE="4"

SECTION="\e[${UNDERLINE};${MAGENTA}m"
TOPIC="\e[${UNDERLINE};${GREEN}m"
CONTENT="\e[${BOLD};${YELLOW}m"
END="\e[${RESET}m"
OK="\e[${BOLD};${GREEN}m"
NOK="\e[${BOLD};${RED}m"

COMPOSE_FOLDER="/home/$USER/docker/lemonpi"
SRC_FOLDER="/docker"
BACKUP_FOLDER="/docker/backup"
REMOTE_USER="wolfgang.keller"
REMOTE_HOST="ds416play"
REMOTE_PORT="221"
REMOTE_FOLDER="lemonpi"

function ctrl_c() {
	echo "** Trapped CTRL-C"
	exit 1
}

validate_folder () {
	if [ ! -d "$COMPOSE_FOLDER" ]; then
		echo -e "\nFolder \"$COMPOSE_FOLDER\" does not exist!\n"
		exit 1
	fi
}

mc_user () {
	MC_USER=`docker exec $1 rcon-cli list | cut -d' ' -f3`

	return $MC_USER
}

docker_update () {
	echo -e "\n\n${SECTION}docker${END}"

	echo -e "\n-> ${TOPIC}docker:${END} ${CONTENT}pull${END}"
	cd $COMPOSE_FOLDER && docker compose pull

	echo -e "\n-> ${TOPIC}docker:${END} ${CONTENT}up${END}"
	for i in minecraft minecraft-small
	do
		mc_user $i
		RES=$?
		if [ $RES -eq 0 ]; then
			cd $COMPOSE_FOLDER && docker compose up -d $i
		fi
	done
	cd $COMPOSE_FOLDER && docker compose up -d nginx homeassistant octoprint minecraft-backup minecraft-small-backup -d

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
	cd $COMPOSE_FOLDER && docker compose run --rm -p 8080:80 certbot $COMMAND
#	cd $COMPOSE_FOLDER && docker compose run --rm -p 8080:80 certbot renew --dry-run
#	cd $COMPOSE_FOLDER && docker compose run --rm -p 8080:80 certbot renew
#	cd $COMPOSE_FOLDER && docker compose run --rm -p 8080:80 certbot certonly --dry-run --standalone --agree-tos --expand --preferred-challenges=http --email wolfgang.keller@wobilix.de --domain dyndns.wobilix.de
#	cd $COMPOSE_FOLDER && docker compose run --rm -p 8080:80 certbot certonly --standalone --agree-tos --expand --preferred-challenges=http --email wolfgang.keller@wobilix.de --domain dyndns.wobilix.de

	echo -e "\n-> ${TOPIC}certbot:${END} ${CONTENT}reload nginx${END}"
	cd $COMPOSE_FOLDER && docker compose exec -it nginx nginx -s reload

	echo -e "\n-> ${TOPIC}certbot:${END} ${CONTENT}clean-up${END}"
	cd $COMPOSE_FOLDER && docker compose down certbot
}

esphome () {
	if [ $# -eq 0 ]; then
		COMMAND="config"
	else
		COMMAND=$*
	fi

   echo -e "\n\n${SECTION}esphome${END}: $COMMAND"

	echo -e "\n-> ${TOPIC}esphome:${END} ${CONTENT}basement${END}"
	cd $COMPOSE_FOLDER && docker compose run --rm esphome $COMMAND basement.yaml

	echo -e "\n-> ${TOPIC}esphome:${END} ${CONTENT}livingroom${END}"
	cd $COMPOSE_FOLDER && docker compose run --rm esphome $COMMAND livingroom.yaml
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

backup () {
	echo -e "\n\n${SECTION}backup${END}"

	sudo mkdir -p $BACKUP_FOLDER
	if [ $# -eq 0 ]; then
		SRC_FILES=`ls $SRC_FOLDER | grep -v backup`
	else
		SRC_FILES=$*
	fi

	for SRC in $SRC_FILES
	do
		DST=$SRC.tgz

		echo -en "\n-> ${TOPIC}backup:${END} ${CONTENT}$SRC${END} "
		if [ -f $BACKUP_FOLDER/$DST ]; then 
			sudo cp $BACKUP_FOLDER/$DST $BACKUP_FOLDER/$DST.backup
		fi
		cd $SRC_FOLDER && sudo tar czf $BACKUP_FOLDER/$DST $SRC 2>/dev/null

		if [ $? -eq 0 ]; then
			echo -en "${OK}OK${END}"
		else
			echo -en "${NOK}NOK${END}"
			sudo rm $BACKUP_FOLDER/$DST
		fi
	done
}

save () {
	echo -e "\n\n${SECTION}save${END}"

	if [ $# -eq 0 ]; then
		SRC_FILES=`ls $BACKUP_FOLDER | grep -v backup`
	else
    	SRC_FILES=$*
	fi

	echo -en "\n-> ${TOPIC}save:${END} ${CONTENT}$REMOTE_HOST${END} "
	ping -c 1 $REMOTE_HOST 1>/dev/null

	if [ $? -eq 0 ]; then
		echo
		cd $BACKUP_FOLDER && rsync -aP -e "ssh -p $REMOTE_PORT" --rsync-path=/bin/rsync $SRC_FILES $REMOTE_USER@$REMOTE_HOST:$REMOTE_FOLDER
	else
    	echo -e "${NOK}NOK${END}"
	fi
}

validate_folder

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
	backup)
		shift
		backup $*
		;;
	save)
		shift
		save $*
		;;
	*)
    	echo -e "\n$0 [update|docker|health|certbot|esphome|backup|save]"
    	;;
esac

echo -e "\n"
