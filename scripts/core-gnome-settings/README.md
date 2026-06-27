# core-gnome-settings

Ubuntu / GNOME 向けの設定を `gsettings` で一括適用するスクリプト。
ThinkPad に限らず、GNOME が動作する環境であれば機種を問わず利用できる。

## 設定内容

| 設定項目 | 値 |
|---|---|
| GNOME アニメーション | 有効 |
| キーリピート遅延 | 180ms |
| キーリピート間隔 | 10ms |
| IME 切替キー | `Ctrl+Space` |
| ウィンドウ切替 | `Alt+Tab` + `Ctrl+Tab`（backward: `Shift+Alt+Tab` + `Shift+Ctrl+Tab`） |
| switch-panels | デフォルトにリセット |
| ワークスペース切替 | `Ctrl+1〜4` |
| ウィンドウドラッグ修飾キー | `Ctrl` |
| フォントヒンティング | full |
| フォントアンチエイリアス | grayscale |

## 使い方

```bash
./scripts/core-gnome-settings/apply-settings.sh
```

`sudo` は不要。設定はログアウト不要で即時反映される。
