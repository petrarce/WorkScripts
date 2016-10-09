#!/bin/bash
grep_filter(){
    str=$(echo ${1} | sed -e 's`\\`\\\\\\\\`g' -e 's`\$`\\\\\$`g' -e 's`\*`\\\*`g' -e 's`\[`\\\[`g' -e 's`\]`\\\]`g' -e 's`\"`\\\"`g' -e 's,`,\\`,g' -e 's`\!`\\\!`g')
    echo $str
}

delete_sp_symb(){
    cat $1 | sed -e 's`\!``g' -e 's,`,,g' -e 's,\[,,g' -e 's,\],,g' -e 's,\",,g'  -e 's,\*,,g' -e 's,\\,,g' -e 's,\$,,g'
}

delete_sp_symb $1
#обeртка для bash (1 slesh)
#`![]"*
#обуртка для grep (1 slesh)
#\$
