#!/bin/sh

# Usage:
#   cat ../chaifen/三碼豹碼字根碼位映射表.csv | table/gen_map.sh >table/hao_map.txt

# 忽略首行 => 排序并去重
tail -n +2 | sed 's/\(.*\),.*,\(.*\)/\2\t\1/g' | sort --unique
