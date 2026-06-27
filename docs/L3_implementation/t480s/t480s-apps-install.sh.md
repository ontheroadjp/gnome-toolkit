# t480s/t480s-apps-install.sh（削除済み）

> **このファイルは削除済みスクリプトの歴史的記録である。**
> `t480s-apps-install.sh` は `0cbdcf8 chore: move t480s scripts into t480s/ subdirectory`
> でディレクトリ整理後、さらに機能分割によって削除された。
> 現在は `scripts/core-tools/install.sh`（汎用ツール）と
> 各 `applications/*/install.sh`（アプリ固有）に分割・移行されており、
> ルートの `install.sh` がこれらを一括オーケストレートする。
>
> このドキュメントは参照用として残しているが、実ファイルは存在しない。
> `tests/test_install.sh:129-135` がその削除を確認するテストとして残っている。

## 旧スクリプトが担っていた機能の移行先

| 旧ステップ | 移行先 |
|---|---|
| dev 基盤（build-essential, curl, git, tmux, fzf, bat, vim-gtk3, jq, yq） | `scripts/core-tools/install.sh` [1] |
| システムユーティリティ（hyperfine, rclone, gocryptfs, gpaste-2） | `scripts/core-tools/install.sh` [2] |
| システム監視（htop, nethogs, iftop, whois, arp-scan） | `scripts/core-tools/install.sh` [3] |
| ffmpeg / mpv | `applications/mpv-player/install.sh` |
| GNOME Shell Extension Manager | `scripts/core-tools/install.sh` [4] |
| keyd | `applications/keyd/install.sh` |
| mise + Node.js 24 | `scripts/core-tools/install.sh` [5] |
| gh | `scripts/core-tools/install.sh` [6] |
| ghq | `scripts/core-tools/install.sh` [7] |
| Claude Code | `scripts/core-tools/install.sh` [8] |
| Codex CLI | `scripts/core-tools/install.sh` [9] |
| Google Chrome | `applications/chrome/install.sh` |
| yt-dlp | `applications/yt-dlp/install.sh` |
| espanso | `applications/espanso/install.sh` |
