---
name: voice-input-install-sh
description: Build whisper.cpp, download base model, register GNOME shortcut for voice input
metadata:
  type: project
---

## 目的・役割

`voice-input.sh` の実行環境を整える初回セットアップスクリプト。再実行しても冪等に動く。

## 動作の概要（実行順）

1. **依存チェック** (`_check_deps`): `git cmake make gcc arecord wl-copy notify-send` の存在確認。不足時は apt コマンドを案内して終了。
2. **whisper.cpp ビルド** (`_build_whisper`): `~/.local/lib/whisper.cpp/` に clone → cmake ビルド。バイナリ既存ならスキップ。
3. **モデルダウンロード** (`_download_model`): `~/.local/share/whisper-models/ggml-base.bin` を HuggingFace から取得。既存ならスキップ。
4. **GNOME ショートカット登録** (`_register_gnome_shortcut`): `gsettings` で `custom-keybindings` に新スロットを追加。`voice-input.sh` が既登録ならスキップ（重複防止）。

## 主要な定数

| 定数 | 値 |
|------|----|
| `WHISPER_INSTALL_DIR` | `~/.local/lib/whisper.cpp` |
| `MODEL_FILE` | `~/.local/share/whisper-models/ggml-base.bin` |
| `SHORTCUT_BINDING` | `<Control><Shift>equal`（Ctrl+Shift+=） |

## 重要な設計判断

- **sudo 不要**: すべて `~/.local/` 以下に展開するため root 権限は不要。
- **重複登録防止**: 既存の全 custom スロットをループして `voice-input.sh` を含むコマンドが見つかれば早期 return する（`install.sh:70-76`）。初回実行前に binding を変更して再実行しても二重登録されない。
- **モデル URL**: `https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin`。モデルを変える場合は `MODEL_FILE` と `MODEL_URL` を合わせて変更する。

## 統合ポイント

- **呼び出し元**: ユーザーが手動で実行（`bash scripts/voice-input/install.sh`）
- **生成物**: `~/.local/lib/whisper.cpp/build/bin/whisper-cli`、`~/.local/share/whisper-models/ggml-base.bin`、GNOME カスタムショートカット

## 注意事項

- ビルドに `build-essential cmake libasound2-dev` が必要。未インストールの場合は `_check_deps` がエラーメッセージと apt コマンドを出力して終了する。
- whisper.cpp のビルドは初回のみ 5〜10 分かかる。

## 変更履歴（git log より自動生成）

- adb6559 feat(#6): add whisper.cpp-based voice input script for GNOME
