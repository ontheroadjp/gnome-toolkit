# リポジトリ構造

モノレポ構成ではない（`apps/` / `packages/` 等のワークスペース分割は存在しない。
トップレベルのディレクトリ・ファイルは以下のみ）。

```
.
├── t480s.sh                              # GNOME desktop 設定スクリプト
├── t480s_apps.sh                         # パッケージ/CLIツール導入スクリプト
├── .config/
│   └── alacritty/
│       ├── alacritty.toml                # Alacritty 本体設定
│       └── theme/
│           ├── tokyo-night.toml          # 配色テーマ（現在アクティブ）
│           ├── tokyo-night-storm.toml    # 配色テーマ（代替）
│           └── dracula.toml              # 配色テーマ（代替）
├── .local/
│   └── bin/
│       └── gnome-overview-toggle         # GNOME Overview トグルスクリプト
└── scripts/
    └── battery-alert/                    # バッテリー低下通知（Python + systemd timer）
        ├── battery_alert.py
        ├── .env.example
        ├── install.sh
        ├── README.md
        ├── tests/
        │   └── test_battery_alert.py
        └── .config/systemd/user/
            ├── battery-alert.service
            └── battery-alert.timer
```

(`docs/` は本コマンドにより新規追加。`.git/` は省略)

## 各ディレクトリ/ファイルの責務（実装から確認）

### `t480s.sh`
リポジトリルート直下のスクリプト。`gsettings set` コマンド列のみで構成され
（`t480s.sh:7-54`）、GNOME のアニメーション・キーボード・キーバインド・
フォントレンダリング・バッテリー充電閾値を設定する。
末尾のコメント（`t480s.sh:56-64`）に `tlp` を使った充電閾値の永続化手順が
メモとして残っているが、実行コードではない（コメントアウト済み）。

### `t480s_apps.sh`
リポジトリルート直下のスクリプト。`apt install` と、各ツール公式の
インストール手順（`curl`/`wget` パイプ、`npm install -g`）を順に実行し、
新規マシンの開発環境を構築する。各ツールは
`command -v <tool> >/dev/null 2>&1` で存在確認した上で条件分岐する箇所が
多い（`t480s_apps.sh:47,67,80,93,101,109,121`）。

### `.config/alacritty/`
ホームディレクトリの `~/.config/alacritty` にシンボリックリンクとして
配置されることを実機で確認済み（`readlink -f ~/.config/alacritty` の結果が
このリポジトリ内パスと一致）。Alacritty のメイン設定
(`alacritty.toml`) と、3つの配色テーマファイル(`theme/*.toml`)を持つ。
`alacritty.toml:18-43` にはコメントで「T480s」と「MBP15」の2機種分の
フォント設定が記載されており、現在 T480s 用設定のみがアクティブ
（MBP15 用はコメントアウト済み、`alacritty.toml:38-43`）。

### `.local/bin/gnome-overview-toggle`
ホームディレクトリの `~/.local/bin/gnome-overview-toggle` に
シンボリックリンクとして配置されることを実機で確認済み。
実行可能ビット付き（`rwxrwxr-x`）の POSIX sh スクリプトで、
`gdbus call` のみで GNOME Shell の Overview 状態をトグルする外部依存のない
単機能スクリプト。

### `scripts/battery-alert/`
バッテリー残量低下を `notify-send` で通知する Python 製 oneshot スクリプト
一式。`battery_alert.py`（標準ライブラリのみ）が `/sys/class/power_supply/BAT*`
を読み、`.env` の `NOTIFY_THRESHOLDS`（カンマ区切りで複数指定可）のうち
放電中に下回ったしきい値ごとに1回通知する（充電開始でリセット）。
定期実行は systemd timer（`.config/systemd/user/battery-alert.timer`）が
担い、ポーリング間隔（`.env` の `POLL_INTERVAL`）は `battery_alert.py`
自身ではなく `install.sh` が timer ユニットへ反映する
（テンプレート `__POLL_INTERVAL__` を実値で置換）。
`tests/test_battery_alert.py` に `unittest` ベースのテストがある。
詳細は [scripts/battery-alert/README.md](../../scripts/battery-alert/README.md) 参照。

## 未確認事項

1. **`.config/` / `.local/bin/` をホームディレクトリへリンクする手順が
   リポジトリ内に存在しない。**
   - 何が未確認か: dotfiles を `~/.config` 等へ配置する処理
     （シンボリックリンク作成スクリプト、`stow`/`dotbot` 等の設定）が
     このリポジトリのどこにも見つからない。
   - なぜ確定できないか: 実機ではリンクが手動で作成済みの状態
     （`readlink -f` で確認）だが、その作成コマンド自体はリポジトリの
     どのファイルにも記録されていない。
   - 何を見れば確定できるか: 今後 `install.sh` や `Makefile`、
     `README.md` 内の手順説明が追加された場合はそれを確認する。
     現時点ではユーザー本人に運用手順を確認するのが最も確実。

2. **`gnome-overview-toggle` のキーバインド割り当て
     （`Shift+Ctrl+Space`、`dconf` の `custom-keybindings/custom0`）が
     リポジトリ内のどこにも記録されていない。**
   - 何が未確認か: このキーバインドを別マシンで再現する手順。
   - なぜ確定できないか: `dconf dump` で実機の現在値を読めるのみで、
     リポジトリにはこの設定を `gsettings`/`dconf load` で復元する
     スクリプトが存在しない。
   - 何を見れば確定できるか: `t480s.sh` に該当する `gsettings set
     org.gnome.settings-daemon.plugins.media-keys.custom-keybinding`
     系の行が将来追加されればそれを参照する。

3. **過去に存在したと推測される MBP15 向けスクリプトの有無。**
   - 何が未確認か: `alacritty.toml` 内のコメント
     （`alacritty.toml:38-43`）から、過去に MBP15 用の設定が
     運用されていた可能性があるが、対応するセットアップスクリプトは
     現リポジトリに存在しない。
   - なぜ確定できないか: 本リポジトリはコマンド実行時点でコミット履歴が
     0件（`git log` が "does not have any commits yet" を返す）であり、
     `git log`/`git blame` による過去の確認ができない。
   - 何を見れば確定できるか: 別リポジトリやバックアップが存在するか、
     ユーザー本人に確認する。
