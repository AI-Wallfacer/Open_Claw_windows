import json
import os
import sys
import time
from pathlib import Path


STATE_FILE = Path(os.getenv("STATE_FILE", "/state/heartbeat.json"))
MAX_AGE_SECONDS = int(os.getenv("HEALTHCHECK_MAX_AGE_SECONDS", "180"))


def main() -> int:
    if not STATE_FILE.exists():
        print(f"heartbeat file not found: {STATE_FILE}")
        return 1

    try:
        payload = json.loads(STATE_FILE.read_text(encoding="utf-8"))
        updated_at = payload.get("updated_at")
        if not updated_at:
            print("heartbeat missing updated_at")
            return 1
    except Exception as exc:
        print(f"heartbeat parse failed: {exc}")
        return 1

    mtime = STATE_FILE.stat().st_mtime
    age = time.time() - mtime
    if age > MAX_AGE_SECONDS:
        print(f"heartbeat too old: {age:.1f}s > {MAX_AGE_SECONDS}s")
        return 1

    print("ok")
    return 0


if __name__ == "__main__":
    sys.exit(main())

