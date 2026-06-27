# `scripts/core-tools/install.sh`

## 目的・役割

このリポジトリに設定ファイルが存在しない「汎用ツール」のパッケージインストールを一括で行うスクリプト。
アプリケーション設定（symlink 配置）は各 `applications/*/install.sh` が担う。

## 動作の概要

9 ステップを順番に実行する。sudo + ネットワーク接続が必要。

| ステップ | 内容 | 手段 |
|---|---|---|
| [1] | 開発基盤ツール | apt: build-essential, curl, unzip, tree, git, tmux, fzf, bat, vim-gtk3, jq, yq |
| [2] | システムユーティリティ | apt: hyperfine, rclone, gocryptfs, gpaste-2（失敗を無視）|
| [3] | システム監視ツール | apt: htop, nethogs, iftop, whois, arp-scan |
| [4] | GNOME 拡張管理 | apt: gnome-shell-extension-manager |
| [5] | mise + Node.js 24 | `curl https://mise.run \| sh`、その後 `mise use -g node@24` |
| [6] | GitHub CLI (gh) | apt keyring 登録 + apt install（`command -v gh` で存在確認） |
| [7] | ghq | GitHub Releases から zip 取得 → `/usr/local/bin` へ配置（`command -v ghq` で確認） |
| [8] | Claude Code | `curl -fsSL https://claude.ai/install.sh \| bash`（`command -v claude` で確認） |
| [9] | Codex CLI | `mise exec node@24 -- npm install -g @openai/codex`（`command -v codex` で確認） |

## 重要な設計判断

- `set -eu`（`-C` は使わない）: apt や wget の出力はリダイレクトしないため noclobber 不要
- apt 系（[1][2][3][4]）は存在チェックなし — `apt install` の冪等性に委ねる
- curl/wget 系（[6][7][8][9]）は `command -v` で存在確認し、インストール済みはスキップ
- mise の MISE_BIN 解決: [5] でインストール直後は PATH に入らないため `${HOME}/.local/bin/mise` を明示。[9] でも同様に再解決する（`install.sh:97`）
- gpaste-2 は Ubuntu 24.04 で利用不可の環境があるため `|| echo` で失敗を無視（`install.sh:33`）

## 統合ポイント

- 呼び出し元: `install.sh`（リポジトリルート）の最初のステップとして呼ばれる
- このスクリプト自体は symlink を作成しない。設定配置は各 `applications/*/install.sh` が担う
- codex は mise 経由の Node.js に依存するため、[5] より後に実行する必要がある

## 注意事項

- `curl | sh` 形式（mise, Claude Code）を含む。URL の正当性は CLAUDE.md の方針に従い変更時に確認する
- `/tmp` に `cd` してから wget するステップ（[7][9]）があるため、スクリプト内で `cd /tmp || exit` を使用している
