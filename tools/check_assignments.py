import re, subprocess, sys

# NOTA (Important 4 del review de Tarea 1, diferido a proposito): ASSIGN.search
# devuelve como maximo un match por linea, asi que una asignacion partida en
# dos lineas (p.ej. al reindentar al mover codigo a otra codeunit) es
# invisible en ambos lados (old y new) y no se compara. Esto tiende a ruido
# (falso "sin cambios" para esa linea puntual, no a enmascarar una perdida
# real de las demas), asi que se documenta en vez de arreglarse aqui.
ASSIGN = re.compile(r'(\w+)\.("[^"]+"|[A-Za-z_]\w*)\s*:=\s*(\w+)\.("[^"]+"|[A-Za-z_]\w*)\s*;')

# Resuelve variable Record -> nombre de tabla declarada, para poder incluir
# la tabla en la clave de comparacion (Critical 3). Sin esto, dos copias no
# relacionadas entre tablas distintas pero con el mismo nombre de campo
# (p.ej. "No.", "Description") colisionan en la misma tupla y una perdida
# real queda enmascarada por una copia no relacionada que sigue presente.
VAR_DECL = re.compile(r'(\w+)\s*:\s*Record\s+("[^"]+"|[A-Za-z_]\w*)\s*;')


def var_types(text):
    types = {}
    for vm in VAR_DECL.finditer(text):
        types[vm.group(1)] = vm.group(2).strip('"')
    return types


def pairs(text):
    types = var_types(text)
    out = set()
    for line in text.split("\n"):
        if line.strip().startswith("//"):
            continue
        m = ASSIGN.search(line)
        if m:
            dst_var, dst_field, src_var, src_field = m.group(1), m.group(2), m.group(3), m.group(4)
            # Variable no declarada como Record en el mismo texto (p.ej. parametro
            # tipado en la firma, o variable global fuera del fragmento leido):
            # se usa el nombre de variable como respaldo, que sigue tolerando
            # el rename dentro de la misma tabla mientras no colisione entre
            # tablas distintas resueltas.
            dst_table = types.get(dst_var, dst_var)
            src_table = types.get(src_var, src_var)
            out.add((dst_table, dst_field, src_table, src_field))
    return out


def git_show(ref, f):
    # Critical 2: antes no se comprobaba returncode/stderr, asi que un git show
    # fallido (ref invalido, ruta rota, etc.) devolvia stdout vacio -- IDENTICO
    # al caso legitimo "archivo nuevo, no existia en ese ref" -- y una perdida
    # real quedaba silenciada porque `old` salia vacio por error tecnico.
    result = subprocess.run(["git", "show", "%s:%s" % (ref, f)],
                             capture_output=True, text=True)
    if result.returncode != 0:
        stderr = result.stderr or ""
        if "does not exist in" in stderr or "exists on disk, but not in" in stderr:
            # Archivo genuinamente nuevo respecto a ese ref: no es un error,
            # el conjunto "old" para ese archivo es vacio.
            return ""
        # Cualquier otro fallo (ref inexistente, etc.): fallar fuerte en vez
        # de callar.
        sys.stderr.write("ERROR git show %s:%s -> %s" % (ref, f, stderr))
        sys.exit(2)
    return result.stdout


ref, files = sys.argv[1], sys.argv[2:]
old, new = set(), set()
for f in files:
    old |= pairs(git_show(ref, f))
    try:
        new |= pairs(open(f, encoding="utf-8").read())
    except FileNotFoundError:
        pass

lost, added = old - new, new - old
for dst_table, dst_field, src_table, src_field in sorted(lost):
    print("PERDIDA  %s.%s := %s.%s" % (dst_table, dst_field, src_table, src_field))
for dst_table, dst_field, src_table, src_field in sorted(added):
    print("NUEVA    %s.%s := %s.%s" % (dst_table, dst_field, src_table, src_field))
print("OK - conjunto de copias intacto" if not lost else "FALLA - %d copias perdidas" % len(lost))
sys.exit(1 if lost else 0)
