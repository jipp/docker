#!/bin/bash

YAML=`find . -maxdepth 1 \( -name "*.yml" -o -name "*.yaml" \)`

function execute() {
	for FILE in $YAML
	do
		echo
		docker compose $FLAGS -f $FILE $1
	done
}

function prune() {
	docker system prune -f
}

function status() {
	docker images
	echo
	docker ps -a
	echo
	docker compose ls -a
}

function list() {
	echo $YAML
}

function help() {
	echo "Usage: $0 {up|run|down|pull|rm|ps|config|prune|status} [flags]"
	exit 1
}

if (( $# < 1 )); then
        help
fi

COMMAND=$1
shift
FLAGS=$@

case "$COMMAND" in
	'up')		execute "up -d" ;;
	'run')		execute "up" ;;
	'down')		execute "down" ;;
	'pull')		execute "pull" ;;
	'rm')		execute "rm -f" ;;
	'ps')		execute "ps -a" ;;
	'config')	execute "config" ;;
	'prune')	prune ;;
	'status')	status ;;
	'list')		list ;;
	*)		help ;;
esac

exit 0
