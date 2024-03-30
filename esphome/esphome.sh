#!/bin/bash

if (( $# < 1 )); then
        exit 1
fi


if [[ "$@" = "pull" ]]
then
	docker pull esphome/esphome
	docker system prune -f
	exit 0
fi

if [ -c /dev/ttyUSB0 ]
then
	docker run --rm --device /dev/ttyUSB0 -v "${PWD}/config":/config -it esphome/esphome $@
else
	docker run --rm --network host -v "${PWD}/config":/config -it esphome/esphome $@
fi

exit 0
