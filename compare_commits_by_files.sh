#!/bin/bash
#set -x
TOPDIR=`pwd`
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
#generateChecksumsFile
#Args:
#	inpFileWithCommits file where stored commits and their relative repos
#	outpFileWithCommits - file where wi will putt checksums
#	branchName - branch on which we are working
generateChecksumsFile(){
		inpFileWithCommits=${1}
		outpFileWithCommits=${2}
		branchName=${3}
		commits=`cat ${inpFileWithCommits}`

		for i in ${commits}; do
			if [ ! -z "$(echo $i | grep ':')" ]; then
				echo $i >> ${TOPDIR}/${outpFileWithCommits}
				cd ${TOPDIR}/$(echo $i | sed -e 's,:,,g')
				git checkout ${branchName}
				git pull
			else
				#write md5 sums of all changed files in scope of commit
				git diff ${i}^ ${i} | tail -n +3 |  md5sum | sed -e 's,^,'$i' ,g' -e 's,-,,g' >> ${TOPDIR}/${outpFileWithCommits}
			fi
		done
		cd ${TOPDIR}
}

grepChecksumm(){
	inpFileWithCommits=${1}
	checkFile=${2}

	checksums="$(cat ${inpFileWithCommits} | grep -v ':')"

	for i in ${checksums}; do
		var="$(echo $i | sed -e 's,-,,g')"
		grep ${checkFile} -e "${var}"
	done
}


#==================Main script==================

#cat ${TOPDIR}/${int_2_0CommitsFiles} | awk '{print $1}' | \
#	grep -ve "Commits" -ve  "------------"

#clear all files
echo > ${TOPDIR}/${CC_int_2_0ChecksumsFile}
echo > ${TOPDIR}/${int_2_0ChecksumsFile}

generateChecksumsFile ${reposWithCommitsCC_int_2_0File} \
											${CC_int_2_0ChecksumsFile}				\
											${branchCC_int2_0}
generateChecksumsFile ${reposWithCommits_int_2_0File} \
											${int_2_0ChecksumsFile}				\
											${branchInt2_0}
grepChecksumm ${CC_int_2_0ChecksumsFile} ${int_2_0ChecksumsFile}

cd ${TOPDIR}
set +x

#echo "${CC_int_2_0Commits}"
