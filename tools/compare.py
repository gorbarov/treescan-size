#!/usr/bin/env python3
"""Сравнивает JSON Swift-сканера с эталонным Python-сканером на одной папке.

    python3 tools/compare.py /tmp/ts-fixture            # сам запустит оба сканера
    python3 tools/compare.py /tmp/ts-fixture --swift-json a.json --py-json b.json

Эталон — reference/treesize.py. Поля, зависящие от момента запуска
(took, scanned, host, api), не сравниваются. Порядок одинаковых по размеру
элементов нормализуется. Выход 0 — совпало, 1 — есть расхождения.
"""
import argparse
import json
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
PROJECT = HERE.parent
PY_REF = PROJECT / "reference/treesize.py"
VOLATILE = {"took", "scanned", "host", "api"}


def norm_node(n):
    n = list(n)
    if len(n) > 9 and isinstance(n[9], list):
        n[9] = sorted((norm_node(k) for k in n[9]), key=lambda k: (-k[2], k[0], k[1]))
    return n


def normalize(d):
    d = {k: v for k, v in d.items() if k not in VOLATILE}
    d["tree"] = norm_node(d["tree"])
    d["top"] = sorted(d["top"], key=lambda t: (-t[0], t[1]))
    d["ext"] = sorted(d["ext"], key=lambda e: (-e[1], e[0]))
    d["dups"] = sorted(([g[0], sorted(g[1])] for g in d["dups"]), key=lambda g: (-g[0] * (len(g[1]) - 1), g[1][0]))
    d["stuck"] = sorted(d.get("stuck", []))
    return d


def diff(a, b, path="", out=None, limit=30):
    out = [] if out is None else out
    if len(out) >= limit:
        return out
    if type(a) != type(b) and not (isinstance(a, (int, float)) and isinstance(b, (int, float))):
        out.append(f"{path}: тип {type(a).__name__} ≠ {type(b).__name__}: {str(a)[:80]} | {str(b)[:80]}")
    elif isinstance(a, dict):
        for k in sorted(set(a) | set(b)):
            if k not in a or k not in b:
                out.append(f"{path}.{k}: есть только в {'python' if k in a else 'swift'}")
            else:
                diff(a[k], b[k], f"{path}.{k}", out, limit)
    elif isinstance(a, list):
        if len(a) != len(b):
            out.append(f"{path}: длина {len(a)} ≠ {len(b)}")
        for i, (x, y) in enumerate(zip(a, b)):
            diff(x, y, f"{path}[{i}]", out, limit)
    elif a != b:
        out.append(f"{path}: {str(a)[:80]} ≠ {str(b)[:80]}")
    return out


def main():
    p = argparse.ArgumentParser()
    p.add_argument("folder")
    p.add_argument("--swift-json")
    p.add_argument("--py-json")
    a = p.parse_args()
    tmp = Path(tempfile.mkdtemp(prefix="ts-compare-"))
    py_json = a.py_json or str(tmp / "py.json")
    sw_json = a.swift_json or str(tmp / "swift.json")
    if not a.py_json:
        subprocess.run([sys.executable, str(PY_REF), a.folder, "--no-open", "--dump-json", py_json,
                        "-o", str(tmp / "py.html")], check=True, capture_output=True)
    if not a.swift_json:
        subprocess.run(["swift", "run", "-c", "release", "--scratch-path", "/tmp/ts-build", "tscan", a.folder, "--json", sw_json],
                       cwd=PROJECT, check=True)
    py = normalize(json.loads(Path(py_json).read_text()))
    sw = normalize(json.loads(Path(sw_json).read_text()))
    problems = diff(py, sw, "data")
    if problems:
        print(f"РАСХОЖДЕНИЯ ({len(problems)}{'+' if len(problems) >= 30 else ''}), слева python, справа swift:")
        print("\n".join("  " + x for x in problems))
        sys.exit(1)
    print(f"OK: вывод Swift совпадает с эталоном ({py['tree'][5]} файлов, {py['tree'][6]} папок)")


if __name__ == "__main__":
    main()
