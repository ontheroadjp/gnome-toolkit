#!/usr/bin/env python3
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

MUSIC_DIR = Path.home() / "Music"
PLAYLIST_FILE = MUSIC_DIR / "playlist" / "mpv-player.m3u"

MEDIA_EXTENSIONS = {
    ".3gp",
    ".aac",
    ".aiff",
    ".ape",
    ".asf",
    ".avi",
    ".flac",
    ".flv",
    ".m2ts",
    ".m4a",
    ".m4v",
    ".mka",
    ".mkv",
    ".mov",
    ".mp3",
    ".mp4",
    ".mpeg",
    ".mpg",
    ".oga",
    ".ogg",
    ".ogm",
    ".ogv",
    ".opus",
    ".ts",
    ".wav",
    ".webm",
    ".wma",
    ".wmv",
}

MAIN_MENU = (
    "1. 楽曲を選んで再生",
    "2. 検索結果をすべて再生",
    "3. 前回のプレイリストを再生",
)
PLAYBACK_MENU = (
    "A. 再生",
    "B. リピート再生",
    "C. ランダム再生",
)

PLAY_ONCE = "A"
PLAY_REPEAT = "B"
PLAY_SHUFFLE = "C"


def discover_media_files(music_dir: Path = MUSIC_DIR) -> list[Path]:
    if not music_dir.is_dir():
        return []
    return sorted(
        path
        for path in music_dir.rglob("*")
        if path.is_file() and path.suffix.lower() in MEDIA_EXTENSIONS
    )


def format_media_choices(paths: list[Path], music_dir: Path = MUSIC_DIR) -> str:
    lines = [display_path(path, music_dir) for path in paths]
    return "\n".join(lines) + ("\n" if lines else "")


def display_path(path: Path, music_dir: Path = MUSIC_DIR) -> str:
    try:
        return str(path.relative_to(music_dir))
    except ValueError:
        return str(path)


def resolve_display_path(display: str, music_dir: Path = MUSIC_DIR) -> Path:
    path = Path(display)
    if path.is_absolute():
        return path
    return music_dir / path


def select_media_with_fzf(paths: list[Path], music_dir: Path = MUSIC_DIR) -> list[Path]:
    result = subprocess.run(
        ["fzf", "--multi", "--prompt", "music> "],
        input=format_media_choices(paths, music_dir),
        text=True,
        stdout=subprocess.PIPE,
        check=False,
    )
    if result.returncode != 0 or not result.stdout.strip():
        return []
    return [
        resolve_display_path(line, music_dir)
        for line in result.stdout.splitlines()
        if line.strip()
    ]


def select_filtered_media_with_fzf(
    paths: list[Path], music_dir: Path = MUSIC_DIR
) -> list[Path]:
    result = subprocess.run(
        [
            "fzf",
            "--multi",
            "--prompt",
            "search> ",
            "--bind",
            "enter:select-all+accept",
        ],
        input=format_media_choices(paths, music_dir),
        text=True,
        stdout=subprocess.PIPE,
        check=False,
    )
    if result.returncode != 0 or not result.stdout.strip():
        return []
    return [
        resolve_display_path(line, music_dir)
        for line in result.stdout.splitlines()
        if line.strip()
    ]


def write_playlist(paths: list[Path], playlist_file: Path = PLAYLIST_FILE) -> None:
    playlist_file.parent.mkdir(parents=True, exist_ok=True)
    content = "#EXTM3U\n" + "\n".join(str(path) for path in paths) + "\n"
    playlist_file.write_text(content)


def playlist_has_entries(playlist_file: Path = PLAYLIST_FILE) -> bool:
    if not playlist_file.is_file():
        return False
    return any(
        line.strip() and not line.startswith("#")
        for line in playlist_file.read_text().splitlines()
    )


def build_mpv_command(playlist_file: Path, mode: str) -> list[str]:
    command = ["mpv", "--no-video", f"--playlist={playlist_file}"]
    if mode == PLAY_REPEAT:
        command.append("--loop-playlist=inf")
    elif mode == PLAY_SHUFFLE:
        command.append("--shuffle")
    return command


def play_playlist(playlist_file: Path = PLAYLIST_FILE, mode: str = PLAY_ONCE) -> int:
    return subprocess.run(build_mpv_command(playlist_file, mode), check=False).returncode


def print_menu(title: str, entries: tuple[str, ...]) -> None:
    print()
    print(title)
    for entry in entries:
        print(entry)


def read_main_choice() -> str:
    print_menu("main menu", MAIN_MENU)
    return input("> ").strip()


def read_playback_choice() -> str:
    print_menu("再生メニュー", PLAYBACK_MENU)
    return input("> ").strip().upper()


def choose_playback_mode() -> str | None:
    mode = read_playback_choice()
    if mode not in {PLAY_ONCE, PLAY_REPEAT, PLAY_SHUFFLE}:
        print("無効な選択です。", file=sys.stderr)
        return None
    return mode


def create_playlist_from_selection() -> bool:
    media_files = discover_media_files()
    if not media_files:
        print(f"メディアファイルが見つかりません: {MUSIC_DIR}", file=sys.stderr)
        return False
    selected = select_media_with_fzf(media_files)
    if not selected:
        print("選択されたファイルがありません。", file=sys.stderr)
        return False
    write_playlist(selected)
    return True


def create_playlist_from_search() -> bool:
    media_files = discover_media_files()
    if not media_files:
        print(f"メディアファイルが見つかりません: {MUSIC_DIR}", file=sys.stderr)
        return False
    matched = select_filtered_media_with_fzf(media_files)
    if not matched:
        print("検索結果がありません。", file=sys.stderr)
        return False
    write_playlist(matched)
    print(f"{len(matched)} 件をプレイリストに追加しました。")
    return True


def replay_existing_playlist() -> bool:
    if not playlist_has_entries():
        print(f"既存のプレイリストがありません: {PLAYLIST_FILE}", file=sys.stderr)
        return False
    return True


def run() -> int:
    choice = read_main_choice()
    if choice == "1":
        ready_to_play = create_playlist_from_selection()
    elif choice == "2":
        ready_to_play = create_playlist_from_search()
    elif choice == "3":
        ready_to_play = replay_existing_playlist()
    else:
        print("無効な選択です。", file=sys.stderr)
        return 1

    if not ready_to_play:
        return 1

    mode = choose_playback_mode()
    if mode is None:
        return 1
    return play_playlist(mode=mode)


def main() -> None:
    raise SystemExit(run())


if __name__ == "__main__":
    main()
