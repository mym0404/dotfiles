#!/usr/bin/env python3
import argparse
import ast
import concurrent.futures
import curses
import difflib
import hashlib
import itertools
import locale
import os
from pathlib import Path
import re
import select
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
HISTORY_PAGE_SIZE = 100
LOADING_FRAMES = "|/-\\"
CTRL_D = 4
CTRL_N = 14
CTRL_P = 16
CTRL_U = 21
COPY_HASH_KEY = ord("y")
COPY_PATCH_KEY = ord("p")
ENTER_KEYS = (10, 13, curses.KEY_ENTER)
ANSI = re.compile(r"\x1b\][^\x07]*?(?:\x07|\x1b\\)|\x1b\[[0-?]*[ -/]*[@-~]")
LOG_FORMAT = "%x1e%H%x00%ct%x00%an%x00%s%x00%P%x00"
LOG_RECORD_SEPARATOR = b"\x1e"
GIT_COMMAND = ("git", "--literal-pathspecs", "--no-pager")


class Commands:
    def __init__(self):
        self.processes = set()
        self.lock = threading.Lock()
        self.is_closed = False

    def start(self, args, *, cwd=None, stderr=subprocess.PIPE):
        with self.lock:
            if self.is_closed:
                raise RuntimeError("History closed")
            child = subprocess.Popen(args, cwd=cwd, stdin=subprocess.PIPE,
                                     stdout=subprocess.PIPE, stderr=stderr)
            self.processes.add(child)
        return child

    def run(self, args, *, cwd=None, data=None, allowed=(0,)):
        child = self.start(args, cwd=cwd)
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

    def stream_log(self, args, *, cwd):
        with tempfile.TemporaryFile() as errors:
            child = self.start(args, cwd=cwd, stderr=errors)
            pending = b""
            try:
                while True:
                    boundary = pending.find(LOG_RECORD_SEPARATOR, 1)
                    if boundary >= 0:
                        record, pending = pending[:boundary], pending[boundary:]
                        yield record
                        continue
                    if not select.select([child.stdout], [], [], COMMAND_TIMEOUT)[0]:
                        raise subprocess.TimeoutExpired(args, COMMAND_TIMEOUT)
                    chunk = child.stdout.read1(65536)
                    if chunk:
                        pending += chunk
                        continue
                    child.wait(timeout=COMMAND_TIMEOUT)
                    if child.returncode:
                        errors.seek(0)
                        raise RuntimeError(errors.read().decode("utf-8", "replace").strip() or
                                           f"Git history exited with {child.returncode}")
                    if pending:
                        yield pending
                    return
            except subprocess.TimeoutExpired:
                raise RuntimeError("Git history query timed out") from None
            finally:
                if child.poll() is None:
                    child.terminate()
                try:
                    child.wait(timeout=COMMAND_TIMEOUT)
                except subprocess.TimeoutExpired:
                    child.kill()
                    child.wait()
                child.stdin.close()
                child.stdout.close()
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


def log_records(raw):
    for record in raw.split(LOG_RECORD_SEPARATOR)[1:]:
        sha, stamp, author, subject, parents, body = record.split(b"\0", 5)
        yield Commit(sha.decode(), int(stamp), author.decode("utf-8", "replace"),
                     subject.decode("utf-8", "replace"), parents.decode().split(),
                     "", "", "0", "0"), body.lstrip(b"\0\n")


def numstats(raw):
    fields = iter(raw.split(b"\0"))
    for field in fields:
        if not field:
            continue
        added, deleted, name = field.split(b"\t", 2)
        old_name = next(fields) if not name else name
        new_name = next(fields) if not name else name
        yield added.decode(), deleted.decode(), os.fsdecode(old_name), os.fsdecode(new_name)


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
        self.head = ""
        self.offset = 0
        self.has_more = False
        self.next_path = self.path
        self.line_range = None
        self.record_stream = None

    def git(self, *args, data=None, allowed=(0,)):
        return self.commands.run([*GIT_COMMAND, *args],
                                 cwd=self.root, data=data, allowed=allowed)

    def blob(self, sha, path):
        result = self.git("show", f"{sha}:{path}")
        return result

    def load(self):
        self.close()
        self.head = self.git("rev-parse", "--verify", HEAD_REVISION, allowed=(0, 128)).decode().strip()
        self.offset = 0
        self.next_path = self.path
        self.has_more = bool(self.head)
        if self.lines and self.has_more:
            self.line_range = self.map_lines()
            self.has_more = self.line_range is not None
        commits = self.load_more() if self.has_more else []
        status = self.git("status", "--porcelain", "--untracked-files=normal", "--", self.path)
        if status:
            stats = self.git("diff", "--numstat", self.head, "--", self.path).decode().split() if self.head else []
            added, deleted = stats[:2] if stats else (str(len(self.file.read_bytes().splitlines())), "0")
            commits.append(Commit(WORKTREE, int(time.time()), "you",
                                  "Working tree (staged + unstaged)", [], self.path, self.path,
                                  added, deleted))
        return commits

    def load_more(self):
        args = ["log", "--no-color", "--no-ext-diff", "--no-textconv", f"--format={LOG_FORMAT}"]
        if self.lines:
            start, end = self.line_range
            raw = self.git("-c", "core.quotePath=true", *args,
                           f"--max-count={HISTORY_PAGE_SIZE}", f"--skip={self.offset}",
                           "--src-prefix=a/", "--dst-prefix=b/",
                           "-L", f"{start},{end}:{self.path}", self.head)
            records = list(log_records(raw))
        else:
            try:
                if self.record_stream is None:
                    self.record_stream = self.commands.stream_log(
                        [*GIT_COMMAND, *args, "--follow", "--numstat", "-z", self.head, "--", self.path],
                        cwd=self.root,
                    )
                    for _ in itertools.islice(self.record_stream, self.offset):
                        pass
                records = [next(log_records(raw)) for raw in itertools.islice(self.record_stream, HISTORY_PAGE_SIZE)]
            except (RuntimeError, OSError):
                self.close()
                raise
        if self.lines and records:
            self.load_line_stats(records)
        else:
            path = self.next_path
            for commit, body in records:
                stats = next(numstats(body), ("0", "0", path, path))
                commit.added, commit.deleted, commit.parent_path, commit.path = stats
                path = commit.parent_path
            self.next_path = path
        self.offset += len(records)
        self.has_more = len(records) == HISTORY_PAGE_SIZE
        return [commit for commit, _ in reversed(records)]

    def close(self):
        if self.record_stream is not None:
            self.record_stream.close()
            self.record_stream = None

    def load_line_stats(self, records):
        commits = {}
        paths = set()
        for commit, body in records:
            for line in body.splitlines():
                if not line.startswith((b"--- ", b"+++ ")):
                    continue
                name = line[4:].split(b"\t", 1)[0]
                if name.startswith(b'"'):
                    # Git quotes filename bytes with C-style octal escapes.
                    name = ast.literal_eval(name.decode("ascii")).encode("latin-1")
                if name != b"/dev/null":
                    name = os.fsdecode(name[2:])
                    if line.startswith(b"--- "):
                        commit.parent_path = name
                    else:
                        commit.path = name
                if line.startswith(b"+++ "):
                    break
            commit.path = commit.path or commit.parent_path
            commit.parent_path = commit.parent_path or commit.path
            commits[commit.sha] = commit
            paths.update((commit.path, commit.parent_path))
        raw = self.git("show", "--numstat", "-z", "--no-color", "--no-ext-diff", "--no-textconv",
                       "--find-renames", "--diff-merges=first-parent", f"--format={LOG_FORMAT}",
                       *commits, "--", *sorted(paths))
        for details, body in log_records(raw):
            commit = commits[details.sha]
            commit.parents = details.parents
            for added, deleted, old_name, new_name in numstats(body):
                if new_name == commit.path:
                    commit.added, commit.deleted, commit.parent_path = added, deleted, old_name
                    break

    def map_lines(self):
        head = self.git("show", f"{self.head}:{self.path}", allowed=(0, 128)).splitlines(keepends=True)
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
            self.note = "Selected lines are new in the working tree; no committed history."
            return None
        return min(mapped), max(mapped)

    def comparison(self, commits, mode):
        oldest, newest = commits[0], commits[-1]
        if mode == MODE_CURRENT:
            if oldest.sha == WORKTREE:
                before = self.git("show", f"{self.head}:{self.path}", allowed=(0, 128)) if self.head else b""
                title = "HEAD -> working tree (staged + unstaged)"
            else:
                before = self.blob(oldest.sha, oldest.path)
                title = f"{oldest.sha[:8]} -> working tree (staged + unstaged)"
            after = self.file.read_bytes() if self.file.exists() else b""
            old_name = oldest.path
            return title, before, after, old_name, self.path
        if oldest.sha == WORKTREE:
            return self.comparison(commits, MODE_CURRENT)
        before = self.git("show", f"{oldest.parents[0]}:{oldest.parent_path}",
                          allowed=(0, 128)) if oldest.parents else b""
        if newest.sha == WORKTREE:
            after = self.file.read_bytes() if self.file.exists() else b""
        else:
            after = self.git("show", f"{newest.sha}:{newest.path}", allowed=(0, 128))
        title = f"Commit {newest.sha[:8]}" if len(commits) == 1 else (
            f"{oldest.sha[:8]}^ -> {newest.sha[:8]} ({len(commits)} selected)"
        )
        return title, before, after, oldest.parent_path, newest.path

    def diff(self, commits, mode):
        title, before, after, old_name, new_name = self.comparison(commits, mode)
        return title, file_diff(self.commands, before, after, old_name, new_name)

    def diff_paths(self, commits, mode):
        _, before, after, old_name, new_name = self.comparison(commits, mode)
        old = self.cached_file(before, old_name, f"before-{hashlib.sha256(before).hexdigest()[:12]}")
        is_working = mode == MODE_CURRENT or commits[-1].sha == WORKTREE
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
        self.history_executor = concurrent.futures.ThreadPoolExecutor(max_workers=1)
        self.history_future = None
        self.history_error = ""
        self.is_loaded = False

    def selection(self):
        if self.anchor is None:
            return self.index, self.index
        return min(self.anchor, self.index), max(self.anchor, self.index)

    def selected_commits(self):
        first, last = self.selection()
        return self.history.commits[first:last + 1]

    def update_history(self, rows):
        if self.history_future and self.history_future.done():
            try:
                commits = self.history_future.result()
            except (RuntimeError, OSError) as error:
                self.history_error = str(error)
            else:
                if self.is_loaded:
                    count = len(commits)
                    self.history.commits = commits + self.history.commits
                    self.index += count
                    self.top += count
                    if self.anchor is not None:
                        self.anchor += count
                else:
                    self.history.commits = commits
                    self.index = max(0, len(commits) - 1)
                    self.is_loaded = True
            self.history_future = None
        if self.history_future is None and not self.history_error:
            if not self.is_loaded:
                self.history_future = self.history_executor.submit(self.history.load)
            elif self.history.has_more and self.index <= max(5, rows):
                self.history_future = self.history_executor.submit(self.history.load_more)

    def render_diff(self, commits, mode, width):
        title, patch = self.history.diff(commits, mode)
        if not patch:
            return title, "No differences.\n"
        output = self.history.commands.run(
            [self.delta, "--paging=never", "--line-numbers", "--true-color=never",
             f"--width={max(30, width)}"], data=patch,
        ).decode("utf-8", "replace")
        return title, output

    def update_preview(self, width):
        commits = self.selected_commits()
        key = (commits[0].sha, commits[-1].sha, len(commits), self.mode, width)
        if self.future and self.future.done():
            try:
                title, output = self.future.result()
                self.cache[self.request] = (title, output.splitlines())
            except (RuntimeError, OSError) as error:
                self.cache[self.request] = ("Preview error", [str(error)])
            self.future = None
        if key in self.cache:
            self.preview_title, self.preview = self.cache[key]
        elif self.future is None:
            self.request = key
            self.future = self.executor.submit(self.render_diff, commits, self.mode, width)
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
            paths = ["--diff", *map(str, self.history.diff_paths(self.selected_commits(), self.mode))]
        self.history.commands.run([self.zed, "--add", *paths], cwd=self.history.root)

    def copy_selection(self, key):
        if key == COPY_HASH_KEY:
            commit = self.history.commits[self.index]
            if commit.sha == WORKTREE:
                self.message = "Working tree has no commit hash."
                return
            data = commit.sha.encode("ascii")
            label = "Commit hash"
        else:
            _, data = self.history.diff(self.selected_commits(), self.mode)
            if not data:
                self.message = "No file changes to copy."
                return
            label = "File patch"
        self.history.commands.run(["pbcopy"], data=data)
        self.message = f"{label} copied."

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
        count = len(self.history.commits) - int(bool(self.history.commits) and self.history.commits[-1].sha == WORKTREE)
        progress = ""
        if self.history_future:
            frame = LOADING_FRAMES[int(time.monotonic() * 8) % len(LOADING_FRAMES)]
            progress = f" | {frame} loading {HISTORY_PAGE_SIZE} {'more' if self.is_loaded else 'commits'}"
        elif self.history_error:
            progress = " | load failed (r: retry)"
        elif self.history.has_more:
            progress = " | older history available"
        screen.write(1, 1, scope + f"{count} commits loaded | {self.history.root.name}" + progress, width - 2)
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
        status = self.message or self.history_error or self.history.note or (
            f"{last - first + 1} selected | d: changes before oldest -> newest" if self.anchor is not None else
            "Open Zed tab: Enter: snapshot   c: compare with working tree   d: file diff"
        )
        screen.write(height - 3, 1, status, width - 2, screen.style(3))
        screen.write(height - 2, 1, "j/k Ctrl+N/P: move  h/l/t: focus  v: range  y: hash  p: file patch  Esc: clear  q: quit", width - 2)
        screen.write(height - 1, 1, "Ctrl+D/U: preview page (any focus) | Enter/d/c: Zed tabs; history stays open", width - 2,
                     screen.style(8 if curses.COLORS > 8 else 7))
        window.refresh()

    def run(self, window):
        screen = Screen(window)
        while True:
            self.update_history(max(1, window.getmaxyx()[0] - 6))
            self.draw(screen)
            key = window.getch()
            if key == -1:
                continue
            self.message = ""
            if key in (ord("q"), 3):
                return None
            if key == ord("r") and self.history_error:
                self.history_error = ""
            elif key in (ord("h"), curses.KEY_LEFT):
                self.focus = PANEL_COMMITS
            elif key in (ord("l"), curses.KEY_RIGHT) and window.getmaxyx()[1] >= PREVIEW_MIN_WIDTH:
                self.focus = PANEL_PREVIEW
            elif key == ord("t") and window.getmaxyx()[1] >= PREVIEW_MIN_WIDTH:
                self.focus = PANEL_PREVIEW if self.focus == PANEL_COMMITS else PANEL_COMMITS
            elif key in (ord("j"), ord("k"), CTRL_N, CTRL_P, curses.KEY_DOWN, curses.KEY_UP, CTRL_D, CTRL_U,
                         curses.KEY_NPAGE, curses.KEY_PPAGE, ord("g"), ord("G")):
                step = 1 if key in (ord("j"), CTRL_N, curses.KEY_DOWN) else -1
                if key in (CTRL_D, CTRL_U, curses.KEY_NPAGE, curses.KEY_PPAGE):
                    step = max(1, (window.getmaxyx()[0] - 6) // 2) * (1 if key in (CTRL_D, curses.KEY_NPAGE) else -1)
                if self.focus == PANEL_PREVIEW or key in (CTRL_D, CTRL_U):
                    target = 0 if key == ord("g") else len(self.preview) - 1 if key == ord("G") else self.scroll + step
                    self.scroll = max(0, min(max(0, len(self.preview) - 1), target))
                else:
                    target = 0 if key == ord("g") else len(self.history.commits) - 1 if key == ord("G") else self.index + step
                    self.index = max(0, min(max(0, len(self.history.commits) - 1), target))
                    self.scroll = 0
            elif key == ord("v") and self.history.commits:
                self.anchor = self.index if self.anchor is None else None
                self.scroll = 0
            elif key == 27:
                self.anchor = None
                self.focus = PANEL_COMMITS
                self.scroll = 0
            elif self.history.commits and key in (*ENTER_KEYS, ord("c"), ord("d"), COPY_HASH_KEY, COPY_PATCH_KEY):
                try:
                    if key in (COPY_HASH_KEY, COPY_PATCH_KEY):
                        self.copy_selection(key)
                    else:
                        self.open_tab(key)
                except (RuntimeError, OSError) as error:
                    self.message = str(error)

    def close(self):
        self.history.commands.close()
        self.history_executor.shutdown(wait=True, cancel_futures=True)
        self.executor.shutdown(wait=True, cancel_futures=True)
        self.history.close()


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
