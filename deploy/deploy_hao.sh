#!/bin/zsh

# 豹码输入法部署脚本
# 用途：生成豹码输入法的 RIME 方案并打包发布
# 作者：原作者
# 最后更新：$(date +%Y-%m-%d)

set -e  # 遇到错误立即退出
set -u  # 使用未定义的变量时报错

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >&2
}

error() {
    log "错误: $1" >&2
    exit 1
}

# 检测操作系统类型
OS_TYPE=$(uname)

# 初始化环境变量和工作目录
source ~/.zshrc

cd "$(dirname $0)" || error "无法切换到脚本目录"
WD="$(pwd)"
SCHEMAS="../schemas"
REF_NAME="${REF_NAME:-v$(date +%Y%m%d%H%M)}"

# 创建内存中的临时目录
create_ramdisk() {
    local size="512M"
    
    if [ "${OS_TYPE}" = "Darwin" ]; then
        # macOS 实现
        RAMDISK=$(mktemp -d) || error "无法创建临时目录"
        # macOS 下使用原生临时文件系统，它默认就在内存中
        trap 'log "清理临时文件..."; rm -rf "${RAMDISK}"' EXIT
    elif [ "${OS_TYPE}" = "Linux" ]; then
        # Linux 实现 - 修改为不使用 mount 命令
        RAMDISK=$(mktemp -d) || error "无法创建临时目录"
        # 在 GitHub Actions 中，直接使用 /tmp 目录，不需要额外挂载
        trap 'log "清理临时文件..."; rm -rf "${RAMDISK}"' EXIT
    else
        error "不支持的操作系统: ${OS_TYPE}"
    fi
    
    log "成功创建内存临时目录: ${RAMDISK}"
}

# 清理和准备目录
rm -rf "${SCHEMAS}/hao/build" "${SCHEMAS}/releases"
create_ramdisk
mkdir -p "${SCHEMAS}/releases"

# 生成输入方案
gen_schema() {
    local NAME="$1"
    local DESC="${2:-${NAME}}"
    
    if [ -z "${NAME}" ]; then
        error "方案名称不能为空"
    fi
    
    log "开始生成方案: ${NAME}"
    
    local HAO="${RAMDISK}/${NAME}"
    mkdir -p "${HAO}/lua/hao" "${HAO}/lua/ace" "${HAO}/opencc" || error "无法创建必要目录"
    
    # 复制基础文件到内存
    log "复制基础文件到内存..."
    cp ../table/*.txt "${HAO}" || error "复制码表文件失败"
    cp ../template/default.*.yaml ../template/hao.*.yaml ../template/hao.*.txt "${HAO}" || error "复制模板文件失败"
    cp ../template/squirrel.yaml "${HAO}" || error "复制 squirrel 配置失败"
    cp ../template/stroke*.yaml "${HAO}" || error "复制 stroke 配置失败"
    cp ../template/symbols.yaml "${HAO}" || error "复制 symbols 配置失败"
    cp ../template/weasel.yaml "${HAO}" || error "复制 weasel 配置失败"
    cp ../template/lua/hao/*.lua "${HAO}/lua/hao" || error "复制 Lua 脚本失败"
    cp -r ../template/lua/ace/* "${HAO}/lua/ace" || error "复制 Lua 脚本失败"
    cp ../template/opencc/*.json ../template/opencc/*.txt "${HAO}/opencc" || error "复制 OpenCC 配置失败"
    cp ../template/leopard*.yaml "${HAO}" || error "复制豹码配置失败"
    cp ../template/qr*.yaml "${HAO}" || error "复制二维码配置失败"

    # 使用自定义配置覆盖默认值
    if [ -d "${NAME}" ]; then
        log "应用自定义配置..."
        cp -r "${NAME}"/*.txt "${HAO}"
    fi

    # 生成映射表
    log "生成映射表..."
    cat "${HAO}/map.txt" | python ../assets/gen_mappings_table.py >"${HAO}/hao.mappings_table.txt" || error "生成映射表失败"

    # 生成简化字码表
    log "生成简化字码表..."
    ./generator -q \
        -d "${HAO}/hao_div.txt" \
        -s "${HAO}/hao_simp.txt" \
        -m "${HAO}/hao_map.txt" \
        -f "${HAO}/freq.txt" \
        -w "${HAO}/cjkext_whitelist.txt" \
        -c "${HAO}/char.txt" \
        -u "${HAO}/fullcode.txt" \
        -o "${HAO}/div.txt" \
        || error "生成简化字码表失败"

    # 合并词典文件
    log "合并词典文件..."
    cat "${HAO}/char.txt" >>"${HAO}/hao.base.dict.yaml"
    grep -v '#' "${HAO}/hao_quick.txt" >>"${HAO}/hao.base.dict.yaml"
    cat "${HAO}/fullcode.txt" >>"${HAO}/hao.full.dict.yaml"
    #cat "${HAO}/hao.smart.txt" >"${HAO}/hao.smart.txt"
    cat "${HAO}/div.txt" >"${HAO}/opencc/hao_div.txt"

    # 生成词典
    log "生成词典..."
    mkdir -p "${HAO}/gendict/data"
    cat "${HAO}/fullcode.txt" > "${HAO}/gendict/data/单字全码表.txt"
    pushd ${WD}/../assets/gendict || error "无法切换到 gendict 目录"
        cp "${HAO}/gendict/data/单字全码表.txt" "data/单字全码表.txt"
        cargo run || error "生成词典失败"
        cat data/output.txt >> "${HAO}/hao.words.dict.yaml"
    popd

    # 生成单字fix全码表
    pushd ${WD}/../assets/simpcode || error "无法切换到 simpcode 目录"
        python genfullcode.py || error "生成单字fix全码表失败"
    popd

    # 生成简码
    log "生成简码..."
    if ! conda activate rime; then
        error "无法激活 conda 环境"
    fi
    
    # 创建简码生成所需的目录结构
    mkdir -p "${HAO}/simpcode"
    cp -r ../assets/simpcode/pair_equivalence.txt "${HAO}/simpcode/"
    
    # 检查必要文件是否存在
    for f in "${HAO}/hao.full.dict.yaml" "${HAO}/freq.txt"; do
        if [ ! -f "$f" ]; then
            error "缺少必要的文件: $f"
        fi
    done
    
    # 设置环境变量
    export SCHEMAS_DIR="${HAO}"
    export ASSETS_DIR="${HAO}"
    
    # 运行简码生成脚本
    pushd ${WD}/../assets/simpcode || error "无法切换到 simpcode 目录"
        python simpcode.py || error "生成简码失败"
        #cat res.txt >> "${HAO}/leopard.dict.yaml"
        awk '/单字标记/ {system("cat res.txt"); next} 1' ${HAO}/leopard.dict.yaml > temp && mv temp ${HAO}/leopard.dict.yaml
        awk '/单字全码/ {system("cat ../gendict/data/单字全码表_modified.txt"); next} 1' ${HAO}/leopard.dict.yaml > temp && mv temp ${HAO}/leopard.dict.yaml
    popd
    
    # 确保 leopard 配置文件存在
    for f in "${HAO}"/leopard*.yaml; do
        if [ ! -f "$f" ]; then
            error "缺少必要的leopard配置文件: $f"
        fi
    done

    # 生成大竹词提
    log "生成大竹词提..."
    export INPUT_DIR="${HAO}"
    export OUTPUT_DIR="${HAO}"
    bash ../assets/gen_dazhu.sh || error "生成大竹词提失败"

    # 处理词典文件
    if [ -f "${HAO}/leopard.dict.yaml" ]; then
        cat "${HAO}/leopard.dict.yaml" | \
            sed 's/^\(.*\)\t\(.*\)\t\(.*\)/\1\t\2/g' | \
            sed 's/\t/{TAB}/g' | \
            grep '.*{TAB}[a-z]\{1,2\}$' | \
            sed 's/{TAB}/\t/g' | \
            sed 's/$/1/g' \
            > "../deploy/hao/hao_simp.txt"
        log "重新生成简化字码表..."
        ./generator -q \
            -d "${HAO}/hao_div.txt" \
            -s "${HAO}/hao_simp.txt" \
            -m "${HAO}/hao_map.txt" \
            -f "${HAO}/freq.txt" \
            -w "${HAO}/cjkext_whitelist.txt" \
            -c "${HAO}/char.txt" \
            -u "${HAO}/fullcode.txt" \
            -o "${HAO}/div.txt" \
        || error "生成简化字码表失败"
    else
        error "leopard.dict.yaml 文件不存在"
    fi

    # 将最终文件复制到目标目录
    log "复制最终文件到目标目录..."
    mkdir -p "${SCHEMAS}/${NAME}"
    
    # 使用rsync进行选择性复制，排除指定文件
    rsync -a --exclude='/gendict' \
              --exclude='/simpcode' \
              --exclude='/多字词.txt' \
              --exclude='/char.txt' \
              --exclude='/cjkext_whitelist.txt' \
              --exclude='/div.txt' \
              --exclude='/freq*.txt' \
              --exclude='/fullcode.txt' \
              --exclude='/hao_*.txt' \
              --exclude='/map.txt' \
              "${HAO}/" "${SCHEMAS}/${NAME}/" || error "复制文件失败"

    # 删除临时目录
    log "删除临时目录..."
    rm -rf "${RAMDISK}"

    # 打包发布
    log "打包发布文件..."
    pushd "${SCHEMAS}" || error "无法切换到发布目录"
        tar -cf - "./${NAME}" | zstd -9 -T0 --long=31 -c > "releases/${NAME}-${REF_NAME}.tar.zst" || error "打包失败"
        #tar -cf - --exclude="wanxiang-lts-zh-hans.gram" "./${NAME}" | zstd -9 -T0 --long=31 -c > "releases/${NAME}-${REF_NAME}.tar.zst" || error "打包失败"
    popd

    log "方案 ${NAME} 生成完成"
}

# 主程序
log "开始部署豹码输入法..."
gen_schema hao || error "生成豹码方案失败"
log "部署完成"
