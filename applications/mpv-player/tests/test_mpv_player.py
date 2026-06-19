from __future__ import annotations

import importlib.util
import subprocess
import tempfile
import unittest
from pathlib import Path
from types import ModuleType
from unittest.mock import patch


def load_module() -> ModuleType:
    module_path = Path(__file__).resolve().parent.parent / "mpv-player.py"
    spec = importlib.util.spec_from_file_location("mpv_player", module_path)
    if spec is None or spec.loader is None:
        raise RuntimeError("failed to load mpv-player.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


mpv_player = load_module()


class TestMpvPlayer(unittest.TestCase):
    def test_discover_media_files_returns_supported_files_sorted(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            music_dir = Path(tmp)
            (music_dir / "b.mp4").write_text("")
            (music_dir / "a.mp3").write_text("")
            (music_dir / "note.txt").write_text("")
            nested = music_dir / "nested"
            nested.mkdir()
            (nested / "c.FLAC").write_text("")

            result = mpv_player.discover_media_files(music_dir)

            self.assertEqual(
                result,
                [
                    music_dir / "a.mp3",
                    music_dir / "b.mp4",
                    nested / "c.FLAC",
                ],
            )

    def test_select_filtered_media_with_fzf_returns_filtered_paths(self) -> None:
        music_dir = Path("music")
        paths = [music_dir / "a.mp3", music_dir / "nested" / "b.mp4"]
        completed = subprocess.CompletedProcess(
            args=["fzf"], returncode=0, stdout="a.mp3\nnested/b.mp4\n"
        )

        with patch.object(mpv_player.subprocess, "run", return_value=completed) as mock_run:
            result = mpv_player.select_filtered_media_with_fzf(paths, music_dir)

        mock_run.assert_called_once()
        command = mock_run.call_args.args[0]
        self.assertIn("--bind", command)
        self.assertIn("enter:select-all+accept", command)
        self.assertEqual(result, [music_dir / "a.mp3", music_dir / "nested" / "b.mp4"])

    def test_write_playlist_creates_parent_and_m3u_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            playlist_file = Path(tmp) / "playlist" / "mpv-player.m3u"
            paths = [Path("music/a.mp3"), Path("music/b.mp4")]

            mpv_player.write_playlist(paths, playlist_file)

            self.assertEqual(
                playlist_file.read_text(), "#EXTM3U\nmusic/a.mp3\nmusic/b.mp4\n"
            )

    def test_playlist_has_entries_ignores_comments_and_blank_lines(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            playlist_file = Path(tmp) / "mpv-player.m3u"
            playlist_file.write_text("#EXTM3U\n\nmusic/a.mp3\n")

            self.assertTrue(mpv_player.playlist_has_entries(playlist_file))

    def test_playlist_has_entries_returns_false_when_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            playlist_file = Path(tmp) / "missing.m3u"

            self.assertFalse(mpv_player.playlist_has_entries(playlist_file))

    def test_build_mpv_command_for_play_once(self) -> None:
        command = mpv_player.build_mpv_command(Path("music/playlist.m3u"), "A")

        self.assertEqual(command, ["mpv", "--no-video", "--playlist=music/playlist.m3u"])

    def test_build_mpv_command_for_repeat(self) -> None:
        command = mpv_player.build_mpv_command(Path("music/playlist.m3u"), "B")

        self.assertEqual(
            command,
            [
                "mpv",
                "--no-video",
                "--playlist=music/playlist.m3u",
                "--loop-playlist=inf",
            ],
        )

    def test_build_mpv_command_for_shuffle(self) -> None:
        command = mpv_player.build_mpv_command(Path("music/playlist.m3u"), "C")

        self.assertEqual(
            command,
            [
                "mpv",
                "--no-video",
                "--playlist=music/playlist.m3u",
                "--shuffle",
            ],
        )

    def test_select_media_with_fzf_returns_selected_paths(self) -> None:
        music_dir = Path("music")
        paths = [music_dir / "a.mp3", music_dir / "nested" / "b.mp4"]
        completed = subprocess.CompletedProcess(
            args=["fzf"], returncode=0, stdout="nested/b.mp4\n"
        )

        with patch.object(mpv_player.subprocess, "run", return_value=completed):
            result = mpv_player.select_media_with_fzf(paths, music_dir)

        self.assertEqual(result, [music_dir / "nested" / "b.mp4"])


if __name__ == "__main__":
    unittest.main()
