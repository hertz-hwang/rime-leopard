#!/bin/sh

# 生成大竹碼表
#
# Usage:
#   cat docs/hao/smyh.full.dict.yaml | assets/gen_dazhu_addfull.sh >>dazhu.txt

sed 's/\(.*\)\t\(.*\)/\1\t\2/g' | \
    sed 's/\t/{TAB}/g' | \
    grep '.*{TAB}.*' | \
    sed 's/1/_/g' | \
    sed 's/2/;/g' | \
    sed 's/\(.*\){TAB}\(.*\)/全\2\t\1/g'
