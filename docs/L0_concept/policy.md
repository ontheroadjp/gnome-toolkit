# ポリシー

## 技術選定ポリシー

- シェルスクリプト（bash / sh）を主体とし、一部 Python を使用する。
  専用の言語ビルドツール・プロジェクトレベルのパッケージマネージャは導入しない。
  根拠: リポジトリ直下に `package.json` / `go.mod` / `Gemfile` /
  `requirements.txt` / `Cargo.toml` のいずれも存在しないことを確認済み。
  Python は `scripts/battery-alert/battery_alert.py`、`applications/mpv-player/mpv-player.py`
  のみで使用し、標準ライブラリのみに依存する（外部 pip パッケージなし）。
- マシン設定は GNOME 標準の `gsettings` コマンドで行い、独自の設定DBや
  ラッパーツールは作らない。根拠: `t480s/t480s-settings.sh` の全 `gsettings` 行
  （`t480s-settings.sh:6,14-16,21,27-30,35-38,43,50-51`）。
- パッケージ導入は OS 標準の `apt` を第一手段とし、`apt` に存在しないものは
  各ツール公式のインストール手順（`curl | sh`, `wget` + `dpkg`,
  `npm install -g` 等）を個別に踏む。根拠: `scripts/core-tools/install.sh:9-20`（apt）、
  `scripts/core-tools/install.sh:56`（mise インストール用 curl）、
  `scripts/core-tools/install.sh:96`（Claude Code インストール用 curl）、
  `scripts/core-tools/install.sh:107`（codex は npm 経由）。
- 設定ファイル（`applications/*/`、`gnome-extensions/*/`）はホームディレクトリの
  対応パスへシンボリックリンクとして配置する運用。根拠: 各 `applications/*/install.sh`
  が `ln -sf` でシンボリックリンクを作成する実装（例: `applications/alacritty/install.sh`）。
- アプリのパッケージインストールと設定ファイルの配置を分離する。
  汎用ツールのインストールは `scripts/core-tools/install.sh`、
  アプリ固有のインストールは各 `applications/*/install.sh` が担う。
  根拠: `install.sh`（ルート）の構成から実装を確認。

## セキュリティ方針

- 公開リポジトリを想定する場合、認証情報・トークン・個人を特定できる
  情報をスクリプトや設定ファイルに直接書かないこと。
  現時点のスクリプト・設定ファイルを確認した範囲では、
  認証情報のハードコードは検出されなかった（`t480s/t480s-settings.sh`、
  `scripts/core-tools/install.sh`、`applications/alacritty/alacritty.toml`、
  `gnome-extensions/gnome-overview-toggle/gnome-overview-toggle` を確認済み）。
- `curl | sh` / `wget | sudo tee` 形式のリモートスクリプト実行
  （`scripts/core-tools/install.sh:56,67-71,96`）は、実行前にURLの出典を
  都度確認すること。これらは公式インストーラを利用しているが、リポジトリとして
  ピン留め（チェックサム検証等）は行っていない（未対応・未確認の改善余地）。
- `applications/espanso/match/private.yml` はメールアドレス等の個人情報を含むため
  `.gitignore` で除外する（`applications/espanso/match/private.yml.example` から
  コピーして作成する運用）。

## パフォーマンス要件

特になし。個人利用のセットアップスクリプトであり、実行頻度は
低い（マシン初期化時、または設定変更時のみ）。

## 禁止事項

- このリポジトリにアプリケーションロジック（DB、API、フロントエンド等）を
  混在させない。スコープはデスクトップ環境設定とセットアップ手順に限定する。
- `git add -A` / `git add .` のような無差別なステージングを行わない
  （CLAUDE.md のコミット運用ルールより）。
