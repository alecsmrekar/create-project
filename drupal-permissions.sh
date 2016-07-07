#!/bin/bash

# Help menu
print_help() {
	cat <<-HELP
	This script is used to fix permissions of a Drupal installation.
	You can optionally provide the following arguments:
	1) Path to your Drupal installation (defaults to current directory).
	2) Username of the user that you want to give files/directories ownership (defaults to current user).
	3) HTTPD group name (defaults to www-data).
	Usage with optional arguments: (sudo) bash ${0##*/} --drupal_path=PATH --drupal_user=USER --httpd_group=GROUP
	HELP
	exit 0
}

if [ $(id -u) != 0 ]; then
	printf '**************************************\n'
	printf '* Error: You must run this with sudo. *\n'
	printf '**************************************\n'
	print_help
	exit 1
fi

# Set defaults
drupal_path_default=$(pwd)
drupal_user_default=${SUDO_USER:-$USER}
httpd_group_default="www-data"

# Set variables
drupal_path=${1:-$drupal_path_default}
drupal_user=${2:-$drupal_user_default}
httpd_group=${3:-$httpd_group_default}

# Remove trailing slash
drupal_path=${drupal_path%/}

# Parse Command Line Arguments
while [ $# -gt 0 ]; do
	case "$1" in
		--drupal_path=*)
			drupal_path="${1#*=}"
			;;
		--drupal_user=*)
			drupal_user="${1#*=}"
			;;
		--httpd_group=*)
			httpd_group="${1#*=}"
			;;
		--help) print_help;;
		*)
			printf '***********************************************************\n'
			printf '* Error: Invalid argument, run --help for valid arguments. *\n'
			printf '***********************************************************\n'
			exit 1
	esac
	shift
done

# Check if we have a valied Drupal installation
if [ -z "${drupal_path}" ] || [ ! -d "${drupal_path}/sites" ] || [ ! -f "${drupal_path}/core/modules/system/system.module" ] && [ ! -f "${drupal_path}/modules/system/system.module" ]; then
	printf '*********************************************\n'
	printf '* Error: Please provide a valid Drupal path. *\n'
	printf '*********************************************\n'
	print_help
	exit 1
fi

# Check if we have a valid user
if [ -z "${drupal_user}" ] || [[ $(id -un "${drupal_user}" 2> /dev/null) != "${drupal_user}" ]]; then
	printf '*************************************\n'
	printf '* Error: Please provide a valid user. *\n'
	printf '*************************************\n'
	print_help
	exit 1
fi

# Change the permissions
cd $drupal_path
printf 'Changing ownership of all contents of '${drupal_path}':\n user => '${drupal_user}' \t group => '${httpd_group}'\n'
chown -R ${drupal_user}:${httpd_group} .
printf 'Changing permissions of all directories inside '${drupal_path}' to 'rwxr-x---'...\n'
find . -type d -exec chmod u=rwx,g=rx,o= '{}' \;
printf 'Changing permissions of all files inside '${drupal_path}' to 'rw-r-----'...\n'
find . -type f -exec chmod u=rw,g=r,o= '{}' \;
printf 'Changing permissions of 'files' directories in '${drupal_path}/sites' to 'rwxrwx---'...\n'
cd sites
find . -type d -name files -exec chmod ug=rwx,o= '{}' \;
printf 'Changing permissions of all files inside all 'files' directories in '${drupal_path}/sites' to 'rw-rw----'...\n'
printf 'Changing permissions of all directories inside all 'files' directories in '${drupal_path}/sites' to 'rwxrwx---'...\n'
for x in ./*/files; do
	find ${x} -type d -exec chmod ug=rwx,o= '{}' \;
	find ${x} -type f -exec chmod ug=rw,o= '{}' \;
done

echo 'Done setting proper permissions on files and directories'
