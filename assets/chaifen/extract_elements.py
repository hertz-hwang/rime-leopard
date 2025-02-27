def extract_elements(line):
    """从一行文本中提取元素集合"""
    elements = set()
    parts = line.split('\t')
    if len(parts) < 2:
        return elements
        
    content = parts[1]
    i = 0
    while i < len(content):
        if content[i] == '{':
            # 找到匹配的右括号
            end = content.find('}', i)
            if end != -1:
                # 提取大括号内的内容作为一个元素
                elements.add(content[i:end+1])
                i = end + 1
                continue
        elif content[i] not in ['\n', '\t', ' ']:
            # 将单个字符作为元素
            elements.add(content[i])
        i += 1
    return elements

def main():
    all_elements = set()
    
    with open('chaifen.txt', 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('...'):
                elements = extract_elements(line)
                all_elements.update(elements)
    
    # 输出所有元素
    print("找到的所有元素:")
    for element in sorted(all_elements):
        print(element)
    print(f"\n总共找到 {len(all_elements)} 个元素")

if __name__ == '__main__':
    main() 