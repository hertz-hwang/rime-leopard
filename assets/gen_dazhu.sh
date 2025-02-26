#!/bin/sh

# 生成大竹碼表
#
# Usage:
#   cat docs/hao/smyh.base.dict.yaml | assets/gen_dazhu.sh >dazhu.txt

sed 's/\(.*\)\t\(.*\)\t\(.*\)\t\(.*\)/\1\t\2\t\3/g' | \
    sed 's/\t/{TAB}/g' | \
    grep '.*{TAB}.*{TAB}.*' | \
    sed 's/1/_/g' | \
    sed 's/2/_/g' | \
    sed "s/3/_/g" | \
    sed 's/\(.*\){TAB}\(.*\){TAB}.*/\2\t\1/g'
