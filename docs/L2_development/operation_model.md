# 運用モデル（ローカル実行手順）

CI が存在しないため（`.github/` 不在を確認済み）、以下はすべて
リポジトリ内のスクリプトを直接読み、その内容から逆引きした手順である。

## 前提

- 対象OS: Ubuntu系（`apt` が使えること）。根拠: `scripts/core-tools/install.sh:9,26,36,47,64` が
  すべて `sudo apt install` を呼んでいる。
- 対象デスクトップ: GNOME Shell。根拠: `scripts/core-gnome-settings/apply-settings.sh` の `org.gnome.*` schema、
  `gnome-extensions/gnome-overview-toggle/gnome-overview-toggle` の `org.gnome.Shell` DBus呼び出し。
- 実行権限: 両スクリプトとも実行可能ビット付き
  （`ls -la` で `rwxrwxr-x` を確認済み）。

## 1. パッケージ・ツールのセットアップ

```bash
./scripts/core-tools/install.sh
```

- `sudo` を要求するため対話的に実行すること。
- `curl | sh` 形式のインストーラ（mise, Claude Code）と Docker/GitHub CLI/ghq の
  repository・release 取得を含むため、ネットワーク接続が必要。
- `command -v` で存在確認後にインストールするため、再実行しても重複インストールにはならない設計
  （mise, gh, ghq, claude, codex）。apt 系パッケージには存在チェックがなく `apt install` の冪等性に依存する。
- Docker は公式 apt repository を登録して `docker-ce` 等を導入し、`docker` group を作成して
  `$USER` を追加する。sudo なしで `docker` コマンドを使えるようになるのはログアウト/ログイン後、
  または `newgrp docker` 実行後である。
- アプリ固有のパッケージ（keyd, ffmpeg, mpv, yt-dlp, espanso, google-chrome）は
  各 `applications/*/install.sh` が担う（Section 3 参照）。

## 2. GNOME デスクトップ設定の適用

```bash
# 機種不問・sudo 不要
./scripts/core-gnome-settings/apply-settings.sh
```

- `gsettings set/reset` のみで構成される。`sudo` 不要。
- GNOME が動作する Ubuntu / GNOME 環境であれば機種を問わず利用できる。

ThinkPad T480s 固有のバッテリー充電閾値を設定する場合は別スクリプトを使う:

```bash
# ThinkPad 専用・sudo 必須
./scripts/core-t480s-settings/apply-settings.sh
```

- `thinkpad_acpi` が提供する `/sys/class/power_supply/BAT0/charge_*_threshold` へ書き込む。
  T480s 以外の機種では当該 sysfs 属性が存在しないため失敗する。
- 設定は再起動後にリセットされる。永続化には `tlp` が必要
  （`apply-settings.sh:12-19` のコメント参照。実行コードではない）。

## 3. dotfiles・アプリ設定のインストール

各アプリの設定ファイルを `~/.config/` 等へシンボリックリンクするには
`install-all.sh` を使う。

```bash
# 全アプリ一括インストール
./install-all.sh

# または個別インストール
./applications/alacritty/install.sh      # ~/.config/alacritty → applications/alacritty/
./applications/espanso/install.sh        # ~/.config/espanso → applications/espanso/
./applications/mpv-player/install.sh     # ~/.local/bin/music, ~/.config/mpv → applications/mpv-player/
./applications/yt-dlp/install.sh         # ~/.config/yt-dlp → applications/yt-dlp/
sudo ./applications/keyd/install.sh      # /etc/keyd → applications/keyd/ (sudo 必要)

# gnome-overview-toggle（install-all.sh 内ではコメントアウト、個別に実行）
./gnome-extensions/gnome-overview-toggle/install.sh
```

各 `install.sh` は `SCRIPT_DIR` を起点とした絶対パスで symlink を作成するため、
リポジトリのクローン先に依存しない。

## 4. Alacritty テーマの切り替え

`applications/alacritty/alacritty.toml:5-6` の `import` 行を編集し、
コメントアウトを入れ替えることで切り替える（GUIやコマンドでの
切り替え機構はない。手動でファイルを編集する運用）。

```toml
import = ["~/.config/alacritty/theme/tokyo-night.toml"]
#import = ["~/.config/alacritty/theme/dracula.toml"]
```

`live_config_reload = true`（`alacritty.toml:9`）のため、保存すると
起動中の Alacritty に即時反映される。

## 5. battery-alert のインストール

```bash
cd scripts/battery-alert
cp .env.example .env   # 必要に応じてしきい値・ポーリング間隔を編集
./install.sh
systemctl --user daemon-reload
systemctl --user enable --now battery-alert.timer
```

- `install.sh` は `battery_alert.py` と `battery-alert.service` を
  `~/.local/bin/`・`~/.config/systemd/user/` へシンボリックリンクし、
  `.env` の `POLL_INTERVAL` を `battery-alert.timer` のテンプレートに
  反映して書き出す。`sudo` は不要。
- `.env` を変更した場合は `install.sh` を再実行しないと
  `POLL_INTERVAL` が systemd timer に反映されない
  （`scripts/battery-alert/README.md` 参照）。

## 6. mpv music launcher のインストールと実行

```bash
./applications/mpv-player/install.sh
music
```

- `install.sh` は `applications/mpv-player/mpv-player.py` を
  `~/.local/bin/music` へシンボリックリンクする。`sudo` は不要。
- `music` は起動時に main menu を表示し、`~/Music` 配下の音声/動画ファイル
  から playlist を作成する。メニュー 2 では fzf で絞り込まれた候補全件を
  playlist に入れる。
- playlist は `~/Music/playlist/mpv-player.m3u` に上書き保存される。
- 再生は `mpv --no-video` で実行される。

## 7. voice input のインストールと実行

```bash
scripts/voice-input/install.sh
systemctl --user status voice-input-whisper.service
```

- インストーラーはwhisper.cppとbaseモデルを配置し、
  `voice-input-whisper.service` をenable/startしてからGNOMEショートカットを登録する。
  sudoは不要だが、初回のビルドとモデル取得にはネットワーク接続が必要。
- サービスは `127.0.0.1:8178` のみにbindし、モデルをメモリへ常駐させる。
- `Ctrl+Shift+=` で録音を開始・停止し、完了後に `Ctrl+V` で結果を貼り付ける。
- サービス停止時はCLIへフォールバックせず、文字起こし失敗の通知を表示する。

## 8. Vim Insert mode 終了時の入力ソース切替

vim-plug を使用する場合、`~/.vimrc` の `plug#begin()` と `plug#end()` の間に
以下を追加し、`:PlugInstall` を実行する。

```vim
Plug 'ontheroadjp/core-toolkit-for-gnome', { 'rtp': 'scripts/vim-switch-us-input' }
```

- Vim の `InsertLeave` 発火時に `dbus-send` をバックグラウンド実行する。
- session bus 上の `fep-switcher@local.SwitchToUs()` を直接呼び出し、
  tmux 用クライアントには依存しない。
- `+job` 対応 Vim、`dbus-send`、有効な `fep-switcher@local` が必要。

## テスト実行

```bash
# install.sh の整合性・参照ファイル・呼び出し構成を検証
bash tests/test_install.sh

# 全 install.sh を shellcheck（未インストールの場合は bash -n）で検証
bash tests/lint_shell.sh

# 各モジュールのユニット／インテグレーションテスト
cd scripts/battery-alert && python3 -m unittest discover -s tests

cd ../../applications/mpv-player && python3 -m unittest discover -s tests

cd ../../scripts/voice-input && bash tests/test_voice_input.sh

cd ../vim-switch-us-input && bash tests/test-vim-switch-us-input.sh
```

`scripts/core-gnome-settings/apply-settings.sh` 等のテストスイートは存在せず、
動作確認は実行後に GNOME の実際の挙動を目視で確認する運用である
（未確認: 目視確認の具体的なチェックリストはリポジトリ内に存在しない）。
