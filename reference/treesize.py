#!/usr/bin/env python3
"""TreeSize для мака: сканирует папку и собирает один самодостаточный HTML-отчёт.

    python3 treesize.py                      # Dropbox целиком, отчёт откроется в браузере
    python3 treesize.py ~/Downloads -o d.html
    python3 treesize.py / --no-open
    python3 treesize.py --serve              # отчёт с правым кликом: Finder, корзина, «не синхронизировать»

Ничего не удаляет и не читает содержимое файлов — только метаданные (stat),
поэтому облачные файлы Dropbox («только онлайн») не скачиваются.
"""
import argparse
import ctypes
import heapq
import hmac
import json
import os
import secrets
import shutil
import socket
import stat
import subprocess
import sys
import threading
import time
import webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from datetime import datetime
from pathlib import Path

SF_DATALESS = 0x40000000          # macOS: файл есть только в облаке (File Provider)
KEEP_FILES_PER_DIR = 400          # сколько самых больших файлов папки хранить поимённо
TOP_FILES = 1000
AGE_BUCKETS = [(30, "до 1 месяца"), (90, "1–3 месяца"), (365, "3–12 месяцев"),
               (730, "1–2 года"), (1825, "2–5 лет"), (None, "старше 5 лет")]
HERE = Path(__file__).resolve().parent
IGNORE_ATTRS = ("com.apple.fileprovider.ignore#P", "com.dropbox.ignored")   # «не синхронизировать» в Dropbox

try:
    _libc = ctypes.CDLL(None, use_errno=True)
    _libc.getxattr.argtypes = [ctypes.c_char_p, ctypes.c_char_p, ctypes.c_void_p, ctypes.c_size_t, ctypes.c_uint32, ctypes.c_int]
except (OSError, AttributeError):
    _libc = None


def is_ignored(path):
    """Папка помечена Dropbox как «не синхронизировать» (атрибут xattr)."""
    if _libc is None:
        return False
    b = os.fsencode(path)
    return any(_libc.getxattr(b, a.encode(), None, 0, 0, 1) >= 0 for a in IGNORE_ATTRS)   # 1 = XATTR_NOFOLLOW


class Dir:
    __slots__ = ("name", "size", "alloc", "cloud", "files", "dirs", "mtime", "kids", "fl", "rest", "err", "ign", "selfign")

    def __init__(self, name):
        self.name = name
        self.size = self.alloc = self.cloud = self.files = self.dirs = 0
        self.mtime = 0.0
        self.kids = []      # подпапки
        self.fl = []        # (size, name, alloc, cloud, mtime) — крупнейшие файлы
        self.rest = [0, 0, 0, 0, 0.0, 0, 0]   # файлов, размер, на диске, облако, mtime, папок, не синхр. — мелочь
        self.err = 0
        self.ign = 0        # байт внутри, помеченных «не синхронизировать»
        self.selfign = False  # сама папка помечена


def list_dir(path, timeout):
    """Список папки с lstat каждого элемента — в отдельном потоке.

    File Provider (Dropbox, iCloud) иногда навсегда зависает на чтении папки,
    на ней висит даже `ls`. Если за `timeout` секунд не пришло ни одного
    нового элемента, бросаем папку (поток остаётся висеть, это не страшно).
    Возвращает (список (name, path, stat|None), ошибка|None) или None при зависании.
    """
    res = {"items": [], "err": None, "done": False}

    def work():
        try:
            with os.scandir(path) as it:
                for e in it:
                    try:
                        res["items"].append((e.name, e.path, e.stat(follow_symlinks=False)))
                    except OSError:
                        res["items"].append((e.name, e.path, None))
        except OSError as ex:
            res["err"] = ex
        res["done"] = True

    t = threading.Thread(target=work, daemon=True)
    t.start()
    seen, idle = -1, 0.0
    while True:
        t.join(0.5)
        if res["done"]:
            return res["items"], res["err"]
        n = len(res["items"])
        idle = 0.0 if n != seen else idle + 0.5
        seen = n
        if idle >= timeout:
            return None


class Scanner:
    def __init__(self, args):
        self.args = args
        self.top = []                    # heap (size, path, alloc, cloud, mtime)
        self.ext = {}                    # ext -> [size, count, cloud]
        self.age = [[0, 0] for _ in AGE_BUCKETS]
        self.dups = {}                   # (size, ext) -> [paths]
        self.seen_inodes = set()
        self.errors = 0
        self.stuck = []                  # папки, которые не ответили
        self.nfiles = 0
        self.bytes = 0                   # сколько уже насчитали — для отсечки мелочи на лету
        self.cur = ""                    # текущая папка — для прогресса в браузере
        self.last_report = 0.0
        self.now = time.time()

    def progress(self, path):
        self.cur = path
        t = time.time()
        if t - self.last_report > 1.5:
            self.last_report = t
            short = path if len(path) < 70 else "…" + path[-69:]
            sys.stderr.write(f"\r  {self.nfiles:>9,} файлов  {short:<72}".replace(",", " "))
            sys.stderr.flush()

    def scan(self, path, name, dev):
        d = Dir(name)
        self.progress(path)
        listing = list_dir(path, self.args.timeout)
        if listing is None:
            self.stuck.append(path)
            sys.stderr.write(f"\r  ⚠ не отвечает {self.args.timeout:.0f} с, пропускаю: {path}\n")
            d.err = 1
            return d
        entries, err = listing
        if err is not None:
            self.errors += 1
            d.err = 1
            return d
        files = []
        for e_name, e_path, s in entries:
            if s is None:
                self.errors += 1
                continue
            mode = s.st_mode
            if stat.S_ISLNK(mode):
                continue
            if stat.S_ISDIR(mode):
                if self.args.one_fs and s.st_dev != dev:
                    continue
                sub = self.scan(e_path, e_name, dev)
                d.kids.append(sub)
                d.size += sub.size; d.alloc += sub.alloc; d.cloud += sub.cloud
                d.files += sub.files; d.dirs += sub.dirs + 1
                d.err += sub.err
                d.ign += sub.ign
                if sub.mtime > d.mtime:
                    d.mtime = sub.mtime
                continue
            size = s.st_size
            if s.st_nlink > 1:
                key = (s.st_dev, s.st_ino)
                if key in self.seen_inodes:
                    size = 0            # жёсткая ссылка — место уже посчитано
                else:
                    self.seen_inodes.add(key)
            alloc = s.st_blocks * 512 if size else 0
            cloud = size if (getattr(s, "st_flags", 0) & SF_DATALESS) else 0
            mt = s.st_mtime
            if mt > self.now + 86400:       # битые даты из будущего (бывает 2262 год) не считаем
                mt = 0.0
            self.nfiles += 1
            d.files += 1; d.size += size; d.alloc += alloc; d.cloud += cloud
            if mt > d.mtime:
                d.mtime = mt
            files.append((size, e_name, alloc, cloud, mt))
            self.account(e_path, e_name, size, alloc, cloud, mt)
        # Мелочь сворачиваем сразу, чтобы скан всего диска не съедал память. Отсечка по уже
        # насчитанному объёму не выше итоговой, так что в отчёт это всё равно не попало бы.
        floor = self.bytes * self.args.min_share
        r = d.rest
        files.sort(key=lambda f: f[0], reverse=True)
        keep = 0
        while keep < len(files) and keep < KEEP_FILES_PER_DIR and (keep < 3 or files[keep][0] >= floor):
            keep += 1
        for f in files[keep:]:
            r[0] += 1; r[1] += f[0]; r[2] += f[2]; r[3] += f[3]
            if f[4] > r[4]:
                r[4] = f[4]
        d.fl = files[:keep]
        if len(d.kids) > 3:
            d.kids.sort(key=lambda k: k.size, reverse=True)
            small = [k for k in d.kids[3:] if k.size < floor]
            if small:
                d.kids = d.kids[:len(d.kids) - len(small)]
                for k in small:
                    r[0] += k.files; r[1] += k.size; r[2] += k.alloc; r[3] += k.cloud
                    r[4] = max(r[4], k.mtime); r[5] += 1 + k.dirs; r[6] += k.ign
        if is_ignored(path):
            d.ign, d.selfign = d.size, True
        return d

    def account(self, path, name, size, alloc, cloud, mt):
        self.bytes += size
        item = (size, path, alloc, cloud, mt)
        if len(self.top) < TOP_FILES:
            heapq.heappush(self.top, item)
        elif size > self.top[0][0]:
            heapq.heapreplace(self.top, item)
        dot = name.rfind(".")
        ext = name[dot + 1:].lower() if 0 < dot < len(name) - 1 and len(name) - dot <= 12 else ""
        x = self.ext.get(ext)
        if x is None:
            self.ext[ext] = [size, 1, cloud]
        else:
            x[0] += size; x[1] += 1; x[2] += cloud
        days = (self.now - mt) / 86400
        for i, (lim, _) in enumerate(AGE_BUCKETS):
            if lim is None or days < lim:
                self.age[i][0] += size; self.age[i][1] += 1
                break
        if size >= self.args.dup_min:
            self.dups.setdefault((size, ext), []).append(path)


def serialize(d, thr):
    """[тип, имя, размер, на диске, в облаке, файлов, папок, изменён, не синхронизируется (-1 — сама папка), дети]; тип: 0 папка, 1 файл, 2 сводка мелочи."""
    items = [(k.size, 0, k) for k in d.kids] + [(f[0], 1, f) for f in d.fl]
    items.sort(key=lambda x: x[0], reverse=True)
    out = []
    agg = list(d.rest[:5])        # файлов, размер, на диске, облако, mtime
    agg_dirs, agg_ign = d.rest[5], d.rest[6]
    for i, (size, kind, obj) in enumerate(items):
        keep = size >= thr or i < 3
        if kind == 0:
            if keep:
                out.append(serialize(obj, thr))
            else:
                agg[0] += obj.files; agg[1] += obj.size; agg[2] += obj.alloc; agg[3] += obj.cloud
                agg[4] = max(agg[4], obj.mtime); agg_dirs += 1 + obj.dirs; agg_ign += obj.ign
        else:
            if keep:
                out.append([1, obj[1], obj[0], obj[2], obj[3], 1, 0, int(obj[4]), 0])
            else:
                agg[0] += 1; agg[1] += obj[0]; agg[2] += obj[2]; agg[3] += obj[3]
                agg[4] = max(agg[4], obj[4])
    if agg[0] or agg_dirs:
        out.append([2, "", agg[1], agg[2], agg[3], agg[0], agg_dirs, int(agg[4]), agg_ign])
    node = [0, d.name, d.size, d.alloc, d.cloud, d.files, d.dirs, int(d.mtime), -1 if d.selfign else d.ign]
    if out:
        node.append(out)
    return node


def main():
    default_root = Path.home() / "Library/CloudStorage/Dropbox"
    p = argparse.ArgumentParser(description="TreeSize для мака: отчёт о занятом месте в HTML")
    p.add_argument("path", nargs="?", default=str(default_root if default_root.exists() else Path.cwd()))
    p.add_argument("-o", "--out", help="куда сохранить HTML (по умолчанию reports/<папка>_<дата>.html рядом со скриптом)")
    p.add_argument("--no-open", action="store_true", help="не открывать отчёт в браузере")
    p.add_argument("--serve", action="store_true",
                   help="открыть отчёт через локальный сервер: правый клик умеет показать в Finder, "
                        "переместить в корзину, исключить из синхронизации Dropbox")
    p.add_argument("--all-fs", dest="one_fs", action="store_false", help="заходить на другие диски и тома")
    p.add_argument("--min-share", type=float, default=2e-6,
                   help="мельче этой доли от общего размера — сворачивать в «мелочь» (по умолчанию 2e-6)")
    p.add_argument("--dup-min", type=int, default=5 * 2**20, help="минимальный размер для поиска дублей, байт (5 МБ)")
    p.add_argument("--timeout", type=float, default=10, help="сколько секунд ждать зависшую папку облака (10)")
    p.add_argument("--dump-json", help="дополнительно сохранить сырые данные скана в JSON")
    p.add_argument("--from-json", help="не сканировать, а собрать HTML из ранее сохранённого JSON")
    args = p.parse_args()

    if args.from_json:
        data = json.loads(Path(args.from_json).read_text(encoding="utf-8"))
        return write_report(data, args)

    root = os.path.abspath(os.path.expanduser(args.path))
    if not os.path.isdir(root):
        sys.exit(f"Нет такой папки: {root}")
    data = scan_root(root, args)
    if args.dump_json:
        Path(args.dump_json).expanduser().write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
    write_report(data, args)


def scan_root(root, args, holder=None):
    sys.setrecursionlimit(20000)
    print(f"Сканирую {root}", file=sys.stderr)
    t0 = time.time()
    sc = Scanner(args)
    if holder is not None:
        holder["sc"] = sc                # сервер читает отсюда прогресс
    tree = sc.scan(root, root, os.stat(root).st_dev)
    took = time.time() - t0
    sys.stderr.write("\r" + " " * 100 + "\r")
    num = lambda x: f"{x:,}".replace(",", " ")
    print(f"Готово за {took:.0f} с: {num(tree.files)} файлов, {num(tree.dirs)} папок, "
          f"{tree.size / 2**30:.1f} ГБ", file=sys.stderr)

    dup_groups = []
    for (size, ext), paths in sc.dups.items():
        if len(paths) > 1:
            dup_groups.append([size, sorted(paths)])
    dup_groups.sort(key=lambda g: g[0] * (len(g[1]) - 1), reverse=True)

    data = {
        "root": root,
        "host": socket.gethostname(),
        "scanned": datetime.now().strftime("%Y-%m-%d %H:%M"),
        "took": round(took, 1),
        "errors": sc.errors,
        "stuck": sc.stuck,
        "tree": serialize(tree, max(1, int(tree.size * args.min_share))),
        "top": [[s, p_, a, c, int(m)] for s, p_, a, c, m in sorted(sc.top, reverse=True)],
        "ext": sorted(([e, v[0], v[1], v[2]] for e, v in sc.ext.items()), key=lambda x: -x[1]),
        "age": [[label, v[0], v[1]] for (_, label), v in zip(AGE_BUCKETS, sc.age)],
        "dups": dup_groups[:300],
        "dupMin": args.dup_min,
    }
    return data


def render_html(data):
    payload = json.dumps(data, ensure_ascii=False, separators=(",", ":")).replace("</", "<\\/")
    template = (HERE / "template.html").read_text(encoding="utf-8")
    return template.replace("/*__DATA__*/{}", payload)


def write_report(data, args):
    root = data["root"]
    html_out = render_html(data)

    out = report_path(root, args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(html_out, encoding="utf-8")
    print(f"Отчёт: {out}  ({out.stat().st_size / 2**20:.1f} МБ)", file=sys.stderr)
    if args.serve:
        serve(data, args, out)
    elif not args.no_open:
        webbrowser.open(out.resolve().as_uri())


def report_path(root, out_arg=None):
    if out_arg:
        out = Path(out_arg).expanduser()
    else:
        slug = "".join(ch if ch.isalnum() else "_" for ch in (os.path.basename(root) or "root"))
        out = HERE / "reports" / f"{slug}_{datetime.now():%Y-%m-%d_%H%M}.html"
    return out


def act(action, path):
    """Действие над файлом из контекстного меню. Возвращает текст ошибки или None."""
    if action == "reveal":
        r = subprocess.run(["open", "-R", path], capture_output=True, text=True)
    elif action == "trash":
        # /usr/bin/trash (macOS 14+) кладёт в корзину с «Вернуть»; облачные файлы Dropbox не скачивает
        cmd = ["/usr/bin/trash", path] if os.path.exists("/usr/bin/trash") else \
              ["osascript", "-e", 'on run a', "-e", 'tell application "Finder" to delete (POSIX file (item 1 of a))', "-e", "end run", path]
        r = subprocess.run(cmd, capture_output=True, text=True)
        if r.returncode == 0:
            for _ in range(30):                 # облачная папка может исчезать не мгновенно
                if not os.path.lexists(path):
                    return None
                time.sleep(0.1)
            return "команда корзины отработала, но файл остался на месте"
    elif action == "ignore":
        r = subprocess.run(["xattr", "-s", "-w", IGNORE_ATTRS[0], "1", path], capture_output=True, text=True)
    elif action == "unignore":
        for a in IGNORE_ATTRS:
            subprocess.run(["xattr", "-s", "-d", a, path], capture_output=True, text=True)
        return "не получилось снять пометку" if is_ignored(path) else None
    else:
        return "неизвестное действие"
    return (r.stderr or r.stdout or f"код {r.returncode}").strip() if r.returncode else None


def places():
    """Диски и типовые папки для панели «Открыть»."""
    home = Path.home()
    res = []

    def disk(name, path):
        try:
            u = shutil.disk_usage(path)
            res.append({"kind": "disk", "name": name, "path": path, "total": u.total, "free": u.free})
        except OSError:
            pass

    disk("Macintosh HD", "/System/Volumes/Data")      # том с данными: Users, Applications, Library
    try:
        for v in sorted(os.listdir("/Volumes")):
            p = os.path.join("/Volumes", v)
            if os.path.ismount(p) and os.path.realpath(p) != "/":
                disk(v, p)
    except OSError:
        pass
    folders = [("Домашняя папка", home), ("Загрузки", home / "Downloads"), ("Документы", home / "Documents"),
               ("Рабочий стол", home / "Desktop"), ("iCloud Drive", home / "Library/Mobile Documents/com~apple~CloudDocs")]
    cs = home / "Library/CloudStorage"
    if cs.is_dir():
        folders += [(p.name, p) for p in sorted(cs.iterdir()) if p.is_dir()]
    for name, p in folders:
        if p.is_dir():
            res.append({"kind": "folder", "name": name, "path": str(p)})
    return res


def choose_folder():
    """Системный диалог выбора папки. Возвращает путь или None (отмена)."""
    r = subprocess.run(["osascript", "-e", "activate", "-e",
                        'POSIX path of (choose folder with prompt "Какую папку или диск просканировать?")'],
                       capture_output=True, text=True)
    return r.stdout.strip() or None if r.returncode == 0 else None


def protected(path):
    """Папки, которые из отчёта в корзину не отправляем: корни дисков, системные, домашняя."""
    p = os.path.realpath(path)
    home = os.path.realpath(os.path.expanduser("~"))
    if p in (home, os.path.join(home, "Library")):
        return True
    parts = Path(p).parts
    if p.startswith("/System/Volumes/Data"):
        parts = ("/",) + parts[4:]
    return len(parts) <= 2 or (len(parts) <= 3 and parts[1] in ("Users", "Volumes")) or parts[1] in ("System", "usr", "bin", "sbin")


def serve(data, args, out):
    """Локальный сервер только для этого мака: отдаёт отчёт и выполняет действия из меню.

    Защита: слушает 127.0.0.1, случайный токен в каждом POST, проверка Host
    (от DNS rebinding), JSON-тело (чужие сайты не пройдут без CORS-префлайта).
    Действия над файлами — только внутри просканированной папки, не над ней самой
    и не над системными папками (protected).
    """
    token = secrets.token_urlsafe(24)
    st = {"data": data, "root": os.path.realpath(data["root"]), "out": out,
          "html": render_html(dict(data, api=token)).encode("utf-8")}
    holder = {}
    scan_lock = threading.Lock()

    def rescan(new_root=None):
        if not scan_lock.acquire(blocking=False):
            return "скан уже идёт"
        try:
            root = new_root or st["data"]["root"]
            fresh = scan_root(root, args, holder)
            if new_root and os.path.realpath(new_root) != st["root"]:
                st["out"] = report_path(new_root)
            st["out"].parent.mkdir(parents=True, exist_ok=True)
            st["out"].write_text(render_html(fresh), encoding="utf-8")      # сохранённый отчёт — без токена
            st.update(data=fresh, root=os.path.realpath(root), html=render_html(dict(fresh, api=token)).encode("utf-8"))
            print(f"Отчёт обновлён: {st['out']}", file=sys.stderr)
            return None
        finally:
            holder.clear()
            scan_lock.release()

    class H(BaseHTTPRequestHandler):
        def log_message(self, *a):
            pass

        def _host_ok(self):
            return self.headers.get("Host", "") in (f"127.0.0.1:{port}", f"localhost:{port}")

        def _send(self, code, body, ctype="application/json; charset=utf-8"):
            self.send_response(code)
            self.send_header("Content-Type", ctype)
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Cache-Control", "no-store")
            self.send_header("X-Content-Type-Options", "nosniff")
            self.end_headers()
            self.wfile.write(body)

        def do_GET(self):
            if not self._host_ok() or self.path not in ("/", "/index.html"):
                return self._send(404, b"{}")
            self._send(200, st["html"], "text/html; charset=utf-8")

        def do_POST(self):
            def reply(err, **extra):
                body = dict(ok=not err, error=err, **extra)
                self._send(200 if not err else 400, json.dumps(body, ensure_ascii=False).encode())
            if not self._host_ok() or self.path != "/api" or \
                    not self.headers.get("Content-Type", "").startswith("application/json"):
                return self._send(403, b"{}")
            try:
                req = json.loads(self.rfile.read(min(int(self.headers.get("Content-Length", 0)), 65536)))
            except (ValueError, TypeError):
                return reply("плохой запрос")
            if not hmac.compare_digest(str(req.get("t", "")), token):
                return self._send(403, b"{}")
            action = req.get("action")
            if action == "progress":
                sc = holder.get("sc")
                return reply(None, files=sc.nfiles if sc else 0, bytes=sc.bytes if sc else 0, cur=sc.cur if sc else "")
            if action == "places":
                return reply(None, places=places())
            if action == "choose":
                return reply(None, path=choose_folder())
            if action == "rescan":
                return reply(rescan())
            if action == "scan":
                target = os.path.abspath(os.path.expanduser(str(req.get("path", ""))))
                if not os.path.isdir(target):
                    return reply("такой папки нет")
                return reply(rescan(target))
            root = st["root"]
            path = os.path.abspath(str(req.get("path", "")))
            parent = os.path.realpath(os.path.dirname(path))
            if not (parent == root or parent.startswith(root + os.sep)) or not os.path.lexists(path):
                return reply("путь вне просканированной папки или уже не существует")
            path = os.path.join(parent, os.path.basename(path))
            if action == "trash" and protected(path):
                return reply("это системная или корневая папка — её отсюда не удаляю")
            err = act(action, path)
            print(f"  {action}: {path}" + (f" — ОШИБКА: {err}" if err else ""), file=sys.stderr)
            reply(err)

    httpd = ThreadingHTTPServer(("127.0.0.1", 0), H)
    port = httpd.server_address[1]
    url = f"http://127.0.0.1:{port}/"
    print(f"\nОтчёт с действиями: {url}\nЗакройте это окно или нажмите Ctrl+C, чтобы выключить.", file=sys.stderr)
    if not args.no_open:
        webbrowser.open(url)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
    sys.stdout.flush(); sys.stderr.flush()
    os._exit(0)   # не ждать потоков, повисших на облачных папках
