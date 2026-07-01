# `scripts/core-tools/install.sh`

## 目的・役割

このリポジトリに設定ファイルが存在しない「汎用ツール」のパッケージインストールを一括で行うスクリプト。
アプリケーション設定（symlink 配置）は各 `applications/*/install.sh` が担う。

## 動作の概要

10 ステップを順番に実行する。sudo + ネットワーク接続が必要。

| ステップ | 内容 | 手段 |
|---|---|---|
| [1] | 開発基盤ツール | apt: build-essential, curl, unzip, tree, git, tmux, fzf, bat, vim-gtk3, jq, yq |
| [2] | システムユーティリティ | apt: hyperfine, rclone, gocryptfs, gpaste-2（失敗を無視）|
| [3] | システム監視ツール | apt: htop, nethogs, iftop, whois, arp-scan |
| [4] | GNOME 拡張管理 | apt: gnome-shell-extension-manager |
| [5] | Docker Engine | Docker 公式 apt repository を `/etc/apt/sources.list.d/docker.sources` に登録し、docker packages を apt install。`docker` group を作成して `$USER` を追加 |
| [6] | mise + Node.js 24 | `curl https://mise.run \| sh`、その後 `mise use -g node@24` |
| [7] | GitHub CLI (gh) | apt keyring 登録 + apt install（`command -v gh` で存在確認） |
| [8] | ghq | GitHub Releases から zip 取得 → `/usr/local/bin` へ配置（`command -v ghq` で確認） |
| [9] | Claude Code | `curl -fsSL https://claude.ai/install.sh \| bash`（`command -v claude` で確認） |
| [10] | Codex CLI | `mise exec node@24 -- npm install -g @openai/codex`（`command -v codex` で確認） |

## 重要な設計判断

- `set -eu`（`-C` は使わない）: apt や wget の出力はリダイレクトしないため noclobber 不要
- apt 系（[1][2][3][4][5]）は存在チェックなし — `apt install` の冪等性に委ねる
- Docker は Ubuntu の公式 apt repository を deb822 形式で登録する。`/etc/os-release` の `UBUNTU_CODENAME` を優先し、未定義なら `VERSION_CODENAME` を使う（`install.sh:58-63`）
- Docker の sudo なし実行設定は `docker` group の存在確認後に `sudo usermod -aG docker "$USER"` を実行する（`install.sh:71-74`）。反映にはログアウト/ログインまたは `newgrp docker` が必要であることを表示する（`install.sh:75-77`）
- curl/wget 系（[7][8][9][10]）は `command -v` で存在確認し、インストール済みはスキップ
- mise の MISE_BIN 解決: [6] でインストール直後は PATH に入らないため `${HOME}/.local/bin/mise` を明示。[10] でも同様に再解決する（`install.sh:135`）
- gpaste-2 は Ubuntu 24.04 で利用不可の環境があるため `|| echo` で失敗を無視（`install.sh:33`）

## 統合ポイント

- 呼び出し元: `install-all.sh`（リポジトリルート）の最初のステップとして呼ばれる
- このスクリプト自体は symlink を作成しない。設定配置は各 `applications/*/install.sh` が担う
- codex は mise 経由の Node.js に依存するため、[6] より後に実行する必要がある

## 注意事項

- `curl | sh` 形式（mise, Claude Code）を含む。URL の正当性は CLAUDE.md の方針に従い変更時に確認する
- Docker 公式 apt repository の GPG key を `curl -fsSL https://download.docker.com/linux/ubuntu/gpg` で取得する（`install.sh:56`）
- `docker` group は root 相当の権限を持つため、スクリプトは警告を表示する（`install.sh:77`）
- `/tmp` に `cd` してから wget するステップ（[8]）があるため、スクリプト内で `cd /tmp || exit` を使用している

## 変更履歴（git log より自動生成）

- cc53830 feat(#38): add docker to core tools installer
- 6b93fec chore(#31): replace t480s-apps-install.sh with per-app install.sh and scripts/core-tools/install.sh
