#!/bin/bash

cd "$(dirname $0)"
WD="$(pwd)"
SCHEMAS="../schemas"
REF_NAME="${REF_NAME:-v$(date +%Y%m%d%H%M)}"
rm -rf "${SCHEMAS}"
trap 'rm -rf "$TMPDIR"' EXIT
TMPDIR=$(mktemp -d) || exit 1

gen_schema() {
    NAME="$1"
    DESC="${2:-${NAME}}"
    if [ -z "${NAME}" ]; then
        return 1
    fi
    HAO="${SCHEMAS}/${NAME}"
    mkdir -p /"${TMPDIR}"/"${NAME}" "${HAO}/lua/hao" "${HAO}/opencc"
    cp ../table/*.txt /"${TMPDIR}"/"${NAME}"
    cp ../template/default.*.yaml ../template/hao.*.yaml ../template/hao.*.txt "${HAO}"
    cp ../template/squirrel.yaml "${HAO}"
    cp ../template/lua/hao/*.lua "${HAO}/lua/hao"
    cp ../template/opencc/*.json ../template/opencc/*.txt "${HAO}/opencc"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i "" "s/name: 豹碼/name: 豹碼·${NAME}/g" "${HAO}"/hao.{custom,schema}.yaml
        #sed -i "" "s/version: beta/version: ${REF_NAME}/g" "${HAO}"/*.dict.yaml "${HAO}"/hao.schema.yaml
    else
        # Linux 和其他系统
        sed -i "s/name: 豹碼/name: 豹碼·${NAME}/g" "${HAO}"/hao.{custom,schema}.yaml
        #sed -i "s/version: beta/version: ${REF_NAME}/g" "${HAO}"/*.dict.yaml "${HAO}"/hao.schema.yaml
    fi
    #sed -i "s/version: beta/version: ${REF_NAME}/g" "${HAO}"/*.dict.yaml "${HAO}"/hao.schema.yaml
    # 使用 deploy/hao 覆蓋默認值
    if [ -d "${NAME}" ]; then
        cp -r "${NAME}"/*.txt /"${TMPDIR}"/"${NAME}"
    fi
    cat /"${TMPDIR}"/"${NAME}"/hao_map.txt | python ../assets/gen_mappings_table.py >"${HAO}"/hao.mappings_table.txt
    # 生成簡化字碼表
    ./generator -q \
        -d /"${TMPDIR}"/"${NAME}"/hao_div.txt \
        -s /"${TMPDIR}"/"${NAME}"/hao_simp.txt \
        -m /"${TMPDIR}"/"${NAME}"/hao_map.txt \
        -f /"${TMPDIR}"/"${NAME}"/freq.txt \
        -w /"${TMPDIR}"/"${NAME}"/cjkext_whitelist.txt \
        -c /"${TMPDIR}"/char.txt \
        -u /"${TMPDIR}"/fullcode.txt \
        -o /"${TMPDIR}"/div.txt \
        || exit 1
    cat /"${TMPDIR}"/char.txt >>"${HAO}/hao.base.dict.yaml"
    grep -v '#' /"${TMPDIR}"/"${NAME}"/hao_quick.txt >>"${HAO}/hao.base.dict.yaml"
    cat /"${TMPDIR}"/fullcode.txt >>"${HAO}/hao.full.dict.yaml"
    cat /"${TMPDIR}"/${NAME}/hao.smart.txt >>"${HAO}/hao.smart.txt"
    cat /"${TMPDIR}"/div.txt >"${HAO}/opencc/hao_div.txt"
}

# 打包 hao 方案
gen_schema hao 半音托版 || exit 1
