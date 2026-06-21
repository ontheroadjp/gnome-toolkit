---
name: voice-input-install-sh
description: Install whisper.cpp, its persistent user service, and the GNOME shortcut
metadata:
  type: project
---

## 目的・役割

音声入力に必要な依存コマンド、whisper.cpp、モデル、systemdユーザーサービス、
GNOMEカスタムショートカットをセットアップする冪等なインストーラー。

## 動作概要

1. `git`、ビルドツール、録音・HTTP・通知・クリップボード・systemdコマンドを確認する
   （`install.sh:19-29`）。
2. CLIと `whisper-server` の両方がなければwhisper.cppをReleaseビルドする
   （`install.sh:31-51`）。
3. `ggml-base.bin` がなければダウンロードする（`install.sh:61-70`）。
4. サービスunitをユーザー設定へリンクし、daemon reload後にenable/startする
   （`install.sh:53-59`）。
5. `Ctrl+Shift+=` のGNOMEカスタムショートカットを重複なく登録する
   （`install.sh:72-113`）。

実行順は `install.sh:117-141` に定義されている。

## 主要な生成物

| 生成物 | パス |
|---|---|
| whisper.cpp | `~/.local/lib/whisper.cpp` |
| モデル | `~/.local/share/whisper-models/ggml-base.bin` |
| systemd unitリンク | `~/.config/systemd/user/voice-input-whisper.service` |
| GNOMEショートカット | `<Control><Shift>equal` |

## 重要な設計判断

- CLIとサーバーの両方をビルド済み判定に含め、旧インストール環境でもサーバーが不足
  していれば再ビルドする（`install.sh:31-49`）。
- サービスunitはコピーせずリポジトリ内ファイルへのシンボリックリンクとし、更新を
  再インストールなしで反映できるようにする（`install.sh:53-57`）。
- すべてユーザーディレクトリとsystemdユーザーサービスで構成し、sudoを要求しない。

## 統合ポイント

- 呼び出し元: 利用者による `scripts/voice-input/install.sh` 実行
- 呼び出し先: `git`、CMake、Hugging Face、`systemctl --user`、`gsettings`
- インストール対象: `voice-input.sh`、`voice-input-whisper.service`

## 注意事項・既知の制限

- 初回ビルドとモデル取得にはネットワーク接続が必要。
- systemdユーザーセッションが利用可能であることを前提とする。
- 固定ポート8178が他プロセスに使用されている場合、サービスは起動できない。

## 変更履歴（git log より自動生成）

- d3925f3 feat(#17): keep whisper model loaded for voice input
- adb6559 feat(#6): add whisper.cpp-based voice input script for GNOME
