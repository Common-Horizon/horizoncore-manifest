#!/bin/bash

WDIR=/workdir

# Check if machine is set otherwise exit
if [ -z "$MACHINE" ]
then
    echo "Please set MACHINE variable"
    exit 1
fi

# Check if default build directory is setup
if [ -z "$1" ]
then
    BDDIR=build-torizon
else
    BDDIR="$1"
fi

# Check if branch is passed as argument
if [ -z "$BRANCH" ]
then
    BRANCH=kirkstone-6.x.y
fi

if [ -z "$MANIFEST" ]
then
    MANIFEST=torizoncore/default.xml
fi

# Configure Git if not configured
if [ ! $(git config --global --get user.email) ]; then
    git config --global user.email "you@example.com"
    git config --global user.name "Your Name"
    git config --global color.ui false
fi

# Create a directory for yocto setup
mkdir -p $WDIR/torizon
cd $WDIR/torizon

# Initialize if repo not yet initialized
repo status 2> /dev/null
if [ "$?" = "1" ]
then
    repo init -u https://git.toradex.com/toradex-manifest.git -b $BRANCH -m $MANIFEST
    repo sync
fi # Do not sync automatically if repo is setup already

# Initialize build environment
if [ -z "$DISTRO"  ]
then
    MACHINE=$MACHINE source setup-environment
else
    DISTRO=$DISTRO MACHINE=$MACHINE source setup-environment

    if [ $? -ne 0 ]
    then
        echo "Error setting up environment"
        exit $?
    fi
fi

# Only start build if requested
if [ -z "$IMAGE" ]
then
    echo "Build environment configured"
    # Spawn a shell
    exec bash -i
elif [ -z "$CMD" ]
then
    echo "Build environment configured. Building target image $IMAGE"
    echo "> DISTRO=$DISTRO MACHINE=$MACHINE bitbake $IMAGE"
    bitbake $IMAGE
    # the end
else
    exec bash -c "$CMD"
fi
