#!/bin/bash
#================VARIABLES================
#----Common variables
TOPDIR=`pwd`
WORKDIR=${TOPDIR}/files
tempCommotFile="temp"

#----CC_to_int variables
CC_int_2_0ChecksumsFile='2_0_CC_int.checksums'
reposWithCommitsCC_int_2_0File='commits_fileCC_int.txt'
CC_int_2_0Commits=''
CC_int_2_0Commits=`cat ${TOPDIR}/${reposWithCommitsCC_int_2_0File}`
branchCC_int2_0='D3.1_GW-SDK2.0_CC_Int'

#----2.0_int_variables
int_2_0ChecksumsFile='2_0_int.checksums'
reposWithCommits_int_2_0File='commits_file_int.txt'
int_2_0Commits=''
int_2_0Commits=`cat ${TOPDIR}/${reposWithCommits_int_2_0File}`
branchInt2_0='D3.1_GW-SDK2.0_int'

natchesFile='cc_int-int.matches'

#CC_int_2_0CommitsFiles='D3.1_GW-SDK2.0_CC_Int.lst'
#int_2_0CommitsFiles='D3.1_GW-SDK2.0_int.lst'



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
		fi
	done
}

analise_dir(){
	local ARG=${1}
	local makeInDir=${2}
	local ARGS=${3}

	FILES_LIST=`ls -l | awk '{print $9}'`
	for i in ${FILES_LIST}; do
		${makeInDir} ${i} ${ARGS}
		sleep 1
	done
}

analise_repo_dir(){
	local CUR_DIR=`pwd`

	cd ${CUR_DIR}/${1}
	echo '>>>>>>>REPO' ${CUR_DIR}/${1}

	analise_dir NULL analiseinfo_file ""

	cd ${CUR_DIR}/
	echo '<<<<<<<REPO' ${CUR_DIR}/
}

analise_branch_dir(){
	local CUR_DIR=`pwd`
	local branch="$(echo ${1} | sed -e 's,\./,,g')"

	cd ${CUR_DIR}/${1}
	echo '>>>>>>>BRANCHDIR' ${CUR_DIR}/${1}

	analise_dir NULL analise_repo_dir ""

	cd ${CUR_DIR}/
	echo '<<<<<<<BRANCHDIR' ${CUR_DIR}/
}

analise_work_dir(){
	local CUR_DIR=`pwd`

	cd ${CUR_DIR}/${1}
	echo '>>>>>>>WORKDIR' ${CUR_DIR}/${1}

	analise_dir NULL analise_branch_dir ""

	cd ${CUR_DIR}/
	echo '<<<<<<<WORKDIR' ${CUR_DIR}/
}

read_commit(){
	commit=${1}
	git diff ${commit}^ ${commit}
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
			repo=$(echo ${i} | sed -e 's,:,,g')

			if [[ ! -d ${TOPDIR}/${repo} ]]; then
				return
			fi
			cd ${TOPDIR}/${repo}
			git checkout ${branch}
		else
			commitFile="${i}"
			commit=${i}

			read_commit ${commit} > ${TOPDIR}/temp
			delete_sp_symb ${TOPDIR}/temp > ${TOPDIR}/temp1
			mv ${TOPDIR}/temp1 ${TOPDIR}/temp

			touch ${CUR_DIR}/${commitFile}
			analise_commit ${TOPDIR}/temp ${CUR_DIR}/${commitFile}
		fi
	done

	cd ${CUR_DIR}
}

analise_commit(){
	while read line; do
		echo ${line} | grep -e '+++ b/' -e "^+" -e "^-" >> ${2}
	done < ${1}
}

compare_commits(){
	local branch1=${1}
	local branch2=${2}

	local reposBranch1=`ls -l ${WORKDIR}/${branch1} | awk '{print $9}'`
	local commitsBranch1=
	local commitsBranch2=
	local COMPARED_CMT_DIR=${WORKDIR}/compared
	local STAT_FILE="${COMPARED_CMT_DIR}/statistics.txt"
	local fSize1=0
	local fSize2=0
	local curStat=0
	echo "" > ${STAT_FILE}

	mkdir -p ${COMPARED_CMT_DIR}
	for repo in ${reposBranch1}; do
		echo ${repo} '>>>>>>REPO'
		echo "${repo}\:" >> ${STAT_FILE}
		commitsBranch1="$(cat ${WORKDIR}/${branch1}/${repo}/repoInfoFile | grep -v ':')"
		commitsBranch2="$(cat ${WORKDIR}/${branch2}/${repo}/repoInfoFile | grep -v ':')"

		for cmtB1 in ${commitsBranch1}; do
			for cmtB2 in ${commitsBranch2}; do
				fSize1=`ls -l ${WORKDIR}/${branch1}/${repo}/${cmtB1} | awk '{print $5}'`
				fSize2=`ls -l ${WORKDIR}/${branch2}/${repo}/${cmtB2} | awk '{print $5}'`
				if [[ "$(echo ${fSize1}'>='${fSize2} | bc -l)" -eq 1 ]]; then
					curStat=$(echo "scale=2; ${fSize2}/${fSize1}" | bc -l)
					if [[ $(echo $(echo "scale=2; ${fSize2}/${fSize1}" | bc -l)'>'0.9 | bc -l) -eq 1 ]]; then
						meld ${WORKDIR}/${branch1}/${repo}/${cmtB1} ${WORKDIR}/${branch2}/${repo}/${cmtB2}
					fi
				else
					curStat=$(echo "scale=2; ${fSize1}/${fSize2}" | bc -l)
					if [[ $(echo $(echo "scale=2; ${fSize1}/${fSize2}" | bc -l)'>'0.9 | bc -l) -eq 1 ]]; then
						meld ${WORKDIR}/${branch1}/${repo}/${cmtB1} ${WORKDIR}/${branch2}/${repo}/${cmtB2}
					fi
				fi
				echo "\[${branch1}\]: ${cmtB1} \[${branch2}\]: ${cmtB2} equal\: ${curStat}\%" >>${STAT_FILE}
			done
		done
	done
}

delete_sp_symb(){
    cat $1 | sed -e 's`\!``g' -e 's,`,,g' -e 's,\[,,g' -e 's,\],,g' -e 's,\",,g'  -e 's,\*,,g' -e 's,\\,,g' -e 's,\$,,g'
}
#==================Main script==================

echo "do you want to run this script:[y/n]" && read ANSW
if [ ! "${ANSW}" == "y" ]; then exit 0; fi

echo "do you want to rebuild all files: [y/n]" && read ANSW
if [ "${ANSW}" == "y" ]; then
	rm -rf ${WORKDIR}
	createFolderStructure ${TOPDIR}/commits_fileCC_int.txt ${branchCC_int2_0}
	createFolderStructure ${TOPDIR}/commits_file_int.txt ${branchInt2_0}

	cd ${TOPDIR}
	analise_work_dir files
fi

#compare commits and write them comparation results to temp file
echo "start comparation process:[y/n]" && read ANSW
if [ "${ANSW}" == "y" ]; then
	compare_commits ${branchInt2_0} ${branchCC_int2_0}
fi
