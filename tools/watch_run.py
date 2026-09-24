#!/usr/bin/env python3
"""Что сейчас делает исполнитель: последние действия и сколько секунд назад была запись.
    python3 tools/watch_run.py            # последний лог
    python3 tools/watch_run.py <лог> 20   # 20 последних действий
"""
import glob, json, os, sys, time
path = sys.argv[1] if len(sys.argv) > 1 else max(glob.glob("docs/runs/*.jsonl"), key=os.path.getmtime)
n = int(sys.argv[2]) if len(sys.argv) > 2 else 12
ev, done = [], None
for line in open(path, encoding="utf-8"):
    try: e = json.loads(line)
    except ValueError: continue
    if e.get("type") == "assistant":
        for c in e["message"].get("content", []):
            if c.get("type") == "tool_use":
                i = c["input"]
                ev.append(f"{c['name']}: " + str(i.get("command") or i.get("file_path") or i.get("pattern") or "")[:110])
            elif c.get("type") == "text" and c["text"].strip():
                ev.append("говорит: " + c["text"].strip().replace("\n", " ")[:110])
    elif e.get("type") == "result":
        done = e.get("subtype")
    elif e.get("type") == "tool_execution_start":          # формат Pi
        a = e.get("args", {})
        ev.append(f"{e.get('toolName')}: " + str(a.get("command") or a.get("path") or a.get("pattern") or "")[:110])
    elif e.get("type") == "message_end" and e.get("message", {}).get("role") == "assistant":
        for c in e["message"].get("content", []):
            if c.get("type") == "text" and c.get("text", "").strip():
                ev.append("говорит: " + c["text"].strip().replace("\n", " ")[:110])
    elif e.get("type") == "agent_settled":
        done = "success"
idle = int(time.time() - os.path.getmtime(path))
print(f"{os.path.basename(path)} — {'ЗАКОНЧИЛ: ' + done if done else f'работает, последняя запись {idle} с назад'}")
print("\n".join("  " + x for x in ev[-n:]))
