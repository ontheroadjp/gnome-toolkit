# 実装仕様サマリ

DB・APIは存在しないため `database.md` / `api.md` は生成していない
（生成条件: DB/APIの実装が存在する場合のみ。本リポジトリには該当実装なし）。

## 1. `t480s.sh` — GNOME 設定スクリプト

全行 `gsettings set <schema> <key> <value>` の形式（一部 `sudo tee` で
sysfs に書き込み）。設定一覧:

| schema.key | 値 | 行 |
|---|---|---|
| `org.gnome.desktop.interface enable-animations` | `true` | `t480s.sh:7` |
| `org.gnome.desktop.peripherals.keyboard repeat` | `true` | `t480s.sh:12` |
| `org.gnome.desktop.peripherals.keyboard delay` | `140` | `t480s.sh:13` |
| `org.gnome.desktop.peripherals.keyboard repeat-interval` | `10` | `t480s.sh:14` |
| `org.gnome.desktop.wm.keybindings switch-input-source` | `['<Control>space']` | `t480s.sh:26` |
| `org.gnome.desktop.wm.preferences mouse-button-modifier` | `'<Ctrl>'` | `t480s.sh:31` |
| `org.gnome.desktop.wm.keybindings move-to-side-w` | `['<Ctrl>Left']` | `t480s.sh:38` |
| `org.gnome.desktop.wm.keybindings move-to-side-e` | `['<Ctrl>Right']` | `t480s.sh:39` |
| `org.gnome.desktop.interface font-hinting` | `'full'` | `t480s.sh:46` |
| `org.gnome.desktop.interface font-antialiasing` | `'grayscale'` | `t480s.sh:47` |
| `/sys/class/power_supply/BAT0/charge_start_threshold` | `30` | `t480s.sh:53` |
| `/sys/class/power_supply/BAT0/charge_stop_threshold` | `85` | `t480s.sh:54` |

コメントアウトされた未採用候補（`t480s.sh:19-21`, `34-36`）も
ファイル内に残されている（ウィンドウ最大化・タイル化の別キーバインド案）。

## 2. `t480s_apps.sh` — パッケージ/ツール導入スクリプト

### apt 経由（存在チェックなし、無条件実行）

- 開発基盤: `build-essential curl tree git gh tmux fzf bat vim-gtk3 jq yq`
  (`t480s_apps.sh:9-20`)
- ランチャー/暗号化/クラウド: `rofi hyperfile rclone gocryptfs`
  (`t480s_apps.sh:29-33`)
- メディア: `yt-dlp ffmpeg mpv` (`t480s_apps.sh:39-42`)

### 条件付きインストール（`command -v` で存在確認）

| ツール | 確認方法 | インストール手段 | 行 |
|---|---|---|---|
| `keyd` | `command -v keyd` | PPA (`ppa:keyd-team/ppa`) + apt、`systemctl enable --now keyd` | `t480s_apps.sh:47-54` |
| `mise` | `command -v mise` | `curl https://mise.run \| sh` | `t480s_apps.sh:58-61` |
| `gh` | `command -v gh` | apt キーリング登録 + apt install | `t480s_apps.sh:67-76` |
| `ghq` | `command -v ghq` | GitHub Releases から zip 取得 → `usr/local/bin` へ配置 | `t480s_apps.sh:80-89` |
| `claude` | `command -v claude` | `curl -fsSL https://claude.ai/install.sh \| bash` | `t480s_apps.sh:93-97` |
| `codex` | `command -v codex` | `npm install -g @openai/codex` | `t480s_apps.sh:101-105` |
| `google-chrome` | `command -v google-chrome` | `.deb` を `wget` → `apt install ./*.deb` | `t480s_apps.sh:109-117` |
| `yt-dlp` | `command -v yt-dlp` | 存在しなければ単体バイナリを `wget`、存在すれば `yt-dlp -U` で自己更新 | `t480s_apps.sh:121-128` |

`mise` 導入後、`mise use -g node@24` で Node.js 24 をグローバル設定
（`t480s_apps.sh:63`）。

## 3. `.config/alacritty/alacritty.toml` — Alacritty 設定

- `import`: アクティブテーマは `theme/tokyo-night.toml`
  （`alacritty.toml:5`、`dracula.toml` は同ファイル6行目でコメントアウト）
- `live_config_reload = true`（`alacritty.toml:9`）
- フォント: T480s向けに `monospace` size 12、`offset = {x=1, y=6}`
  （`alacritty.toml:20-29`）。MBP15向け設定は丸ごとコメントアウト
  （`alacritty.toml:38-43`）。
- ウィンドウ: 装飾なし(`decorations = "None"`)、`Windowed` 起動
  （`alacritty.toml:46-50`）。
- カラー: `colors.primary` の背景/前景を個別オーバーライドしつつ、
  一部の `normal`/`bright` 色のみ上書き（`alacritty.toml:56-80`）。
  上書きされていない色はインポート先テーマ(`tokyo-night.toml`)の値を使う
  （Alacrittyの`import`は浅いマージである前提。alacritty側の仕様であり
  本リポジトリ内では検証不能 — 未確認）。
- キーバインド: `Ctrl+Shift+F12` でシンプルフルスクリーン切替、
  `Ctrl+↑/↓` でフォントサイズ変更（`alacritty.toml:84-88`）。

### テーマファイル（`theme/*.toml`）

3ファイルとも `[colors.primary/normal/bright]` のみを定義する
パレット専用ファイル（24〜76行）。`tokyo-night.toml` と
`tokyo-night-storm.toml` は背景色のみが異なる（`0x1a1b26` vs `0x24283b`、
各ファイル2行目）。

## 4. `.local/bin/gnome-overview-toggle` — Overview トグル

```
gdbus call --session --dest org.gnome.Shell \
  --object-path /org/gnome/Shell \
  --method org.freedesktop.DBus.Properties.Get \
  org.gnome.Shell OverviewActive
```
で現在値を取得し（`gnome-overview-toggle:3-10`）、`true`/`false` を
反転させて `org.freedesktop.DBus.Properties.Set` で書き戻す
（`gnome-overview-toggle:12-22`）。外部コマンド依存は `gdbus` のみ。

このリポジトリには記録されていないが、実機の `dconf` 状態
（`dconf dump /org/gnome/settings-daemon/plugins/media-keys/
custom-keybindings/custom0/`）では以下が確認できた:

```
binding='<Shift><Control>space'
command='~/.local/bin/gnome-overview-toggle'
name='Gunome Runcher'
```

これはライブシステムの観測結果であり、リポジトリのファイル内容からは
導出できない（[repository_structure.md](../L1_project/repository_structure.md)
の未確認事項2を参照）。

## 5. `scripts/battery-alert/` — バッテリー低下通知

oneshot の Python スクリプト（`battery_alert.py`、標準ライブラリのみ）を
systemd timer が定期実行する構成（常駐プロセスなし）。

| 項目 | 内容 | 根拠 |
|---|---|---|
| バッテリー検出 | `/sys/class/power_supply/BAT*` をソートして先頭を採用 | `battery_alert.py` `find_battery_path` |
| 通知しきい値 | `.env` の `NOTIFY_THRESHOLDS`（カンマ区切り、デフォルト `50`） | `battery_alert.py` `parse_thresholds`、`.env.example` |
| 通知タイミング | 放電中（`status == "Discharging"`）に各しきい値を初めて下回った時点で1回ずつ通知。充電に戻ると状態ファイルをクリアし、次の放電サイクルで再通知 | `battery_alert.py` `run` / `thresholds_to_notify` / `clear_state` |
| 状態管理 | `/tmp` 配下の状態ファイル（`battery-alert.state`）に通知済みしきい値を保存 | `battery_alert.py` `STATE_FILE` / `save_notified_thresholds` |
| ポーリング間隔 | `.env` の `POLL_INTERVAL`（デフォルト `120` 秒）。`battery_alert.py` 自身は読まない。`install.sh` が `battery-alert.timer` テンプレートの `__POLL_INTERVAL__` を置換して `~/.config/systemd/user/` に書き出す | `install.sh`、`.config/systemd/user/battery-alert.timer` |
| 通知方法 | `notify-send -u critical` | `battery_alert.py` `send_notification` |
| テスト | `tests/test_battery_alert.py`（`unittest`、19件） | ファイル内容確認済み |

## 6. `scripts/mpv-player/` — mpv music launcher

`mpv-player.py` は標準ライブラリのみの Python スクリプトで、起動時に
main menu を表示する。対象ディレクトリは `~/Music`、playlist の保存先は
`~/Music/playlist/mpv-player.m3u`。

| 項目 | 内容 | 根拠 |
|---|---|---|
| メディア検出 | `~/Music` 配下を再帰検索し、音声/動画の拡張子を幅広く対象にする | `mpv-player.py` `MEDIA_EXTENSIONS` / `discover_media_files` |
| 個別選択 | 検出したメディアを `fzf --multi` に渡し、選択されたファイルで playlist を作成 | `mpv-player.py` `select_media_with_fzf` / `create_playlist_from_selection` |
| 検索結果再生 | `fzf` を開き、Enter 時点で絞り込まれている候補を `select-all+accept` で全件受け取って playlist を作成。検索語なしの場合は全候補が対象 | `mpv-player.py` `select_filtered_media_with_fzf` / `create_playlist_from_search` |
| 前回 playlist | 既存の `mpv-player.m3u` に実エントリがある場合のみ再生へ進む | `mpv-player.py` `playlist_has_entries` / `replay_existing_playlist` |
| 再生方法 | `mpv --no-video --playlist=<playlist>` を実行。リピートは `--loop-playlist=inf`、ランダムは `--shuffle` を追加 | `mpv-player.py` `build_mpv_command` / `play_playlist` |
| インストール | `~/.local/bin/music` を `mpv-player.py` へのシンボリックリンクとして作成 | `install.sh` |
| テスト | `tests/test_mpv_player.py`（`unittest`、9件） | ファイル内容確認済み |
