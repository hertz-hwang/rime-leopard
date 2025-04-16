#!/bin/sh

# 生成大竹碼表
#
# 环境变量:
#   INPUT_DIR: 输入文件目录
#   OUTPUT_DIR: 输出文件目录

# 检查必要的环境变量
if [ -z "${INPUT_DIR}" ] || [ -z "${OUTPUT_DIR}" ]; then
    echo "错误: 需要设置 INPUT_DIR 和 OUTPUT_DIR 环境变量"
    exit 1
fi

# 生成大竹码表
cat "${INPUT_DIR}/hao.words.dict.yaml" | \
    sed 's/^\(.*\)\t\(.*\)/\1\t\2⇥/g' | \
    sed 's/\t/{TAB}/g' | \
    grep '.*{TAB}.*' | \
    sed 's/{TAB}/\t/g' | \
    awk '{print $2 "\t" $1}' | \
    sed 's/1/_/g' | \
    sed 's/2/;/g' | \
    sed "s/3/'/g" \
    >"${OUTPUT_DIR}/assets/dazhu-hao.txt"

cat "${INPUT_DIR}/hao.base.dict.yaml" | \
    sed 's/^\(.*\)\t\(.*\)/\1\t\2/g' | \
    sed 's/\t/{TAB}/g' | \
    grep '.*{TAB}.*' | \
    sed 's/{TAB}/\t/g' | \
    awk '{print $2 "\t" $1}' | \
    sed 's/1/_/g' | \
    sed 's/2/;/g' | \
    sed "s/3/'/g" \
    >>"${OUTPUT_DIR}/assets/dazhu-hao.txt"

cat "${INPUT_DIR}/hao.full.dict.yaml" | \
    sed 's/^\(.*\)\t\(.*\)/\1\t\2⇥/g' | \
    sed 's/\t/{TAB}/g' | \
    grep '.*{TAB}.*' | \
    sed 's/{TAB}/\t/g' | \
    awk '{print $2 "\t" $1}' | \
    sed 's/1/_/g' | \
    sed 's/2/;/g' | \
    sed "s/3/'/g" \
    >>"${OUTPUT_DIR}/assets/dazhu-hao.txt"

if [ -f "${INPUT_DIR}/hao.symbols.dict.yaml" ]; then
    cat "${INPUT_DIR}/hao.symbols.dict.yaml" | \
        sed 's/^\(.*\)\t\(.*\)/\1\t\2/g' | \
        sed 's/\t/{TAB}/g' | \
        grep '.*{TAB}.*' | \
        sed 's/{TAB}/\t/g' | \
        awk '{print "/" $2 "\t" $1}' \
        >>"${OUTPUT_DIR}/assets/dazhu-hao.txt"
fi

if [ -f "${INPUT_DIR}/opencc/hao_div.txt" ]; then
    cat "${INPUT_DIR}/opencc/hao_div.txt" | \
        sed 's/\(.*\)\t\(.*\)/\2\t\1/g' \
        >>"${OUTPUT_DIR}/assets/dazhu-hao.txt"
fi

if [ -f "${INPUT_DIR}/leopard.dict.yaml" ]; then
    cat "${INPUT_DIR}/leopard.dict.yaml" | \
        sed 's/^\(.*\)\t\(.*\)/\1\t\2/g' | \
        sed 's/\t/{TAB}/g' | \
        grep '.*{TAB}.*' | \
        sed 's/{TAB}/\t/g' | \
        awk '{print $2 "\t" $1}' | \
        sed 's/1/_/g' | \
        sed 's/2/;/g' | \
        sed "s/3/'/g" \
        >"${OUTPUT_DIR}/assets/dazhu-leopard.txt"
    
    cat "${INPUT_DIR}/dicts/leopard.personal.dict.yaml" | \
        sed 's/^\(.*\)\t\(.*\)/\1\t\2/g' | \
        sed 's/\t/{TAB}/g' | \
        grep '.*{TAB}.*' | \
        sed 's/{TAB}/\t/g' | \
        awk '{print $2 "\t" $1}' \
        >>"${OUTPUT_DIR}/assets/dazhu-leopard.txt"
    
    cat "${INPUT_DIR}/hao.symbols.dict.yaml" | \
        sed 's/^\(.*\)\t\(.*\)/\1\t\2/g' | \
        sed 's/\t/{TAB}/g' | \
        grep '.*{TAB}.*' | \
        sed 's/{TAB}/\t/g' | \
        awk '{print "/" $2 "\t" $1}' \
        >>"${OUTPUT_DIR}/assets/dazhu-leopard.txt"

    if [ -f "${INPUT_DIR}/opencc/hao_div.txt" ]; then
        cat "${INPUT_DIR}/opencc/hao_div.txt" | \
            sed 's/\(.*\)\t\(.*\)/\2\t\1/g' \
            >>"${OUTPUT_DIR}/assets/dazhu-leopard.txt" && \
        cat "${INPUT_DIR}/opencc/hao_div.txt" | \
            sed 's/\(.*\)\t(\(.*\),.*,.*/\2\t\1/g' \
            >"${OUTPUT_DIR}/assets/dazhu-leopard-chai.txt"
    fi
fi

#sed 's/^\(.*\)\t\(.*\)/\1\t\2/g' | \
#    sed 's/\t/{TAB}/g' | \
#    grep '.*{TAB}.*' | \
#    sed -E 's/(\W+){TAB}([0-9a-z]+).*\n/\1{TAB}\2\n/g' #| \
#    #sed 's/1/_/g' | \
#    #sed 's/2/_/g' | \
    #sed "s/3/_/g" #| \
    #sed 's/\(.*\){TAB}\(.*\)/\2\t\1/g'
