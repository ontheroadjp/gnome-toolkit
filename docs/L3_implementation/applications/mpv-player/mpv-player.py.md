# `applications/mpv-player/mpv-player.py`

## 目的・役割

`music` / `video` の2モードに対応した、fzf 選択 + mpv 再生を行う対話的な CLI。
起動時のカレントディレクトリ配下を再帰的にスキャンし、モードに応じた拡張子の
メディアファイルのみを選択候補とする。`-d`/`--delete` オプションで、選択した
ファイルを確認の上そのまま削除する専用フローも提供する。

## 動作の概要と主要ロジック

1. `parse_args(sys.argv[1:])`（`mpv-player.py:243-253`）が引数を検証し
   `(player_mode, delete)` を返す。`-d`/`--delete` は位置引数の前後どちらでも
   受け付ける。`music`/`video` 以外の位置引数、または引数なし/複数は usage を
   表示して `SystemExit(1)`
2. `main()`（`mpv-player.py:315-322`）: `delete` が真の場合は `run_delete` へ、
   偽の場合は通常の `run(player_mode)` へ分岐する
3. `run(player_mode)`（`mpv-player.py:284-312`、再生フロー）
   - 対象ディレクトリは `Path.cwd()`（コマンド実行時のカレントディレクトリ、再帰探索）
   - `no_video = player_mode == MODE_MUSIC`（music は音声のみ、video は映像表示）
   - `extensions = MEDIA_EXTENSIONS_BY_MODE[player_mode]` でモードごとの拡張子集合を選択
   - main menu（`1`: 個別選択 / `2`: 検索結果全件 / `3`: 前回playlist再生）
   - playback menu（`A`: 通常 / `B`: リピート / `C`: シャッフル）
4. `build_mpv_command`（`mpv-player.py:158-167`）: `no_video` が真の場合のみ `--no-video` を付与
5. `run_delete(media_dir, extensions, prompt)`（`mpv-player.py:267-281`、削除フロー）
   - `discover_media_files` でモード別拡張子のみ候補にし、`select_media_with_fzf` で複数選択させる
   - `confirm_deletion(count)`（`mpv-player.py:256-258`）で `Delete N file(s)? [y/N]` を表示し、
     `y`/`yes`（大小文字不問）以外の入力（Enterのみ含む）はキャンセル扱い
   - 承認時のみ `delete_selected_files`（`mpv-player.py:261-264`）が各ファイルを `Path.unlink()` する

## 重要な設計判断

### 対象ディレクトリを `~/Music` / `~/Videos` 固定にせず `Path.cwd()` にした

当初は `~/Music`（music）/ `~/Videos`（video）決め打ちで設計したが、
ユーザーの実運用では任意のサブディレクトリを対象にしたいという要望があり、
`run()` は常に `Path.cwd()` を対象ディレクトリとする設計に変更した
（`mpv-player.py:248`）。呼び出し側が `cd` してから実行する前提。

### モードごとに拡張子を分離した

当初は `MEDIA_EXTENSIONS` という単一の拡張子集合（音声・動画混在）を
music/video 両方で共有していたが、video 実行時に音声ファイルが、
music 実行時に動画ファイルが選択肢に混ざるのは意図と異なるため、
`MUSIC_EXTENSIONS` / `VIDEO_EXTENSIONS` に分離し
`MEDIA_EXTENSIONS_BY_MODE` でモードと対応付けた（`mpv-player.py:12-49`）。

### メニュー文言・エラーメッセージは英語かつモード非依存

分割前の実装は「楽曲」等 music 前提の日本語文言だったが、video モードでも
違和感がないよう、`MAIN_MENU` / `PLAYBACK_MENU` および全エラーメッセージを
英語・モード中立な表現（例: `"1. Select files to play"`）に統一した
（`mpv-player.py:51-60`, `189-244`）。

### `mpv-music-player.py` + `mpv-video-player.sh` から統合

直近のコミット（`e59fb39`）で `mpv-player.py` は音声専用の
`mpv-music-player.py` と、メニューなしの一行スクリプト
`mpv-video-player.sh`（fd + fzf + mpv）に分割されていたが、
docs/tests が更新されないまま不整合な状態だった。本変更で単一ファイルに
再統合し、video にも music と同じ対話メニューフローを持たせた。

### 削除は確認プロンプトのみを安全装置とし、ゴミ箱には送らない

`delete_selected_files` は `Path.unlink()` を直接呼ぶため取り消せない。
ゴミ箱移動（`gio trash` 等）は依存を増やすため採用せず、代わりに
`confirm_deletion` の y/N 確認（デフォルト N）を唯一の安全装置としている。

## 統合ポイント

- 呼び出し元: `applications/mpv-player/install.sh` が `~/.local/bin/mpv-player`
  へシンボリックリンクする。呼び出しは `mpv-player music` / `mpv-player video`、
  削除フローは `mpv-player <music|video> -d`（または `--delete`）
- 依存コマンド: `fzf`, `mpv`（`install.sh` が apt でインストール）
- テスト: `applications/mpv-player/tests/test_mpv_player.py`（unittest, 31件）

## 注意事項・既知の制限

- 対象ディレクトリはカレントディレクトリ固定のため、`~/Music` 等を対象にしたい場合は
  そのディレクトリに `cd` してから実行する必要がある
- playlist ファイルは常に `<cwd>/playlist/mpv-player.m3u` に上書きされる
- `-d`/`--delete` による削除は即時かつ不可逆（ゴミ箱を経由しない）。確認プロンプトの
  デフォルトは N（Enterのみ・`y`/`yes` 以外は全てキャンセル扱い）

## 変更履歴（git log より自動生成）

- 13e5a42 feat(#42): add -d/--delete option to mpv-player.py
- 778b08c refactor(#40): merge mpv-video-player.sh into mpv-player.py with music/video mode
- e59fb39 fix(mpv-player): split mpv wrapper into music and video players
- 32bfb58 refactor(mpv-player): move from scripts/ to applications/
