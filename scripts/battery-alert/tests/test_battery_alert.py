from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import battery_alert  # noqa: E402


class TestLoadEnv(unittest.TestCase):
    def test_missing_file_returns_empty_dict(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            env_file = Path(tmp) / ".env"
            self.assertEqual(battery_alert.load_env(env_file), {})

    def test_parses_key_value_and_skips_comments_and_blanks(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            env_file = Path(tmp) / ".env"
            env_file.write_text(
                "# comment\n\nNOTIFY_THRESHOLDS=80,50,30\nPOLL_INTERVAL=60\n"
            )
            self.assertEqual(
                battery_alert.load_env(env_file),
                {"NOTIFY_THRESHOLDS": "80,50,30", "POLL_INTERVAL": "60"},
            )


class TestParseThresholds(unittest.TestCase):
    def test_none_returns_default(self) -> None:
        self.assertEqual(battery_alert.parse_thresholds(None), [50])

    def test_empty_string_returns_default(self) -> None:
        self.assertEqual(battery_alert.parse_thresholds(""), [50])

    def test_sorts_descending_and_dedupes(self) -> None:
        self.assertEqual(
            battery_alert.parse_thresholds("30,80,50,80"), [80, 50, 30]
        )


class TestThresholdsToNotify(unittest.TestCase):
    def test_returns_only_crossed_and_unnotified_descending(self) -> None:
        result = battery_alert.thresholds_to_notify(
            capacity=40, thresholds=[80, 50, 30], notified=set()
        )
        self.assertEqual(result, [80, 50])

    def test_excludes_already_notified(self) -> None:
        result = battery_alert.thresholds_to_notify(
            capacity=40, thresholds=[80, 50, 30], notified={50}
        )
        self.assertEqual(result, [80])

    def test_empty_when_capacity_above_all_thresholds(self) -> None:
        result = battery_alert.thresholds_to_notify(
            capacity=90, thresholds=[80, 50, 30], notified=set()
        )
        self.assertEqual(result, [])


class TestNotifiedStateFile(unittest.TestCase):
    def test_load_missing_file_returns_empty_set(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            state_file = Path(tmp) / "state"
            self.assertEqual(battery_alert.load_notified_thresholds(state_file), set())

    def test_save_and_load_roundtrip(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            state_file = Path(tmp) / "state"
            battery_alert.save_notified_thresholds(state_file, {80, 50})
            self.assertEqual(
                battery_alert.load_notified_thresholds(state_file), {80, 50}
            )

    def test_clear_state_removes_existing_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            state_file = Path(tmp) / "state"
            state_file.write_text("80")
            battery_alert.clear_state(state_file)
            self.assertFalse(state_file.exists())

    def test_clear_state_noop_when_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            state_file = Path(tmp) / "state"
            battery_alert.clear_state(state_file)
            self.assertFalse(state_file.exists())


class TestFindBatteryPath(unittest.TestCase):
    def test_returns_none_when_dir_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            missing = Path(tmp) / "no-such-dir"
            self.assertIsNone(battery_alert.find_battery_path(missing))

    def test_returns_first_bat_entry_sorted(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            power_supply_dir = Path(tmp)
            (power_supply_dir / "BAT1").mkdir()
            (power_supply_dir / "BAT0").mkdir()
            result = battery_alert.find_battery_path(power_supply_dir)
            self.assertEqual(result, power_supply_dir / "BAT0")


class TestReadBatteryState(unittest.TestCase):
    def test_reads_capacity_and_status(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            battery_path = Path(tmp)
            (battery_path / "capacity").write_text("42\n")
            (battery_path / "status").write_text("Discharging\n")
            capacity, status = battery_alert.read_battery_state(battery_path)
            self.assertEqual(capacity, 42)
            self.assertEqual(status, "Discharging")


class TestRun(unittest.TestCase):
    def _make_battery(self, root: Path, capacity: int, status: str) -> Path:
        battery_path = root / "BAT0"
        battery_path.mkdir()
        (battery_path / "capacity").write_text(str(capacity))
        (battery_path / "status").write_text(status)
        return battery_path

    def test_does_nothing_when_no_battery_present(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            env_file = root / ".env"
            state_file = root / "state"
            power_supply_dir = root / "power_supply"
            power_supply_dir.mkdir()

            with patch.object(battery_alert.subprocess, "run") as mock_run:
                battery_alert.run(env_file, state_file, power_supply_dir)

            mock_run.assert_not_called()
            self.assertFalse(state_file.exists())

    def test_notifies_only_lowest_crossed_threshold(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            power_supply_dir = root / "power_supply"
            power_supply_dir.mkdir()
            self._make_battery(power_supply_dir, capacity=40, status="Discharging")

            env_file = root / ".env"
            env_file.write_text("NOTIFY_THRESHOLDS=80,50,30\n")
            state_file = root / "state"

            with patch.object(battery_alert.subprocess, "run") as mock_run:
                battery_alert.run(env_file, state_file, power_supply_dir)

            self.assertEqual(mock_run.call_count, 1)
            self.assertIn("50%以下", mock_run.call_args[0][0][4])
            self.assertEqual(
                battery_alert.load_notified_thresholds(state_file), {80, 50}
            )

    def test_all_crossed_thresholds_are_saved_to_state(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            power_supply_dir = root / "power_supply"
            power_supply_dir.mkdir()
            self._make_battery(power_supply_dir, capacity=38, status="Discharging")

            env_file = root / ".env"
            env_file.write_text("NOTIFY_THRESHOLDS=10,20,30,40,50,60,70,80\n")
            state_file = root / "state"

            with patch.object(battery_alert.subprocess, "run") as mock_run:
                battery_alert.run(env_file, state_file, power_supply_dir)

            self.assertEqual(mock_run.call_count, 1)
            self.assertIn("40%以下", mock_run.call_args[0][0][4])
            self.assertEqual(
                battery_alert.load_notified_thresholds(state_file),
                {80, 70, 60, 50, 40},
            )

    def test_does_not_renotify_already_notified_threshold(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            power_supply_dir = root / "power_supply"
            power_supply_dir.mkdir()
            self._make_battery(power_supply_dir, capacity=40, status="Discharging")

            env_file = root / ".env"
            env_file.write_text("NOTIFY_THRESHOLDS=50\n")
            state_file = root / "state"
            battery_alert.save_notified_thresholds(state_file, {50})

            with patch.object(battery_alert.subprocess, "run") as mock_run:
                battery_alert.run(env_file, state_file, power_supply_dir)

            mock_run.assert_not_called()

    def test_resets_state_when_charging(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            power_supply_dir = root / "power_supply"
            power_supply_dir.mkdir()
            self._make_battery(power_supply_dir, capacity=40, status="Charging")

            env_file = root / ".env"
            state_file = root / "state"
            battery_alert.save_notified_thresholds(state_file, {50})

            with patch.object(battery_alert.subprocess, "run") as mock_run:
                battery_alert.run(env_file, state_file, power_supply_dir)

            mock_run.assert_not_called()
            self.assertFalse(state_file.exists())


if __name__ == "__main__":
    unittest.main()
