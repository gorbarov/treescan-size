#!/usr/bin/env python3
"""Учёт запуска: docs/launch/tracker.json.

  tools/launch.py                      — сводка в терминал
  tools/launch.py set <id> status=posted url=https://… date=2026-10-01 notes="…"
  tools/launch.py account <key> status=есть name=…
  tools/launch.py metrics              — снять звёзды/форки/скачивания через gh api и дописать в metrics
"""
import json, subprocess, sys, time
from pathlib import Path

TRACKER = Path(__file__).resolve().parent.parent / "docs/launch/tracker.json"


def load():
    return json.loads(TRACKER.read_text(encoding="utf-8"))


def save(t):
    TRACKER.write_text(json.dumps(t, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")


def kv(args):
    out = {}
    for a in args:
        k, _, v = a.partition("=")
        out[k] = v
    return out


def gh(path):
    r = subprocess.run(["gh", "api", path], capture_output=True, text=True, timeout=30)
    if r.returncode:
        raise RuntimeError(r.stderr.strip() or f"gh api {path} failed")
    return json.loads(r.stdout)


def metrics(t):
    repo = t["repo"]
    info = gh(f"repos/{repo}")
    rels = gh(f"repos/{repo}/releases")
    downloads = sum(a.get("download_count", 0) for r in rels for a in r.get("assets", []))
    m = {"date": time.strftime("%Y-%m-%d %H:%M"), "stars": info["stargazers_count"], "forks": info["forks_count"],
         "watchers": info["subscribers_count"], "issues": info["open_issues_count"], "downloads": downloads,
         "private": info["private"]}
    try:  # трафик доступен только владельцу
        v = gh(f"repos/{repo}/traffic/views")
        m["views14d"], m["uniques14d"] = v["count"], v["uniques"]
    except Exception:
        pass
    t["metrics"].append(m)
    return m


def main():
    t = load()
    cmd = sys.argv[1] if len(sys.argv) > 1 else "show"
    if cmd == "set":
        ch = next(c for c in t["channels"] if c["id"] == sys.argv[2])
        ch.update(kv(sys.argv[3:]))
        save(t)
    elif cmd == "account":
        t["accounts"].setdefault(sys.argv[2], {}).update(kv(sys.argv[3:]))
        save(t)
    elif cmd == "metrics":
        print(metrics(t))
        save(t)
    for c in sorted(t["channels"], key=lambda c: (c["day"], c["id"])):
        print(f'д{c["day"]:>3}  {c["status"]:<8} {c["name"]:<40} {c["url"]}')
    if t["metrics"]:
        print("метрики:", t["metrics"][-1])


if __name__ == "__main__":
    main()
