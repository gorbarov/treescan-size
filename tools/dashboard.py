#!/usr/bin/env python3
"""Табло стройки: что делают исполнители прямо сейчас. Только чтение логов, только этот мак.
    python3 tools/dashboard.py            # http://127.0.0.1:8777
Источники: docs/runs/*.jsonl (Claude Code и Pi), docs/board.json (статусы заданий), /tmp/ts-build/*.png (снимки окна).
"""
import glob
import json
import os
import re
import sys
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

PROJECT = Path(__file__).resolve().parent.parent
RUNS = PROJECT / "docs/runs"
BOARD = PROJECT / "docs/board.json"
SNAPS = Path("/tmp/ts-build")
ARCHIVE = Path("/tmp/ts-snaps")          # история снимков: исполнитель перезаписывает файлы в /tmp/ts-build
REF = PROJECT / "docs/ref"               # эталонные снимки HTML-макета
PORT = int(os.environ.get("PORT", 8777))
PRICE = {"deepseek/deepseek-v4-flash": (2.5, 15), "deepseek/deepseek-v4.1-flash": (7, 15),
         "qwen/qwen3.8-flash": (7, 15), "z-ai/glm-5.3-flash": (13, 42)}


class Run:
    """Разбор одного лога с продолжением с того места, где остановились."""

    def __init__(self, path):
        self.path, self.offset = path, 0
        name = os.path.basename(path)[:-6]
        m = re.match(r"(\d{4}-\d\d-\d\d)_(\d\d)(\d\d)_(.+)", name)
        self.started = f"{m.group(2)}:{m.group(3)}" if m else ""
        rest = m.group(4) if m else name
        self.harness = "Pi" if "_pi_" in rest else "Claude Code"
        self.task = re.match(r"(\d\d|00)", rest).group(1) if re.match(r"\d\d", rest) else "?"
        self.title = rest.split("_deepseek")[0].split("_pi_")[0].split("_qwen")[0].split("_z-ai")[0]
        self.resume = "_r" in name[-6:]
        self.model, self.done, self.turns = "?", None, 0
        self.tin = self.tout = 0
        self.feed = []          # [время_когда_увидели, значок, текст]
        self.calls = {}         # id вызова инструмента -> команда (чтобы понять, чей это результат)
        self.msg_usage = {}     # id сообщения -> токены (Claude Code повторяет usage в каждом блоке сообщения)
        self.first_seen = time.time()
        self.t_first = self.t_last = None

    def add(self, icon, text):
        self.feed.append([time.time(), icon, text])
        self.feed = self.feed[-60:]

    def tool_icon(self, name, arg):
        a = arg or ""
        if name.lower() == "bash":
            if "check_task" in a: return "🧪"
            if "swift build" in a or "swift run" in a: return "🔨"
            if "git commit" in a: return "📦"
            return "⌨️"
        return {"read": "📖", "edit": "✏️", "write": "📝", "grep": "🔎", "glob": "🔎"}.get(name.lower(), "🔧")

    def update(self):
        try:
            size = os.path.getsize(self.path)
        except OSError:
            return
        if size <= self.offset:
            return
        with open(self.path, "rb") as f:
            f.seek(self.offset)
            chunk = f.read()
        cut = chunk.rfind(b"\n")
        if cut < 0:
            return
        self.offset += cut + 1
        for raw in chunk[:cut].split(b"\n"):
            if b'"type":"system"' in raw[:40] and b'"init"' not in raw[:80]:
                continue          # поток служебных событий Claude Code — пропускаем без разбора
            try:
                e = json.loads(raw)
            except ValueError:
                continue
            self.parse(e)

    def parse(self, e):
        t = e.get("type")
        # --- Claude Code ---
        if t == "system" and e.get("subtype") == "init":
            self.model = e.get("model", self.model)
        elif t == "assistant":
            m = e["message"]
            self.model = m.get("model") or self.model
            u = m.get("usage") or {}
            if m.get("id") and u:
                self.msg_usage[m["id"]] = (u.get("input_tokens", 0) + u.get("cache_read_input_tokens", 0)
                                           + u.get("cache_creation_input_tokens", 0), u.get("output_tokens", 0))
                self.turns = len(self.msg_usage)
                if not self.done:
                    self.tin = sum(a for a, _ in self.msg_usage.values()); self.tout = sum(b for _, b in self.msg_usage.values())
            for c in m.get("content", []):
                if c.get("type") == "tool_use":
                    i = c.get("input", {})
                    arg = str(i.get("command") or i.get("file_path") or i.get("pattern") or "")
                    self.calls[c.get("id")] = (c["name"].lower(), arg)
                    self.add(self.tool_icon(c["name"], arg), f"{c['name']}: {short_path(arg)}")
                elif c.get("type") == "text" and c.get("text", "").strip():
                    self.add("💬", c["text"].strip())
        elif t == "user":
            for c in e.get("message", {}).get("content", []):
                if isinstance(c, dict) and c.get("type") == "tool_result":
                    self.result_text(c.get("content"), c.get("is_error"), self.calls.get(c.get("tool_use_id"), ("", "")))
        elif t == "result":
            self.done = e.get("subtype", "success")
            u = e.get("usage", {})
            self.tin = u.get("input_tokens", 0) + u.get("cache_read_input_tokens", 0) + u.get("cache_creation_input_tokens", 0)
            self.tout = u.get("output_tokens", 0)
            self.turns = e.get("num_turns") or self.turns
        # --- Pi ---
        elif t == "tool_execution_start":
            a = e.get("args", {})
            arg = str(a.get("command") or a.get("path") or a.get("pattern") or "")
            self.calls[e.get("toolCallId")] = (str(e.get("toolName", "")).lower(), arg)
            self.add(self.tool_icon(e.get("toolName", ""), arg), f"{e.get('toolName')}: {short_path(arg)}")
        elif t == "tool_execution_end":
            r = e.get("result", {}).get("content", [])
            self.result_text(r, e.get("isError"), self.calls.get(e.get("toolCallId"), ("", "")))
        elif t == "message_end" and e.get("message", {}).get("role") == "assistant":
            m = e["message"]; u = m.get("usage") or {}
            self.turns += 1; self.model = m.get("model") or self.model
            self.tin += u.get("input", 0) + u.get("cacheRead", 0) + u.get("cacheWrite", 0); self.tout += u.get("output", 0)
            for c in m.get("content", []):
                if c.get("type") == "text" and c.get("text", "").strip():
                    self.add("💬", c["text"].strip())
        elif t == "agent_settled":
            self.done = "success"

    def result_text(self, content, is_error, call=("", "")):
        tool, cmd = call
        text = content if isinstance(content, str) else " ".join(
            c.get("text", "") for c in (content or []) if isinstance(c, dict))
        if tool == "bash" and re.search(r"(^|[;&|]\s*)(tools/)?check_task\.sh\s", cmd.replace(str(PROJECT) + "/", "")):
            ok = [l for l in text.splitlines() if re.search(r"ЗАДАНИЕ \S+: OK|снимок готов", l)]
            self.add("✅" if ok else "🟥", ok[0].strip() if ok else "проверка не прошла: " + short_path(text.strip().splitlines()[-1] if text.strip() else "")[:160])
        elif "Build complete" in text:
            self.add("🟢", "сборка прошла")
        else:
            errs = [l.strip() for l in text.splitlines() if "error:" in l]
            if errs:
                self.add("❌", f"{len(errs)} ошибк. сборки: " + short_path(errs[0])[:160])
            elif is_error:
                self.add("⛔", "отказ: " + text.strip()[:160])

    def state(self):
        idle = int(time.time() - os.path.getmtime(self.path))
        running = not self.done and idle < 900
        pin, pout = PRICE.get(self.model, (10, 30))
        rub = self.tin / 1e6 * pin + self.tout / 1e6 * pout
        return {"file": os.path.basename(self.path), "task": self.task, "title": self.title, "harness": self.harness,
                "model": self.model, "started": self.started, "status": "работает" if running else (self.done or "оборван"),
                "running": running, "idle": idle, "turns": self.turns, "tin": self.tin, "tout": self.tout, "rub": round(rub, 2),
                "minutes": round((os.path.getmtime(self.path) - os.path.getctime(self.path)) / 60, 1),
                "feed": [[int(time.time() - ts), ic, tx[:300]] for ts, ic, tx in self.feed[-40:]]}


def short_path(s):
    return s.replace(str(PROJECT) + "/", "").replace(str(PROJECT), ".")


RUN_CACHE = {}


def collect():
    for p in glob.glob(str(RUNS / "*.jsonl")):
        if p not in RUN_CACHE:
            RUN_CACHE[p] = Run(p)
        RUN_CACHE[p].update()
    runs = sorted((r.state() for r in RUN_CACHE.values()), key=lambda r: r["file"])
    try:
        board = json.loads(BOARD.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        board = {"tasks": []}
    live = {r["task"] for r in runs if r["running"]}
    for t in board["tasks"]:
        if t["id"] in live:
            t["status"] = "в работе"
    ARCHIVE.mkdir(exist_ok=True)
    for p in glob.glob(str(SNAPS / "*.png")):
        mt = int(os.path.getmtime(p))
        dst = ARCHIVE / f"{Path(p).stem}__{mt}.png"
        if not dst.exists() and time.time() - mt > 2:      # дождаться, пока файл допишется
            try:
                dst.write_bytes(Path(p).read_bytes())
            except OSError:
                pass
    snaps = []
    for p in sorted(glob.glob(str(ARCHIVE / "*.png")), key=os.path.getmtime, reverse=True)[:60]:
        stem, _, mt = Path(p).stem.rpartition("__")
        snaps.append({"file": os.path.basename(p), "name": stem, "time": time.strftime("%H:%M", time.localtime(int(mt or 0)))})
    refs = sorted(os.path.basename(p) for p in glob.glob(str(REF / "*.png")))
    try:
        launch = json.loads(LAUNCH.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        launch = None
    return {"runs": runs, "board": board, "snaps": snaps, "refs": refs, "launch": launch, "now": time.strftime("%H:%M:%S"),
            "total_rub": round(sum(r["rub"] for r in runs), 2)}


LAUNCH = Path(__file__).resolve().parent.parent / "docs/launch/tracker.json"
PAGE = (Path(__file__).resolve().parent / "dashboard.html")


class H(BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def send(self, code, body, ctype):
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path == "/":
            return self.send(200, PAGE.read_bytes(), "text/html; charset=utf-8")
        if self.path == "/api/state":
            return self.send(200, json.dumps(collect(), ensure_ascii=False).encode(), "application/json; charset=utf-8")
        m = re.match(r"^/(snap|ref)/([\w.-]+\.png)$", self.path.split("?")[0])
        if m:
            f = (ARCHIVE if m.group(1) == "snap" else REF) / m.group(2)
            if f.is_file():
                return self.send(200, f.read_bytes(), "image/png")
        self.send(404, b"", "text/plain")


if __name__ == "__main__":
    print(f"Табло: http://127.0.0.1:{PORT}/", file=sys.stderr)
    ThreadingHTTPServer(("127.0.0.1", PORT), H).serve_forever()
