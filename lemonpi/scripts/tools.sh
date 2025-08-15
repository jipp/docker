#!/bin/bash

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

MINECRAFT="minecraft minecraft-small"
ESPHOME="basement.yaml livingroom.yaml"

check_mc_user () {
	MC_USER=`docker exec $1 rcon-cli list | cut -d' ' -f3`
	if [ $MC_USER -eq 0 ]; then
		return 0
	fi
	return 1
}

docker_update () {
	echo -e "\n\n${SECTION}docker${END}"

	echo -e "\n-> ${TOPIC}docker:${END} ${CONTENT}pull${END}"
	cd $COMPOSE_FOLDER && docker compose pull

	echo -e "\n-> ${TOPIC}docker:${END} ${CONTENT}up${END}"
	for i in $MINECRAFT
	do
		if check_mc_user $i -eq 0; then
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
# commands:
#	renew --dry-run
#	renew
#	certonly --dry-run --standalone --agree-tos --expand --preferred-challenges=http --email wolfgang.keller@wobilix.de --domain dyndns.wobilix.de
#	certonly --standalone --agree-tos --expand --preferred-challenges=http --email wolfgang.keller@wobilix.de --domain dyndns.wobilix.de

	echo -e "\n\n${SECTION}certbot${END}"

	if [ $# -eq 0 ]; then
		COMMAND="renew --dry-run"
	else
		COMMAND=$*
	fi

	echo -e "\n-> ${TOPIC}certbot:${END} ${CONTENT}$COMMAND${END}"
	cd $COMPOSE_FOLDER && docker compose run --rm -p 8080:80 certbot $COMMAND

	echo -e "\n-> ${TOPIC}certbot:${END} ${CONTENT}reload nginx${END}"
	cd $COMPOSE_FOLDER && docker compose exec -it nginx nginx -s reload

	echo -e "\n-> ${TOPIC}certbot:${END} ${CONTENT}clean-up${END}"
	cd $COMPOSE_FOLDER && docker compose down certbot
}

esphome () {
	echo -e "\n\n${SECTION}esphome${END}"

	if [ $# -eq 0 ]; then
		COMMAND="config"
	else
		COMMAND=$*
	fi

	echo -e "\n-> ${TOPIC}esphome:${END} ${CONTENT}$COMMAND${END}"
	for i in $ESPHOME
	do
		cd $COMPOSE_FOLDER && docker compose run --rm esphome $COMMAND $i
	done
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

	echo -e "\n-> ${TOPIC}health:${END} ${CONTENT}uname -a${END}"
	uname -a

	echo -e "\n-> ${TOPIC}health:${END} ${CONTENT}uptime${END}"
	uptime

	echo -e "\n-> ${TOPIC}health:${END} ${CONTENT}temperature${END}"
	vcgencmd measure_temp

	echo -e "\n-> ${TOPIC}health:${END} ${CONTENT}df${END}"
	df -h

	echo -e "\n-> ${TOPIC}health:${END} ${CONTENT}dmesg${END}"
	dmesg -e -l emerg --level=alert,crit,err,warn,notice
}

backup () {
	echo -e "\n\n${SECTION}backup${END}"
	
	if [ $# -eq 0 ]; then
		SRC_FILES=`ls $SRC_FOLDER | grep -v backup`
	else
		SRC_FILES=$*
	fi

	sudo mkdir -p $BACKUP_FOLDER

	for SRC in $SRC_FILES
	do
		DST=$SRC.tgz

		echo -en "\n-> ${TOPIC}backup:${END} ${CONTENT}$SRC${END} "
		if [ -d $SRC_FOLDER/$SRC ]; then

			if [ -f $BACKUP_FOLDER/$DST ]; then 
				sudo mv $BACKUP_FOLDER/$DST $BACKUP_FOLDER/$DST.backup
			fi
			
			cd $SRC_FOLDER && sudo tar czf $BACKUP_FOLDER/$DST $SRC 2>/dev/null
			if [ $? -eq 0 ]; then
				if [ -f $BACKUP_FOLDER/$DST.backup ]; then
					sudo rm $BACKUP_FOLDER/$DST.backup
				fi
				echo -en "${OK}OK${END}"
			else
				if [ -f $BACKUP_FOLDER/$DST.backup ]; then
					sudo mv $BACKUP_FOLDER/$DST.backup $BACKUP_FOLDER/$DST
				fi
				echo -en "${NOK}NOK${END}"
			fi

		else
			echo -en "${NOK}NOK${END}"
		fi
	done
}

save () {
	echo -e "\n\n${SECTION}save${END}"

	echo -en "\n-> ${TOPIC}local folder:${END} ${CONTENT}$BACKUP_FOLDER${END} "
	if [ ! -d $BACKUP_FOLDER ]; then
		echo -e "${NOK}NOK${END}"
		echo -e "\nFolder \"$BACKUP_FOLDER\" does not exist!\n"
		exit 1
	fi

	if [ $# -eq 0 ]; then
		SRC_FILES=`ls $BACKUP_FOLDER | grep -v backup`
	else
    	SRC_FILES=$*
	fi

	echo -en "\n-> ${TOPIC}remote host:${END} ${CONTENT}$REMOTE_HOST${END} "
#	ping -c 1 $REMOTE_HOST &>/dev/null

	cd $BACKUP_FOLDER && ls -l $SRC_FILES &>/dev/null

	if [ $? -eq 0 ]; then
		echo
		cd $BACKUP_FOLDER && rsync -aP -e "ssh -p $REMOTE_PORT" --rsync-path=/bin/rsync $SRC_FILES $REMOTE_USER@$REMOTE_HOST:$REMOTE_FOLDER
	else
    	echo -e "${NOK}NOK${END}"
	fi
}

list () {
	echo -e "\n\n${SECTION}list${END}"

	echo -en "\n-> ${TOPIC}list:${END} ${CONTENT}$BACKUP_FOLDER${END} "
	if [ ! -d $BACKUP_FOLDER ]; then
		echo -e "${NOK}NOK${END}"
		echo -e "\nFolder \"$BACKUP_FOLDER\" does not exist!\n"
		exit 1
	fi

	echo -e "${OK}OK${END}"
	ls -lh $BACKUP_FOLDER
}

minecraft () {
   for i in $MINECRAFT
   do
      echo $i
      docker exec $i rcon-cli list
   done
}

if [ ! -d $COMPOSE_FOLDER ]; then
	echo -e "\nFolder \"$COMPOSE_FOLDER\" does not exist!\n" 
	exit 1
fi

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
	list)
		list
		;;
	minecraft)
		minecraft
      ;;
	*)
    	echo -e "\n$0 [update|docker|health|certbot|esphome|backup|save|list|minecraft]"
    	;;
esac

echo -e "\n"
