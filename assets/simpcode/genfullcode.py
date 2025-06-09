import os
import re

def load_freq_dict(freq_file):
    freq_dict = {}
    with open(freq_file, 'r', encoding='utf-8') as f:
        for line in f:
            if line.startswith('#'):
                continue
            char, freq = line.strip().split('\t')
            freq_dict[char] = float(freq)
    return freq_dict

def process_line(line):
    result = []
    last_letter = None
    for char in line:
        if char.isalpha():
            last_letter = char
        elif char == '1' and last_letter is not None:
            result.append(last_letter)
            continue
        result.append(char)
    return ''.join(result)

# 读取字频文件
freq_path = os.path.join(os.path.dirname(__file__), '../../deploy/hao/freq.txt')
freq_dict = load_freq_dict(freq_path)

# 读取并处理编码文件
input_path = os.path.join(os.path.dirname(__file__), '../gendict/data/单字全码表.txt')
output_path = input_path.replace('.txt', '_modified.txt')

# 存储处理后的数据
processed_data = []

with open(input_path, 'r', encoding='utf-8') as f_in:
    for line in f_in:
        processed = process_line(line)
        char = processed[0]  # 第一个字符是汉字
        code = processed[1:].strip()  # 剩余部分是编码
        freq = freq_dict.get(char, 0.0)  # 获取字频，如果不存在则为0
        processed_data.append((char, code, freq))

# 按字频排序（从高到低）
processed_data.sort(key=lambda x: x[2], reverse=True)

# 写入结果
with open(output_path, 'w', encoding='utf-8') as f_out:
    for char, code, freq in processed_data:
        f_out.write(f"{char}\t{code}\t{freq:.10f}\n")

print(f"文件处理完成，生成新文件：{output_path}")
