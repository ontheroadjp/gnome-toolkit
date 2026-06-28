# コンセプト

## 目的

このリポジトリは、Ubuntu 24.04 LTS / GNOME 環境の設定と core アプリケーションを
バージョン管理し、簡単に環境をゼロから構築できるようにすることが目的:

1. 機種不問の GNOME デスクトップ設定を `gsettings` で一括適用するスクリプト
   （`scripts/core-gnome-settings/apply-settings.sh`）
2. ThinkPad T480s 固有のバッテリー充電閾値設定スクリプト
   （`scripts/core-t480s-settings/apply-settings.sh`）
3. マシン初期セットアップ時に必要なパッケージ・CLI ツールを
   `apt` / `curl` / `wget` / `npm` 経由で導入するスクリプト
   （`scripts/core-tools/install.sh` および各 `applications/*/install.sh`）
4. ホームディレクトリにシンボリックリンクとして配置される設定ファイル・
   ユーティリティスクリプト（`applications/alacritty/**`、
   `gnome-extensions/gnome-overview-toggle/gnome-overview-toggle` 等）
5. GNOME 拡張・スクリプト群（入力ソース切替、音声入力、バッテリー通知等）

## 解決する問題

OS再インストールやマシン更新時に、ターミナルの見た目・キーバインド・
GNOME の挙動・必要なCLIツール群を手作業で再構築する手間を、
スクリプト実行とシンボリックリンクの再作成だけで済ませられるようにする。

根拠: `install-all.sh`（リポジトリルート）が各 `applications/*/install.sh` を
順に呼び出すことで、`~/.config/alacritty` → `applications/alacritty/`、
`~/.config/mpv` → `applications/mpv-player/`、
`~/.local/bin/switch-input-to-us` → `scripts/tmux-switch-us-input/switch-input-to-us`
等のシンボリックリンクが一括で作成される（`install-all.sh` 全体を確認済み）。

## 対象ユーザー

Ubuntu 24.04 LTS / GNOME を利用するユーザー全般。
`scripts/core-t480s-settings/` を除くすべてのモジュールは
Ubuntu / GNOME が動作する環境であれば機種を問わず利用できる
（`README.md` 冒頭の記述および各スクリプトの実装から確認済み）。

## 設計上の制約

- シェルスクリプト（bash/sh）と Python のみで構成し、外部ビルドツール・
  プロジェクトレベルのパッケージマネージャは導入しない設計方針（`policy.md` 参照）。
  抽象化・汎用化は必要最小限にとどめる。
  ハードウェア固有の設定（バッテリー充電閾値等）は `scripts/core-t480s-settings/` に
  分離されており、閾値（30%/85%）はハードコード
  （`scripts/core-t480s-settings/apply-settings.sh:8-9`）。
  それ以外のモジュールは機種を問わず利用できる設計。
- `sudo` を要するコマンドが複数のスクリプトに直接記述されており
  （`scripts/core-t480s-settings/apply-settings.sh:8-9`、`scripts/core-tools/install.sh:9,26,37,48` 等）、
  対話的に人間が実行する前提でエラーハンドリングは行われていない。
- CI は存在しない（`.github/` 不在）。`tests/` 配下にシェルスクリプトと
  Python の unittest ベースのテストが存在するが、手動実行が前提である
  （`tests/test_install.sh`、`tests/lint_shell.sh`、各 `scripts/*/tests/` 参照）。
