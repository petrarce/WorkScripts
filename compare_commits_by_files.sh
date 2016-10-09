#!/bin/bash
##set -x
#================dirs structure================
TOPDIR=`pwd`
WORKDIR=${TOPDIR}/files

CC_int_2_0ChecksumsFile='2_0_CC_int.checksums'
int_2_0ChecksumsFile='2_0_int.checksums'
natchesFile='cc_int-int.matches'

#CC_int_2_0CommitsFiles='D3.1_GW-SDK2.0_CC_Int.lst'
#int_2_0CommitsFiles='D3.1_GW-SDK2.0_int.lst'

reposWithCommitsCC_int_2_0File='commits_fileCC_int.txt'
reposWithCommits_int_2_0File='commits_file_int.txt'

CC_int_2_0Commits=''
int_2_0Commits=''

CC_int_2_0Commits=`cat ${TOPDIR}/${reposWithCommitsCC_int_2_0File}`
int_2_0Commits=`cat ${TOPDIR}/${reposWithCommits_int_2_0File}`

branchCC_int2_0='D3.1_GW-SDK2.0_CC_Int'
branchInt2_0='D3.1_GW-SDK2.0_int'

tempCommotFile="temp"
#generateChecksumsFile
#Args:
#	inpFileWithCommits file where stored commits and their relative repos
#	outpFileWithCommits - file where wi will putt checksums
#	branchName - branch on which we are working
createFolderStructure(){
	dataFile=`cat ${1}`
	branchname=${2}
	repoInfoFile=""

	mkdir -p ${WORKDIR}/${branchname}
	for i in ${dataFile}; do
		if [[ ! -z "$(echo ${i} | grep ":" )" ]]; then
			TEMP_WORKDIR=${WORKDIR}/${branchname}/$(echo ${i} | sed -e 's,:,,g')
			mkdir -p ${TEMP_WORKDIR}; cd ${TEMP_WORKDIR}
			repoInfoFile="$(echo ${i} | sed -e 's,:,,g')-info"
			echo "${i}" > ${TEMP_WORKDIR}/repoInfoFile
		else
			echo "${i}" >> ${TEMP_WORKDIR}/repoInfoFile
		fi
	done
}

analise_dir(){
	local ARG=${1}
	local makeInDir=${2}
	local ARGS=${3}

	FILES_LIST=`ls -l | awk '{print $9}'`
	for i in ${FILES_LIST}; do
		echo ${CUR_DIR}/${i} =================
		echo ${ARG} $makeInDir $ARGS
		${makeInDir} ${i} ${ARGS}
		sleep 1
	done
}

analise_repo_dir(){
	local CUR_DIR=`pwd`

	cd ${CUR_DIR}/${1}
	echo '>>>>>>>REPO' ${CUR_DIR}/${1}
	analise_dir NULL analiseinfo_file ""
	echo '<<<<<<<REPO' ${CUR_DIR}/

	cd ${CUR_DIR}/
}

analise_branch_dir(){
	local CUR_DIR=`pwd`
	local branch="$(echo ${1} | sed -e 's,\./,,g')"

	cd ${CUR_DIR}/${1}
	echo '>>>>>>>BRANCHDIR' ${CUR_DIR}/${1}
	analise_dir NULL analise_repo_dir ""
	echo '<<<<<<<BRANCHDIR' ${CUR_DIR}/
	cd ${CUR_DIR}/
}

analise_work_dir(){
	local CUR_DIR=`pwd`

	cd ${CUR_DIR}/${1}
	echo '>>>>>>>WORKDIR' ${CUR_DIR}/${1}

	analise_dir NULL analise_branch_dir ""
	echo '<<<<<<<WORKDIR' ${CUR_DIR}/

	cd ${CUR_DIR}/
}

read_commit(){
	commit=${1}
	git diff ${1}
}

analiseinfo_file(){
	local infoFile=${1}
	local commits=`cat ${infoFile}`
	local CUR_DIR=`pwd`
	local commitFile=""
	local commit=


	repo=
	for i in ${commits}; do
		if [[ ! -z "$(echo ${i} | grep ':' )" ]]; then
			repo=${i}

			cd ${TOPDIR}/$(echo ${i} | sed -e 's,:,,g')
		else
			commitFile="${i}"
			commit=${i}

			git diff ${commit}^ ${commit} > ${TOPDIR}/temp
			touch ${CUR_DIR}/${commitFile}
			analise_commit ${TOPDIR}/temp ${CUR_DIR}/${commitFile}
		fi
	done

	cd ${CUR_DIR}
	exit
}

analise_commit(){
	while read line; do
		echo ${line} | grep -e '+++ b/' -e "^+ " -e "^- " >> ${2}
	done < ${1}
}

#==================Main script==================

#cat ${TOPDIR}/${int_2_0CommitsFiles} | awk '{print $1}' | \
#	grep -ve "Commits" -ve  "------------"


createFolderStructure ${TOPDIR}/commits_fileCC_int.txt ${branchCC_int2_0}
createFolderStructure ${TOPDIR}/commits_file_int.txt ${branchInt2_0}

cd ${TOPDIR}
analise_work_dir files
