#!/usr/bin/env python3
import argparse
import concurrent.futures
import curses
import difflib
import hashlib
import locale
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import threading
import time
import unicodedata
from dataclasses import dataclass


WORKTREE = "WORKTREE"
HEAD_REVISION = "HEAD"
MODE_CURRENT = "current"
MODE_COMMIT = "commit"
PANEL_COMMITS = "commits"
PANEL_PREVIEW = "preview"
FOCUS_MARKER = "[*]"
COMMAND_TIMEOUT = 30
PREVIEW_MIN_WIDTH = 120
CTRL_N = 14
CTRL_P = 16
ENTER_KEYS = (10, 13, curses.KEY_ENTER)
ANSI = re.compile(r"\x1b\][^\x07]*?(?:\x07|\x1b\\)|\x1b\[[0-?]*[ -/]*[@-~]")
LOG_FORMAT = "%x1e%H%x00%ct%x00%an%x00%s%x00%P%x00"


class Commands:
    def __init__(self):
        self.processes = set()
        self.lock = threading.Lock()
        self.is_closed = False

    def run(self, args, *, cwd=None, data=None, allowed=(0,)):
        with self.lock:
            if self.is_closed:
                raise RuntimeError("History closed")
            child = subprocess.Popen(args, cwd=cwd, stdin=subprocess.PIPE,
                                     stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            self.processes.add(child)
        try:
            try:
                output, errors = child.communicate(data, timeout=COMMAND_TIMEOUT)
            except subprocess.TimeoutExpired:
                child.kill()
                child.communicate()
                raise RuntimeError(f"Command timed out: {args[0]}") from None
            if child.returncode not in allowed:
                raise RuntimeError(errors.decode("utf-8", "replace").strip() or
                                   f"{args[0]} exited with {child.returncode}")
            return output
        finally:
            with self.lock:
                self.processes.discard(child)

    def close(self):
        with self.lock:
            self.is_closed = True
            for child in self.processes:
                if child.poll() is None:
                    child.terminate()


@dataclass
class Commit:
    sha: str
    timestamp: int
    author: str
    subject: str
    parents: list
    path: str
    parent_path: str
    added: str
    deleted: str


class History:
    def __init__(self, file, lines=None):
        self.commands = Commands()
        source = Path(file).absolute()
        self.file = source.parent.resolve() / source.name
        self.root = Path(self.commands.run(
            ["git", "-C", str(self.file.parent), "rev-parse", "--show-toplevel"]
        ).decode().strip())
        self.path = self.file.relative_to(self.root).as_posix()
        self.lines = lines
        self.commits = []
        self.note = ""

    def git(self, *args, data=None, allowed=(0,)):
        return self.commands.run(["git", "--literal-pathspecs", "--no-pager", *args],
                                 cwd=self.root, data=data, allowed=allowed)

    def blob(self, sha, path):
        result = self.git("show", f"{sha}:{path}")
        return result

    def load(self):
        has_head = bool(self.git("rev-parse", "--verify", HEAD_REVISION, allowed=(0, 128)))
        raw = self.git("log", "--follow", "--numstat", "-z", "--no-color",
                       f"--format={LOG_FORMAT}", "--", self.path) if has_head else b""
        path = self.path
        for record in raw.split(b"\x1e")[1:]:
            sha, stamp, author, subject, parents, stats = record.split(b"\0", 5)
            stats = stats.lstrip(b"\0\n")
            added = deleted = "0"
            old_path = None
            if stats:
                plus, minus, names = stats.split(b"\t", 2)
                added, deleted = plus.decode(), minus.decode()
                if names.startswith(b"\0"):
                    old, new = names[1:].split(b"\0", 2)[:2]
                    path = os.fsdecode(new)
                    old_path = os.fsdecode(old)
                else:
                    path = os.fsdecode(names.split(b"\0", 1)[0])
            self.commits.append(Commit(
                sha.decode(), int(stamp), author.decode("utf-8", "replace"),
                subject.decode("utf-8", "replace"), parents.decode().split(),
                path, old_path or path, added, deleted,
            ))
            if old_path is not None:
                path = old_path

        if self.lines and self.commits:
            self.filter_lines()
        status = self.git("status", "--porcelain", "--untracked-files=normal", "--", self.path)
        if status:
            stats = self.git("diff", "--numstat", HEAD_REVISION, "--", self.path).decode().split() if has_head else []
            added, deleted = stats[:2] if stats else (str(len(self.file.read_bytes().splitlines())), "0")
            self.commits.insert(0, Commit(WORKTREE, int(time.time()), "you",
                                         "Working tree (staged + unstaged)", [], self.path, self.path,
                                         added, deleted))
        self.commits.reverse()
        return self.commits

    def filter_lines(self):
        head = self.blob(HEAD_REVISION, self.path).splitlines(keepends=True)
        working = self.file.read_bytes().splitlines(keepends=True)
        start, end = self.lines
        mapped = []
        for tag, a, b, x, y in difflib.SequenceMatcher(None, head, working, autojunk=False).get_opcodes():
            lo, hi = max(x, start - 1), min(y, end)
            if lo >= hi:
                continue
            if tag == "equal":
                mapped.extend((a + lo - x + 1, a + hi - x))
            elif tag == "replace" and a < b:
                mapped.extend((a + 1, b))
        if not mapped:
            self.commits = []
            self.note = "Selected lines are new in the working tree; no committed history."
            return
        hashes = set(self.git("log", "--no-patch", "--format=%H", "-L",
                              f"{min(mapped)},{max(mapped)}:{self.path}", HEAD_REVISION).decode().split())
        self.commits = [commit for commit in self.commits if commit.sha in hashes]

    def comparison(self, first, last, mode):
        oldest, newest = self.commits[first], self.commits[last]
        if mode == MODE_CURRENT:
            if oldest.sha == WORKTREE:
                before = self.git("show", f"HEAD:{self.path}", allowed=(0, 128))
                title = "HEAD -> working tree (staged + unstaged)"
            else:
                before = self.blob(oldest.sha, oldest.path)
                title = f"{oldest.sha[:8]} -> working tree (staged + unstaged)"
            after = self.file.read_bytes() if self.file.exists() else b""
            old_name = oldest.path
            return title, before, after, old_name, self.path
        if oldest.sha == WORKTREE:
            return self.comparison(first, last, MODE_CURRENT)
        before = self.git("show", f"{oldest.parents[0]}:{oldest.parent_path}",
                          allowed=(0, 128)) if oldest.parents else b""
        if newest.sha == WORKTREE:
            after = self.file.read_bytes() if self.file.exists() else b""
        else:
            after = self.git("show", f"{newest.sha}:{newest.path}", allowed=(0, 128))
        title = f"Commit {newest.sha[:8]}" if first == last else (
            f"{oldest.sha[:8]}^ -> {newest.sha[:8]} ({last - first + 1} selected)"
        )
        return title, before, after, oldest.parent_path, newest.path

    def diff(self, first, last, mode):
        title, before, after, old_name, new_name = self.comparison(first, last, mode)
        return title, file_diff(self.commands, before, after, old_name, new_name)

    def diff_paths(self, first, last, mode):
        _, before, after, old_name, new_name = self.comparison(first, last, mode)
        old = self.cached_file(before, old_name, f"before-{hashlib.sha256(before).hexdigest()[:12]}")
        is_working = mode == MODE_CURRENT or self.commits[last].sha == WORKTREE
        new = self.file if is_working and self.file.exists() else self.cached_file(
            after, new_name, f"after-{hashlib.sha256(after).hexdigest()[:12]}",
        )
        return old, new

    def snapshot(self, index):
        commit = self.commits[index]
        if commit.sha == WORKTREE:
            return self.file
        data = self.blob(commit.sha, commit.path)
        return self.cached_file(data, commit.path, commit.sha[:12])

    def cached_file(self, data, path, revision):
        identity = hashlib.sha256(os.fsencode(str(self.root))).hexdigest()[:12]
        destination = Path.home() / "Library/Caches/zed-file-history" / identity / revision / path
        destination.parent.mkdir(parents=True, exist_ok=True)
        if not destination.exists():
            destination.write_bytes(data)
            destination.chmod(0o444)
        return destination


def file_diff(commands, before, after, old_name, new_name):
    with tempfile.TemporaryDirectory(prefix="zed-history-diff-") as directory:
        root = Path(directory)
        old, new = root / "before" / old_name, root / "after" / new_name
        old.parent.mkdir(parents=True, exist_ok=True)
        new.parent.mkdir(parents=True, exist_ok=True)
        old.write_bytes(before)
        new.write_bytes(after)
        return commands.run(
            ["git", "--no-pager", "diff", "--no-index", "--no-ext-diff", "--no-textconv",
             "--no-color", "--src-prefix=", "--dst-prefix=", "--", str(old.relative_to(root)),
             str(new.relative_to(root))], cwd=root, allowed=(0, 1),
        )


def relative_date(timestamp):
    seconds = max(0, int(time.time()) - timestamp)
    for size, suffix in [(31536000, "y"), (2592000, "mo"), (604800, "w"),
                         (86400, "d"), (3600, "h"), (60, "m")]:
        if seconds >= size:
            return f"{seconds // size}{suffix}"
    return "now"


def cell_width(text):
    return sum(0 if unicodedata.combining(char) else
               2 if unicodedata.east_asian_width(char) in "WF" else 1 for char in text)


def clip(text, width):
    result = []
    used = 0
    for char in text.replace("\t", "    "):
        if unicodedata.category(char).startswith("C"):
            continue
        size = cell_width(char)
        if used + size > width:
            break
        result.append(char)
        used += size
    return "".join(result)


class Screen:
    def __init__(self, window):
        self.window = window
        self.pairs = {}
        curses.start_color()
        curses.use_default_colors()
        curses.curs_set(0)
        window.timeout(50)
        window.keypad(True)

    def style(self, foreground=-1, background=-1, bold=False):
        key = (foreground, background)
        if key not in self.pairs and len(self.pairs) + 1 < curses.COLOR_PAIRS:
            number = len(self.pairs) + 1
            curses.init_pair(number, *key)
            self.pairs[key] = number
        return curses.color_pair(self.pairs.get(key, 0)) | (curses.A_BOLD if bold else 0)

    def write(self, row, column, text, width, style=0):
        text = clip(text, max(0, width))
        try:
            self.window.addstr(row, column, text, style)
        except curses.error:
            pass
        return cell_width(text)

    def ansi(self, row, column, text, width):
        position = 0
        foreground = background = -1
        bold = False
        start = 0
        for match in ANSI.finditer(text):
            position += self.write(row, column + position, text[start:match.start()], width - position,
                                   self.style(foreground, background, bold))
            start = match.end()
            sequence = match.group()
            if not sequence.endswith("m") or not sequence.startswith("\x1b["):
                continue
            values = [int(value or 0) for value in sequence[2:-1].split(";")]
            index = 0
            while index < len(values):
                value = values[index]
                if value == 0:
                    foreground = background = -1
                    bold = False
                elif value in (1, 22):
                    bold = value == 1
                elif 30 <= value <= 37:
                    foreground = value - 30
                elif 90 <= value <= 97:
                    foreground = value - 90 + (8 if curses.COLORS >= 16 else 0)
                elif 40 <= value <= 47:
                    background = value - 40
                elif value in (39, 49):
                    if value == 39:
                        foreground = -1
                    else:
                        background = -1
                elif value in (38, 48) and index + 2 < len(values):
                    if values[index + 1] == 5:
                        color = values[index + 2]
                        index += 2
                    elif values[index + 1] == 2 and index + 4 < len(values):
                        rgb = values[index + 2:index + 5]
                        color = 16 + sum(round(channel / 255 * 5) * scale
                                         for channel, scale in zip(rgb, (36, 6, 1)))
                        index += 4
                    else:
                        color = -1
                    if color >= curses.COLORS:
                        color = -1
                    if value == 38:
                        foreground = color
                    else:
                        background = color
                index += 1
        self.write(row, column + position, text[start:], width - position,
                   self.style(foreground, background, bold))


class Browser:
    def __init__(self, history, delta, zed):
        self.history = history
        self.delta = delta
        self.zed = zed
        self.index = 0
        self.anchor = None
        self.focus = PANEL_COMMITS
        self.mode = MODE_COMMIT
        self.scroll = 0
        self.top = 0
        self.preview = []
        self.preview_title = "Loading history..."
        self.message = ""
        self.future = None
        self.request = None
        self.cache = {}
        self.executor = concurrent.futures.ThreadPoolExecutor(max_workers=1)

    def selection(self):
        if self.anchor is None:
            return self.index, self.index
        return min(self.anchor, self.index), max(self.anchor, self.index)

    def render_diff(self, first, last, mode, width):
        title, patch = self.history.diff(first, last, mode)
        if not patch:
            return title, "No differences.\n"
        output = self.history.commands.run(
            [self.delta, "--paging=never", "--line-numbers", "--true-color=never",
             f"--width={max(30, width)}"], data=patch,
        ).decode("utf-8", "replace")
        return title, output

    def update_preview(self, width):
        key = (*self.selection(), self.mode, width)
        if self.future and self.future.done():
            try:
                self.cache[self.request] = self.future.result()
            except (RuntimeError, OSError) as error:
                self.cache[self.request] = ("Preview error", str(error))
            self.future = None
        if key in self.cache:
            self.preview_title, output = self.cache[key]
            self.preview = output.splitlines()
        elif self.future is None:
            self.request = key
            self.future = self.executor.submit(self.render_diff, *key)
            self.preview_title, self.preview = "Loading diff...", []
        else:
            self.preview_title, self.preview = "Loading diff...", []
        if len(self.cache) > 80:
            self.cache.pop(next(iter(self.cache)))

    def open_tab(self, key):
        if key in ENTER_KEYS:
            paths = [str(self.history.snapshot(self.index))]
        else:
            self.mode = MODE_CURRENT if key == ord("c") else MODE_COMMIT
            paths = ["--diff", *map(str, self.history.diff_paths(*self.selection(), self.mode))]
        self.history.commands.run([self.zed, "--add", *paths], cwd=self.history.root)

    def draw(self, screen):
        window = screen.window
        height, width = window.getmaxyx()
        window.erase()
        if height < 9 or width < 45:
            screen.write(0, 0, "Resize terminal to at least 45 x 9. q: quit", width - 1)
            window.refresh()
            return
        is_wide = width >= PREVIEW_MIN_WIDTH
        left = min(max(58, width * 46 // 100), width - 48) if is_wide else width
        screen.write(0, 1, f"FILE HISTORY  {self.history.path}", width - 2,
                     screen.style(6, bold=True))
        scope = f"lines {self.history.lines[0]}:{self.history.lines[1]} | " if self.history.lines else ""
        screen.write(1, 1, scope + f"{len(self.history.commits)} commits | {self.history.root.name}", width - 2)
        rows = height - 6
        self.top = min(self.top, self.index)
        if self.index >= self.top + rows:
            self.top = self.index - rows + 1
        first, last = self.selection()
        screen.write(2, 1, (f"{FOCUS_MARKER} " if self.focus == PANEL_COMMITS else "") + "COMMITS", left - 2,
                     screen.style(6 if self.focus == PANEL_COMMITS else 7, bold=True))
        visible = self.history.commits[self.top:self.top + rows]
        for offset, commit in enumerate(visible):
            index = self.top + offset
            row = height - 3 - len(visible) + offset
            is_selected = self.anchor is not None and first <= index <= last
            background = 238 if index == self.index and curses.COLORS >= 256 else -1
            base = screen.style(background=background)
            screen.write(row, 0, " " * left, left, base)
            marker = ">" if index == self.index else " "
            marker += "*" if is_selected else " "
            column = screen.write(row, 0, marker + " ", left, screen.style(6, background, True))
            column += screen.write(row, column, commit.sha[:8].ljust(9), left - column,
                                   screen.style(3, background))
            column += screen.write(row, column, relative_date(commit.timestamp).rjust(4) + " ",
                                   left - column, screen.style(6, background))
            author = clip(commit.author, 12)
            column += screen.write(row, column, author + " " * (13 - cell_width(author)),
                                   left - column, screen.style(2 + sum(map(ord, commit.author)) % 5, background))
            stats_width = len(commit.added) + len(commit.deleted) + 4
            subject_width = max(0, left - column - stats_width - 1)
            screen.write(row, column, commit.subject, subject_width, base)
            column = left - stats_width
            column += screen.write(row, column, f"+{commit.added} ", stats_width,
                                   screen.style(2, background))
            screen.write(row, column, f"-{commit.deleted}", left - column,
                         screen.style(1, background))
        if is_wide and self.history.commits:
            self.update_preview(width - left - 3)
            for row in range(2, height - 3):
                screen.write(row, left, "│", 1, screen.style(8 if curses.COLORS > 8 else 7))
            screen.write(2, left + 2, (f"{FOCUS_MARKER} " if self.focus == PANEL_PREVIEW else "") + self.preview_title,
                         width - left - 3, screen.style(6, bold=True))
            for offset, line in enumerate(self.preview[self.scroll:self.scroll + rows]):
                screen.ansi(offset + 3, left + 2, line, width - left - 3)
        status = self.message or self.history.note or (
            f"{last - first + 1} selected | d: changes before oldest -> newest" if self.anchor is not None else
            "Open Zed tab: Enter: snapshot   c: compare with working tree   d: file diff"
        )
        screen.write(height - 3, 1, status, width - 2, screen.style(3))
        screen.write(height - 2, 1, "j/k or Ctrl+N/P: move  h/l: panels  t: toggle focus  Shift+V: range  Esc: clear  q: quit", width - 2)
        screen.write(height - 1, 1, "Preview: same keys scroll, Ctrl+D/U page | Enter/d/c open Zed tabs; history stays open", width - 2,
                     screen.style(8 if curses.COLORS > 8 else 7))
        window.refresh()

    def run(self, window):
        screen = Screen(window)
        loading = self.executor.submit(self.history.load)
        while not loading.done():
            screen.write(0, 1, "Loading file history... q: quit", window.getmaxyx()[1] - 2)
            window.refresh()
            if window.getch() in (ord("q"), 3, 27):
                return None
        loading.result()
        self.index = max(0, len(self.history.commits) - 1)
        while True:
            self.draw(screen)
            key = window.getch()
            if key == -1:
                continue
            self.message = ""
            if key in (ord("q"), 3):
                return None
            if key in (ord("h"), curses.KEY_LEFT):
                self.focus = PANEL_COMMITS
            elif key in (ord("l"), curses.KEY_RIGHT) and window.getmaxyx()[1] >= PREVIEW_MIN_WIDTH:
                self.focus = PANEL_PREVIEW
            elif key == ord("t") and window.getmaxyx()[1] >= PREVIEW_MIN_WIDTH:
                self.focus = PANEL_PREVIEW if self.focus == PANEL_COMMITS else PANEL_COMMITS
            elif key in (ord("j"), ord("k"), CTRL_N, CTRL_P, curses.KEY_DOWN, curses.KEY_UP, 4, 21,
                         curses.KEY_NPAGE, curses.KEY_PPAGE, ord("g"), ord("G")):
                step = 1 if key in (ord("j"), CTRL_N, curses.KEY_DOWN) else -1
                if key in (4, 21, curses.KEY_NPAGE, curses.KEY_PPAGE):
                    step = max(1, (window.getmaxyx()[0] - 6) // 2) * (1 if key in (4, curses.KEY_NPAGE) else -1)
                if self.focus == PANEL_PREVIEW:
                    target = 0 if key == ord("g") else len(self.preview) - 1 if key == ord("G") else self.scroll + step
                    self.scroll = max(0, min(max(0, len(self.preview) - 1), target))
                else:
                    target = 0 if key == ord("g") else len(self.history.commits) - 1 if key == ord("G") else self.index + step
                    self.index = max(0, min(max(0, len(self.history.commits) - 1), target))
                    self.scroll = 0
            elif key == ord("V") and self.history.commits:
                self.anchor = self.index if self.anchor is None else None
                self.scroll = 0
            elif key == 27:
                self.anchor = None
                self.focus = PANEL_COMMITS
                self.scroll = 0
            elif self.history.commits and key in (*ENTER_KEYS, ord("c"), ord("d")):
                try:
                    self.open_tab(key)
                except (RuntimeError, OSError) as error:
                    self.message = str(error)

    def close(self):
        self.history.commands.close()
        self.executor.shutdown(wait=True, cancel_futures=True)


def main():
    parser = argparse.ArgumentParser(description="Zed current-file Git history with delta preview")
    parser.add_argument("file", nargs="?", default=os.environ.get("ZED_FILE"))
    parser.add_argument("--selected-lines", action="store_true")
    parser.add_argument("--lines", help="Inclusive working-tree line range, START:END")
    args = parser.parse_args()
    if not args.file:
        parser.error("Open a saved file in Zed first, or provide its path.")
    lines = None
    if args.selected_lines:
        selected = os.environ.get("ZED_SELECTED_TEXT", "")
        if not selected:
            parser.error("Zed did not provide selected text. Select at least one non-blank line.")
        start = int(os.environ.get("ZED_ROW", "1"))
        lines = (start, start + len(selected.splitlines()) - 1)
    elif args.lines:
        lines = tuple(map(int, args.lines.split(":")))
    if lines and (len(lines) != 2 or lines[0] < 1 or lines[1] < lines[0]):
        parser.error("Invalid line range")
    delta = shutil.which("delta")
    zed = shutil.which("zed")
    if not delta or not zed:
        parser.error("Both delta and zed must be installed and on PATH.")
    locale.setlocale(locale.LC_ALL, "")
    browser = Browser(History(args.file, lines), delta, zed)
    try:
        curses.wrapper(browser.run)
    finally:
        browser.close()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        raise SystemExit(0) from None
    except (RuntimeError, OSError) as error:
        print(f"File history: {error}", file=sys.stderr)
        raise SystemExit(1) from None
