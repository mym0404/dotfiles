import json
import os
import subprocess
import sys
from pathlib import Path


ZED_CLI = "/opt/homebrew/bin/zed"


def main():
    request = json.loads(sys.argv[1])
    path = Path(request["path"]).resolve()

    if path.is_dir():
        os.execv(ZED_CLI, [ZED_CLI, str(path)])

    directory = path.parent
    result = subprocess.run(
        ["/usr/bin/git", "-C", str(directory), "rev-parse", "--show-toplevel"],
        capture_output=True,
        text=True,
        check=False,
    )
    project_root = result.stdout.strip() if result.returncode == 0 else str(directory)

    target = str(path)
    location = request.get("location")
    if location is not None:
        target += f":{location['line']}:{location['column']}"

    os.execv(ZED_CLI, [ZED_CLI, project_root, target])


if __name__ == "__main__":
    main()
