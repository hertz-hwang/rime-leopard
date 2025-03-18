import os
import re

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

input_path = os.path.join(os.path.dirname(__file__), '../gendict/data/单字全码表.txt')
output_path = input_path.replace('.txt', '_modified.txt')

with open(input_path, 'r', encoding='utf-8') as f_in, \
     open(output_path, 'w', encoding='utf-8') as f_out:
    
    for line in f_in:
        processed = process_line(line)
        f_out.write(processed)

print(f"文件处理完成，生成新文件：{output_path}")
