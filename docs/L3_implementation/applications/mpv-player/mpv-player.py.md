# `applications/mpv-player/mpv-player.py`

## 目的・役割

`music` / `video` の2モードに対応した、fzf 選択 + mpv 再生を行う対話的な CLI。
起動時のカレントディレクトリ配下を再帰的にスキャンし、モードに応じた拡張子の
メディアファイルのみを選択候補とする。

## 動作の概要と主要ロジック

1. `parse_player_mode(sys.argv[1:])` が第一引数を検証する。`music`/`video` 以外、
   または引数なし/複数は usage を表示して `SystemExit(1)`（`mpv-player.py:239-244`）
2. `run(player_mode)`（`mpv-player.py:247-275`）
   - 対象ディレクトリは `Path.cwd()`（コマンド実行時のカレントディレクトリ、再帰探索）
   - `no_video = player_mode == MODE_MUSIC`（music は音声のみ、video は映像表示）
   - `extensions = MEDIA_EXTENSIONS_BY_MODE[player_mode]` でモードごとの拡張子集合を選択
   - main menu（`1`: 個別選択 / `2`: 検索結果全件 / `3`: 前回playlist再生）
   - playback menu（`A`: 通常 / `B`: リピート / `C`: シャッフル）
3. `build_mpv_command`（`mpv-player.py:158-167`）: `no_video` が真の場合のみ `--no-video` を付与

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

## 統合ポイント

- 呼び出し元: `applications/mpv-player/install.sh` が `~/.local/bin/mpv-player`
  へシンボリックリンクする。呼び出しは `mpv-player music` / `mpv-player video`
- 依存コマンド: `fzf`, `mpv`（`install.sh` が apt でインストール）
- テスト: `applications/mpv-player/tests/test_mpv_player.py`（unittest, 21件）

## 注意事項・既知の制限

- 対象ディレクトリはカレントディレクトリ固定のため、`~/Music` 等を対象にしたい場合は
  そのディレクトリに `cd` してから実行する必要がある
- playlist ファイルは常に `<cwd>/playlist/mpv-player.m3u` に上書きされる
