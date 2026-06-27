# t480s

Lenovo ThinkPad T480s (Ubuntu 24.04 LTS / GNOME) の初期セットアップスクリプト群。
マシンを再現可能な状態にするため、GNOME デスクトップ設定の一括適用を担う。

## ファイル構成

| ファイル | 役割 |
|---|---|
| `t480s-settings.sh` | GNOME デスクトップ設定を `gsettings` で一括適用 |

> **注意:** 以前存在した `t480s-apps-install.sh`（パッケージ一括インストール）は
> `scripts/core-tools/install.sh` および各 `applications/*/install.sh` に分割・移行された。
> ルートの `install.sh` で一括実行できる。

## t480s-settings.sh

`gsettings` および `/sys/class/power_supply/BAT0/` への書き込みで以下を設定する。

| 設定項目 | 値 |
|---|---|
| GNOME アニメーション | 有効 |
| キーリピート遅延 | 180ms |
| キーリピート間隔 | 10ms |
| IME 切替キー | `Ctrl+Space` |
| ウィンドウ切替 | `Alt+Tab` + `Ctrl+Tab`（backward: `Shift+Alt+Tab` + `Shift+Ctrl+Tab`）|
| switch-panels | デフォルトにリセット |
| ワークスペース切替 | `Ctrl+1〜4` |
| ウィンドウドラッグ修飾キー | `Ctrl` |
| フォントヒンティング | full |
| フォントアンチエイリアス | grayscale |
| バッテリー充電開始閾値 | 30% |
| バッテリー充電停止閾値 | 85% |

### 使い方

```bash
# sudo 必須（バッテリー充電閾値の書き込みに必要）
./t480s/t480s-settings.sh
```

> **注意:** バッテリー充電閾値はシステム再起動後にリセットされる。
> 永続化には `tlp` のインストールと設定が必要（スクリプト末尾のコメント参照）。
