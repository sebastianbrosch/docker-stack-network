#!/bin/bash
#
# This script installs and updates DNS services on a Docker Stack.
#
# You can use these parameters to install and configure the DNS services:
#
#   Option         Long Option            Meaning
#   -d             --debug                Show some debug information.
#   -h             --help                 Show this help.
#   -n <name>      --name <name>          The name of the Docker Stack.
#   -v             --version              Show the version of this script.
#
# This script can exit with one of these exit codes:
#
#    0: The installation was successful.
#   20: Docker is not installed on this server.
#   21: Docker is not in swarm mode.
#   30: The user has not confirmed the installation.
#   31: The network traefik-proxy is not available.
#   32: Docker Stack for DNS services could not be deployed.
#

###########################################################
# Show the help of this script.
###########################################################
function show_help() {
  printf "\n"
  printf "%-s\n\n" "This script installs and updates DNS services on a Docker Stack."
  printf "%-s\n\n" "You can use these parameters to install and configure the DNS services:"
  printf "  %-15s%-23s%-s\n" "Option" "Long Option" "Meaning"
  printf "  %-15s%-23s%-s\n" "-d" "--debug" "Show some debug information."
  printf "  %-15s%-23s%-s\n" "-h" "--help" "Show this help."
  printf "  %-15s%-23s%-s\n" "-n <name>" "--name <name>" "The name of the Docker Stack."
  printf "  %-15s%-23s%-s\n" "-v" "--version" "Show the version of this script."
  printf "\n"
  printf "This script can exit with one of these exit codes:\n\n"
  printf "  %2s: %-s\n" "0" "The installation was successful."
  printf "  %2s: %-s\n" "20" "Docker is not installed on this server."
  printf "  %2s: %-s\n" "21" "Docker is not in swarm mode."
  printf "  %2s: %-s\n" "30" "The user has not confirmed the installation."
  printf "  %2s: %-s\n" "31" "The network traefik-proxy is not available."
  printf "  %2s: %-s\n" "32" "Docker Stack for DNS services could not be deployed."
  printf "\n"
}

###########################################################
# Show the version of this script.
###########################################################
function show_version() {
  echo "1.0"
}

###########################################################
# Get the IP4 address of the server.
###########################################################
function get_ip4() {
  hostname -I | cut -d ' ' -f1
}

###########################################################
# Check whether Docker is installed.
###########################################################
function is_installed_docker() {
  [[ -x "$(command -v docker)" ]]
}

###########################################################
# Check whether a Docker Stack is deployed.
###########################################################
function is_deployed() {
  local name=$1
  [[ "$(docker stack ls --format=\"{{.Name}}\" | grep -cxF \"$name\")" == "1" ]]
}

###########################################################
# Check whether Docker is in swarm mode.
###########################################################
function is_docker_swarm() {
  [[ "$(docker info 2>/dev/null | grep 'Swarm'| awk -F' ' '{print $2}')" == "active" ]]
}

###########################################################
# Get the ID of a specific container.
###########################################################
function get_container_id() {
  local service=$1
  local container=$2
  docker ps -aqf "name=^${service}_${container}"
}

# get all parameter values of user input.
while [[ "$#" != "0" ]]; do
  if [[ "$1" == "-d" ]] || [[ "$1" == "--debug" ]]; then
    debug=1
  elif [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    show_help
    exit 0
  elif [[ "$1" == "-n" ]] || [[ "$1" == "--name" ]]; then
    name="$2"
  elif [[ "$1" == "-v" ]] || [[ "$1" == "--version" ]]; then
    show_version
    exit 0
  fi
  shift
done

# get additional information to execute the script.
# also set default values for missing parameter values.
address="$(get_ip4)"
debug="${debug:-0}"
folder="$(dirname $0)"
name="${name:-dns}"
timezone="$(cat /etc/timezone)"

# check whether Docker is installed on this server.
if ! is_installed_docker; then
  echo "Docker is not installed on this server."
  exit 20
fi

# check whether Docker is in swarm mode.
if ! is_docker_swarm; then
  echo "Docker is not in swarm mode."
  exit 21
fi

# it is possible to run this script in debug mode.
# the debug mode outputs the variables and final compose file.
if [[ "$debug" == "1" ]]; then
  printf "\nVariables:\n\n"
  printf "  %-18s%-s\n" "Debug:" "$debug"
  printf "  %-18s%-s\n" "IP4:" "$address"
  printf "  %-18s%-s\n" "Script Folder:" "$folder"
  printf "  %-18s%-s\n" "Script Version:" "$(show_version)"
  printf "  %-18s%-s\n" "Stack Name:" "$name"
  printf "\nDocker Compose File:\n\n"
  docker stack config --compose-file "$folder/docker-compose.yml"
  exit 0
else
  printf "\nDocker Stack for DNS services (%s):\n\n" "$(show_version)"
  printf "  %-18s%-s\n" "IP4:" "$address"
  printf "  %-18s%-s\n" "Stack Name:" "$name"
fi

# the Docker Stack can be installed or updated.
if is_deployed "$name"; then
  printf "\n"
  printf "Docker Stack for DNS services is already deployed.\n"
  printf "Docker Stack for DNS services will be updated.\n"
  printf "\n"
else
  printf "\n"
  printf "Docker Stack for DNS services is not deployed.\n"
  printf "Docker Stack for DNS services will be deployed.\n"
  printf "\n"
fi

# the user have to confirm the installation.
read -r -p "You want to proceed? [Y/N]: " proceed

# check whether the user wants to proceed the installation.
if [[ "$proceed" != "y" ]] && [[ "$proceed" != "Y" ]]; then
  printf "\nThe user has not confirmed the installation.\n\n"
  exit 30
fi

# set the permissions of the unbound configuration files.
# https://github.com/klutchell/unbound-docker?tab=readme-ov-file#usageexamples
if [[ -d "./unbound/" ]]; then
  sudo chown 101:102 ./unbound/*
fi

# deploy the Docker Stack for DNS services.
docker stack deploy -c "$folder/docker-compose.yml" "$name" 1> /dev/null

# check whether the Docker Stack was deployed successfully.
if ! is_deployed "$name"; then
  printf "\nDocker Stack for DNS services could not be deployed.\n\n"
  exit 32
else
  printf "\nDocker Stack for DNS services was deployed successfully.\n\n"
  exit 0
fi
