# 実装仕様サマリ

DB・APIは存在しないため `database.md` / `api.md` は生成していない
（生成条件: DB/APIの実装が存在する場合のみ。本リポジトリには該当実装なし）。

## 1. `scripts/core-gnome-settings/apply-settings.sh` — GNOME 設定スクリプト

全行 `gsettings set/reset <schema> <key> <value>` の形式。機種不問・`sudo` 不要。設定一覧:

| schema.key | 値 | 行 |
|---|---|---|
| `org.gnome.desktop.interface enable-animations` | `true` | `apply-settings.sh:6` |
| `org.gnome.desktop.peripherals.keyboard repeat` | `true` | `apply-settings.sh:14` |
| `org.gnome.desktop.peripherals.keyboard delay` | `180` | `apply-settings.sh:15` |
| `org.gnome.desktop.peripherals.keyboard repeat-interval` | `10` | `apply-settings.sh:16` |
| `org.gnome.desktop.wm.keybindings switch-input-source` | `['<Control>space']` | `apply-settings.sh:21` |
| `org.gnome.desktop.wm.keybindings switch-windows` | `['<Alt>Tab', '<Control>Tab']` | `apply-settings.sh:27` |
| `org.gnome.desktop.wm.keybindings switch-windows-backward` | `['<Shift><Alt>Tab', '<Shift><Control>Tab']` | `apply-settings.sh:28` |
| `org.gnome.desktop.wm.keybindings switch-panels` | reset (default) | `apply-settings.sh:29` |
| `org.gnome.desktop.wm.keybindings switch-panels-backward` | reset (default) | `apply-settings.sh:30` |
| `org.gnome.desktop.wm.keybindings switch-to-workspace-1` | `['<Control>1']` | `apply-settings.sh:35` |
| `org.gnome.desktop.wm.keybindings switch-to-workspace-2` | `['<Control>2']` | `apply-settings.sh:36` |
| `org.gnome.desktop.wm.keybindings switch-to-workspace-3` | `['<Control>3']` | `apply-settings.sh:37` |
| `org.gnome.desktop.wm.keybindings switch-to-workspace-4` | `['<Control>4']` | `apply-settings.sh:38` |
| `org.gnome.desktop.wm.preferences mouse-button-modifier` | `'<Ctrl>'` | `apply-settings.sh:43` |
| `org.gnome.desktop.interface font-hinting` | `'full'` | `apply-settings.sh:50` |
| `org.gnome.desktop.interface font-antialiasing` | `'grayscale'` | `apply-settings.sh:51` |

コメントアウトされた未採用候補（`apply-settings.sh:47-48`）も
ファイル内に残されている（フォント設定の別値）。

## 1a. `scripts/core-t480s-settings/apply-settings.sh` — ThinkPad 固有設定スクリプト

`thinkpad_acpi` カーネルモジュールが提供する sysfs 属性への書き込みのみ。`sudo` 必須。

| 対象パス | 値 | 行 |
|---|---|---|
| `/sys/class/power_supply/BAT0/charge_start_threshold` | `30` | `apply-settings.sh:8` |
| `/sys/class/power_supply/BAT0/charge_stop_threshold` | `85` | `apply-settings.sh:9` |

設定は再起動後にリセットされる。永続化手順（`tlp` 利用）はコメントアウト（`apply-settings.sh:12-19`）。

## 2. `scripts/core-tools/install.sh` — 汎用ツール導入スクリプト

このリポジトリに設定ファイルが存在しないツールのインストールを担う（10 ステップ）。
各アプリのパッケージインストール（`keyd`, `mpv`, `ffmpeg`, `yt-dlp`, `espanso`, `google-chrome`）は
各 `applications/*/install.sh` が担う。

### apt 経由（存在チェックなし、無条件実行）

- 開発基盤: `build-essential curl unzip tree git tmux fzf bat vim-gtk3 jq yq`
  (`core-tools/install.sh:9-20`)
- システムユーティリティ: `hyperfine rclone gocryptfs`
  (`core-tools/install.sh:26-29`)
  - `gpaste-2 gir1.2-gpaste-2` は `|| echo` で失敗を無視（`core-tools/install.sh:31`）
- システム監視: `htop nethogs iftop whois arp-scan` (`core-tools/install.sh:36-42`)
- GNOME 拡張管理: `gnome-shell-extension-manager` (`core-tools/install.sh:47-48`)
- Docker Engine: Docker 公式 apt repository を登録し、
  `docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin` を導入
  (`core-tools/install.sh:53-70`)
  - `docker` group がなければ作成し、`$USER` を追加する
    (`core-tools/install.sh:71-77`)。反映にはログアウト/ログインまたは `newgrp docker` が必要。

### 条件付きインストール（`command -v` で存在確認）

| ツール | 確認方法 | インストール手段 |
|---|---|---|
| `mise` + Node.js 24 | `command -v mise` | `curl https://mise.run \| sh`、その後 `mise use -g node@24` |
| `gh` | `command -v gh` | apt キーリング登録 + apt install |
| `ghq` | `command -v ghq` | GitHub Releases から zip 取得 → `/usr/local/bin` へ配置 |
| `claude` | `command -v claude` | `curl -fsSL https://claude.ai/install.sh \| bash` |
| `codex` | `command -v codex` | `mise exec node@24 -- npm install -g @openai/codex` |

## 3. `applications/alacritty/alacritty.toml` — Alacritty 設定

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

## 4. `gnome-extensions/gnome-overview-toggle/gnome-overview-toggle` — Overview トグル

```
gdbus call --session --dest org.gnome.Shell \
  --object-path /org/gnome/Shell \
  --method org.freedesktop.DBus.Properties.Get \
  org.gnome.Shell OverviewActive
```
で現在値を取得し、`true`/`false` を反転させて
`org.freedesktop.DBus.Properties.Set` で書き戻す。
外部コマンド依存は `gdbus` のみ。

`gnome-extensions/gnome-overview-toggle/install.sh` が
`~/.local/bin/gnome-overview-toggle` へシンボリックリンクを作成し、
GNOME カスタムキーバインドを登録する。

## 5. `scripts/battery-alert/` — バッテリー低下通知

oneshot の Python スクリプト（`battery_alert.py`、標準ライブラリのみ）を
systemd timer が定期実行する構成（常駐プロセスなし）。

| 項目 | 内容 | 根拠 |
|---|---|---|
| バッテリー検出 | `/sys/class/power_supply/BAT*` をソートして先頭を採用 | `battery_alert.py` `find_battery_path` |
| 通知しきい値 | `.env` の `NOTIFY_THRESHOLDS`（カンマ区切り、デフォルト `50`） | `battery_alert.py` `parse_thresholds`、`.env.example` |
| 通知タイミング | 放電中（`status == "Discharging"`）に各しきい値を初めて下回った時点で、**最も低い**（現在容量に最も近い）しきい値のみ1回通知。同時に複数しきい値を越えた場合も通知は1件のみ（サスペンド復帰時の連続ダイアログを防止）。越えた全しきい値は状態ファイルに記録し再通知しない。充電に戻ると状態ファイルをクリアし、次の放電サイクルで再通知 | `battery_alert.py` `run` / `thresholds_to_notify` / `clear_state` |
| 状態管理 | `/tmp` 配下の状態ファイル（`battery-alert.state`）に通知済みしきい値を保存 | `battery_alert.py` `STATE_FILE` / `save_notified_thresholds` |
| ポーリング間隔 | `.env` の `POLL_INTERVAL`（デフォルト `120` 秒）。`battery_alert.py` 自身は読まない。`install.sh` が `battery-alert.timer` テンプレートの `__POLL_INTERVAL__` を置換して `~/.config/systemd/user/` に書き出す | `install.sh`、`.config/systemd/user/battery-alert.timer` |
| 通知方法 | `notify-send -u critical` | `battery_alert.py` `send_notification` |
| テスト | `tests/test_battery_alert.py`（`unittest`、20件） | ファイル内容確認済み |

## 6. `applications/mpv-player/` — mpv music/video launcher

`mpv-player.py` は標準ライブラリのみの Python スクリプトで、`music`/`video`
いずれかを引数に取る。対象ディレクトリは実行時のカレントディレクトリ（cwd、
再帰検索）で、playlist の保存先は `<cwd>/playlist/mpv-player.m3u`。インストール後は
`mpv-player music` / `mpv-player video` で実行する
（`applications/mpv-player/install.sh` が `~/.local/bin/mpv-player` へシンボリックリンクを作成）。

| 項目 | 内容 | 根拠 |
|---|---|---|
| メディア検出 | 実行時のカレントディレクトリ配下を再帰検索し、モードごとの拡張子（`music`: `MUSIC_EXTENSIONS`、`video`: `VIDEO_EXTENSIONS`）のみを対象にする | `mpv-player.py` `MEDIA_EXTENSIONS_BY_MODE` / `discover_media_files` |
| 個別選択 | 検出したメディアを `fzf --multi` に渡し、選択されたファイルで playlist を作成 | `mpv-player.py` `select_media_with_fzf` / `create_playlist_from_selection` |
| 検索結果再生 | `fzf` を開き、Enter 時点で絞り込まれている候補を `select-all+accept` で全件受け取って playlist を作成。検索語なしの場合は全候補が対象 | `mpv-player.py` `select_filtered_media_with_fzf` / `create_playlist_from_search` |
| 前回 playlist | 既存の `mpv-player.m3u` に実エントリがある場合のみ再生へ進む | `mpv-player.py` `playlist_has_entries` / `replay_existing_playlist` |
| 再生方法 | `mpv --playlist=<playlist>` を実行。`music` モードのみ `--no-video` を付与（`video` は映像を表示）。リピートは `--loop-playlist=inf`、ランダムは `--shuffle` を追加 | `mpv-player.py` `build_mpv_command` / `play_playlist` |
| 削除（`-d`/`--delete`） | 通常の再生フローの代わりに fzf で複数選択させ、`Delete N file(s)? [y/N]` 確認後（`y`/`yes` 以外はキャンセル）にのみ `Path.unlink()` で即時削除（ゴミ箱は経由しない） | `mpv-player.py` `parse_args` / `confirm_deletion` / `delete_selected_files` / `run_delete` |
| インストール | `~/.local/bin/mpv-player` を `mpv-player.py` へのシンボリックリンクとして作成 | `applications/mpv-player/install.sh` |
| テスト | `tests/test_mpv_player.py`（`unittest`、31件） | ファイル内容確認済み |

## 7. FEP 入力ソース切替（4コンポーネント構成）

GNOME 入力ソースの切替を「コア D-Bus サービス」と「イベントクライアント」に分離した構成。

### `scripts/fep-switcher/` — コア（D-Bus サービス）

| 項目 | 内容 | 根拠 |
|---|---|---|
| 役割 | D-Bus サービス `org.gnome.Shell.Extensions.FepSwitcher` を公開するのみ | `fep-switcher/extension.js` |
| メソッド | `SwitchToUs()`: xkb:us を activate / `SwitchToJa()`: ibus:mozc-jp を activate | `fep-switcher/extension.js:41-50` |
| インストール | ルート `install-all.sh` が `~/.local/share/gnome-shell/extensions/fep-switcher@local` へ symlink 作成 | `install-all.sh:49-51` |

### `scripts/app-switch-us-input/` — ウィンドウフォーカスクライアント

| 項目 | 内容 | 根拠 |
|---|---|---|
| 役割 | `notify::focus-window` を監視し端末アプリへのフォーカス時に `SwitchToUs()` を呼ぶ | `app-switch-us-input/extension.js` |
| 呼び出し方法 | `Gio.DBus.session.call()` で `fep-switcher@local` の `SwitchToUs()` を呼び出す | `app-switch-us-input/extension.js:72-79` |
| インストール | ルート `install-all.sh` が `~/.local/share/gnome-shell/extensions/app-switch-us-input@local` へ symlink 作成 | `install-all.sh:55-58` |

### `scripts/tmux-switch-us-input/` — tmux pane クライアント

| 項目 | 内容 | 根拠 |
|---|---|---|
| 役割 | tmux `after-select-pane` フックから `SwitchToUs()` を呼ぶ bash スクリプト | `switch-input-to-us` |
| 呼び出し方法 | `gdbus call` で `fep-switcher@local` の `SwitchToUs()` を呼び出す | `switch-input-to-us:3-7` |
| エラー処理 | `>/dev/null 2>&1` で stdout/stderr を抑制（拡張無効時も静かに失敗） | `switch-input-to-us:7` |
| インストール | ルート `install-all.sh` が `~/.local/bin/switch-input-to-us` へ symlink 作成 | `install-all.sh:62-63` |
| tmux 連携 | `~/.tmux.conf` に `set-hook -g after-select-pane 'run-shell "switch-input-to-us"'` をユーザーが手動追記 | `install-all.sh` の Manual steps 表示 |

### `scripts/vim-switch-us-input/` — Vim Insert mode クライアント

| 項目 | 内容 | 根拠 |
|---|---|---|
| 役割 | Vim が Insert mode を離れたとき `SwitchToUs()` を呼ぶ | `plugin/vim-switch-us-input.vim:30-33` |
| 呼び出し方法 | `job_start()` から reply を待たない `dbus-send` を起動し、`fep-switcher@local` を直接呼ぶ | `plugin/vim-switch-us-input.vim:6-27` |
| エラー処理 | D-Bus の stdin/stdout/stderr を切り離し、入力切替失敗が Vim 操作を妨げない best-effort 動作 | `plugin/vim-switch-us-input.vim:21-27` |
| インストール | vim-plug の `rtp` オプションで `scripts/vim-switch-us-input` を runtime path に追加 | README.md Usage |
| テスト | 偽の `dbus-send` を使い `InsertLeave` 発火時の呼び出し引数を検証 | `tests/test-vim-switch-us-input.sh` |

## 8. `scripts/voice-input/` — オフライン音声入力

GNOME カスタムショートカット（`Ctrl+Shift+=`）で録音をトグルし、
whisper.cpp で文字起こしした結果を Wayland クリップボードにコピーする。

| 項目 | 内容 | 根拠 |
|---|---|---|
| 録音 | `arecord -f S16_LE -r 16000 -c 1` で 16kHz モノラル WAV を `/tmp/voice-input-record.wav` に保存 | `voice-input.sh` `_start_recording` |
| トグル管理 | `/tmp/voice-input.pid` に録音プロセスの PID を保存。toggle 呼び出し時に PID の生死で start/stop を切り替え | `voice-input.sh` `_toggle` |
| 文字起こし | `127.0.0.1:8178` で常駐する `whisper-server` の `/inference` へWAVをmultipart送信。既定言語は日本語、レスポンスはtext | `voice-input.sh` `_stop_and_transcribe` |
| 常駐サービス | systemdユーザーサービスとしてbaseモデルを読み込み、異常終了時は2秒後に再起動 | `voice-input-whisper.service` |
| 出力フィルタ | `grep -v '^\['` で特殊トークン行を除去、複数行を空白で結合 | `voice-input.sh:72` |
| クリップボード | `wl-copy` に渡す（Wayland 環境）。自動ペーストは行わない | `voice-input.sh` `_stop_and_transcribe` |
| 通知 | 通知IDを保存し、`notify-send -r` で録音中・文字起こし中・完了を同一通知上で更新 | `voice-input.sh` `_notify` |
| ビルド先 | `~/.local/lib/whisper.cpp/build/bin/` | `install.sh` `_build_whisper` |
| モデル | `~/.local/share/whisper-models/ggml-base.bin`（~142MB）を HuggingFace から取得 | `install.sh` `_download_model` |
| サービス登録 | unitを `~/.config/systemd/user/` へリンクし、daemon-reload後にenable/start | `install.sh` `_install_whisper_service` |
| ショートカット登録 | `gsettings` で次の空き custom スロットに登録。`voice-input.sh` が既登録ならスキップ（冪等） | `install.sh` `_register_gnome_shortcut` |
| テスト | 外部コマンドをBash関数でモックし、成功時のHTTP・クリップボード処理とサーバー停止時のエラーを検証 | `tests/test_voice_input.sh` |

## 9. `applications/espanso/` — テキスト展開設定

Ubuntu 24.04 / GNOME (Wayland) での Typinator 相当のテキスト展開。
`applications/espanso/install.sh` が `~/.config/espanso` → `applications/espanso/` へ symlink を張り、
`espanso-toggle` を `~/.local/bin/` に配置する。
サービス起動は手動: `espanso service register && espanso service start`。

| ファイル | 役割 | 内容 |
|---|---|---|
| `config/default.yml` | espanso 本体設定 | `backend: Inject`（Wayland 環境で採用。`show_icon: false`、`show_notifications: false`） |
| `match/base.yml` | テキスト展開ルール | `@@1975` トリガー（実際のメールアドレスはローカルで書き換える。プレースホルダー `your-email@example.com` で管理） |
| `match/private.yml` | プライベートトリガー | メールアドレス等を含む。gitignore 対象（`private.yml.example` からコピーして作成） |

## 10. `applications/chrome/` — Chrome CDP 専用プロファイル起動

| 項目 | 内容 | 根拠 |
|---|---|---|
| 起動オプション | `--remote-debugging-port=9222`、`--user-data-dir=~/.config/google-chrome-cdp`、`--class=google-chrome-cdp` を付与して `google-chrome-stable` を起動 | `google-chrome-cdp:6-10` |
| デスクトップ分離 | `CHROME_DESKTOP=google-chrome-cdp.desktop` を export し、通常の Chrome デスクトップエントリと区別する | `google-chrome-cdp:5` |
| インストール | 未インストール時は `wget` で `.deb` を取得し `sudo apt install` する。`~/.local/bin/google-chrome-cdp`・`~/.local/share/applications/google-chrome-cdp.desktop` へシンボリックリンクを作成 | `install.sh:8-13,26-27` |
| 呼び出し元 | ルート `install-all.sh:38` から自動実行される | `install-all.sh:38` |
| テスト | `tests/test_install.sh:20,65-66,85,107` で install.sh の構文・参照ファイルを検証（機能テストではない） | ファイル内容確認済み |

## 11. `applications/youtube/` — YouTube CDP ランチャー

| 項目 | 内容 | 根拠 |
|---|---|---|
| 役割 | CDP（`http://localhost:9222`）経由で YouTube タブを開閉・再利用する CLI | `youtube:1-81` |
| CDP未接続時 | `google-chrome-cdp` を `disown` 付きバックグラウンドで新規起動（2箇所: CDP自体が未起動の場合と、CDPは起動済みだが対象タブが見つからない場合） | `youtube:13-17`, `youtube:78-81` |
| タブ再利用 | `curl` で `/json` を取得し `youtube.com` を含む `page` タイプのタブを検索、見つかれば WebSocket 経由で `Page.navigate` を送信して遷移 | `youtube:19-77` |
| WebSocketフレーム送受信 | 外部ライブラリを使わず、インラインの Python で HTTP Upgrade ハンドシェイクとフレーム組み立てを直接実装（マスクキーは全ゼロ固定） | `youtube:30-76` |
| 検索キーワード | 引数があれば `urllib.parse.quote` でエンコードし `youtube.com/results?search_query=` へ | `youtube:6-11` |
| インストール | `~/.local/bin/youtube`・`~/.local/share/applications/youtube.desktop` へシンボリックリンクを作成 | `install.sh` |
| 呼び出し元 | ルート `install-all.sh` からは呼び出されない（個別実行が必要） | `install-all.sh` に該当行なしを確認済み |
| 既知の制限 | `google-chrome-cdp` の呼び出しが、`$HOME` 展開ではなく特定ユーザーのホームディレクトリを含む絶対パスでハードコードされている（2箇所、詳細は該当行を参照）。このリポジトリを別ユーザーがクローンした場合、ホームディレクトリが異なると当該パスは存在せず失敗する。他のスクリプトが採用する `SCRIPT_DIR`/`$HOME` 起点の相対解決とは異なる実装 | `youtube:14`, `youtube:79` |

## 12. `gnome-extensions/search-light/` — search-light トリガー

| 項目 | 内容 | 根拠 |
|---|---|---|
| 役割 | 入力ソースを US に切り替えてから search-light 拡張のオーバーレイをトグルする | `trigger-search-light:1-15` |
| 手順 | (1) `gdbus` で `fep-switcher@local` の `SwitchToUs()` を呼ぶ (2) 50ms 待機 (3) `gdbus` で `org.gnome.Shell.Eval` を呼び `searchLight._toggle_search_light()` を実行 | `trigger-search-light:3-15` |
| 前提 | `fep-switcher@local`（本リポジトリ内、`scripts/fep-switcher/`）と、外部の search-light GNOME 拡張（本リポジトリ外で別途インストール）の両方が有効であること | `README.md`（`gnome-extensions/search-light/README.md`） |
| インストール | `~/.local/bin/trigger-search-light` へシンボリックリンクを作成するのみ。GNOME カスタムキーバインド登録はユーザーが手動で行う | `install.sh` |
| 呼び出し元 | ルート `install-all.sh` からは呼び出されない（個別実行が必要） | `install-all.sh` に該当行なしを確認済み |
