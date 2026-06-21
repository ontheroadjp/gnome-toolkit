# t480s/t480s-apps-inssstall.sh

## 目的・役割

T480s セットアップ時に必要なパッケージおよびツールを一括インストールするスクリプト。
手動で一度だけ実行することを前提とし、冪等性は保証しない（apt 系は冪等、条件付きブロックは `command -v` で存在確認）。

## 動作の概要

インストールは以下の順序で進む:

1. **dev 基盤** (`build-essential`, `curl`, `tree`, `git`, `gh`, `tmux`, `fzf`, `bat`, `vim-gtk3`, `jq`, `yq`) — 無条件 apt install（行 9–20）
2. **システムユーティリティ** (`hyperfine`, `rclone`, `gocryptfs`, `gpaste-2`) — 無条件 apt install（行 33–37）
3. **システム監視** (`htop`, `nethogs`, `iftop`, `whois`, `arp-scan`) — 無条件 apt install（行 48–53）
4. **メディア** (`yt-dlp`, `ffmpeg`, `mpv`) — 無条件 apt install（行 63–66）
5. **GNOME Shell Extension Manager** — 無条件 apt install（行 71）
6. **keyd** — `command -v keyd` で確認、未インストール時のみ PPA 追加 + apt install + systemctl enable（行 77–84）
7. **mise + node@24** — `command -v mise` で確認、未インストール時のみ `curl https://mise.run | sh`、その後 `mise use -g node@24`（行 89–94）
8. **gh** (keyring 版) — `command -v gh` で確認、手順 1 で apt install 済みのため通常はスキップ（行 99–108）
9. **ghq** — `command -v ghq` で確認、GitHub Releases から zip → `/usr/local/bin`（行 113–122）
10. **claude code** — `command -v claude` で確認、公式インストーラ経由（行 127–131）
11. **codex** — `command -v codex` で確認、`mise exec node@24 -- npm install -g @openai/codex`（行 136–140）
12. **Google Chrome** — `command -v google-chrome` で確認、deb → `apt install`（行 145–153）
13. **yt-dlp** (バイナリ版) — `command -v yt-dlp` で確認、手順 4 で apt install 済みのため `yt-dlp -U` 自己更新パスへ（行 158–165）
14. **espanso** — `command -v espanso` で確認、GitHub Releases から Wayland 向け deb → `apt install`（行 168–178）

## 重要な設計判断

- **codex のインストールに `mise exec node@24 -- npm` を使う**: `mise use -g node@24` 直後は mise shim が現在シェルに反映されないため、`npm` が PATH に存在しない。`mise exec` で明示的に node@24 環境を使う（行 138）。
- **espanso は Wayland 向け deb を使う**: snap 版は config ディレクトリが `~/snap/espanso/current/.config/espanso/` になり symlink 管理と相性が悪い。deb 版は `~/.config/espanso/` を使う。

## 統合ポイント

- `install.sh` が symlink を張る前提で、`t480s-apps-inssstall.sh` はパッケージのインストールのみを担う（設定ファイルの配置は `install.sh` 経由）。
- espanso を追加した場合、`install.sh` で `$HOME/.config/espanso` symlink を作成し、`espanso service register && espanso service start` を手動実行する必要がある。

## 注意事項・既知の制限

- `sudo` を多数使用するため、非 root ユーザーでの実行が前提。パスワードなし `sudo` が設定されていない環境では途中で止まる。
- `cd /tmp` を使うブロック（ghq: 行 115、Chrome: 行 148、espanso: 行 170）は以降の作業ディレクトリが `/tmp` になる。相対パス操作には注意。
- `gh` は手順 1 の apt install と手順 8 の keyring 版条件付きインストールが重複している。手順 1 の apt 版で満足しているため、手順 8 は実質スキップされる。
- `yt-dlp` も apt 版（手順 4）と wget バイナリ版（手順 13）が重複。apt 版インストール済みのため手順 13 は `yt-dlp -U` 自己更新のみ実行される。
- ファイル名に typo あり（`inssstall`）。リネームすると既存環境のエイリアス等が壊れる可能性があるため、現状維持。

## 変更履歴（git log より自動生成）

- 2df7144 feat(#22): add espanso text expander and fix t480s-apps-inssstall.sh bugs
- 0cbdcf8 chore: move t480s scripts into t480s/ subdirectory
