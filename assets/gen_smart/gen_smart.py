#!/usr/bin/env python3
# -*- coding: utf-8 -*-

def read_minimal_set(filename):
    """读取最小字集文件"""
    with open(filename, 'r', encoding='utf-8') as f:
        return set(line.strip() for line in f)

def process_dict_file(input_file, output_file, minimal_set):
    """处理码表，只保留最小字集中的单字，并在单字一简后添加下划线"""
    with open(input_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    output_lines = []
    in_single_char_section = False
    
    for line in lines:
        if line.strip() == '#----------单字开始----------#':
            in_single_char_section = True
            output_lines.append(line)
            continue
        
        if line.strip() == '#----------单字结束----------#':
            in_single_char_section = False
            output_lines.append(line)
            continue
        
        if in_single_char_section and line.strip() and not line.startswith('#'):
            parts = line.split('\t')
            if len(parts) >= 2:
                char = parts[0]
                code = parts[1]
                
                # 检查字是否在最小字集中
                if char in minimal_set:
                    # 如果是一简编码，添加下划线
                    if len(code) == 1:
                        parts[1] = code + '_'
                        line = '\t'.join(parts)
                    
                    output_lines.append(line)
        else:
            output_lines.append(line)
    
    # 写入处理后的文件
    with open(output_file, 'w', encoding='utf-8') as f:
        f.writelines(output_lines)

def main():
    minimal_set = read_minimal_set('minimalset.txt')
    process_dict_file('../../schemas/hao/leopard_smart_temp.dict.yaml', 
                     '../../schemas/hao/leopard_smart.dict.yaml',
                     minimal_set)
    print("处理完成！新文件已保存为 ../../leopard_smart.dict.yaml")

if __name__ == '__main__':
    main() 