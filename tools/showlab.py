#!/usr/bin/env python3
import re,sys
# usage: showlab.py transcript formula label maxchars [hyps_only_first_lines]
path,f,lab=sys.argv[1],sys.argv[2],sys.argv[3]; L=int(sys.argv[4]) if len(sys.argv)>4 else 2000
full=f+('.'+lab if lab else '')
parts=re.split(r'Rule\?\s*',open(path).read())
last=None
for i,p in enumerate(parts[:-1]):
    m=re.search(r'\n('+re.escape(full)+r' :.*)',p,re.S)
    if m: last=(i,m.group(1))
if last:
    s=re.sub(r'\n\s*\n','\n',last[1]); blocks=re.split(r'\n(?=[\[{]-?\d+[\]}])',s)
    out=[]
    for b in blocks:
        ls=b.split('\n'); out.append('\n'.join(ls[:3])[:330])
    print('==== %s (prompt %d) ====\n'%(full,last[0])+'\n'.join(out)[:L])
