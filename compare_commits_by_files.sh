#!/bin/bash
#================VARIABLES================
#----Common variables
TOPDIR=`pwd`
WORKDIR=${TOPDIR}/files
REPOSITORIES_DIR=${TOPDIR}
tempCommotFile="temp"
repoInfoFile="repoInfoFile"

#----CC_to_int variables
CC_int_2_0ChecksumsFile='2_0_CC_int.checksums'
reposWithCommitsCC_int_2_0File='commits_fileCC_int.txt'
CC_int_2_0Commits=`cat ${TOPDIR}/${reposWithCommitsCC_int_2_0File}`
branchCC_int2_0='D3.1_GW-SDK2.0_CC_Int'

#----2.0_int_variables
int_2_0ChecksumsFile='2_0_int.checksums'
reposWithCommits_int_2_0File='commits_file_int.txt'
int_2_0Commits=`cat ${TOPDIR}/${reposWithCommits_int_2_0File}`
branchInt2_0='D3.1_GW-SDK2.0_int'

natchesFile='cc_int-int.matches'


#CC_int_2_0CommitsFiles='D3.1_GW-SDK2.0_CC_Int.lst'
#int_2_0CommitsFiles='D3.1_GW-SDK2.0_int.lst'



#createFolderStructure
#Description - the dunction creates branch folder and repo folders in it
# and deploys them with repoInfoFile, which contains reponame, and commits, of this repo
#	that should be compared
#Args:
#	commtsData content of file with commits of specific branch, that should be compared
#	branchName - branch on which we are working
createFolderStructure(){
	local commtsData=`cat ${1}`
	local branchName=${2}

	local REPO_DIR=

	mkdir -p ${WORKDIR}/${branchName}
	for i in ${commtsData}; do
		if [[ ! -z "$(echo ${i} | grep ":" )" ]]; then
			REPO_DIR=${WORKDIR}/${branchName}/$(echo ${i} | sed -e 's,:,,g')
			mkdir -p ${REPO_DIR}; cd ${REPO_DIR}
     	echo "${i}" > ${REPO_DIR}/${repoInfoFile}
   	else
    	echo "${i}" >> ${REPO_DIR}/${repoInfoFile}
		fi
	done
}

#analise_dir
#Description - anlise dir watches onto the directory, and for each entry in this directory
# it call ${func} and gives it as parameters
#														-entry which was found in directory
#														-additional parameters, which was given by caller of analise_dir
#
#Args:
#	func - function, which will be called from  analise_dir
#	ARGS - arguments, that will be passed to ${func}
analise_dir(){
	local func=${1}
	local ARGS=${2}

	FILES_LIST=`ls -l | awk '{print $9}'`
	for i in ${FILES_LIST}; do
		${func} ${i} ${ARGS}
	done
}
#analise_repo_dir

analise_repo_dir(){
	local CUR_DIR=`pwd`

	cd ${CUR_DIR}/${1}
	echo '>>>>>>>REPO' ${CUR_DIR}/${1}

	analise_dir analise_info_file ""

	cd ${CUR_DIR}/
	echo '<<<<<<<REPO' ${CUR_DIR}/
}

analise_branch_dir(){
	local CUR_DIR=`pwd`
	local branch="$(echo ${1} | sed -e 's,\./,,g')"

	cd ${CUR_DIR}/${1}
	echo '>>>>>>>BRANCHDIR' ${CUR_DIR}/${1}

	analise_dir analise_repo_dir "${branch}"

	cd ${CUR_DIR}/
	echo '<<<<<<<BRANCHDIR' ${CUR_DIR}/
}

analise_work_dir(){
	local CUR_DIR=`pwd`

	cd ${CUR_DIR}/${1}
	echo '>>>>>>>WORKDIR' ${CUR_DIR}/${1}

	analise_dir analise_branch_dir ""

	cd ${CUR_DIR}/
	echo '<<<<<<<WORKDIR' ${CUR_DIR}/
}

read_commit(){
	local commit=${1}
	git diff ${commit}^ ${commit}
}

delete_sp_symb(){
    cat $1 | sed -e 's`\!``g' -e 's,`,,g' -e 's,\[,,g' -e 's,\],,g' -e 's,\",,g'  -e 's,\*,,g' -e 's,\\,,g' -e 's,\$,,g'
}

#analise_info_file
#Description - anlises specified info file
#						 - goes to ropo subdir in REPOSITORIES_DIR
#						 - switches to specified in 2-nd parameter branch
#						 - takes all commit diffs from branch specified in info file one by one and saves them to temp file
#						 - delets all special symbols from temp file and saves result into branch/repo/commit file
#Args:
#	infoFile - file with commit information for repo of specif branch
#	branch - working branch
analise_info_file(){
	local infoFile=${1}
	local branch=${2}
	local commits=`cat ${infoFile}`
	local CUR_DIR=`pwd`
	local commitFile=
	local commit=
	local repo=

	for i in ${commits}; do
		if [[ ! -z "$(echo ${i} | grep ':' )" ]]; then

			repo=$(echo ${i} | sed -e 's,:,,g')

			if [[ ! -d ${TOPDIR}/${repo} ]]; then
				echo "no such ${repo} in ${REPOSITORIES_DIR}" && return
			fi
			cd ${TOPDIR}/${repo}
			git checkout ${branch}
		else
			commitFile="${i}"
			commit=${i}

			#read commit and delete all special symbols from it
			read_commit ${commit} > ${TOPDIR}/temp
			delete_sp_symb ${TOPDIR}/temp > ${TOPDIR}/temp1
			mv ${TOPDIR}/temp1 ${TOPDIR}/temp

			touch ${CUR_DIR}/${commitFile}
			analise_commit ${TOPDIR}/temp ${CUR_DIR}/${commitFile}
		fi
	done

	cd ${CUR_DIR}
}

#analise_commit
#Description - takes only that strings from diff, that starts with + or -
analise_commit(){
	while read line; do
		echo ${line} | grep -e '+++ b/' -e "^+" -e "^-" >> ${2}
	done < ${1}
}

#Comparing commits
#parameters:
#	branch1 - first branch which we compare
# branch2
# compAlg - comparation algorithm: s - by size,
#																	 c - by content of diffs
compare_commits(){
	local branch1=${1}
	local branch2=${2}
	local compAlg=${3}
	if [[ -z "${compAlg}" ]]; then compAlg=c; fi

	local reposBranch1=`ls -l ${WORKDIR}/${branch1} | awk '{print $9}'`
	local repoCommitsB1=
	local repoCommitsB2=
	local RESULT_DIR=${WORKDIR}/compared
	local STAT_FILE="${RESULT_DIR}/statistics.txt"
	local fSize1=0
	local fSize2=0
	local curStat=0

	#create and clean statistics file
	mkdir -p ${RESULT_DIR}
	echo "" > ${STAT_FILE}

	for repo in ${reposBranch1}; do

		echo ${repo} '>>>>>>REPO'
		echo "${repo}\:" >> ${STAT_FILE}

		# take list of comparable commits for every branch from ${repoInfoFile} (it remains in every repo directory after analise_work_dir)
		repoCommitsB1="$(cat ${WORKDIR}/${branch1}/${repo}/${repoInfoFile} | grep -v ':')"
		repoCommitsB2="$(cat ${WORKDIR}/${branch2}/${repo}/${repoInfoFile} | grep -v ':')"

		for cmtB1 in ${repoCommitsB1}; do
			for cmtB2 in ${repoCommitsB2}; do
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

#==================Main script==================

echo "do you want to run this script:[y/n]" && read ANSW
if [ ! "${ANSW}" == "y" ]; then exit 0; fi

#TODO:: make creation of commits_fileCC_int.txt and commits_file_int.txt

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
