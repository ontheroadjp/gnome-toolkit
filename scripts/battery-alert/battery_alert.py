#!/usr/bin/env python3
from __future__ import annotations

import subprocess
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
ENV_FILE = SCRIPT_DIR / ".env"
STATE_FILE = Path("/tmp/battery-alert.state")
POWER_SUPPLY_DIR = Path("/sys/class/power_supply")
DEFAULT_THRESHOLDS = (50,)
DISCHARGING_STATUS = "Discharging"
NOTIFY_URGENCY = "critical"
NOTIFY_TITLE = "バッテリー低下"


def load_env(env_file: Path) -> dict[str, str]:
    if not env_file.is_file():
        return {}
    env: dict[str, str] = {}
    for line in env_file.read_text().splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        key, sep, value = stripped.partition("=")
        if not sep:
            continue
        env[key.strip()] = value.strip()
    return env


def parse_thresholds(raw: str | None) -> list[int]:
    if not raw:
        return sorted(DEFAULT_THRESHOLDS, reverse=True)
    thresholds = {int(part.strip()) for part in raw.split(",") if part.strip()}
    if not thresholds:
        return sorted(DEFAULT_THRESHOLDS, reverse=True)
    return sorted(thresholds, reverse=True)


def find_battery_path(power_supply_dir: Path = POWER_SUPPLY_DIR) -> Path | None:
    if not power_supply_dir.is_dir():
        return None
    for entry in sorted(power_supply_dir.glob("BAT*")):
        return entry
    return None


def read_battery_state(battery_path: Path) -> tuple[int, str]:
    capacity = int((battery_path / "capacity").read_text().strip())
    status = (battery_path / "status").read_text().strip()
    return capacity, status


def load_notified_thresholds(state_file: Path) -> set[int]:
    if not state_file.is_file():
        return set()
    content = state_file.read_text().strip()
    if not content:
        return set()
    return {int(part) for part in content.split(",") if part.strip()}


def save_notified_thresholds(state_file: Path, notified: set[int]) -> None:
    state_file.write_text(",".join(str(t) for t in sorted(notified, reverse=True)))


def clear_state(state_file: Path) -> None:
    if state_file.is_file():
        state_file.unlink()


def thresholds_to_notify(
    capacity: int, thresholds: list[int], notified: set[int]
) -> list[int]:
    return sorted(
        (t for t in thresholds if capacity <= t and t not in notified),
        reverse=True,
    )


def send_notification(threshold: int, capacity: int) -> None:
    message = f"残量が{threshold}%以下（現在: {capacity}%）です。"
    subprocess.run(
        ["notify-send", "-u", NOTIFY_URGENCY, NOTIFY_TITLE, message],
        check=True,
    )


def run(
    env_file: Path = ENV_FILE,
    state_file: Path = STATE_FILE,
    power_supply_dir: Path = POWER_SUPPLY_DIR,
) -> None:
    battery_path = find_battery_path(power_supply_dir)
    if battery_path is None:
        return

    env = load_env(env_file)
    thresholds = parse_thresholds(env.get("NOTIFY_THRESHOLDS"))
    capacity, status = read_battery_state(battery_path)

    if status != DISCHARGING_STATUS:
        clear_state(state_file)
        return

    notified = load_notified_thresholds(state_file)
    to_notify = thresholds_to_notify(capacity, thresholds, notified)

    if to_notify:
        notified.update(to_notify)
        save_notified_thresholds(state_file, notified)
        send_notification(to_notify[-1], capacity)


def main() -> None:
    run()


if __name__ == "__main__":
    main()
