#!/bin/bash

# exit on error
set -e

# set path to your downloads dir
downloadsPath='downloads'
[ ! -d $downloadsPath ] && echo 'Downloads path is not exists'

logFile="$PWD/$(basename "$0").log"

dirName=xb6_comcast_bugtest_$(date +%d-%m-%Y_%H-%M-%S)
mkdir "$dirName"
echo "Created dir: \"$dirName\""
cd "$dirName"

echo "Started: repo init"
repo init -u ssh://gerrit.teamccp.com:29418/rdk/yocto_oe/manifests/arris-intel-manifest -b master -m arrisxb6.xml --repo-url=ssh://gerrit.teamccp.com:29418/rdk/tools/git-repo --no-repo-verify -g all >>$logFile 2>&1

echo "Started: repo sync"
repo sync --verify >>$logFile 2>&1

echo "Started: setup-environment"
MACHINE='arrisxb6arm'
. meta-rdk/setup-environment >>$logFile 2>&1

echo "Started: bitbake rdk-generic-broadband-image"
bitbake rdk-generic-broadband-image >>$logFile 2>&1

echo "Finished"
