import re,sys
path,f=sys.argv[1],sys.argv[2]; N=int(sys.argv[3]) if len(sys.argv)>3 else 20
parts=re.split(r'Rule\?\s*',open(path).read())
seen={}
for p in parts[-N:]:
    m=re.search(r'\n('+f+r'(?:\.\d+)*(?:T)?) (?:\(TCC\))?:\s*\n(.*)',p,re.S)
    if m:
        lab=m.group(1); body=re.sub(r'\n\s*\n','\n',m.group(2)); i=body.find('|-------')
        hyps=[l for l in body[:i].split('\n') if re.match(r'\s*[\[{]-\d+',l)]
        seen[lab]=(len(hyps), re.sub(r'\s+',' ',body[i+8:i+330]))
for lab,(nh,succ) in seen.items(): print(f'{lab}  [{nh} hyps] |- {succ}')
