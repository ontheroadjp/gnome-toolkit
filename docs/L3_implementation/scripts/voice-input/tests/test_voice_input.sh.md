---
name: test-voice-input-sh
description: Integration test for the voice-input HTTP and clipboard flow
metadata:
  type: project
---

## 目的・役割

外部プロセスをモックし、`voice-input.sh` の録音開始からHTTP文字起こし、
クリップボードコピー、エラー通知までを隔離環境で検証する。

## 動作概要

一時HOMEと一時状態ファイルを設定し、終了時に録音プロセスとファイルを確実に削除する
（`test_voice_input.sh:5-23`）。`arecord`、`curl`、`notify-send`、`wl-copy` をexport済み
Bash関数で置換する（`test_voice_input.sh:25-51`）。

成功ケースでは録音PIDとファイルの作成、HTTP endpoint・言語・レスポンス形式、
クリップボード内容、終了後の一時ファイル削除を確認する
（`test_voice_input.sh:53-68`）。失敗ケースではcurlエラー時に非ゼロ終了し、サーバー停止の
通知が記録されることを確認する（`test_voice_input.sh:70-76`）。

## 重要な設計判断

- 実マイク、通知デーモン、Waylandクリップボード、HTTPサーバーへ依存しない。
- 本番スクリプトの環境変数による一時ファイル上書きを利用し、利用者の `/tmp` 状態と
  テストを分離する。

## 統合ポイント

- テスト対象: `scripts/voice-input/voice-input.sh`
- 実行方法: `scripts/voice-input/tests/test_voice_input.sh`

## 注意事項・既知の制限

- whisper.cpp自体の認識精度やsystemd起動は対象外で、実機検証で補完する。

## 変更履歴（git log より自動生成）

- d3925f3 feat(#17): keep whisper model loaded for voice input
