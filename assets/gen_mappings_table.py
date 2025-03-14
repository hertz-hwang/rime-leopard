#!/bin/python

'''
> cat deploy/hao/hao_map.txt | ./asset/gen_mappings_table.py
'''

import sys

mappings: dict[str, list[str]] = {}

space = " " * 13
banner = "│"

def get_row_data(key: str, line: int, cols: int) -> str:
    '''
    generate a row of data from mappings of key
    '''
    if line == 0:
        # head line
        return "="*17 + " "*3 + key + " "*3 + "="*17
    offset, limit = (line-1)*cols, cols
    comps = mappings[key]
    if offset + limit <= len(comps):
        return banner.join(comps[offset:offset+limit])
    elif offset < len(comps):
        return banner.join(comps[offset:len(comps)] + [space]*(offset+limit-len(comps)))
    else:
        return banner.join([space] * limit)

# read all mappings from stdin
for line in sys.stdin.readlines():
    code, comp = line.strip().split('\t')[:2]
    key = code[0]
    comp = comp.strip("{}")
    if not mappings.get(key):
        mappings[key] = []
    mappings[key].append(comp + " "*(13-len(comp)*2-len(code)) + code)

#for row in ["QWERT", "YUIOP", "ASDFG", "HJKL", "ZXCVB", "NM"]:
for row in ["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"]:
    # suppose that every table has 10 rows, then filter the empty ones
    for i in range(0, 10):
        line = []
        for key in row:
            if not mappings.get(key):
                continue
            line.append(get_row_data(key, i, 3))
        line = (banner+space+banner).join(line).rstrip(" "+banner)
        if len(line.strip(" "+banner)) != 0:
            print(space+banner, line, banner, sep="")
    print()
