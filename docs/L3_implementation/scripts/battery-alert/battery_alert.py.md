# `scripts/battery-alert/battery_alert.py`

## 目的・役割

systemd timer から oneshot 起動され、バッテリー残量が設定したしきい値を下回ったときに `notify-send` で通知を送る。常駐プロセスではない。

## 動作の概要と主要ロジック

1. `/sys/class/power_supply/BAT*` をソートして最初のバッテリーを特定する（`find_battery_path`）
2. `capacity`（%）と `status`（"Discharging" / "Charging" など）を読む（`read_battery_state`）
3. 放電中以外（Charging / Full 等）は state ファイルをクリアして終了する（`clear_state`）
4. `.env` の `NOTIFY_THRESHOLDS`（カンマ区切り整数）をパースし、降順にソートする（`parse_thresholds`）
5. state ファイル（`/tmp/battery-alert.state`）から通知済みしきい値を読む（`load_notified_thresholds`）
6. 未通知かつ `capacity <= threshold` を満たす全しきい値を `to_notify`（降順）として列挙する（`thresholds_to_notify`）
7. `to_notify` が存在する場合:
   - 全しきい値を state ファイルに記録する（再通知防止）
   - **`to_notify[-1]`（最低値）に対してのみ `notify-send` を1回呼ぶ**

## 重要な設計判断

### 通知は最低しきい値のみ

サスペンド復帰等で複数しきい値が一度に該当しても、最も低いしきい値（現在容量に最も近いもの）のみ通知する。残りのしきい値はすべて state に記録し、次回ポーリングで再表示しない。

理由: サスペンド中に容量が大きく下がった場合、既に通過した高いしきい値の通知は情報過多かつユーザーの誤操作を招く。現在値に最も近い「最後に越えたしきい値」のみが意思決定に有用。

### state ファイルは /tmp に置く

再起動・充電サイクルをまたいで通知済み状態をリセットするため `/tmp` を使用する。充電に戻ると state ファイルを削除し、次の放電サイクルで全しきい値が再び通知対象になる。

### `to_notify` の降順ソート

`thresholds_to_notify` は降順リストを返す（`battery_alert.py:76-79`）。`run()` は末尾要素 `to_notify[-1]` を最低しきい値として参照する（`battery_alert.py:113`）。

## 統合ポイント

- 呼び出し元: `~/.config/systemd/user/battery-alert.timer`（`install.sh` が生成）
- 設定ファイル: `scripts/battery-alert/.env`（`NOTIFY_THRESHOLDS`, `POLL_INTERVAL`）
- 通知: `notify-send -u critical`

## 注意事項

- `.env` の `POLL_INTERVAL` はこのスクリプト自身は読まない。`install.sh` が `battery-alert.timer` テンプレートの `__POLL_INTERVAL__` を置換して systemd timer に渡す。
- テスト: `tests/test_battery_alert.py`（unittest, 20件）

## 変更履歴（git log より自動生成）

- cc21168 fix(#27): notify only the lowest crossed threshold on each poll
- a323ddf feat(#1): rewrite battery-alert script to Python with .env-configurable thresholds and poll interval
