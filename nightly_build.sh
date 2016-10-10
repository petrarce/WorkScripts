#!/bin/bash
set -x
#==================VARIABLES=================
#-----Generic
TOPDIR=${1}
DL_DIR=${TOPDIR}/downloads
WORKDIR=${TOPDIR}/xb6_comcast_bugtest_$(date +%d-%m-%Y_%H-%M-%S)
logFile=${WORKDIR}/setup.log

#----DEBUG/TEMPORARY BLOCK
WORKDIR=/local/i.foljbort/work/comcast/xb6_comcast_bugtest_10-10-2016_18-19-17
logFile=${WORKDIR}/setup.log
#----

[ ! -d ${TOPDIR} ] && echo 'Top directory specified incorrectly'
[ ! -d ${DL_DIR} ] && echo 'Downloads path is not exists'

echo "Creating dir: \"${WORKDIR}\""
mkdir "${WORKDIR}"
cd "${WORKDIR}"
echo "lgfile">${logFile}

#echo "DEBUG: Creating dir SUCCEED" && return

echo "Starting: repo init"
repo init -u ssh://gerrit.teamccp.com:29418/rdk/yocto_oe/manifests/arris-intel-manifest \
          -b master -m arrisxb6.xml --repo-url=ssh://gerrit.teamccp.com:29418/rdk/tools/git-repo \
          --no-repo-verify -g all >>${logFile} 2>&1

#echo "DEBUG: Starting: repo init SUCCEED" && return

echo "Starting: repo sync"
repo sync --verify >>${logFile} 2>&1

#echo "DEBUG: Starting: repo sync SUCCEED" && return

cd ${WORKDIR}
for MACHINE in ${NIGHTLY_BUILD_MACHINES}; do
  echo "Starting: setup-environment for ${MACHINE}"
  . meta-rdk/setup-environment >>${logFile} 2>&1
  cd ${WORKDIR}
done

set +x
echo "DEBUG: Starting: Starting: setup-environment SUCCEED" && return

#prepare build-${Machines} directories list to enter them and start builds
BUILD_LIST=${WORKDIR}/$(find ${WORKDIR} -name build*)

for BUILD_DIR in ${BUILD_LIST}; do
  cd ${BUILD_DIR}
  echo "Starting: bitbake rdk-generic-broadband-image"
  bitbake rdk-generic-broadband-image #>>${BUILD_DIR}/build.log 2>&1
done

echo "DEBUG: Started: bitbake rdk-generic-broadband-image SUCCEED" && return

cd ${WORKDIR}
echo "Finished"
