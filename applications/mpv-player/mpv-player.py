#!/usr/bin/env python3
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

MODE_MUSIC = "music"
MODE_VIDEO = "video"
PLAYER_MODES = (MODE_MUSIC, MODE_VIDEO)

MUSIC_EXTENSIONS = {
    ".aac",
    ".aiff",
    ".ape",
    ".flac",
    ".m4a",
    ".mka",
    ".mp3",
    ".oga",
    ".ogg",
    ".opus",
    ".wav",
    ".wma",
}

VIDEO_EXTENSIONS = {
    ".3gp",
    ".asf",
    ".avi",
    ".flv",
    ".m2ts",
    ".m4v",
    ".mkv",
    ".mov",
    ".mp4",
    ".mpeg",
    ".mpg",
    ".ogm",
    ".ogv",
    ".ts",
    ".webm",
    ".wmv",
}

MEDIA_EXTENSIONS_BY_MODE = {
    MODE_MUSIC: MUSIC_EXTENSIONS,
    MODE_VIDEO: VIDEO_EXTENSIONS,
}

MAIN_MENU = (
    "1. Select files to play",
    "2. Play all search results",
    "3. Replay last playlist",
)
PLAYBACK_MENU = (
    "A. Play",
    "B. Play on repeat",
    "C. Play shuffled",
)

PLAY_ONCE = "A"
PLAY_REPEAT = "B"
PLAY_SHUFFLE = "C"


def playlist_file_for(media_dir: Path) -> Path:
    return media_dir / "playlist" / "mpv-player.m3u"


def discover_media_files(media_dir: Path, extensions: set[str]) -> list[Path]:
    if not media_dir.is_dir():
        return []
    return sorted(
        path
        for path in media_dir.rglob("*")
        if path.is_file() and path.suffix.lower() in extensions
    )


def format_media_choices(paths: list[Path], media_dir: Path) -> str:
    lines = [display_path(path, media_dir) for path in paths]
    return "\n".join(lines) + ("\n" if lines else "")


def display_path(path: Path, media_dir: Path) -> str:
    try:
        return str(path.relative_to(media_dir))
    except ValueError:
        return str(path)


def resolve_display_path(display: str, media_dir: Path) -> Path:
    path = Path(display)
    if path.is_absolute():
        return path
    return media_dir / path


def select_media_with_fzf(paths: list[Path], media_dir: Path, prompt: str) -> list[Path]:
    result = subprocess.run(
        ["fzf", "--multi", "--prompt", prompt],
        input=format_media_choices(paths, media_dir),
        text=True,
        stdout=subprocess.PIPE,
        check=False,
    )
    if result.returncode != 0 or not result.stdout.strip():
        return []
    return [
        resolve_display_path(line, media_dir)
        for line in result.stdout.splitlines()
        if line.strip()
    ]


def select_filtered_media_with_fzf(
    paths: list[Path], media_dir: Path, prompt: str
) -> list[Path]:
    result = subprocess.run(
        [
            "fzf",
            "--multi",
            "--prompt",
            prompt,
            "--bind",
            "enter:select-all+accept",
        ],
        input=format_media_choices(paths, media_dir),
        text=True,
        stdout=subprocess.PIPE,
        check=False,
    )
    if result.returncode != 0 or not result.stdout.strip():
        return []
    return [
        resolve_display_path(line, media_dir)
        for line in result.stdout.splitlines()
        if line.strip()
    ]


def write_playlist(paths: list[Path], playlist_file: Path) -> None:
    playlist_file.parent.mkdir(parents=True, exist_ok=True)
    content = "#EXTM3U\n" + "\n".join(str(path) for path in paths) + "\n"
    playlist_file.write_text(content)


def playlist_has_entries(playlist_file: Path) -> bool:
    if not playlist_file.is_file():
        return False
    return any(
        line.strip() and not line.startswith("#")
        for line in playlist_file.read_text().splitlines()
    )


def build_mpv_command(playlist_file: Path, mode: str, no_video: bool) -> list[str]:
    command = ["mpv"]
    if no_video:
        command.append("--no-video")
    command.append(f"--playlist={playlist_file}")
    if mode == PLAY_REPEAT:
        command.append("--loop-playlist=inf")
    elif mode == PLAY_SHUFFLE:
        command.append("--shuffle")
    return command


def play_playlist(playlist_file: Path, mode: str, no_video: bool) -> int:
    return subprocess.run(
        build_mpv_command(playlist_file, mode, no_video), check=False
    ).returncode


def print_menu(title: str, entries: tuple[str, ...]) -> None:
    print()
    print(title)
    for entry in entries:
        print(entry)


def read_main_choice() -> str:
    print_menu("main menu", MAIN_MENU)
    return input("> ").strip()


def read_playback_choice() -> str:
    print_menu("playback menu", PLAYBACK_MENU)
    return input("> ").strip().upper()


def choose_playback_mode() -> str | None:
    mode = read_playback_choice()
    if mode not in {PLAY_ONCE, PLAY_REPEAT, PLAY_SHUFFLE}:
        print("Invalid selection.", file=sys.stderr)
        return None
    return mode


def create_playlist_from_selection(
    media_dir: Path, playlist_file: Path, prompt: str, extensions: set[str]
) -> bool:
    media_files = discover_media_files(media_dir, extensions)
    if not media_files:
        print(f"No media files found: {media_dir}", file=sys.stderr)
        return False
    selected = select_media_with_fzf(media_files, media_dir, prompt)
    if not selected:
        print("No files selected.", file=sys.stderr)
        return False
    write_playlist(selected, playlist_file)
    return True


def create_playlist_from_search(
    media_dir: Path, playlist_file: Path, prompt: str, extensions: set[str]
) -> bool:
    media_files = discover_media_files(media_dir, extensions)
    if not media_files:
        print(f"No media files found: {media_dir}", file=sys.stderr)
        return False
    matched = select_filtered_media_with_fzf(media_files, media_dir, prompt)
    if not matched:
        print("No search results.", file=sys.stderr)
        return False
    write_playlist(matched, playlist_file)
    print(f"Added {len(matched)} file(s) to the playlist.")
    return True


def replay_existing_playlist(playlist_file: Path) -> bool:
    if not playlist_has_entries(playlist_file):
        print(f"No existing playlist found: {playlist_file}", file=sys.stderr)
        return False
    return True


DELETE_FLAGS = ("-d", "--delete")
CONFIRM_YES_ANSWERS = {"y", "yes"}


def parse_args(argv: list[str]) -> tuple[str, bool]:
    prog_name = Path(sys.argv[0]).name
    delete = any(arg in DELETE_FLAGS for arg in argv)
    positional = [arg for arg in argv if arg not in DELETE_FLAGS]
    if len(positional) != 1 or positional[0] not in PLAYER_MODES:
        print(
            f"Usage: {prog_name} <{MODE_MUSIC}|{MODE_VIDEO}> [-d|--delete]",
            file=sys.stderr,
        )
        raise SystemExit(1)
    return positional[0], delete


def confirm_deletion(count: int) -> bool:
    answer = input(f"Delete {count} file(s)? [y/N] ").strip().lower()
    return answer in CONFIRM_YES_ANSWERS


def delete_selected_files(paths: list[Path]) -> int:
    for path in paths:
        path.unlink()
    return len(paths)


def run_delete(media_dir: Path, extensions: set[str], prompt: str) -> int:
    media_files = discover_media_files(media_dir, extensions)
    if not media_files:
        print(f"No media files found: {media_dir}", file=sys.stderr)
        return 1
    selected = select_media_with_fzf(media_files, media_dir, prompt)
    if not selected:
        print("No files selected.", file=sys.stderr)
        return 1
    if not confirm_deletion(len(selected)):
        print("Deletion cancelled.")
        return 1
    deleted_count = delete_selected_files(selected)
    print(f"Deleted {deleted_count} file(s).")
    return 0


def run(player_mode: str) -> int:
    media_dir = Path.cwd()
    playlist_file = playlist_file_for(media_dir)
    no_video = player_mode == MODE_MUSIC
    prompt = f"{player_mode}> "
    extensions = MEDIA_EXTENSIONS_BY_MODE[player_mode]

    choice = read_main_choice()
    if choice == "1":
        ready_to_play = create_playlist_from_selection(
            media_dir, playlist_file, prompt, extensions
        )
    elif choice == "2":
        ready_to_play = create_playlist_from_search(
            media_dir, playlist_file, prompt, extensions
        )
    elif choice == "3":
        ready_to_play = replay_existing_playlist(playlist_file)
    else:
        print("Invalid selection.", file=sys.stderr)
        return 1

    if not ready_to_play:
        return 1

    mode = choose_playback_mode()
    if mode is None:
        return 1
    return play_playlist(playlist_file, mode=mode, no_video=no_video)


def main() -> None:
    player_mode, delete = parse_args(sys.argv[1:])
    if delete:
        media_dir = Path.cwd()
        extensions = MEDIA_EXTENSIONS_BY_MODE[player_mode]
        prompt = f"{player_mode}> "
        raise SystemExit(run_delete(media_dir, extensions, prompt))
    raise SystemExit(run(player_mode))


if __name__ == "__main__":
    main()
