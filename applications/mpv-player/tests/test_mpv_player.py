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
            media_dir = Path(tmp)
            (media_dir / "b.mp4").write_text("")
            (media_dir / "a.mp3").write_text("")
            (media_dir / "note.txt").write_text("")
            nested = media_dir / "nested"
            nested.mkdir()
            (nested / "c.FLAC").write_text("")

            result = mpv_player.discover_media_files(
                media_dir, mpv_player.MUSIC_EXTENSIONS | mpv_player.VIDEO_EXTENSIONS
            )

            self.assertEqual(
                result,
                [
                    media_dir / "a.mp3",
                    media_dir / "b.mp4",
                    nested / "c.FLAC",
                ],
            )

    def test_discover_media_files_with_music_extensions_excludes_video(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            media_dir = Path(tmp)
            (media_dir / "a.mp3").write_text("")
            (media_dir / "b.mp4").write_text("")

            result = mpv_player.discover_media_files(media_dir, mpv_player.MUSIC_EXTENSIONS)

            self.assertEqual(result, [media_dir / "a.mp3"])

    def test_discover_media_files_with_video_extensions_excludes_music(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            media_dir = Path(tmp)
            (media_dir / "a.mp3").write_text("")
            (media_dir / "b.mp4").write_text("")

            result = mpv_player.discover_media_files(media_dir, mpv_player.VIDEO_EXTENSIONS)

            self.assertEqual(result, [media_dir / "b.mp4"])

    def test_select_filtered_media_with_fzf_returns_filtered_paths(self) -> None:
        media_dir = Path("media")
        paths = [media_dir / "a.mp3", media_dir / "nested" / "b.mp4"]
        completed = subprocess.CompletedProcess(
            args=["fzf"], returncode=0, stdout="a.mp3\nnested/b.mp4\n"
        )

        with patch.object(mpv_player.subprocess, "run", return_value=completed) as mock_run:
            result = mpv_player.select_filtered_media_with_fzf(paths, media_dir, "music> ")

        mock_run.assert_called_once()
        command = mock_run.call_args.args[0]
        self.assertIn("--bind", command)
        self.assertIn("enter:select-all+accept", command)
        self.assertEqual(result, [media_dir / "a.mp3", media_dir / "nested" / "b.mp4"])

    def test_write_playlist_creates_parent_and_m3u_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            playlist_file = Path(tmp) / "playlist" / "mpv-player.m3u"
            paths = [Path("media/a.mp3"), Path("media/b.mp4")]

            mpv_player.write_playlist(paths, playlist_file)

            self.assertEqual(
                playlist_file.read_text(), "#EXTM3U\nmedia/a.mp3\nmedia/b.mp4\n"
            )

    def test_playlist_has_entries_ignores_comments_and_blank_lines(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            playlist_file = Path(tmp) / "mpv-player.m3u"
            playlist_file.write_text("#EXTM3U\n\nmedia/a.mp3\n")

            self.assertTrue(mpv_player.playlist_has_entries(playlist_file))

    def test_playlist_has_entries_returns_false_when_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            playlist_file = Path(tmp) / "missing.m3u"

            self.assertFalse(mpv_player.playlist_has_entries(playlist_file))

    def test_build_mpv_command_for_play_once_with_no_video(self) -> None:
        command = mpv_player.build_mpv_command(
            Path("music/playlist.m3u"), "A", no_video=True
        )

        self.assertEqual(
            command, ["mpv", "--no-video", "--playlist=music/playlist.m3u"]
        )

    def test_build_mpv_command_for_repeat_with_no_video(self) -> None:
        command = mpv_player.build_mpv_command(
            Path("music/playlist.m3u"), "B", no_video=True
        )

        self.assertEqual(
            command,
            [
                "mpv",
                "--no-video",
                "--playlist=music/playlist.m3u",
                "--loop-playlist=inf",
            ],
        )

    def test_build_mpv_command_for_shuffle_with_no_video(self) -> None:
        command = mpv_player.build_mpv_command(
            Path("music/playlist.m3u"), "C", no_video=True
        )

        self.assertEqual(
            command,
            [
                "mpv",
                "--no-video",
                "--playlist=music/playlist.m3u",
                "--shuffle",
            ],
        )

    def test_build_mpv_command_for_video_omits_no_video(self) -> None:
        command = mpv_player.build_mpv_command(
            Path("video/playlist.m3u"), "A", no_video=False
        )

        self.assertEqual(command, ["mpv", "--playlist=video/playlist.m3u"])

    def test_select_media_with_fzf_returns_selected_paths(self) -> None:
        media_dir = Path("media")
        paths = [media_dir / "a.mp3", media_dir / "nested" / "b.mp4"]
        completed = subprocess.CompletedProcess(
            args=["fzf"], returncode=0, stdout="nested/b.mp4\n"
        )

        with patch.object(mpv_player.subprocess, "run", return_value=completed):
            result = mpv_player.select_media_with_fzf(paths, media_dir, "music> ")

        self.assertEqual(result, [media_dir / "nested" / "b.mp4"])

    def test_playlist_file_for_uses_cwd_relative_playlist_dir(self) -> None:
        media_dir = Path("media")

        self.assertEqual(
            mpv_player.playlist_file_for(media_dir),
            media_dir / "playlist" / "mpv-player.m3u",
        )

    def test_run_uses_current_working_directory_as_media_dir(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            with patch.object(mpv_player.Path, "cwd", return_value=Path(tmp)):
                with patch.object(mpv_player, "read_main_choice", return_value="3"):
                    exit_code = mpv_player.run(mpv_player.MODE_MUSIC)

        self.assertEqual(exit_code, 1)

    def test_parse_player_mode_accepts_music(self) -> None:
        self.assertEqual(mpv_player.parse_player_mode(["music"]), "music")

    def test_parse_player_mode_accepts_video(self) -> None:
        self.assertEqual(mpv_player.parse_player_mode(["video"]), "video")

    def test_parse_player_mode_rejects_unknown_argument(self) -> None:
        with self.assertRaises(SystemExit):
            mpv_player.parse_player_mode(["podcast"])

    def test_parse_player_mode_rejects_missing_argument(self) -> None:
        with self.assertRaises(SystemExit):
            mpv_player.parse_player_mode([])

    def test_media_extensions_by_mode_music_excludes_video_extensions(self) -> None:
        extensions = mpv_player.MEDIA_EXTENSIONS_BY_MODE[mpv_player.MODE_MUSIC]

        self.assertNotIn(".mp4", extensions)
        self.assertIn(".mp3", extensions)

    def test_media_extensions_by_mode_video_excludes_music_extensions(self) -> None:
        extensions = mpv_player.MEDIA_EXTENSIONS_BY_MODE[mpv_player.MODE_VIDEO]

        self.assertNotIn(".mp3", extensions)
        self.assertIn(".mp4", extensions)

    def test_create_playlist_from_selection_only_offers_given_extensions(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            media_dir = Path(tmp)
            (media_dir / "a.mp3").write_text("")
            (media_dir / "b.mp4").write_text("")
            playlist_file = media_dir / "playlist" / "mpv-player.m3u"
            completed = subprocess.CompletedProcess(
                args=["fzf"], returncode=0, stdout="a.mp3\n"
            )

            with patch.object(mpv_player.subprocess, "run", return_value=completed) as mock_run:
                result = mpv_player.create_playlist_from_selection(
                    media_dir, playlist_file, "music> ", mpv_player.MUSIC_EXTENSIONS
                )

            self.assertTrue(result)
            fzf_input = mock_run.call_args.kwargs["input"]
            self.assertEqual(fzf_input, "a.mp3\n")


if __name__ == "__main__":
    unittest.main()
