#!/usr/bin/env python3

import argparse
import subprocess
import os
import json
import time
import tomllib

folder_compose="/home/$USER/docker/lemonpi"
folder_compose_esphome="/home/$USER/docker/lemonpi/esphome"
folder_src="/docker"
folder_backup="/docker/backup"
remote_user="wolfgang.keller"
remote_host="ds416play"
remote_port="221"
remote_folder="lemonpi"

health_commands=['uname -a', 'uptime', 'vcgencmd measure_temp', 'df -h', 'dmesg -e -l emerg --level=alert,crit,err,warn,notice']
update_command='sudo apt update && sudo apt list --upgradable && sudo apt upgrade && sudo apt autoremove -y'

def main():
	parser = argparse.ArgumentParser(description="tool to maintain the system")

	parser.add_argument('-v', '--version', action='version', version='%(prog)s 0.2')
	parser.add_argument('-s', '--system', choices=['health', 'update'], help='system handling')
	parser.add_argument('-b', '--backup', choices=['execute', 'save', 'list'], help='backup handling')
	parser.add_argument('-m', '--minecraft', choices=['list', 'start', 'stop'], help='minecraft handling')
	parser.add_argument('-d', '--docker', help='docker handling')
	parser.add_argument('-c', '--certbot', help='certbot handling - renew --dry-run')
	parser.add_argument('-e', '--esphome', help='esphome handling')

	args = parser.parse_args()

	match args.system:
		case 'health':
			system_health()
		case 'update':
			system_update()

	match args.backup:
		case 'execute':
			backup_execute()
		case 'save':
			backup_save()
		case 'list':
			backup_list()

	match args.minecraft:
		case 'list':
			minecraft_list_server()

	if args.docker != None:
		docker(args.docker)

	if args.certbot != None:
		certbot(args.certbot)

	if args.esphome != None:
		esphome(args.esphome)

	return

def system_health():
	for comamnd in health_commands:
		os.system(comamnd)

def system_update():
	os.system(update_command)

def esphome(cmd):
	parameter = cmd.split()
	if len(parameter) == 1:
		for x in list_esphome_yaml():
			os.system("cd "+folder_compose+" && docker compose run --rm esphome "+parameter[0]+" "+x)
	else:
		os.system("cd "+folder_compose+" && docker compose run --rm esphome "+parameter[0]+" "+parameter[1])

def certbot(cmd="renew --dry-run"):
	os.system("cd "+folder_compose+" && docker compose run --rm -p 8080:80 certbot "+cmd)
	os.system("cd "+folder_compose+" && docker compose exec -it nginx nginx -s reload")
	os.system("cd "+folder_compose+" && docker compose down certbot")

def docker(cmd):
	match cmd:
		case "prune":
			os.system("docker system prune -f")
		case "pull":
			os.system("cd "+folder_compose+" && docker compose "+cmd)
		case _:
			docker_services = list_docker_services()
			os.system("cd "+folder_compose+" && docker compose "+cmd+" "+docker_services)

def list_esphome_yaml():
  return(subprocess.run(["cd "+folder_compose_esphome+" && ls *.yaml"], shell=True, capture_output=True, text=True).stdout.split())
#	return(subprocess.run(["cd "+folder_compose_esphome+" && ls l*.yaml"], shell=True, capture_output=True, text=True).stdout.split())

def list_minecraft_server():
	return(subprocess.run(["docker ps -a --filter status=running --format {{.Names}} --filter name=minecraft-server"], shell=True, capture_output=True, text=True).stdout.split())

def minecraft_list_server():
	for x in list_minecraft_server():
		print(f"{x:25}: ", list_minecraft_user(x), sep="")

def list_minecraft_user(server='minecraft-server'):
	return int(subprocess.run(["docker exec "+server+" rcon-cli list | cut -d' ' -f3"], shell=True, capture_output=True, text=True).stdout.strip())

def list_running_docker_services():
	return(subprocess.run(["docker ps -a --filter status=running --format {{.Names}}"], shell=True, capture_output=True, text=True).stdout.replace('\n', ' ')).strip()

def list_docker_services():
	docker_services=''
	config=json.loads(subprocess.run(["cd "+folder_compose+" && docker compose config --format json"], shell=True, capture_output=True, text=True).stdout)
	services=subprocess.run(["cd "+folder_compose+" && docker compose config --services"], shell=True, capture_output=True, text=True).stdout.split()
	for i in services:
		if config["services"][i]["restart"] != "no":
			docker_services = i + ' ' + docker_services
	return docker_services

def backup_execute():
	if os.path.isdir(folder_src):
		content=os.listdir(folder_src)
	if not os.path.isdir(folder_backup):
		os.makedirs(folder_backup)
	for x in content:
		if "backup" not in x:
			print(f"{x:25}", end="", flush=True)
			try:
				os.system("cd "+folder_src+" && sudo tar czf "+folder_backup+"/"+x+".tgz "+x)
			except:
				print("nok")
			else:
				print("ok")

def backup_list():
	if os.path.isdir(folder_backup):
		content=os.listdir(folder_backup)
		content.sort()
	else:
		print("folder "+folder_backup+" does not exist")
		exit(1)
	for x in content:
		stats=os.stat(folder_backup+"/"+x)
		print(f"{time.ctime(stats.st_mtime):25}  {x:30}  {stats.st_size:11.0f}")

def backup_save():
	if not os.path.isdir(folder_backup):
		print("folder does not exist")
		exit(1)

if __name__ == "__main__":
	main()
