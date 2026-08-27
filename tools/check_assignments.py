import re, subprocess, sys

ASSIGN = re.compile(r'(\w+)\.("[^"]+"|[A-Za-z_]\w*)\s*:=\s*(\w+)\.("[^"]+"|[A-Za-z_]\w*)\s*;')

def pairs(text):
    out = set()
    for line in text.split("\n"):
        if line.strip().startswith("//"):
            continue
        m = ASSIGN.search(line)
        if m:
            out.add((m.group(2), m.group(4)))
    return out

ref, files = sys.argv[1], sys.argv[2:]
old, new = set(), set()
for f in files:
    shown = subprocess.run(["git", "show", "%s:%s" % (ref, f)],
                           capture_output=True, text=True).stdout
    old |= pairs(shown)
    try:
        new |= pairs(open(f, encoding="utf-8").read())
    except FileNotFoundError:
        pass

lost, added = old - new, new - old
for d, s in sorted(lost):
    print("PERDIDA  %s := %s" % (d, s))
for d, s in sorted(added):
    print("NUEVA    %s := %s" % (d, s))
print("OK - conjunto de copias intacto" if not lost else "FALLA - %d copias perdidas" % len(lost))
sys.exit(1 if lost else 0)
