#!/usr/bin/env python3
"""Check that the length in each S("string", length, index) call of text_gen.v equals the real string length"""
import re
import sys
import os

path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "rtl", "text_gen.v")
text = open(path, encoding="utf-8").read()
bad = 0
for m in re.finditer(r'S\("([^"]*)",\s*(\d+)\s*,', text):
    s, n = m.group(1), int(m.group(2))
    if len(s) != n:
        bad += 1
        print("length %d but declared %d : %r" % (len(s), n, s))
    if len(s) > 48:
        print("too long (>48):", repr(s))
        bad += 1
print("mismatches:", bad)
sys.exit(1 if bad else 0)
