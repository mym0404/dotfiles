#!/usr/bin/env python3
import argparse
import base64
from datetime import datetime
import json
import shutil
import subprocess
import tempfile
from pathlib import Path
from urllib.parse import quote


OWNER = "mym0404"
REPO = "ia2"
REPOSITORY = f"{OWNER}/{REPO}"
DEFAULT_QUALITY = 82


def parse_args():
    parser = argparse.ArgumentParser(
        description="Convert an image to WebP and upload it directly to mym0404/ia2 with gh."
    )
    parser.add_argument("--input", required=True, help="Source image path.")
    parser.add_argument(
        "--dest",
        help="Root-level repository filename ending in .webp. Defaults to YYYYMMDDHHMMSSNNN.webp.",
    )
    parser.add_argument("--message", required=True, help="Git commit message.")
    parser.add_argument("--branch", help="Target branch. Defaults to the repository default branch.")
    parser.add_argument("--quality", type=int, default=DEFAULT_QUALITY, help="WebP quality, default 82.")
    parser.add_argument("--max-edge", type=int, help="Resize so the longest edge is at most this many pixels.")
    parser.add_argument("--replace", action="store_true", help="Replace an existing destination file.")
    return parser.parse_args()


def run(command, **kwargs):
    return subprocess.run(command, check=True, **kwargs)


def capture(command):
    return subprocess.run(command, check=True, capture_output=True, text=True).stdout.strip()


def require_command(name):
    path = shutil.which(name)
    if path is None:
        raise SystemExit(f"Required command not found: {name}")
    return path


def validate_dest(dest):
    relative_dest = Path(dest)
    if relative_dest.is_absolute() or ".." in relative_dest.parts:
        raise SystemExit("--dest must be a safe root-level filename.")
    if len(relative_dest.parts) != 1:
        raise SystemExit("--dest must be a root-level filename, not a directory path.")
    if relative_dest.suffix.lower() != ".webp":
        raise SystemExit("--dest must end with .webp")
    return relative_dest


def get_default_branch():
    return capture(
        [
            "gh",
            "repo",
            "view",
            REPOSITORY,
            "--json",
            "defaultBranchRef",
            "--jq",
            ".defaultBranchRef.name",
        ]
    )


def get_existing_sha(dest, branch):
    endpoint = f"/repos/{REPOSITORY}/contents/{quote(dest.as_posix(), safe='/')}?ref={quote(branch)}"
    result = subprocess.run(["gh", "api", endpoint], capture_output=True, text=True)
    if result.returncode != 0:
        if "Not Found" in result.stderr or "HTTP 404" in result.stderr:
            return None
        raise SystemExit(result.stderr.strip())
    payload = json.loads(result.stdout)
    return payload.get("sha")


def list_repo_paths(branch):
    endpoint = f"/repos/{REPOSITORY}/git/trees/{quote(branch, safe='')}?recursive=1"
    result = subprocess.run(["gh", "api", endpoint], capture_output=True, text=True)
    if result.returncode != 0:
        raise SystemExit(result.stderr.strip())
    payload = json.loads(result.stdout)
    return {
        item["path"]
        for item in payload.get("tree", [])
        if item.get("type") == "blob" and isinstance(item.get("path"), str)
    }


def generate_dest(branch):
    existing_paths = list_repo_paths(branch)
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    for sequence in range(1, 1000):
        candidate = f"{timestamp}{sequence:03d}.webp"
        if candidate not in existing_paths:
            return Path(candidate)
    raise SystemExit("Could not find an available generated destination path.")


def upload_file(webp_path, dest, branch, message, replace):
    content = base64.b64encode(webp_path.read_bytes()).decode("ascii")
    body = {
        "message": message,
        "content": content,
        "branch": branch,
    }
    existing_sha = get_existing_sha(dest, branch)
    if existing_sha is not None:
        if not replace:
            raise SystemExit(f"Destination already exists: {dest}. Use --replace to update it.")
        body["sha"] = existing_sha

    endpoint = f"/repos/{REPOSITORY}/contents/{quote(dest.as_posix(), safe='/')}"
    result = subprocess.run(
        ["gh", "api", "--method", "PUT", endpoint, "--input", "-"],
        input=json.dumps(body),
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise SystemExit(result.stderr.strip())
    payload = json.loads(result.stdout)
    return payload["commit"]["sha"]


def cdn_url(dest):
    encoded_path = "/".join(quote(part) for part in dest.parts)
    return f"https://cdn.jsdelivr.net/gh/{REPOSITORY}/{encoded_path}"


def main():
    args = parse_args()
    magick = require_command("magick")
    require_command("gh")

    source = Path(args.input).expanduser().resolve()
    if not source.is_file():
        raise SystemExit(f"Input file not found: {source}")
    if not 1 <= args.quality <= 100:
        raise SystemExit("--quality must be between 1 and 100.")

    branch = args.branch or get_default_branch()
    dest = validate_dest(args.dest) if args.dest else generate_dest(branch)

    with tempfile.TemporaryDirectory(prefix="img-webp-") as temp_dir:
        webp_path = Path(temp_dir) / dest.name
        command = [magick, str(source), "-auto-orient"]
        if args.max_edge is not None:
            if args.max_edge < 1:
                raise SystemExit("--max-edge must be positive.")
            command.extend(["-resize", f"{args.max_edge}x{args.max_edge}>"])
        command.extend(
            [
                "-strip",
                "-quality",
                str(args.quality),
                "-define",
                "webp:method=6",
                str(webp_path),
            ]
        )
        run(command)
        size_bytes = webp_path.stat().st_size
        commit_sha = upload_file(webp_path, dest, branch, args.message, args.replace)

    print(f"repository={REPOSITORY}")
    print(f"branch={branch}")
    print(f"relative_path={dest.as_posix()}")
    print(f"size_bytes={size_bytes}")
    print(f"commit_sha={commit_sha}")
    print(f"cdn_url={cdn_url(dest)}")


if __name__ == "__main__":
    main()
