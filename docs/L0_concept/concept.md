# コンセプト

## 目的

このリポジトリは、特定の1台のマシン（ホスト名 `t480s`、Lenovo ThinkPad T480s 上の
GNOME + Ubuntu 24.04 環境。根拠: リポジトリ内のディレクトリ名 `t480s/` と
スクリプト名 `t480s/t480s-settings.sh`、README に明記された機種名）を、
再現可能な手順でセットアップ・運用するための個人用ツールキットである。

汎用フレームワークやアプリケーションではなく、以下4種類のファイル群を
バージョン管理することが目的:

1. GNOME デスクトップの挙動を `gsettings` で設定するスクリプト
   （`t480s/t480s-settings.sh`）
2. マシン初期セットアップ時に必要なパッケージ・CLI ツールを
   `apt` / `curl` / `wget` / `npm` 経由で導入するスクリプト
   （`scripts/core-tools/install.sh` および各 `applications/*/install.sh`）
3. ホームディレクトリにシンボリックリンクとして配置される設定ファイル・
   ユーティリティスクリプト（`applications/alacritty/**`、
   `gnome-extensions/gnome-overview-toggle/gnome-overview-toggle` 等）
4. GNOME 拡張・スクリプト群（入力ソース切替、音声入力、バッテリー通知等）

## 解決する問題

OS再インストールやマシン更新時に、ターミナルの見た目・キーバインド・
GNOME の挙動・必要なCLIツール群を手作業で再構築する手間を、
スクリプト実行とシンボリックリンクの再作成だけで済ませられるようにする。

根拠: `install.sh`（リポジトリルート）が各 `applications/*/install.sh` を
順に呼び出すことで、`~/.config/alacritty` → `applications/alacritty/`、
`~/.config/mpv` → `applications/mpv-player/`、
`~/.local/bin/switch-input-to-us` → `scripts/tmux-switch-us-input/switch-input-to-us`
等のシンボリックリンクが一括で作成される（`install.sh` 全体を確認済み）。

## 対象ユーザー

リポジトリ所有者本人（シングルユーザー、シングルマシン想定）。
`applications/alacritty/alacritty.toml` 内のコメント（`alacritty.toml:38-43`）から、
過去に MBP15 用の設定が運用されていた可能性があるが、対応するセットアップスクリプトは
現リポジトリに存在しない。

## 設計上の制約

- 単一マシン・単一ユーザーの個人ツールという前提で、抽象化や設定の
  汎用化は行われていない（例: `t480s/t480s-settings.sh` のバッテリー充電閾値
  `t480s-settings.sh:57-58` は T480s 固有のしきい値をハードコードしている）。
- `sudo` を要するコマンドが複数のスクリプトに直接記述されており
  （`t480s/t480s-settings.sh:57-58`、`scripts/core-tools/install.sh:9,26,36,47` 等）、
  対話的に人間が実行する前提でエラーハンドリングは行われていない。
- CI は存在しない（`.github/` 不在）。`tests/` 配下にシェルスクリプトと
  Python の unittest ベースのテストが存在するが、手動実行が前提である
  （`tests/test_install.sh`、`tests/lint_shell.sh`、各 `scripts/*/tests/` 参照）。
