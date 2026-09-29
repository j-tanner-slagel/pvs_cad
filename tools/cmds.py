import re,sys
path,f=sys.argv[1],sys.argv[2]
parts=re.split(r'Rule\?\s*',open(path).read())
for i,p in enumerate(parts[1:],start=1):
    lines=[l for l in p.split('\n') if l.strip()]
    lab=re.findall(r'^('+f+r'(?:\.\d+)*) :',p,re.M)
    print(i,'|',lines[0][:55],'|',lab[-1:],'|',[x[:60] for x in lines if re.search(r'yields|completes|No change|Error|Restoring',x)][:2])
