---
name: voice-input-whisper-service
description: Keep the whisper.cpp base model loaded for local voice-input requests
metadata:
  type: project
---

## 目的・役割

`whisper-server` とbaseモデルをsystemdユーザーサービスとして常駐させ、音声入力ごとの
モデル読み込みを除去する。

## 動作概要

`whisper-server` を `127.0.0.1:8178` で起動し、日本語、単一候補、フォールバックなし、
タイムスタンプなしを既定の推論設定とする（`voice-input-whisper.service:4-6`）。
異常終了時は2秒後に再起動する（`voice-input-whisper.service:7-8`）。

## 重要な設計判断

- 外部ネットワークへAPIを公開しないためlocalhostのみにbindする。
- system serviceではなく `default.target` のuser serviceとして有効化し、root権限を
  使用しない（`voice-input-whisper.service:12-13`）。
- `NoNewPrivileges` と `PrivateTmp` により権限昇格と一時領域の共有を制限する
  （`voice-input-whisper.service:9-10`）。

## 統合ポイント

- インストール・起動: `install.sh` の `_install_whisper_service`
- クライアント: `voice-input.sh` の `VOICE_INPUT_SERVER_URL`
- 実行バイナリ: `~/.local/lib/whisper.cpp/build/bin/whisper-server`
- モデル: `~/.local/share/whisper-models/ggml-base.bin`

## 注意事項・既知の制限

- 常駐中はbaseモデルと推論コンテキストのメモリを継続的に使用する。
- ポート8178は固定であり、競合時はサービス起動に失敗する。

## 変更履歴（git log より自動生成）

- d3925f3 feat(#17): keep whisper model loaded for voice input
