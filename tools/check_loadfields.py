import re, sys

path = sys.argv[1]
src = open(path, encoding="utf-8").read()
code = "\n".join(re.sub(r'//.*$', '', line) for line in src.split("\n"))

gaps = 0
for m in re.finditer(r'(\w+)\.SetLoadFields\(([^;]*?)\);', code, re.S):
    var = m.group(1)
    declared = set(re.findall(r'"[^"]+"', m.group(2)))
    start = code.rfind("procedure", 0, m.start())
    end = code.find("\n    end;", m.end())
    body = code[start:end if end > 0 else len(code)]
    used = set(re.findall(r'%s\.("[^"]+")' % re.escape(var), body))
    missing = used - declared
    if missing:
        gaps += 1
        print("HUECO %s: %s" % (var, sorted(missing)))

print("OK - sin huecos" if not gaps else "FALLA - %d huecos" % gaps)
sys.exit(1 if gaps else 0)
