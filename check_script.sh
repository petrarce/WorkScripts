#!/bin/bash
set -x
grep_filter(){
    str=$(echo ${1} | sed -e 's`\\`\\\\\\\\`g' -e 's`\$`\\\\\$`g' -e 's`\*`\\\*`g' -e 's`\[`\\\[`g' -e 's`\]`\\\]`g' -e 's`\"`\\\"`g' -e 's,`,\\`,g' -e 's`\!`\\\!`g')
    echo $str
}

delete_sp_symb(){
    cat $1 | sed -e 's`\!``g' -e 's,`,,g' -e 's,\[,,g' -e 's,\],,g' -e 's,\",,g'  -e 's,\*,,g' -e 's,\\,,g' -e 's,\$,,g'
}

read_file(){
    filelist=$(find ${1} -type f)
    for file in ${filelist}; do
    #file=${1}
        rm -rf ${commonDiffFile}
        touch ${commonDiffFile}
        delete_sp_symb ${file}
        while read line; do
            matches=$(grep ${file} -e "${line}")
    		if [[ ! -z ${matches} ]]; then
    		    echo ${line} >> ${commonDiffFile}
    		fi
        done < ${file}
        meld ${file} ${commonDiffFile}
    done
}

delete_sp_symb(){
    sed -i   -e 's`\!``g' \
			 -e 's,`,,g' \
			 -e 's,\[,,g' \
			 -e 's,\],,g' \
			 -e 's,\",,g' \
			 -e 's,\*,,g' \
			 -e 's,\\,,g' \
			 -e 's,\$,,g' \
             -e 's,\ ,,g' \
			 -e 's,\-,,g' \
			 -e 's,\+,,g' ${1}
}

rm -rf ${commonDiffFile}
touch ${commonDiffFile}

read_file $1

meld ${1} ${commonDiffFile}
#обeртка для bash (1 slesh)
#`![]"*
#обуртка для grep (1 slesh)
#\$
set +x
