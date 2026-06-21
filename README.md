# gnome-toolkit

Lenovo ThinkPad T480s (Ubuntu 24.04 LTS / GNOME) を再現可能にセットアップするための
個人用シェルスクリプト・dotfiles 集。詳細な設計意図は
[docs/L0_concept/concept.md](docs/L0_concept/concept.md) を参照。

## Features

- `t480s.sh` — GNOME デスクトップ設定（アニメーション、キーリピート、
  入力ソース切り替え、ウィンドウタイル化キーバインド、フォントレンダリング、
  バッテリー充電閾値）を `gsettings` で一括適用。
- `t480s_apps.sh` — 開発ツール・CLIツール一式（git, gh, tmux, fzf, bat,
  rofi, gocryptfs, yt-dlp, ffmpeg, mpv, keyd, mise+Node.js, ghq,
  Claude Code, Codex CLI, Google Chrome 等）を `apt` および各公式
  インストーラ経由で導入。
- `.config/alacritty/` — Alacritty 設定 + 3種類の配色テーマ
  （tokyo-night / tokyo-night-storm / dracula）。
- `.local/bin/gnome-overview-toggle` — GNOME Shell の Activities Overview
  を `gdbus` でトグルするスクリプト（カスタムキーバインド用）。
- `scripts/battery-alert/` — バッテリー残量低下を `notify-send` で通知する
  Python スクリプト。`.env` でしきい値（複数指定可）とポーリング間隔を
  設定可能。systemd ユーザータイマーで常駐プロセスなしに定期実行する。
- `scripts/mpv-player/` — `~/Music` 配下の音声/動画ファイルから
  `~/Music/playlist/mpv-player.m3u` を作成し、`mpv --no-video` で再生する
  Python スクリプト。`install.sh` で `~/.local/bin/music` として実行できる。
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

## Installation

```bash
git clone <this-repo> ~/WORKSPACE/gnome-toolkit
cd ~/WORKSPACE/gnome-toolkit

# dotfiles をホームディレクトリにリンク
ln -s "$(pwd)/.config/alacritty" ~/.config/alacritty
ln -s "$(pwd)/.local/bin/gnome-overview-toggle" ~/.local/bin/gnome-overview-toggle
```

このリンク作成手順はリポジトリ内のスクリプトには含まれておらず、
実機の状態から逆算した手順。詳細は
[docs/L2_development/operation_model.md](docs/L2_development/operation_model.md) を参照。

## Usage

```bash
# パッケージ・CLIツールのセットアップ（sudo必須、ネットワーク必須）
./t480s_apps.sh

# GNOME デスクトップ設定の適用(sudo必須の項目を含む)
./t480s.sh

# mpv music launcher のインストール（sudo不要）
scripts/mpv-player/install.sh
music

# voice input のインストール（sudo不要、初回のみ 5〜10 分かかる）
scripts/voice-input/install.sh
# whisper-server はインストール後に自動起動し、ユーザーログイン時も常駐
# 以後 Ctrl+Shift+= で録音開始/停止、Ctrl+V で貼り付け

# tmux-switch-us-input のインストール（シンボリックリンク作成 + ~/.tmux.conf 追記指示を表示）
./install.sh
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
- バッテリー充電のしきい値（`t480s.sh` 内、30%/85%）は T480s の
  `/sys/class/power_supply/BAT0/*` を直接書き換える。再起動後も
  永続化したい場合は `tlp` の利用が必要（`t480s.sh` 末尾のコメント参照）。
- バッテリー低下通知（`scripts/battery-alert/`）のしきい値・ポーリング間隔は
  `.env` で設定する（詳細は `scripts/battery-alert/README.md` 参照）。
- mpv music launcher（`scripts/mpv-player/`）は playlist を
  `~/Music/playlist/mpv-player.m3u` に毎回上書きする。

## Design Principles

- 単一マシン・単一ユーザーの個人用ツールであり、汎用化・抽象化は行わない。
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
