import json
import os
import signal
import subprocess
import time
from datetime import datetime, timezone
from pathlib import Path

import yaml


TASK_CONFIG = os.getenv("TASK_CONFIG", "/config/tasks.yaml")
LOOP_INTERVAL_SECONDS = int(os.getenv("LOOP_INTERVAL_SECONDS", "60"))
STATE_FILE = Path(os.getenv("STATE_FILE", "/state/heartbeat.json"))

SHOULD_STOP = False


def on_signal(signum, _frame):
    global SHOULD_STOP
    SHOULD_STOP = True
    print(f"[worker] received signal {signum}, will stop after current iteration")


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def load_tasks(config_path: str) -> list[dict]:
    path = Path(config_path)
    if not path.exists():
        print(f"[worker] task config does not exist: {config_path}")
        return []

    with path.open("r", encoding="utf-8") as f:
        doc = yaml.safe_load(f) or {}

    tasks = doc.get("tasks", [])
    if not isinstance(tasks, list):
        print("[worker] config format invalid: tasks must be a list")
        return []
    return tasks


def write_heartbeat(last_results: list[dict], status: str = "ok") -> None:
    STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "status": status,
        "updated_at": now_iso(),
        "loop_interval_seconds": LOOP_INTERVAL_SECONDS,
        "last_results": last_results,
    }
    STATE_FILE.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")


def run_task(task: dict) -> dict:
    name = str(task.get("name", "unnamed-task"))
    command = task.get("command")
    timeout_seconds = int(task.get("timeout_seconds", 60))

    if not command:
        msg = "missing command"
        print(f"[task:{name}] skip: {msg}")
        return {"name": name, "ok": False, "error": msg, "at": now_iso()}

    print(f"[task:{name}] start command={command!r}")
    started = time.time()
    try:
        proc = subprocess.run(
            command,
            shell=True,
            check=False,
            timeout=timeout_seconds,
            capture_output=True,
            text=True,
        )
        elapsed = round(time.time() - started, 3)
        ok = proc.returncode == 0
        if proc.stdout.strip():
            print(f"[task:{name}] stdout: {proc.stdout.strip()}")
        if proc.stderr.strip():
            print(f"[task:{name}] stderr: {proc.stderr.strip()}")
        print(f"[task:{name}] done code={proc.returncode} elapsed={elapsed}s")
        return {
            "name": name,
            "ok": ok,
            "code": proc.returncode,
            "elapsed_seconds": elapsed,
            "at": now_iso(),
        }
    except subprocess.TimeoutExpired:
        elapsed = round(time.time() - started, 3)
        print(f"[task:{name}] timeout after {elapsed}s")
        return {"name": name, "ok": False, "error": "timeout", "elapsed_seconds": elapsed, "at": now_iso()}


def main() -> None:
    signal.signal(signal.SIGTERM, on_signal)
    signal.signal(signal.SIGINT, on_signal)

    print(f"[worker] started, task config: {TASK_CONFIG}")
    print(f"[worker] loop interval: {LOOP_INTERVAL_SECONDS}s")

    while not SHOULD_STOP:
        tasks = load_tasks(TASK_CONFIG)
        results = []

        if not tasks:
            print("[worker] no task configured, sleeping")
        else:
            for task in tasks:
                if SHOULD_STOP:
                    break
                results.append(run_task(task))

        write_heartbeat(results, status="ok")

        for _ in range(LOOP_INTERVAL_SECONDS):
            if SHOULD_STOP:
                break
            time.sleep(1)

    write_heartbeat([], status="stopping")
    print("[worker] stopped")


if __name__ == "__main__":
    main()

