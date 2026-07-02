# 整合性確認の観点と手順

CI が存在しないため、以下の手順は手動実行が前提となる。
`tests/` 配下に自動化テストがあるが、CI に接続されていない（`.github/` 不在）。

## 1. スクリプトの構文チェック

`tests/lint_shell.sh` を実行すると、リポジトリ内のすべての `install.sh` を
shellcheck（または bash -n）で一括チェックできる。

```bash
bash tests/lint_shell.sh
```

個別に確認したい場合:

```bash
bash -n scripts/core-gnome-settings/apply-settings.sh
bash -n scripts/core-t480s-settings/apply-settings.sh
bash -n scripts/core-tools/install.sh
sh -n gnome-extensions/gnome-overview-toggle/gnome-overview-toggle
```

`shellcheck` の設定ファイル（`.shellcheckrc`）はリポジトリ内に
存在しないため、`shellcheck` を使う場合はデフォルトルールで実行する
（未確認: `shellcheck` 自体がこのマシンに導入されているかは
`scripts/core-tools/install.sh` のインストール対象リストに含まれていないため、
別途インストールが必要）。

## 2. install.sh の整合性テスト

```bash
bash tests/test_install.sh
```

以下の5点を検証する:
- 各 `install.sh` の構文チェック（shellcheck/bash -n）
- `install-all.sh` が参照するファイル（mpv-player.py, espanso-toggle, keyd/default.conf 等）の実在確認
- ルートの `install-all.sh` が全 per-app スクリプトを呼び出していること
- ツールカバレッジ（build-essential, tmux, fzf, mise, ghq, claude 等が新スクリプト群でカバーされていること）
- `t480s/t480s-apps-install.sh` が削除済みであること（リファクタリング完了確認）

## 3. 実行可能ビットの確認

このリポジトリのスクリプトは実行可能ビットが意味を持つ
（`./scripts/core-gnome-settings/apply-settings.sh` のように直接実行する運用）。新しいスクリプトを追加・変更した際は
以下で実行権限を確認する。

```bash
ls -la scripts/core-gnome-settings/apply-settings.sh scripts/core-t480s-settings/apply-settings.sh scripts/core-tools/install.sh gnome-extensions/gnome-overview-toggle/gnome-overview-toggle
```

## 4. dotfiles シンボリックリンクの整合性確認

`~/.config/alacritty` 等が このリポジトリ内のパスを指しているかを確認する。

```bash
readlink -f ~/.config/alacritty
readlink -f ~/.config/mpv
readlink -f ~/.config/yt-dlp
readlink -f ~/.config/espanso
readlink -f ~/.local/bin/gnome-overview-toggle
readlink -f ~/.local/bin/switch-input-to-us
readlink -f ~/.local/bin/mpv-player
readlink -f ~/.local/bin/google-chrome-cdp
readlink -f ~/.local/bin/youtube
readlink -f ~/.local/bin/trigger-search-light
```

`applications/youtube/install.sh` と `gnome-extensions/search-light/install.sh` は
`tests/test_install.sh` の検証対象に含まれていない（`grep -n "youtube\|search-light" tests/test_install.sh` で
該当行なしを確認済み。`chrome/install.sh` は検証対象に含まれる: `tests/test_install.sh:20,65-66,85,107`）。
これら2スクリプトの正当性は目視確認に依存する（未確認: 自動テストでの検証手段はリポジトリ内に存在しない）。

期待される出力はそれぞれ `<このリポジトリの絶対パス>/applications/alacritty` 等。

## 5. GNOME 設定の反映確認

`scripts/core-gnome-settings/apply-settings.sh` 実行後、対応する `gsettings get` で値が反映されているかを
確認できる。例:

```bash
gsettings get org.gnome.desktop.peripherals.keyboard repeat-interval
gsettings get org.gnome.desktop.wm.keybindings switch-input-source
gsettings get org.gnome.desktop.wm.keybindings switch-windows
```

## 6. docs と repo.profile.json の相互整合性

`/init-docs` または `/docs-sync` を再実行する際は、以下を確認する。

- `docs/.ai/repo.profile.json` の `commands` に列挙されたコマンドが、
  実際にリポジトリ内のファイルとして存在するか
  （`commands.*.run` に書かれたパスを `ls` で確認）。
- 本ドキュメント群が参照しているファイルパス・行番号が、
  最新のスクリプト内容とズレていないか
  （スクリプトの行数が変わった場合は該当ドキュメントの行番号根拠を
  更新する）。
