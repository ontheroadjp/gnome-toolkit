# CLAUDE.md

このファイルは AI エージェント（Claude Code）がこのリポジトリで作業する際の
運用起点である。詳細な設計判断・根拠は `docs/` 配下を参照すること
（`docs/.ai/repo.profile.json` の `primary_docs` がエントリポイント）。

## このリポジトリについて

Ubuntu 24.04 LTS / GNOME 向けのシェルスクリプト・dotfiles 集。
ハードウェア固有設定（バッテリー充電閾値等）は `scripts/core-t480s-settings/` に分離されており、
それ以外のモジュールは機種を問わず利用できる。CI は存在しない。
テストは `tests/` 配下に手動実行前提で存在する。
詳細: [docs/L0_concept/concept.md](docs/L0_concept/concept.md)。

## Custom / Command の使い分け（AI向けルール）

- task.md: ドキュメント変更を伴う実装に特化。issue 自動生成〜実装〜ドラフト PR 作成まで。docs/* は変更しない。
- patch.md: ドキュメント変更を伴わない軽微な修正に特化。issue/PR 不要。branch + commit → ユーザーが main へマージ。スコープが広がった場合は /task へエスカレーション。
- docs-sync.md: git diff を事実として docs を最小更新し、ドラフト PR を公開する。HARD STOP 時は /init-docs を要求して終了する。
- init-docs.md: repo の実態把握と設計ドキュメント再構築。重い初期化。docs-sync が説明不能になった時点でここに戻る。

## このリポジトリ固有の注意点

- `scripts/core-t480s-settings/apply-settings.sh` は `sudo` を要する行を含む
  （バッテリー充電閾値: `apply-settings.sh:8-9`、`echo 30 | sudo tee /sys/class/power_supply/BAT0/charge_start_threshold` 等）。
  AI が自律的にこれらを実行することは想定しない。実行内容の説明・修正案の提示まではAIの役割、実行はユーザー判断。
- `curl | sh` / `wget | sudo tee` 形式のリモートインストーラ
  （`scripts/core-tools/install.sh:56,67-71,96`）を変更する際は、出典URLの正当性を
  必ず確認すること。
- `applications/` と `gnome-extensions/` 配下の設定ファイルは、各 `install.sh` が
  ホームディレクトリ（`~/.config/`、`~/.local/bin/` 等）へのシンボリックリンクとして
  実機で使われている。これらのパス配下のファイルを編集すると、
  即座に実機の挙動に影響する可能性がある。
- コミット時は `git add -A` / `git add .` を使わず、変更ファイルを個別に
  ステージングする。

## Local Tooling Environment

Observed by /init-docs on 2026-06-28:
- gh: 2.95.0 (installed at /usr/bin/gh)
- gh auth: logged in to github.com as ontheroadjp (keyring), SSH protocol
- node: v24.16.0 (managed by mise, at ~/.local/share/mise/installs/node/24/bin/node)
- npm: 11.13.0 (managed by mise)
- Node runtime manager hints: mise confirmed active (mise use -g node@24 in use)

Notes:
- If `gh` operations fail with API schema or compatibility errors, check `gh --version` first. Prefer upgrading `gh` when possible; if upgrading is impossible, use an equivalent `gh api` REST call or GitHub Web UI for the affected operation.
- Before npm operations, run `node --version` and `npm --version` to confirm Node.js and npm are available in the current shell. mise manages Node.js — if `node` is not found, ensure mise shims are in PATH or use `mise exec node@24 -- <command>`.
- Do not install or upgrade `gh`, Node.js, or npm automatically without explicit user confirmation.
