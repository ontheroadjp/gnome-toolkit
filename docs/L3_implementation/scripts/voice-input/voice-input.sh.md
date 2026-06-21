---
name: voice-input-sh
description: Toggle recording, request persistent whisper.cpp transcription, and copy the result
metadata:
  type: project
---

## 目的・役割

GNOMEカスタムショートカットから呼ばれ、録音の開始・停止と文字起こし結果の
クリップボードコピーを行う。モデル推論は常駐する `whisper-server` に委譲する。

## 動作概要

`toggle` はPIDファイルの録音プロセスが生存していれば停止処理へ、そうでなければ
録音開始へ分岐する（`voice-input.sh:84-95`）。録音は16kHz、モノラル、S16_LEの
WAVとして保存する（`voice-input.sh:31-37`）。

停止時は録音プロセスを終了し、モデルと録音ファイルの存在を確認してから、
`curl` のmultipartリクエストで `whisper-server` の `/inference` へ送る
（`voice-input.sh:39-71`）。レスポンスを1行に整形し、空でなければ `wl-copy` へ
渡す（`voice-input.sh:72-81`）。

## 主要設定

| 設定 | 既定値 | 用途 |
|---|---|---|
| `VOICE_INPUT_LANGUAGE` | `ja` | 文字起こし言語 |
| `VOICE_INPUT_SERVER_URL` | `http://127.0.0.1:8178/inference` | 常駐サーバーAPI |
| `VOICE_INPUT_RECORD_FILE` | `/tmp/voice-input-record.wav` | 録音ファイル |
| `VOICE_INPUT_PID_FILE` | `/tmp/voice-input.pid` | 録音プロセスPID |
| `VOICE_INPUT_NOTIFICATION_ID_FILE` | `/tmp/voice-input-notification.id` | 置換対象の通知ID |

環境変数による一時ファイルの上書きは、通常利用時の既定動作を保ちながら統合テストを
隔離するために使う（`voice-input.sh:4-9`）。

## 重要な設計判断

- モデルをリクエストごとに読み込まないため、CLI直接実行ではなくlocalhostの
  常駐サーバーを利用する（`voice-input.sh:61-71`）。
- 通知IDを保存し、録音中・処理中・完了通知を同一通知として置換する
  （`voice-input.sh:15-29`）。
- 自動ペーストは行わず、Waylandクリップボードへのコピーまでを責務とする
  （`voice-input.sh:79-80`）。

## 統合ポイント

- 呼び出し元: `install.sh` が登録するGNOMEカスタムショートカット
- 呼び出し先: `voice-input-whisper.service` の `whisper-server`
- 外部コマンド: `arecord`、`curl`、`wl-copy`、`notify-send`

## 注意事項・既知の制限

- サーバー停止時は文字起こしを失敗として通知し、CLIへのフォールバックは行わない
  （`voice-input.sh:62-70`）。
- 音声認識結果はクリップボードへコピーされるため、貼り付け操作は利用者が行う。

## 変更履歴（git log より自動生成）

- d3925f3 feat(#17): keep whisper model loaded for voice input
- adb6559 feat(#6): add whisper.cpp-based voice input script for GNOME
