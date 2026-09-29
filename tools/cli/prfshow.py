import re,sys
# prfshow.py <file.prf> <formula>: print the proof script compactly
s=open(sys.argv[1]).read()
name=sys.argv[2]
i=s.find('(|%s| 0'%name)
t=s[i:]
k=t.find('("" ')
# find the end of script: the dependency list starts with '\n   ((|'
e=t.find('\n   ((|',k)
scr=t[k:e]
scr=re.sub(r'\s+',' ',scr)
scr=scr.replace(' NIL NIL)',')').replace(' NIL)',')')
print(scr[:int(sys.argv[3]) if len(sys.argv)>3 else 5000])
