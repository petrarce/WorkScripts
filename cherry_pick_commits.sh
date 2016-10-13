################################################################################
#Args:
#   cmtListFile - file consists of blocks [BLOCK]:
#   [BLOCK]
#   [BLOCK]
#   [BLOCK]
#   ...
#[BLOCK]s allows to make featurebranches on several repositories:
#[BLOCK] structure:
#   branch <name>   #branch from whitch all feature branches will be forked
#   repo   <path>   #path to repe on which all work will be done
#   feature <name>  #name of featurebranch
#   <commit_hash> [patch <patch/to/patch/name.patch>  <patch/to//msg>/cmt.msg]
#   ...
# if [patch <patch/to/patch/name.patch>  <patch/to//msg>/cmt.msg] specified
#   script will apply name.patch and commit it with message cmt.msg
#
#
#developer: Ivan Folbort
################################################################################
#!/bin/bash
cmtListFile=${1}

#------VARIABLES------

branchName=
curBranch=

TOPDIR=$(pwd)


#===================MAIN===================
while read line; do
    if [[ "$(echo ${line} | awk '{print $1}')" = "branch" ]]; then
        if [[ ! -z ${branchName} ]]; then git checkout ${branchName} -f; fi
        branchName=$(echo ${line} | awk '{print $2}')

    elif [[ "$(echo ${line} | awk '{print $1}')" = "repo" ]]; then
        REPO_PATH=$(echo ${line} | awk '{print $2}')

        curBranch=$(git branch |grep "\*"| sed -e 's,\* ,,g')
        git checkout ${branchName} -f
        cd ${REPO_PATH}

    elif [[ "$(echo ${line} | awk '{print $1}')" = "feature" ]]; then
        featureBranch=$(echo ${line} | awk '{print $2}')
        git checkout ${branchName}
        git checkout -b "${featureBranch}"
        git config --local branch.${featureBranch}.description "SomeTitle"

    elif [[ ! -z "$(echo ${line} | awk '{print $2}')" ]]; then
        cmtDiffFile=$(echo ${line} | awk '{print $3}')
        cmtMsgFile=$(echo ${line} | awk '{print $4}')
        patch -p 1 < ${TOPDIR}/${cmtDiffFile}
        git add .
        git commit -F ${TOPDIR}/${cmtMsgFile}

    else
        cmtHash=$(echo ${line} | awk '{print $1}')
        git cherry-pick ${cmtHash}

    fi

done < ${cmtListFile}

if [[ ! -z ${branchName} ]]; then git checkout ${branchName} -f; fi
cd ${TOPDIR}
