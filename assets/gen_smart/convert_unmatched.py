#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import re
from collections import defaultdict

def load_encoding_dict(dict_file):
    """加载编码字典"""
    encoding_dict = {}
    with open(dict_file, 'r', encoding='utf-8') as f:
        for line in f:
            if not line.strip() or line.startswith('#'):
                continue
            parts = line.strip().split('\t')
            if len(parts) >= 2:
                word = parts[0]
                code = parts[1]
                encoding_dict[word] = code
    return encoding_dict

def encode_sentence(sentence, encoding_dict):
    """将句子转换为编码"""
    codes = []
    for char in sentence:
        if char in encoding_dict:
            codes.append(encoding_dict[char])
        else:
            print(f"警告：找不到字符 '{char}' 的编码")
    return ' '.join(codes)  # 用空格连接每个字的编码

def process_unmatched_lines(unmatched_file, encoding_dict, output_file):
    """处理未匹配的行并生成输出"""
    # 读取现有的userdb内容
    existing_entries = []
    existing_words = set()
    header_lines = []
    seen_entries = set()  # 用于去重
    
    with open(output_file, 'r', encoding='utf-8') as f:
        for line in f:
            if line.startswith('#'):
                header_lines.append(line)
                continue
            if not line.strip():
                continue
            parts = line.strip().split('\t')
            if len(parts) >= 2:
                # 只保留每个词句的第一次出现
                if parts[1] not in existing_words:
                    existing_entries.append((parts[0], parts[1], parts[2] if len(parts) > 2 else 'c=0 d=0 t=0'))
                    existing_words.add(parts[1])

    print(f"现有userdb中有 {len(existing_entries)} 个条目（去重后）")

    # 处理新条目
    new_entries = []
    processed_count = 0
    skipped_count = 0
    
    with open(unmatched_file, 'r', encoding='utf-8') as f:
        for line in f:
            parts = line.strip().split('\t')
            if len(parts) >= 1:
                sentence = parts[0]
                if sentence not in existing_words:  # 只处理不存在的词句
                    code = encode_sentence(sentence, encoding_dict)
                    if code:
                        new_entries.append((code, sentence, 'c=0 d=0 t=0'))
                        existing_words.add(sentence)  # 防止新条目中也有重复
                        processed_count += 1
                else:
                    skipped_count += 1

    print(f"处理了 {processed_count} 个新句子")
    print(f"跳过了 {skipped_count} 个句子")

    # 合并并排序所有条目
    all_entries = existing_entries + new_entries
    all_entries.sort(key=lambda x: x[0])  # 按编码排序

    # 写入文件
    with open(output_file, 'w', encoding='utf-8') as f:
        # 写入头部注释
        for line in header_lines:
            f.write(line)
        
        # 写入所有条目
        for code, word, extra in all_entries:
            f.write(f"{code}\t{word}\t{extra}\n")

    print(f"已写入 {len(all_entries)} 个条目")

def main():
    # 文件路径
    unmatched_file = 'assets/gen_smart/unmatched_lines.txt'
    dict_file = 'schemas/hao/dicts/leopard_smart.dict.yaml'
    output_file = 'assets/gen_smart/leopard_smart.userdb.txt'

    # 检查文件是否存在
    if not os.path.exists(dict_file):
        print(f"错误：找不到字典文件 {dict_file}")
        return

    if not os.path.exists(unmatched_file):
        print(f"错误：找不到未匹配文件 {unmatched_file}")
        return

    # 加载编码字典
    encoding_dict = load_encoding_dict(dict_file)
    print(f"已加载 {len(encoding_dict)} 个编码映射")

    # 处理未匹配的行
    process_unmatched_lines(unmatched_file, encoding_dict, output_file)
    print("处理完成")

if __name__ == '__main__':
    main() 