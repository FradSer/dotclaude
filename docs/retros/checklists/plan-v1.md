# Plan Checklist

- **Version:** v1
- **Mode:** plan
- **Created:** 2026-04-04

---

## Checklist Items

### PLAN-COV-01 -- BDD scenario coverage

**Description:** Every BDD scenario defined in the design (`bdd-specs.md`) has at least one mapped task in the implementation plan.

**Check method:** Cross-reference each `Scenario:` block from the design's `bdd-specs.md` link in `_index.md` against `## BDD` or `## Scenarios` sections in root-level `task-*.md` files. A scenario is covered when a task file references its title or restates its Given/When/Then steps.

**Executable check:**
```bash
python3 - <<'PY'
from pathlib import Path
import re
import sys

index = Path("_index.md").read_text()
match = re.search(r"\]\(([^)]+/bdd-specs\.md)\)", index)
if not match:
    print("missing BDD specs link in _index.md")
    sys.exit(1)

bdd_path = (Path("_index.md").parent / match.group(1)).resolve()
if not bdd_path.exists():
    print(f"missing BDD specs file: {match.group(1)}")
    sys.exit(1)

scenarios = sorted(set(re.findall(r"^\s*Scenario:\s*(.+)$", bdd_path.read_text(), re.M)))
task_text = "\n".join(path.read_text() for path in Path(".").glob("task-*.md"))
missing = [scenario for scenario in scenarios if scenario not in task_text]
for scenario in missing:
    print(scenario)
PY
```

**Evidence format:** `<scenario title>` -- not mapped to any task (or empty output if all covered)

`# Type: inferential` -- "mapped to" requires semantic matching between scenario titles and task descriptions; exact string match is insufficient.

---

### TASK-COMP-03 -- Verification commands are executable

**Description:** All verification commands listed in task files begin with an executable binary name, not a description verb. Commands starting with "verify that", "check that", "ensure that", or "manually" are not executable by a shell.

**Check method:** Scan code-fenced verification command sections in root-level task files for lines beginning with non-executable patterns.

**Executable check:**
```bash
grep -rn -E "^[[:space:]]*(verify that|check that|ensure that|manually)" task-*.md
```

**Evidence format:** `<task file>:<line>` -- `<quoted command text>` (or empty output if all commands are executable)

`# Type: computational` -- grep for description verbs against task files produces a deterministic, repeatable result.

---

### DEP-01 -- No circular dependencies in task graph

**Description:** The dependency graph formed by `depends-on` fields across all task files must be acyclic. A cycle means no valid execution order exists.

**Check method:** Parse `depends-on` fields from all root-level task files, build a directed graph, and run a topological sort. If the sort fails, report the cycle path.

**Executable check:**
```bash
python3 -c "
import re, glob, sys
g = {}
for f in glob.glob('task-*.md'):
    tid = re.search(r'(\d{3})', f)
    if not tid: continue
    tid = tid.group(1)
    g.setdefault(tid, [])
    with open(f) as fh:
        for line in fh:
            m = re.findall(r'depends-on:\s*([\w\-,\s]+)', line, re.I)
            for match in m:
                for dep in re.findall(r'\d{3}', match):
                    g[tid].append(dep)
WHITE, GRAY, BLACK = 0, 1, 2
color = {n: WHITE for n in g}
path = []
def dfs(n):
    color[n] = GRAY; path.append(n)
    for nb in g.get(n, []):
        if color.get(nb) == GRAY:
            cycle = path[path.index(nb):]
            print(' -> '.join(cycle) + ' -> ' + nb); sys.exit(1)
        if color.get(nb, WHITE) == WHITE: dfs(nb)
    color[n] = BLACK; path.pop()
for n in list(g): 
    if color[n] == WHITE: dfs(n)
print('no cycles detected')
"
```

**Evidence format:** `<task-A> -> <task-B> -> <task-A>` (cycle path), or "no cycles detected"

`# Type: computational` -- graph cycle detection is an algorithmic operation with a deterministic outcome.

---

### DEP-02 -- All dependency references resolve

**Description:** Every task ID referenced in a `depends-on` field must correspond to an existing root-level task file. Dangling references indicate missing or renamed tasks.

**Check method:** Extract all `depends-on` IDs from task files and verify each ID matches a root-level task file.

**Executable check:**
```bash
python3 -c "
import re, glob, os
files = glob.glob('task-*.md')
ids = set()
for f in files:
    m = re.search(r'(\d{3})', os.path.basename(f))
    if m: ids.add(m.group(1))
missing = []
for f in files:
    with open(f) as fh:
        for line in fh:
            for m in re.findall(r'depends-on:\s*([\w\-,\s]+)', line, re.I):
                for dep in re.findall(r'\d{3}', m):
                    if dep not in ids:
                        missing.append((os.path.basename(f), dep))
for task, dep in missing:
    print(f'{task} -- unresolved dependency: {dep}')
if not missing:
    print('all dependencies resolve')
"
```

**Evidence format:** `<task file>` -- unresolved dependency: `<ID>` (or "all dependencies resolve")

`# Type: computational` -- ID existence check against the file list is deterministic.

---

### TEST-01 -- Impl tasks have corresponding test tasks

**Description:** Every implementation task (filename containing `impl`) must have a corresponding test task sharing the same NNN prefix, or contain an explicit justification for the absence of tests.

**Check method:** Match task filenames by their three-digit NNN prefix. For each `impl` task, look for a `test` task with the same prefix. If no test counterpart exists, check the impl file for an absence justification (e.g., "no test needed" or "test covered by").

**Executable check:**
```bash
python3 -c "
import re, glob, os
files = [os.path.basename(f) for f in glob.glob('task-*.md')]
impl_prefixes = set()
test_prefixes = set()
for f in files:
    m = re.search(r'task-(\d{3})', f)
    if not m: continue
    prefix = m.group(1)
    if 'impl' in f.lower(): impl_prefixes.add(prefix)
    if 'test' in f.lower(): test_prefixes.add(prefix)
unresolved = []
missing = impl_prefixes - test_prefixes
for prefix in sorted(missing):
    impl_file = [f for f in files if re.search(r'task-' + re.escape(prefix), f) and 'impl' in f.lower()]
    has_justification = False
    for f in impl_file:
        with open(f) as fh:
            content = fh.read().lower()
            if 'no test needed' in content or 'test covered by' in content:
                has_justification = True
    if not has_justification:
        unresolved.append(prefix)
        print(f'{impl_file[0]} -- missing test counterpart for prefix {prefix}')
if not unresolved:
    print('all impl tasks have test counterparts or justifications')
"
```

**Evidence format:** `<task file>` -- missing test counterpart for prefix `<NNN>` (or "all impl tasks have test counterparts or justifications")

`# Type: computational` -- filename pattern matching against the NNN prefix is deterministic.
