#
# neschael
# tools/fix_dbg.py
#
# adds 16 to the offsets of code and vectors to make the dbg line up in mesen
# this is a byproduct of having three bin files, but (hopefully) this will make it eaasier to have a build option
# that omits the header
# 

import sys, re

def add16(m):
    return f"ooffs={int(m.group(1)) + 16}"

def fix(line):
    # only touch the two relevant lines
    if 'oname="bin/prg.bin"' not in line:
        return line
    
    return re.sub(r'ooffs=(\d+)', add16, line)

with open(sys.argv[1], 'r') as f:
    lines = f.readlines()

with open(sys.argv[1], 'w') as f:
    for line in lines:
        f.write(fix(line))

print("dbg file updated")