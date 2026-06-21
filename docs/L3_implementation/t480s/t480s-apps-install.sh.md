# t480s/t480s-apps-install.sh

## 目的・役割

T480s セットアップ時に必要なパッケージおよびツールを一括インストールするスクリプト。
手動で一度だけ実行することを前提とし、冪等性は保証しない（apt 系は冪等、条件付きブロックは `command -v` で存在確認）。

## 動作の概要

インストールは以下の順序で進む:

1. **dev 基盤** (`build-essential`, `curl`, `unzip`, `tree`, `git`, `tmux`, `fzf`, `bat`, `vim-gtk3`, `jq`, `yq`) — 無条件 apt install（行 10–21）
2. **システムユーティリティ** (`hyperfine`, `rclone`, `gocryptfs`) — 無条件 apt install（行 30–34）
   - `gpaste-2 gir1.2-gpaste-2` — `|| echo` で失敗しても継続（行 37）
3. **システム監視** (`htop`, `nethogs`, `iftop`, `whois`, `arp-scan`) — 無条件 apt install（行 44–49）
4. **メディア** (`ffmpeg`, `mpv`) — 無条件 apt install（行 56–59）
5. **GNOME Shell Extension Manager** — 無条件 apt install（行 63）
6. **keyd** — `command -v keyd` で確認、未インストール時のみ PPA 追加 + apt install + systemctl enable（行 69–76）
7. **mise + node@24** — `command -v mise` で確認、未インストール時のみ `curl https://mise.run | sh`、その後 `mise use -g node@24`（行 80–86）
8. **gh** — `command -v gh` で確認、GitHub keyring 経由で apt install（行 89–100）
9. **ghq** — `command -v ghq` で確認、GitHub Releases から zip → `/usr/local/bin`（行 103–114）
10. **claude code** — `command -v claude` で確認、公式インストーラ経由（行 117–121）
11. **codex** — `command -v codex` で確認、`mise exec node@24 -- npm install -g @openai/codex`（行 124–128）
12. **Google Chrome** — `command -v google-chrome` で確認、deb → `apt install`（行 131–135）
13. **yt-dlp** — `command -v yt-dlp` で確認、未インストール時は `/usr/local/bin` へバイナリ wget、インストール済みは `yt-dlp -U` で自己更新（行 139–147）
14. **espanso** — `command -v espanso` で確認、GitHub Releases から Wayland 向け deb → `apt install`（行 150–158）

## 重要な設計判断

- **`gh` を apt 無条件ブロックに含めない**: Ubuntu 標準リポジトリ版は古い。`command -v` で確認してから GitHub keyring 経由でインストールすることで最新版が入る。
- **`yt-dlp` を apt 無条件ブロックに含めない**: apt 管理下のバイナリを `yt-dlp -U` で上書き更新すると apt との整合性が崩れる。`/usr/local/bin` へのバイナリ直接配置に統一することで apt と競合しない。
- **`unzip` を apt ブロックに追加**: ghq インストールブロックで `unzip` コマンドが必要なため。
- **`gpaste-2` を `|| echo` で保護**: Ubuntu 24.04 の標準リポジトリに存在しない可能性があるため、失敗しても後続処理を止めない。
- **`codex` のインストールに `mise exec node@24 -- npm` を使う**: `mise use -g node@24` 直後は mise shim が現在シェルに反映されないため、`npm` が PATH に存在しない。`mise exec` で明示的に node@24 環境を使う。
- **espanso は Wayland 向け deb を使う**: snap 版は config ディレクトリが `~/snap/espanso/current/.config/espanso/` になり symlink 管理と相性が悪い。deb 版は `~/.config/espanso/` を使う。

## 統合ポイント

- `install.sh` が symlink を張る前提で、このスクリプトはパッケージのインストールのみを担う（設定ファイルの配置は `install.sh` 経由）。
- espanso 追加後、`install.sh` で `$HOME/.config/espanso` symlink を作成し、`espanso service register && espanso service start` を手動実行する必要がある。

## 注意事項・既知の制限

- `sudo` を多数使用するため、非 root ユーザーでの実行が前提。パスワードなし `sudo` が設定されていない環境では途中で止まる。
- `cd /tmp` を使うブロック（ghq: 行 105、Chrome: 行 132、espanso: 行 151）は以降の作業ディレクトリが `/tmp` になる。相対パス操作には注意。

## 変更履歴（git log より自動生成）

- 2df7144 feat(#22): add espanso text expander and fix t480s-apps-inssstall.sh bugs
- 0cbdcf8 chore: move t480s scripts into t480s/ subdirectory
