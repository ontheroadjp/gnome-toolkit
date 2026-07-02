# テスト戦略・実行方法

CI が存在しないため（`.github/` 不在を確認済み）、すべてのテストは手動実行が前提。
`package.json` 等のテストランナー定義もないため、各テストはディレクトリごとに個別のコマンドで実行する
（一括実行する root レベルのテストランナーは存在しない）。

## テストの分類

| 種別 | 対象 | フレームワーク | 件数 |
|---|---|---|---|
| リポジトリ全体の構文・構成検証 | 全 `install.sh` / `install-all.sh` | 独自 pass/fail カウンタ（bash） | `tests/test_install.sh`: 5 テストスイート |
| リポジトリ全体の構文チェック | 全 `install.sh` / `install-all.sh`（動的検出） | shellcheck（未導入時は `bash -n`） | `tests/lint_shell.sh`: 検出数に依存 |
| ユニットテスト | `scripts/battery-alert/battery_alert.py` | Python `unittest` | 20件 |
| ユニットテスト | `applications/mpv-player/mpv-player.py` | Python `unittest` | 31件 |
| 統合テスト（モック） | `scripts/voice-input/voice-input.sh` | bash（`arecord`/`curl`/`notify-send`/`wl-copy` を関数で差し替え） | シェルスクリプト1本（アサーション列） |
| 統合テスト（モック） | `scripts/vim-switch-us-input/plugin/vim-switch-us-input.vim` | sh + 実 vim（`-es` バッチモード、`dbus-send` をモック） | シェルスクリプト1本 |

## 1. `tests/test_install.sh` — install.sh 群の整合性検証

```bash
bash tests/test_install.sh
```

固定の `INSTALL_SCRIPTS` 配列（`tests/test_install.sh:13-22`）を対象に、以下5点を検証する:

1. **構文チェック**（`test_install.sh:25-52`）: shellcheck があれば使用、なければ `bash -n`
2. **参照ファイルの実在確認**（`test_install.sh:56-72`）: `mpv-player.py`, `espanso-toggle`,
   `google-chrome-cdp`, `keyd/default.conf`, `alacritty.toml`, `yt-dlp/config`,
   `fep-switcher/extension.js`, `app-switch-us-input/extension.js`, `switch-input-to-us` の実在を確認
3. **`install-all.sh` の呼び出し網羅性**（`test_install.sh:76-95`）: `EXPECTED_CALLS`
   （`test_install.sh:78-86`）が `install-all.sh` 内に `grep -qF` で存在するかを確認。
   `applications/youtube/install.sh` と `gnome-extensions/search-light/install.sh` は
   `install-all.sh` から呼ばれない設計のため `EXPECTED_CALLS` に含まれていない
   （実装が呼んでいないことをテストが積極的に確認しているわけではない点に注意）
4. **ツールカバレッジ確認**（`test_install.sh:99-124`）: 新スクリプト群の内容を結合し、
   `TOOLS` 配列（`test_install.sh:109-116`）の各ツール名が含まれるかを `grep` で確認。
   これは「削除済みの `t480s-apps-install.sh` が担っていたインストール対象が
   新スクリプト群でカバーされているか」を検証する後方互換テスト
5. **`t480s-apps-install.sh` 削除確認**（`test_install.sh:128-135`）: `t480s/t480s-apps-install.sh`
   が存在しないことを確認する（リファクタリング完了の回帰防止）

終了コードは `[ "$FAIL" -eq 0 ]`（`test_install.sh:142`）。

## 2. `tests/lint_shell.sh` — 全 install スクリプトの構文チェック

```bash
bash tests/lint_shell.sh
```

`find "${REPO_DIR}" \( -name "install.sh" -o -name "install-all.sh" \)`（`lint_shell.sh:34`）で
リポジトリ内の対象ファイルを動的に検出するため、`tests/test_install.sh` と異なり
固定配列を持たない。新しい `install.sh` を追加すれば自動的に対象へ含まれる
（`applications/youtube/install.sh`・`gnome-extensions/search-light/install.sh` も対象）。
shellcheck があれば使用、なければ `bash -n`。

## 3. `scripts/battery-alert/tests/test_battery_alert.py`

```bash
cd scripts/battery-alert && python3 -m unittest discover -s tests
```

`unittest` ベース、20件（`grep -c "def test_" tests/test_battery_alert.py` で確認済み）。
しきい値パース・状態ファイルの読み書き・通知要否判定（`thresholds_to_notify`）・
バッテリーパス検出の各関数を個別に検証する。標準ライブラリのみに依存し外部モックライブラリは使わない。

## 4. `applications/mpv-player/tests/test_mpv_player.py`

```bash
cd applications/mpv-player && python3 -m unittest discover -s tests
```

`unittest` ベース、31件（`grep -c "def test_" tests/test_mpv_player.py` で確認済み）。
`parse_args`（`-d`/`--delete` 判定含む）、メディア検出、playlist 書き込み、
`mpv` コマンド組み立て、削除フロー（`confirm_deletion`/`delete_selected_files`）を検証する。

## 5. `scripts/voice-input/tests/test_voice_input.sh`

```bash
cd scripts/voice-input && bash tests/test_voice_input.sh
```

フレームワークを使わない素の bash スクリプト。`arecord`/`curl`/`notify-send`/`wl-copy` を
シェル関数として再定義し `export -f` することで `voice-input.sh` から呼ばれる外部コマンドを
差し替える（`test_voice_input.sh:25-51`）。`$HOME` もテスト用ディレクトリへ差し替える
（`test_voice_input.sh:7`）。録音開始→停止→クリップボードへの反映を検証した後、
`TEST_CURL_SHOULD_FAIL=1` でサーバー停止時のエラー通知を検証する
（`test_voice_input.sh:70-76`）。アサーションは `test`/`grep` の失敗時に
`set -euo pipefail`（`test_voice_input.sh:3`）でスクリプト自体が非ゼロ終了する方式。

## 6. `scripts/vim-switch-us-input/tests/test-vim-switch-us-input.sh`

```bash
cd scripts/vim-switch-us-input && bash tests/test-vim-switch-us-input.sh
```

`sh` スクリプトで、偽の `dbus-send`（引数をログファイルへ書き出すだけ）を
`PATH` の先頭に配置したテスト用 `bin/` に置き、実際の `vim` を `-Nu NONE -es`
（バッチモード）で起動して `InsertLeave` イベントを発火させ、ログファイルの内容を検証する
（`test-vim-switch-us-input.sh:1-30` 以降）。プラグイン本体（`vim-switch-us-input.vim`）を
モックせず実行することで統合的に検証する。

## カバレッジ方針

- **手動実行前提の対象を優先**: GNOME 実機の挙動に依存する `scripts/core-gnome-settings/apply-settings.sh`
  や `scripts/core-t480s-settings/apply-settings.sh` にはテストスイートがなく、目視確認が運用（未確認:
  具体的なチェックリストはリポジトリ内に存在しない）。
- **外部インストーラを伴うスクリプトはモック優先**: `voice-input.sh`・`vim-switch-us-input.vim` は
  実機依存のコマンド（`arecord`, `dbus-send` 等）をモックして決定的に検証する。
- **`applications/youtube/install.sh`・`gnome-extensions/search-light/install.sh` は
  `tests/lint_shell.sh` の構文チェックのみが対象**で、`tests/test_install.sh` の参照ファイル確認・
  ツールカバレッジ確認の対象には含まれていない（未確認: 意図的な除外か、単に更新漏れかは
  リポジトリ内の記述からは判別できない。次に見るべきファイル: `tests/test_install.sh` の
  今後のコミット履歴、または作者への確認）。

## 未確認事項

1. **`shellcheck` 自体の導入有無**
   - 何が未確認か: 実行環境に `shellcheck` がインストールされているか。
   - なぜ確定できないか: `scripts/core-tools/install.sh` のインストール対象リストに
     `shellcheck` が含まれていないことは確認済みだが、ユーザーが別途導入している可能性は
     リポジトリ内の情報だけでは判別できない。
   - 何を見れば確定できるか: 実行環境で `command -v shellcheck` を実行する。
