#!/bin/bash

# 创建deploy文件的字符列表
cut -f1 -d'[' deploy/hao/smyh_div.txt | sort > /tmp/deploy_chars.txt

# 找出在table中但不在deploy中的字符及其拆分信息，只显示前500条
echo "以下字符在table/smyh_div.txt中存在，但在deploy/hao/smyh_div.txt中缺失 (前100条):"
echo `date` | awk -F" " '{ print "# " $1 $2 $3 "\n" }' > lost_div.txt
awk 'BEGIN{FS="["} 
     NR==FNR{chars[$1]=1; next} 
     !($1 in chars){print $0}' \
    /tmp/deploy_chars.txt table/smyh_div.txt | head -n 100 >>lost_div.txt

# 清理临时文件
rm /tmp/deploy_chars.txt 