#!/usr/bin/bash

# check if we have docker installed
if ! command -v docker &> /dev/null
then
    echo "You need to have Docker installed and configured: https://docs.docker.com/engine/install/debian/"
    exit
fi

# check if we have docker compose plugin installed
_OUPUT=$(docker compose version)
# check if the output contains "Docker Compose version v2.x.x"
if [[ $_OUPUT != *"Docker Compose version v2"* ]]; then
    echo "You need to have Docker Compose v2 installed and configured: https://docs.docker.com/compose/install/linux/"
    exit
fi

# output the arguments
echo "Arguments: $@"
echo "Number of arguments: $#"
echo "  WORKDIR: $1"
echo "  MACHINE: $2"
echo "  TYPE: $3"

# if there is a 3rd argument, then it should be to exec in debug mode
if [ $# -eq 4 ]; then
    if [ "$4" == "debug" ]; then
        export DEBUG=1
    else
        echo ""
        echo "Invalid 4th argument, only supported 'debug'"
        echo ""
        exit
    fi
fi

# check the type, only support "release" and "dev"
if [ "$3" != "release" ] && [ "$3" != "dev" ]; then
    echo ""
    echo "Invalid type, only supported 'release' and 'dev'"
    echo ""
    exit
fi

# check if the path for the workdir exists and is an absolute path
if [ ! -d "$1" ]; then
    echo ""
    echo "Invalid WORKDIR, make sure it is an absolute path"
    echo ""
    exit
fi

# create the workdir if it does not exist
if [ ! -d "$1/workdir" ]; then
    mkdir -p $1/workdir/torizon
fi

# load the ./.vscode/machines.json using jq
MACHINES_FILE="./.vscode/machines.json"
MACHINES=()

if [ -f "$MACHINES_FILE" ]; then
    RAW_MACHINES=$(./.scripts/jq -r '.[] | .machine' $MACHINES_FILE)
    IFS=$'\n' read -r -d '' -a MACHINES <<< "$RAW_MACHINES"

    # check if the machine exists
    MACHINE_FOUND=false
    for MACHINE in "${MACHINES[@]}"; do
        if [ "$MACHINE" == "$2" ]; then
            MACHINE_FOUND=true
            break
        fi
    done

    if [ "$MACHINE_FOUND" == false ]; then
        echo ""
        echo "Machine $2 not found in ./.vscode/machines.json"
        echo ""
        exit
    fi
else
    echo ""
    echo "No ./.vscode/machines.json, make sure that you are running the script from the root of the project"
    echo ""
    exit
fi

# set the environment variables
export WORKDIR=$1/workdir
export MACHINE=$2

if [ "$3" == "release" ]; then
    export IMAGE=torizon-core-common-docker
else
    export IMAGE=torizon-core-common-docker-dev
fi

# first build
docker compose -f ./.devcontainer/docker-compose.yml build

if [ "$DEBUG" == 1 ]; then
    docker compose -f ./.devcontainer/docker-compose.yml run --rm crops-common-torizon-debug
    exit
fi

# spin up the docker container
docker compose -f ./.devcontainer/docker-compose.yml run --rm crops-common-torizon
