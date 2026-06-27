# core-t480s-settings

Lenovo ThinkPad T480s 固有のハードウェア設定を適用するスクリプト。
`thinkpad_acpi` カーネルモジュールが提供する sysfs インターフェイスに依存するため、
**ThinkPad 以外の機種では動作しない**。

## 設定内容

| 設定項目 | 値 | 備考 |
|---|---|---|
| バッテリー充電開始閾値 | 30% | `/sys/class/power_supply/BAT0/charge_start_threshold` |
| バッテリー充電停止閾値 | 85% | `/sys/class/power_supply/BAT0/charge_stop_threshold` |

> **注意:** この設定はシステム再起動後にリセットされる。
> 永続化には `tlp` のインストールと設定が必要（スクリプト末尾のコメント参照）。

## 使い方

```bash
# sudo 必須（sysfs への書き込みに必要）
./scripts/core-t480s-settings/apply-settings.sh
```
