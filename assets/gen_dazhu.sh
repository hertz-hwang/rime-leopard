#!/bin/sh

# 生成大竹碼表
#
# Usage:
#   cat docs/hao/smyh.base.dict.yaml | assets/gen_dazhu.sh >dazhu.txt
cat docs/hao/smyh.base.dict.yaml | \
    sed 's/^\(.*\)\t\(.*\)/\1\t\2/g' | \
    sed 's/\t/{TAB}/g' | \
    grep '.*{TAB}.*' | \
    sed 's/{TAB}/\t/g' | \
    awk '{print $2 "\t" $1}' | \
    sed 's/1/_/g' | \
    sed 's/2/;/g' | \
    sed "s/3/'/g" \
    >dazhu.txt

cat docs/hao/smyh.full.dict.yaml | \
    sed 's/^\(.*\)\t\(.*\)/\1\t\2全/g' | \
    sed 's/\t/{TAB}/g' | \
    grep '.*{TAB}.*' | \
    sed 's/{TAB}/\t/g' | \
    awk '{print $2 "\t" $1}' | \
    sed 's/1/_/g' | \
    sed 's/2/;/g' | \
    sed "s/3/'/g" \
    >>dazhu.txt

#sed 's/^\(.*\)\t\(.*\)/\1\t\2/g' | \
#    sed 's/\t/{TAB}/g' | \
#    grep '.*{TAB}.*' | \
#    sed -E 's/(\W+){TAB}([0-9a-z]+).*\n/\1{TAB}\2\n/g' #| \
#    #sed 's/1/_/g' | \
#    #sed 's/2/_/g' | \
    #sed "s/3/_/g" #| \
    #sed 's/\(.*\){TAB}\(.*\)/\2\t\1/g'
