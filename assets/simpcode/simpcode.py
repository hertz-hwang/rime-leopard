#by单单
import time
import re
import os

# 开始计时
start_time = time.time()

# 从环境变量获取目录
SCHEMAS_DIR = os.getenv('SCHEMAS_DIR', '../schemas/hao')
ASSETS_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# 文件路径
fMB = os.path.join(SCHEMAS_DIR, 'hao.full.dict.yaml')  # 码表路径
fRes = os.path.join(ASSETS_DIR, 'simpcode/res.txt')  # 保存路径
lenCode_limit = {1: 1, 2: 1, 3: 1, 4: 99}  # 不指定为1重

isFreq = True  # 是否按照词频重新排序 True|False
fFreq = os.path.join(SCHEMAS_DIR, 'freq.txt')  # 词频路径
fEquiv = os.path.join(ASSETS_DIR, 'simpcode/pair_equivalence.txt')  # 当量文件路径

# 处理数字编码，将数字替换为数字前的最后一个字母重复两次
def replace_digits(code):
    import re
    # 查找编码中的数字部分
    match = re.search(r'([a-z])(\d+)$', code)
    if match:
        last_letter = match.group(1)  # 数字前的最后一个字母
        return code[:match.start(2)] + last_letter * 2  # 重复两次替换数字
    return code

print(f"1. 开始加载当量数据... {time.time() - start_time:.2f}秒")
# 加载当量数据
equiv_data = {}
try:
    with open(fEquiv, 'r', encoding='utf8') as f:
        for line in f:
            parts = line.strip().split('\t')
            if len(parts) == 2:
                equiv_data[parts[0]] = float(parts[1])
    print(f"成功加载当量数据，共{len(equiv_data)}条记录")
except Exception as e:
    print(f"加载当量文件出错: {e}")
    
# 计算编码的当量值 - 使用缓存优化性能
equiv_cache = {}
def calculate_equiv(code):
    if code in equiv_cache:
        return equiv_cache[code]
        
    total_equiv = 0
    # 计算每个相邻字符对的当量
    for i in range(len(code) - 1):
        pair = code[i:i+2]
        total_equiv += equiv_data.get(pair, 1.5)  # 默认为1.5
    
    equiv_cache[code] = total_equiv
    return total_equiv

print(f"2. 开始处理码表... {time.time() - start_time:.2f}秒")
# 处理码表
word_codes = []
try:
    with open(fMB, 'r', encoding='utf8') as f:  # 载入码表
        # 跳过YAML头部
        in_header = False
        for line in f:
            line = line.strip('\n')
            
            # 处理YAML头部
            if line == '---':
                in_header = True
                continue
            if in_header:
                if line == '...':
                    in_header = False
                continue
                
            # 处理实际数据
            if line and not line.startswith('#'):
                parts = line.split('\t')
                if len(parts) >= 2:
                    # 处理编码中的数字部分
                    parts[1] = replace_digits(parts[1])
                    word_codes.append(parts)
    print(f"成功加载码表，共{len(word_codes)}条记录")
except Exception as e:
    print(f"加载码表文件出错: {e}")

print(f"3. 加载词频数据... {time.time() - start_time:.2f}秒")
# 加载词频数据
freq = {}
try:
    with open(fFreq, 'r', encoding='utf8') as f:  # 载入字词频表
        for line in f:
            parts = line.strip('\n').split('\t')
            if len(parts) >= 2:
                # 将词频值转换为浮点数，并确保在0~1之间
                freq_value = float(parts[1])
                freq_value = max(0.0, min(1.0, freq_value))  # 限制在0~1之间
                freq[parts[0]] = freq_value
    print(f"成功加载词频数据，共{len(freq)}条记录")
except Exception as e:
    print(f"加载词频文件出错: {e}")

print(f"4. 处理排序... {time.time() - start_time:.2f}秒")
# 为每个词语添加词频信息（默认为0）
for i in range(len(word_codes)):
    if len(word_codes[i]) >= 1:
        char = word_codes[i][0]
        word_freq = freq.get(char, 0.0)  # 默认值改为0.0
        # 如果词代码中已经有词频（weight），则保留，否则添加
        if len(word_codes[i]) >= 3:
            try:
                # 尝试转换现有的权重值为浮点数
                existing_weight = float(word_codes[i][2])
                # 如果转换成功且在有效范围内，则保留
                if 0.0 <= existing_weight <= 1.0:
                    word_freq = existing_weight
            except:
                pass
        
        # 确保word_codes[i]至少有3个元素
        while len(word_codes[i]) < 3:
            word_codes[i].append('')
        
        word_codes[i][2] = f"{word_freq:.6f}"  # 设置词频，保留6位小数

# 排序
if isFreq:
    word_codes.sort(key=lambda x: float(x[2]) if len(x) >= 3 and x[2] else 0.0, reverse=True)

print(f"5. 开始生成简码... {time.time() - start_time:.2f}秒")
# 出简不出全，考虑当量手感
codes = []
for word in word_codes:
    if len(word) >= 2:
        codes.append(word[1])
    else:
        codes.append("")

# 优化的简码生成算法
simplified_codes = []  # 存储最终的简码
used_codes = {}  # 跟踪每个简码已被使用的次数

# 为每个词语分配简码
for word_idx, full_code in enumerate(codes):
    if not full_code:  # 跳过空编码
        simplified_codes.append("")
        continue
        
    # 找出该词可能的所有简码并计算当量值
    candidates = []
    for length in range(1, min(len(full_code) + 1, 5)):  # 限制最大简码长度为4
        code_prefix = full_code[:length]
        equiv_value = calculate_equiv(code_prefix)
        candidates.append((code_prefix, equiv_value, length))
    
    # 按照当量值排序（值越小越好）
    candidates.sort(key=lambda x: x[1])
    
    # 尝试分配简码，优先使用当量值低的
    code_assigned = False
    for code_prefix, _, length in candidates:
        limit = lenCode_limit.get(length, 1)
        current_count = used_codes.get(code_prefix, 0)
        
        if current_count < limit:
            simplified_codes.append(code_prefix)
            used_codes[code_prefix] = current_count + 1
            code_assigned = True
            break
    
    # 如果无法分配简码，则使用完整编码
    if not code_assigned:
        simplified_codes.append(full_code)

print(f"6. 保存结果... {time.time() - start_time:.2f}秒")
# 保存结果，包含字频信息
try:
    with open(fRes, 'w', encoding='utf8') as f:
        for i in range(min(len(word_codes), len(simplified_codes))):
            if len(word_codes[i]) >= 2:
                char = word_codes[i][0]
                code = simplified_codes[i]
                freq_value = word_codes[i][2] if len(word_codes[i]) >= 3 else "0"
                f.write(f'{char}\t{code}\t{freq_value}\n')
    print(f"结果已保存到 {fRes}，共{min(len(word_codes), len(simplified_codes))}条记录")
except Exception as e:
    print(f"保存结果文件出错: {e}")

print(f"处理完成！总耗时: {time.time() - start_time:.2f}秒")