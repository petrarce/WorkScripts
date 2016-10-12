################################################################################
#This script creates fetches new environment with repo and builds images with
#of machines, specified in NIGHTLY_BUILD_MACHINES variable in global environment
#(should be set on terminal)
#
#execute this script from source:
#. nightly_build opt1 opt2 opt3
#
#opt1 - comcast directory, where all repo views are
#opt2 - current repo view (optional)
#opt3 - skip sync process (if repo view already exists and configured /optional)
#
# developers - Konstantin Fursenko, Ivan Folbort
################################################################################
#!/bin/bash
#==================VARIABLES=================
#-----Generic
TOPDIR=${1}
if [ -z "${2}" ]; then WORKDIR=${TOPDIR}/xb6_comcast_bugtest_$(date +%d-%m-%Y_%H-%M-%S)
                  else WORKDIR=${TOPDIR}/${2} ;fi
DL_DIR=${TOPDIR}/downloads
logFile=${WORKDIR}/setup.log
ARG=${3}

configure_builddir(){
    sed -ie 's,BB_NUMBER_THREADS ?= "${@oe.utils.cpu_count()}",BB_NUMBER_THREADS ?= "8",g' \
        conf/local.conf
}
#==============MAIN==============
[ ! -d ${TOPDIR} ] && echo 'Top directory specified incorrectly'
[ ! -d ${DL_DIR} ] && echo 'Downloads path is not exists'

echo "Creating dir: \"${WORKDIR}\"\n ${DL_DIR} \n download symlink"
mkdir "${WORKDIR}"; mkdir ${DL_DIR}
ln -s ${TOPDIR}/downloads ${WORKDIR}/downloads
cd "${WORKDIR}"

if [[ ! "${ARG}" = "--no-sync" ]]; then
    #statements

echo "Starting: repo init"
repo init -u ssh://gerrit.teamccp.com:29418/rdk/yocto_oe/manifests/arris-intel-manifest \
          -b master -m arrisxb6.xml --repo-url=ssh://gerrit.teamccp.com:29418/rdk/tools/git-repo \
          --no-repo-verify -g all

echo "Starting: repo sync"
repo sync --verify

fi

cd ${WORKDIR}
for MACHINE in ${NIGHTLY_BUILD_MACHINES}; do
  echo "Starting: setup-environment for ${MACHINE}"
  . meta-rdk/setup-environment ${WORKDIR}/build-${MACHINE}
  configure_builddir
  cd ${WORKDIR}
done

#prepare build-${Machines} directories list to enter them and start builds
BUILD_LIST="$(find ${WORKDIR} -maxdepth 1 -name build\*)"

for BUILD_DIR in ${BUILD_LIST}; do
  cd ${BUILD_DIR}
  echo "Starting: bitbake rdk-generic-broadband-image"
  bitbake rdk-generic-broadband-image
done

cd ${TOPDIR}

echo "Finished"
