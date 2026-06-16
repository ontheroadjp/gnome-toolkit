# 運用モデル（ローカル実行手順）

CI が存在しないため（`.github/` 不在を確認済み）、以下はすべて
リポジトリ内のスクリプトを直接読み、その内容から逆引きした手順である。

## 前提

- 対象OS: Ubuntu系（`apt` が使えること）。根拠: `t480s_apps.sh:9,29,39` が
  すべて `sudo apt install` を呼んでいる。
- 対象デスクトップ: GNOME Shell。根拠: `t480s.sh` の `org.gnome.*` schema、
  `.local/bin/gnome-overview-toggle` の `org.gnome.Shell` DBus呼び出し。
- 実行権限: 両スクリプトとも実行可能ビット付き
  （`ls -la` で `rwxrwxr-x` を確認済み）。

## 1. パッケージ・ツールのセットアップ

```bash
./t480s_apps.sh
```

- `sudo` を要求するため対話的に実行すること（`t480s_apps.sh:9` 等）。
- `curl | sh` 形式のインストーラ（mise: `t480s_apps.sh:60`、
  claude code: `t480s_apps.sh:94`）を含むため、ネットワーク接続が必要。
- 各ツールは `command -v` で存在確認後にインストールするため、
  再実行しても重複インストールにはならない設計（`t480s_apps.sh:47,67,
  80,93,101,109,121`）。ただし apt 系のパッケージ（`t480s_apps.sh:9-20,
  29-33,39-42`）には存在チェックがなく、`apt install` の冪等性に依存する。

## 2. GNOME デスクトップ設定の適用

```bash
./t480s.sh
```

- `sudo` を要求する箇所がある（バッテリー充電閾値、`t480s.sh:53-54`）。
  これは `BAT0` という `/sys/class/power_supply/` 配下のデバイス名に
  依存しており、T480s 以外の機種やバッテリー名が異なる環境では
  失敗する可能性がある（未確認: `BAT0` という名前が他機種でも
  共通かどうかは本リポジトリの範囲では検証していない）。
- バッテリー充電閾値を再起動後も永続化させたい場合は、
  `t480s.sh:56-64` のコメントに `tlp` パッケージを使う手順がメモされて
  いるが、これは実行コードではなく手動対応が必要。

## 3. dotfiles のリンク配置

`.config/alacritty/` と `.local/bin/gnome-overview-toggle` を
`~/.config/alacritty`、`~/.local/bin/gnome-overview-toggle` として
利用するには、シンボリックリンクを作成する。

```bash
ln -s "$(pwd)/.config/alacritty" ~/.config/alacritty
ln -s "$(pwd)/.local/bin/gnome-overview-toggle" ~/.local/bin/gnome-overview-toggle
```

このリンク作成コマンド自体はリポジトリのどのスクリプトにも
含まれていない（未確認事項。
[repository_structure.md](../L1_project/repository_structure.md) の
未確認事項 1 を参照）。上記コマンドは実機の現在のリンク先
（`readlink -f` で確認した実際のパス）から逆算した手順であり、
リポジトリ内に明文化された「公式手順」ではない点に注意。

## 4. Alacritty テーマの切り替え

`.config/alacritty/alacritty.toml:5-6` の `import` 行を編集し、
コメントアウトを入れ替えることで切り替える（GUIやコマンドでの
切り替え機構はない。手動でファイルを編集する運用）。

```toml
import = ["~/.config/alacritty/theme/tokyo-night.toml"]
#import = ["~/.config/alacritty/theme/dracula.toml"]
```

`live_config_reload = true`（`alacritty.toml:9`）のため、保存すると
起動中の Alacritty に即時反映される。

## 5. battery-alert のインストール

```bash
cd scripts/battery-alert
cp .env.example .env   # 必要に応じてしきい値・ポーリング間隔を編集
./install.sh
systemctl --user daemon-reload
systemctl --user enable --now battery-alert.timer
```

- `install.sh` は `battery_alert.py` と `battery-alert.service` を
  `~/.local/bin/`・`~/.config/systemd/user/` へシンボリックリンクし、
  `.env` の `POLL_INTERVAL` を `battery-alert.timer` のテンプレートに
  反映して書き出す。`sudo` は不要。
- `.env` を変更した場合は `install.sh` を再実行しないと
  `POLL_INTERVAL` が systemd timer に反映されない
  （`scripts/battery-alert/README.md` 参照）。

## 6. mpv music launcher のインストールと実行

```bash
scripts/mpv-player/install.sh
music
```

- `install.sh` は `scripts/mpv-player/mpv-player.py` を
  `~/.local/bin/music` へシンボリックリンクする。`sudo` は不要。
- `music` は起動時に main menu を表示し、`~/Music` 配下の音声/動画ファイル
  から playlist を作成する。メニュー 2 では fzf で絞り込まれた候補全件を
  playlist に入れる。
- playlist は `~/Music/playlist/mpv-player.m3u` に上書き保存される。
- 再生は `mpv --no-video` で実行される。

## ビルド・テストについて

リポジトリ全体としてのビルドプロセス・CIは存在しない（`.github/` 不在を
確認済み）。`scripts/battery-alert/` と `scripts/mpv-player/` には
`unittest` ベースのテストがあり、以下で実行できる
（追加インストール不要、標準ライブラリのみ）。

```bash
cd scripts/battery-alert
python3 -m unittest discover -s tests

cd ../../scripts/mpv-player
python3 -m unittest discover -s tests
```

それ以外のスクリプト（`t480s.sh` 等）にはテストスイートが存在せず、
動作確認はスクリプト実行後に GNOME の実際の挙動を目視で確認する運用と
推測される（未確認: 目視確認の具体的なチェックリストはリポジトリ内に
存在しない）。
