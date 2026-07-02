# mpv-player

実行時のカレントディレクトリ配下の音声・動画ファイルを fzf でインタラクティブに選択し、
mpv で再生する Python スクリプト。`music`（音声のみ）/ `video`（映像あり）の2モードに対応。

## 仕組み

1. 実行時のカレントディレクトリを再帰的にスキャンし、モードに応じた拡張子のメディアファイルを列挙する
2. fzf で選択またはキーワード絞り込みを行う
3. 選択結果を `<cwd>/playlist/mpv-player.m3u` に書き出す
4. mpv で再生する。`music` モードは `--no-video` を付与して音声のみ再生し、`video` モードは映像も表示する

メインメニューは以下の3モードを提供する。

| 選択 | 動作 |
|---|---|
| `1` | fzf でファイルを個別選択してプレイリスト作成 |
| `2` | fzf でキーワード絞り込み → 全件をプレイリストに追加 |
| `3` | 前回のプレイリストをそのまま再生 |

再生モード選択（`A`: 通常 / `B`: リピート / `C`: シャッフル）も対話的に行う。

## 対応拡張子

- `music`: mp3, flac, aac, m4a, ogg, opus, wav, aiff, ape, wma など
- `video`: mp4, mkv, avi, mov, webm, wmv など

## ファイル構成

| ファイル | 役割 |
|---|---|
| `mpv-player.py` | メインスクリプト（標準ライブラリ + fzf + mpv のみ） |
| `install.sh` | `~/.local/bin/mpv-player` にシンボリックリンクを作成 |

## インストール

```bash
./applications/mpv-player/install.sh
```

インストール後、対象ディレクトリに `cd` してから実行する:

```bash
mpv-player music
# または
mpv-player video
```

## ファイルの削除（`-d` / `--delete`）

`-d`/`--delete` を付けると、通常の再生フローの代わりに fzf で選択したファイルを削除できる:

```bash
mpv-player music -d
# または
mpv-player video --delete
```

fzf で選択後 `Delete N file(s)? [y/N]` の確認が表示され、`y`/`yes`（大小文字不問）以外の
入力（Enterのみ含む）は削除をキャンセルする。**削除は即時かつ不可逆（ゴミ箱を経由しない）** ため注意すること。

> **前提:** `fzf` と `mpv` がインストール済みであること（`install.sh` が apt で導入する）。
