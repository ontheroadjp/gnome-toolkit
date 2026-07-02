# gnome-toolkit

Ubuntu 24.04 LTS / GNOME 向けのシェルスクリプト・dotfiles 集。
ハードウェア固有の設定（バッテリー充電閾値等）は `scripts/core-t480s-settings/` に分離されており、
それ以外のモジュール（アプリ設定・GNOME 拡張・スクリプト群）は
Ubuntu / GNOME が動作する環境であれば機種を問わず利用できる。詳細な設計意図は
[docs/L0_concept/concept.md](docs/L0_concept/concept.md) を参照。

## Features

- `scripts/core-gnome-settings/apply-settings.sh` — GNOME デスクトップ設定（アニメーション、
  キーリピート、入力ソース切り替え、ウィンドウ/ワークスペース切替キーバインド、
  フォントレンダリング）を `gsettings` で一括適用。機種を問わず利用可能。
- `scripts/core-t480s-settings/apply-settings.sh` — ThinkPad 固有のバッテリー充電閾値を
  `/sys/class/power_supply/BAT0/` 経由で設定（`thinkpad_acpi` カーネルモジュール必須）。
- `scripts/core-tools/install.sh` — 汎用CLIツール一式（git, gh, tmux, fzf, bat,
  gocryptfs, Docker Engine, mise+Node.js, ghq, Claude Code, Codex CLI 等）を `apt` および
  各公式インストーラ経由で導入。各アプリ固有のインストールは
  `applications/*/install.sh` が担い、`install.sh`（ルート）で一括実行できる。
- `applications/alacritty/` — Alacritty 設定 + 3種類の配色テーマ
  （tokyo-night / tokyo-night-storm / dracula）。`install.sh` で
  `~/.config/alacritty` へのシンボリックリンクを配置する。
- `gnome-extensions/gnome-overview-toggle/` — GNOME Shell の Activities Overview
  を `gdbus` でトグルするスクリプト（カスタムキーバインド用）。`install.sh` で
  `~/.local/bin/gnome-overview-toggle` へのシンボリックリンクと GNOME ショートカット登録を行う。
- `scripts/battery-alert/` — バッテリー残量低下を `notify-send` で通知する
  Python スクリプト。`.env` でしきい値（複数指定可）とポーリング間隔を
  設定可能。systemd ユーザータイマーで常駐プロセスなしに定期実行する。
- `applications/mpv-player/` — 実行時のカレントディレクトリ配下の音声/動画ファイルから
  `<cwd>/playlist/mpv-player.m3u` を作成し、mpv で再生する Python スクリプト。
  `mpv-player music`（音声のみ）/ `mpv-player video`（映像あり）の2モードに対応。
  `install.sh` で `~/.local/bin/mpv-player` として実行できる。
- `scripts/voice-input/` — whisper.cpp を使ったオフライン音声入力。`Ctrl+Shift+=`
  で録音トグル、文字起こし結果を Wayland クリップボードにコピーする。
  `install.sh` でモデルを常駐させるsystemdユーザーサービスも登録する。
- `scripts/fep-switcher/` — GNOME 入力ソース切替コア拡張（`fep-switcher@local`）。
  `SwitchToUs()` / `SwitchToJa()` を D-Bus 経由で提供する。イベント処理は持たない。
- `scripts/app-switch-us-input/` — ウィンドウフォーカス時に US へ切替するクライアント拡張。
  `fep-switcher@local` の D-Bus メソッドを呼び出す。
- `scripts/tmux-switch-us-input/` — tmux の pane 切り替え時に `fep-switcher@local` へ
  D-Bus 経由で US 切替を依頼するシェルスクリプト。
- `scripts/vim-switch-us-input/` — Vim の Insert mode 終了時に
  `fep-switcher@local` へ D-Bus 経由で US 切替を依頼する Vim plugin。
- `applications/espanso/` — espanso テキスト展開設定。`@@1975` などのトリガーを
  メールアドレス等に展開する（Wayland 対応 Inject backend）。`install.sh` で
  `~/.config/espanso` へのシンボリックリンクと `espanso-toggle` スクリプトを配置する。
- `applications/keyd/` — keyd キーリマッパー設定。`install.sh` で `/etc/keyd` へ
  シンボリックリンクを作成する（`sudo` 必要）。
- `applications/yt-dlp/` — yt-dlp ダウンロード設定。`install.sh` で
  `~/.config/yt-dlp` へのシンボリックリンクを作成する。
- `applications/chrome/` — CDP（`--remote-debugging-port=9222`）を有効化した専用プロファイルの
  Google Chrome ラッパー（`google-chrome-cdp`）。`install-all.sh` から自動実行される。
- `applications/youtube/` — CDP 経由で既存の YouTube タブを再利用して開く CLI ランチャー
  （`youtube`）。`applications/chrome/` の導入が前提。個別実行が必要（`install-all.sh` には含まれない）。
- `gnome-extensions/search-light/` — 入力ソースを US に切替後、search-light 拡張の
  オーバーレイをトリガーするスクリプト。個別実行が必要（`install-all.sh` には含まれない）。

## Installation

```bash
git clone <this-repo> ~/WORKSPACE/gnome-toolkit
cd ~/WORKSPACE/gnome-toolkit

# dotfiles・設定ファイルを一括インストール（symlink 作成）
./install-all.sh

# または各アプリを個別にインストール
./applications/alacritty/install.sh
./applications/espanso/install.sh
./applications/mpv-player/install.sh
sudo ./applications/keyd/install.sh  # sudo 必要
./applications/yt-dlp/install.sh
./applications/chrome/install.sh     # install-all.sh からも自動実行される

# install-all.sh には含まれない個別インストール
./applications/youtube/install.sh                    # 前提: applications/chrome/install.sh 実行済み
./gnome-extensions/search-light/install.sh            # 前提: fep-switcher@local 拡張が有効
./gnome-extensions/gnome-overview-toggle/install.sh   # コメントアウトを解除して実行
```

詳細は [docs/L2_development/operation_model.md](docs/L2_development/operation_model.md) を参照。

## Usage

```bash
# 汎用ツール・CLIツールのセットアップ（sudo必須、ネットワーク必須）
./scripts/core-tools/install.sh

# GNOME デスクトップ設定の適用（sudo 不要）
./scripts/core-gnome-settings/apply-settings.sh

# ThinkPad 固有: バッテリー充電閾値の設定（sudo 必須）
./scripts/core-t480s-settings/apply-settings.sh

# mpv music/video launcher のインストール（sudo不要）
applications/mpv-player/install.sh
mpv-player music   # または: mpv-player video

# voice input のインストール（sudo不要、初回のみ 5〜10 分かかる）
scripts/voice-input/install.sh
# whisper-server はインストール後に自動起動し、ユーザーログイン時も常駐
# 以後 Ctrl+Shift+= で録音開始/停止、Ctrl+V で貼り付け

# tmux-switch-us-input のインストール（シンボリックリンク作成 + ~/.tmux.conf 追記指示を表示）
./install-all.sh
# 指示に従い ~/.tmux.conf に set-hook 行を追記して `prefix + r` でリロード
```

Vim plugin は vim-plug の runtime path 指定で導入する。`~/.vimrc` の
`plug#begin()` と `plug#end()` の間に以下を追加し、`:PlugInstall` を実行する:

```vim
Plug 'ontheroadjp/core-toolkit-for-gnome', { 'rtp': 'scripts/vim-switch-us-input' }
```

Alacritty の配色テーマを切り替えるには、
`.config/alacritty/alacritty.toml` の `import` 行のコメントを入れ替える
（`live_config_reload = true` のため保存と同時に反映される）。

詳細な手順・前提条件は
[docs/L2_development/operation_model.md](docs/L2_development/operation_model.md) を参照。

## Configuration

- Alacritty の配色テーマは `.config/alacritty/theme/*.toml` に3種類用意されており、
  `alacritty.toml` の `import` 行で切り替える（GUIやコマンドでの切り替え機構はない）。
- バッテリー充電のしきい値（`scripts/core-t480s-settings/apply-settings.sh` 内、30%/85%）は
  T480s の `/sys/class/power_supply/BAT0/*` を直接書き換える。再起動後も
  永続化したい場合は `tlp` の利用が必要（`core-t480s-settings/apply-settings.sh` 末尾のコメント参照）。
- バッテリー低下通知（`scripts/battery-alert/`）のしきい値・ポーリング間隔は
  `.env` で設定する（詳細は `scripts/battery-alert/README.md` 参照）。
- mpv music/video launcher（`applications/mpv-player/`）は playlist を
  `<cwd>/playlist/mpv-player.m3u`（実行時のカレントディレクトリ基準）に毎回上書きする。

## Testing

```bash
# install.sh の構文・参照ファイル・呼び出し構成を検証
bash tests/test_install.sh

# 全 install.sh を shellcheck（未インストールの場合は bash -n）で検証
bash tests/lint_shell.sh

# 各モジュールのユニット／インテグレーションテスト
python3 -m unittest discover -s scripts/battery-alert/tests
python3 -m unittest discover -s applications/mpv-player/tests
bash scripts/voice-input/tests/test_voice_input.sh
bash scripts/vim-switch-us-input/tests/test-vim-switch-us-input.sh
```

## Design Principles

- ハードウェア固有の設定（バッテリー充電閾値等）は `scripts/core-t480s-settings/` に分離する。それ以外のモジュールは Ubuntu / GNOME 環境であれば機種を問わず利用できる。
- シェルスクリプト（bash / sh）のみで構成し、専用の言語・ビルドツール・
  パッケージマネージャは導入しない。
- パッケージ導入は OS 標準の `apt` を第一手段とし、`apt` にないものは
  各ツール公式の手順を個別に踏む。
- アプリケーションロジック（DB・API・フロントエンド）はこのリポジトリの
  スコープに含めない。

詳細は [docs/L0_concept/policy.md](docs/L0_concept/policy.md) を参照。

## Documentation

設計判断の根拠やディレクトリ責務、実装仕様の詳細は `docs/` 配下を参照。

- [docs/L0_concept/](docs/L0_concept/) — コンセプト・ポリシー
- [docs/L1_project/](docs/L1_project/) — プロジェクト概要・リポジトリ構造
- [docs/L2_development/](docs/L2_development/) — 運用手順・整合性確認
- [docs/L3_implementation/](docs/L3_implementation/) — 実装仕様サマリ
