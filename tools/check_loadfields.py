import re, sys

path = sys.argv[1]
src = open(path, encoding="utf-8").read()
code = "\n".join(re.sub(r'//.*$', '', line) for line in src.split("\n"))

# Delimitador de definicion: procedure o trigger, anclado a inicio de linea.
# rfind("procedure", ...) fallaba cuando el SetLoadFields vive en un
# `trigger OnRun()` sin ningun `procedure` antes en el archivo (-1 -> body
# vacio -> "OK" falso). Ver Critical 1 del review de Tarea 1.
DEF_RE = re.compile(r'^\s*(local\s+)?(procedure|trigger)\s+(\w+)\s*\(([^)]*)\)', re.M)

# Detecta llamadas identificador(args). Se usa tanto para localizar el codigo
# del refactor (RowNeedsWork(Customer), ApplyBELLON(Customer), etc.) como,
# incidentalmente, para llamadas a metodos de sistema (FindSet, Modify...);
# esas se descartan porque sus argumentos nunca son exactamente el nombre de
# la variable/parametro que se esta rastreando.
CALL_RE = re.compile(r'\b([A-Za-z_]\w*)\s*\(([^()]*)\)')

MAX_DEPTH = 5


def parse_params(raw):
    """Aplana la lista de parametros de una firma a una lista ordenada de
    nombres (sin 'var', sin tipo), para poder mapear la posicion de un
    argumento en una llamada al nombre del parametro correspondiente."""
    names = []
    for group in raw.split(";"):
        group = group.strip()
        if not group or ":" not in group:
            continue
        names_part = group.split(":", 1)[0]
        names_part = re.sub(r'^\s*var\s+', '', names_part, flags=re.I)
        for n in names_part.split(","):
            n = n.strip()
            if n:
                names.append(n)
    return names


def build_defs(code):
    """Indexa todos los procedure/trigger del archivo: nombre -> {params,
    cuerpo, rango}. El cuerpo de cada uno se acota igual que antes (hasta la
    proxima linea 'end;' indentada a 4 espacios, que es el cierre del propio
    procedure/trigger y no el de un begin/end anidado mas profundo)."""
    defs = {}
    for dm in DEF_RE.finditer(code):
        name = dm.group(3)
        end = code.find("\n    end;", dm.end())
        end = end if end > 0 else len(code)
        defs[name] = {
            "start": dm.start(),
            "end": end,
            "body": code[dm.start():end],
            "params": parse_params(dm.group(4)),
        }
    return defs


def owner_of(defs, pos):
    for name, info in defs.items():
        if info["start"] <= pos < info["end"]:
            return name
    return None


def fields_used(body, var):
    return set(re.findall(r'%s\.("[^"]+")' % re.escape(var), body))


def collect_used(defs, proc_name, var, depth, visited):
    """Campos usados sobre `var` dentro de `proc_name`, siguiendo de forma
    transitiva (hasta MAX_DEPTH) las llamadas que pasan `var` como argumento
    a otros procedure/trigger del mismo archivo. Este es el arreglo del
    Critical bloqueante: SetLoadFields declarado en un procedure "orquestador"
    (p.ej. MigrateCustomer) mientras los campos se leen/escriben en
    procedimientos ApplyXXX distintos que reciben el registro por parametro
    var -- patron dominante en las 59 tablas del refactor por-tabla."""
    key = (proc_name, var)
    if key in visited or depth > MAX_DEPTH:
        return set()
    visited.add(key)
    info = defs.get(proc_name)
    if info is None:
        return set()
    body = info["body"]
    used = fields_used(body, var)
    for cm in CALL_RE.finditer(body):
        callee, argstr = cm.group(1), cm.group(2)
        args = [a.strip() for a in argstr.split(",")]
        for idx, a in enumerate(args):
            if a != var:
                continue
            callee_info = defs.get(callee)
            if callee_info is None:
                # Punto 5 del arreglo: preferimos ruido a silencio. No
                # asumimos que un procedimiento que no podemos resolver en
                # este archivo (definido en otro objeto, metodo de sistema,
                # etc.) deja de usar campos -- solo avisamos que no se pudo
                # verificar.
                sys.stderr.write(
                    "AVISO %s: no se pudo resolver %s(...) invocado con %s como argumento; "
                    "los campos usados alli no se verifican\n" % (proc_name, callee, var))
                continue
            callee_params = callee_info["params"]
            if idx >= len(callee_params):
                sys.stderr.write(
                    "AVISO %s: %s(...) no tiene parametro en la posicion %d para mapear %s\n"
                    % (proc_name, callee, idx, var))
                continue
            callee_var = callee_params[idx]
            used |= collect_used(defs, callee, callee_var, depth + 1, visited)
    return used


defs = build_defs(code)

gaps = 0
for m in re.finditer(r'(\w+)\.SetLoadFields\(([^;]*?)\);', code, re.S):
    var = m.group(1)
    declared = set(re.findall(r'"[^"]+"', m.group(2)))
    proc_name = owner_of(defs, m.start())
    if proc_name is None:
        sys.stderr.write(
            "AVISO: no se pudo ubicar el procedimiento que contiene el SetLoadFields de %s "
            "(posicion %d); no se pudo verificar\n" % (var, m.start()))
        used = set()
    else:
        used = collect_used(defs, proc_name, var, 0, set())
    missing = used - declared
    if missing:
        gaps += 1
        print("HUECO %s: %s" % (var, sorted(missing)))

print("OK - sin huecos" if not gaps else "FALLA - %d huecos" % gaps)
sys.exit(1 if gaps else 0)
