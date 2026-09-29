import re,sys
# usage: effective.py session.txt transcript.txt out_cmds.txt  -> writes commands that had an effect (in order)
raw=open(sys.argv[1]).read().split('\n')[4:]
# join lines into balanced s-expressions
cmds=[]; buf=''; depth=0
for l in raw:
    if not l.strip() and depth==0: continue
    buf += (('\n' if buf else '') + l)
    depth += l.count('(') - l.count(')')
    if depth<=0:
        c=buf.strip(); buf=''; depth=0
        if c not in ('(postpone)','(quit)','(bye)') and c: cmds.append(c)
parts=re.split(r'Rule\?\s*',open(sys.argv[2]).read())
eff=[]
for i,c in enumerate(cmds, start=1):
    if i>=len(parts): break
    res=parts[i]
    if 'Q.E.D' in res: eff.append(c); break
    if 'Postponing' in res[:200]: break
    if 'No change on' in res or 'Restoring the state' in res: continue
    eff.append(c)
open(sys.argv[3],'w').write('\n'.join(eff)+'\n'); print(sys.argv[1].split('/')[-1], 'total',len(cmds),'effective',len(eff))
