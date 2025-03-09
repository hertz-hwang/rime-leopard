#by单单
fMB = 'mb.txt'  # 码表路径
fRes = 'res.txt'  # 保存路径
lenCode_limit = {1: 1, 2: 1, 3: 1, 4: 99}  # 不指定为1重

isFreq = True  # 是否按照词频重新排序 True|False
fFreq = 'zp.txt'  # 词频路径

# 处理码表
with open(fMB, 'r', encoding='utf8') as f:  # 载入码表
    temp = f.readlines()
    word_codes = [i.strip('\n').split('\t') for i in temp]

# 排序
if isFreq:
    # 处理词频
    with open(fFreq, 'r', encoding='utf8') as f:  # 载入字词频表
        temp = f.readlines()
        freq = {}
        for i in temp:
            j = i.strip('\n').split('\t')
            freq[j[0]] = int(j[1])
    data = [[word, freq.get(word[0], 1)] for word in word_codes]
    data.sort(key=lambda x: x[1], reverse=True)
    word_codes = [i[0] for i in data]

# 出简不出全
codes = [i[1] for i in word_codes]
simpCodes = []
code_dict = {}
for code in codes:
    for i in range(len(code)):
        limit = lenCode_limit.get(i + 1, 1)
        theCode = code[:i + 1]
        if code_dict.get(theCode, 0) < limit or i == len(code) - 1:
            simpCodes.append(theCode)
            if theCode in code_dict:
                code_dict[theCode] += 1
            else:
                code_dict[theCode] = 1
            break

# 保存
with open(fRes, 'w', encoding='utf8') as f:
    for i in range(len(simpCodes)):
        f.write(f'{word_codes[i][0]}\t{simpCodes[i]}\n')
