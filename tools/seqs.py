import re,sys
path,f=sys.argv[1],sys.argv[2]; labels=sys.argv[3].split(','); L=int(sys.argv[4]) if len(sys.argv)>4 else 2500
parts=re.split(r'Rule\?\s*',open(path).read())
for lab in labels:
    full=f+('.'+lab if lab else '')
    last=None
    for i,p in enumerate(parts):
        m=re.search(r'\n('+re.escape(full)+r' :.*)',p,re.S)
        if m: last=(i,m.group(1))
    if last:
        s=re.sub(r'\n\s*\n','\n',last[1])
        # compact: formulas first 3 lines each
        blocks=re.split(r'\n(?=[\[{]-?\d+[\]}])',s)
        out=[]
        for b in blocks:
            ls=b.split('\n'); out.append('\n'.join(ls[:4])[:420])
        print('==== %s (prompt %d) ====\n'%(full,last[0])+'\n'.join(out)[:L])
