# battery-alert

  本ドキュメントは、Ubuntu（GNOME環境）において、サードパーティ製の常駐アプリケーションを使用せず、Linuxカーネルの仮想ファイルシステム（`sysfs`）とOS標準の `systemd` を組み合わせることで、CPUやメモリへの負荷を最小限に抑えたバッテリー監視システムを構築する手順です。

  ## 目次
  1. [システムの概要](#1-システムの概要)
  2. [.env の設定](#2-env-の設定)
  3. [監視・通知スクリプト（battery_alert.py）](#3-監視通知スクリプトbattery_alertpy)
  4. [systemd ユーザーサービスとタイマーの定義](#4-systemd-ユーザーサービスとタイマーの定義)
  5. [インストール](#5-インストール)
  6. [動作確認コマンド](#6-動作確認コマンド)

  ---

  ## 1. システムの概要

  * **目的:** バッテリー残量が設定したしきい値以下になった際、デスクトップに警告通知を表示します。
  * **しきい値:** `.env` の `NOTIFY_THRESHOLDS` で複数指定可能（例: `80,50,30`）。放電中にしきい値を下回ったとき、**最も低いしきい値（現在容量に最も近いもの）に対して1回だけ**通知します。サスペンド復帰などで複数のしきい値を一度に越えた場合も通知は1件のみです。越えた全しきい値は状態ファイルに記録され、次回ポーリングで再表示されません。充電を開始すると通知済み状態はリセットされ、次の放電サイクルで再度通知されます。
  * **動作方式:** oneshot スクリプト（`battery_alert.py`）を systemd timer が定期実行するポーリング方式です。ポーリング間隔は `.env` の `POLL_INTERVAL`（秒、デフォルト120）で設定します。
  * **リソース消費:** 常駐プロセスを持たないため、実行時以外のメモリ・CPU消費は事実上ゼロとなります。通知の重複送信を防ぐため、しきい値ごとの通知済み状態を `/tmp` 配下のステートファイル（`battery-alert.state`）で管理します。

  ---

  ## 2. `.env` の設定

  `.env.example` をコピーして `.env` を作成し、必要に応じて値を変更します。

  ```bash
    cp .env.example .env
  ```

  | 変数 | 説明 | デフォルト |
  |---|---|---|
  | `NOTIFY_THRESHOLDS` | 通知する残量（%）。カンマ区切りで複数指定可能（例: `80,50,30`） | `50` |
  | `POLL_INTERVAL` | ポーリング間隔（秒）。`battery_alert.py` 自体は読まず、`install.sh` が systemd timer に反映する | `120` |

  `.env` はリポジトリにコミットしません（`.gitignore` 参照）。

  ### `.env` を更新する手順

  1. `.env` を編集する（例: `NOTIFY_THRESHOLDS=80,50,30`）
  2. `install.sh` を再実行する（`POLL_INTERVAL` が systemd timer に反映されるのは `install.sh` 実行時のみのため）
     ```bash
       ./install.sh
     ```
  3. 反映された内容を確認する
     ```bash
       cat ~/.config/systemd/user/battery-alert.timer
     ```
  4. `NOTIFY_THRESHOLDS` のみを変更した場合は手順2・3は不要（`battery_alert.py` は実行毎に `.env` を読むため、次回ポーリングから即反映される）

  ---

  ## 3. 監視・通知スクリプト（`battery_alert.py`）

  バッテリーの状態を判定し、`.env` の `NOTIFY_THRESHOLDS` のうち放電中に下回ったものについて `notify-send` を実行する Python スクリプトです（標準ライブラリのみ、追加インストール不要）。

  * バッテリーデバイスのパス（`BAT0` など）は `/sys/class/power_supply/` から動的に取得します
  * バッテリーが存在しない環境（デスクトップPCなど）では何もせず終了します
  * 放電中（`Discharging`）でなくなった場合は通知済み状態をリセットします
  * 1回のチェックで完了する oneshot スクリプトです（ポーリングは systemd timer が担います）

  単体で動作確認したい場合:

  ```bash
    python3 battery_alert.py
  ```

  *(※現在の実際のバッテリー残量が `NOTIFY_THRESHOLDS` のいずれか以下、かつ放電中の状態のときのみ通知が飛びます。テストする場合は `.env` の `NOTIFY_THRESHOLDS` を現在の残量より大きい値に一時的に変更すると動作を確認できます。)*

  ---

  ## 4. systemd ユーザーサービスとタイマーの定義

  ### A. サービスファイル（`battery-alert.service`）
  スクリプトを単発実行するための定義ファイルです。

  ```ini
    [Unit]
    Description=Battery Alert Notification Service

    [Service]
    Type=oneshot
    ExecStart=%h/.local/bin/battery_alert.py
  ```

  ### B. タイマーファイル（`battery-alert.timer`、テンプレート）
  定期実行の間隔を管理する定義ファイルです。`__POLL_INTERVAL__` はプレースホルダーで、`install.sh` が `.env` の `POLL_INTERVAL` の値に置換したものを `~/.config/systemd/user/battery-alert.timer` として書き出します（リポジトリ内のこのファイル自体は実行環境に依存しないテンプレートのまま残ります）。

  ```ini
    [Unit]
    Description=Timer for Battery Alert Service

    [Timer]
    OnBootSec=__POLL_INTERVAL__sec
    OnUnitActiveSec=__POLL_INTERVAL__sec

    [Install]
    WantedBy=timers.target
  ```

  ---

  ## 5. インストール

  `install.sh` が以下を行います:

  * `battery_alert.py` を `~/.local/bin/` にシンボリックリンク
  * `battery-alert.service` を `~/.config/systemd/user/` にシンボリックリンク
  * `.env` の `POLL_INTERVAL`（未設定時は120）を `battery-alert.timer` のプレースホルダーに置換し、`~/.config/systemd/user/battery-alert.timer` として書き出す

  ```bash
    ./install.sh
  ```

  `systemd` に新しい設定ファイルを認識させ、タイマーを有効化して起動処理を行います。

  ```bash
    # 設定ファイルの再読み込み
    systemctl --user daemon-reload

    # ログイン時の自動起動を有効化
    systemctl --user enable battery-alert.timer

    # タイマーを今すぐ起動
    systemctl --user start battery-alert.timer
  ```

  ---

  ## 6. 動作確認コマンド

  タイマーが正常に登録され、稼働しているかは以下のコマンドで確認が可能です。

  * **タイマーの一覧と次回実行時刻の確認:**

  ```bash
    systemctl --user list-timers | grep battery-alert
  ```

  * **生成された timer ユニットに `.env` の `POLL_INTERVAL` が反映されているか確認:**

  ```bash
    cat ~/.config/systemd/user/battery-alert.timer
  ```

  * **スクリプト単体での強制テスト（即座に通知を確認したい場合）:**

  ```bash
    python3 ~/.local/bin/battery_alert.py
  ```
