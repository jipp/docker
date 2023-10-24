#!/bin/bash

YAML=`find . -maxdepth 1 \( -name "*.yml" -o -name "*.yaml" \)`

function execute() {
	for FILE in $YAML
	do
		echo docker compose -f $FILE $@
		docker compose -f $FILE $@
	done
}

function prune() {
	echo docker system prune -f
	docker system prune -f
}

function status() {
	echo docker images
	docker images
	echo docker ps -a
	docker ps -a
	echo docker compose ls -a
	docker compose ls -a
}

function list() {
	echo $YAML
}

function help() {
	echo "Usage: $0 {up|down|pull|rm|ps|config|logs|prune|status} [flags]"
	exit 1
}

if (( $# < 1 )); then
        help
fi

COMMAND=$1
shift
FLAGS=$@

case "$COMMAND" in
	'prune')	prune ;;
	'status')	status ;;
	'list')		list ;;
	*)		execute $COMMAND $FLAGS;;
esac

exit 0
