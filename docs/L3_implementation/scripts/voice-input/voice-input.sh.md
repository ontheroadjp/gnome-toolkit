---
name: voice-input-sh
description: Toggle-record → whisper.cpp transcribe → wl-copy script for GNOME voice input
metadata:
  type: project
---

## 目的・役割

GNOME カスタムショートカットから呼ばれ、音声入力をクリップボードに届けるメインスクリプト。
録音の開始・停止・文字起こし・クリップボードコピーを1ファイルで完結させる。

## 動作の概要

```
voice-input.sh toggle
  ├─ PID ファイルなし / プロセス死亡 → _start_recording
  │    arecord (16kHz mono WAV) をバックグラウンド起動 → PID を /tmp/voice-input.pid に保存
  └─ PID ファイルあり / プロセス生存 → _stop_and_transcribe
       kill arecord → whisper-cli 実行 → wl-copy → notify-send
```

各フェーズで `notify-send` が通知を出す（Recording… / Transcribing… / Copied to clipboard）。

## 主要な定数（ファイル先頭）

| 定数 | 値 | 意味 |
|------|----|------|
| `WHISPER_BIN_DIR` | `~/.local/lib/whisper.cpp/build/bin` | install.sh のビルド出力先 |
| `WHISPER_MODEL` | `~/.local/share/whisper-models/ggml-base.bin` | デフォルトモデル |
| `RECORD_FILE` | `/tmp/voice-input-record.wav` | 録音一時ファイル |
| `PID_FILE` | `/tmp/voice-input.pid` | 録音プロセスの PID |
| `ARECORD_RATE` | `16000` | whisper.cpp が要求するサンプリングレート |

## 重要な設計判断

- **自動ペーストしない**: `ydotool` はデーモン起動が必要で Wayland 上で不安定なため、クリップボードへのコピーのみ行い Ctrl+V はユーザーに委ねる。
- **`_whisper_bin()` で新旧両対応**: whisper.cpp はバージョンによりバイナリ名が `whisper-cli`（新）/ `main`（旧）と異なるため、両方を検索して最初に見つかったものを使う（`voice-input.sh:17-25`）。
- **transcribe 出力フィルタ**: `grep -v '^\['` で `[BLANK_AUDIO]` 等の特殊トークン行を除去、`tr '\n' ' '` で複数行を1行に結合（`voice-input.sh:71`）。

## 統合ポイント

- **呼び出し元**: GNOME カスタムショートカット（`install.sh` が登録）
- **依存コマンド**: `arecord`（alsa-utils）、`wl-copy`（wl-clipboard）、`notify-send`（libnotify）、whisper-cli（install.sh でビルド）

## 注意事項

- モデルを変える場合は `WHISPER_MODEL` の値を変更する（`ggml-small.bin` 等）
- `--language auto` で日英自動判定。特定言語に固定したい場合は `--language ja` 等に変更

## 変更履歴（git log より自動生成）

- adb6559 feat(#6): add whisper.cpp-based voice input script for GNOME
