# リポジトリ構造

モノレポ構成ではない（`apps/` / `packages/` 等のワークスペース分割は存在しない。
トップレベルのディレクトリ・ファイルは以下のみ）。

```
.
├── install.sh                            # 全アプリ一括インストール（per-app install.sh を呼び出す）
├── t480s.sh                              # GNOME desktop 設定スクリプト
├── tests/                                # install.sh 動作検証テスト群
│   ├── test_install.sh                  # install.sh の構文・参照ファイル・呼び出し構成を検証
│   └── lint_shell.sh                    # 全 install.sh を shellcheck/bash -n で構文チェック
├── applications/
│   ├── alacritty/                        # Alacritty 設定 + install.sh
│   │   ├── alacritty.toml               # Alacritty 本体設定（→ ~/.config/alacritty/）
│   │   ├── Alacritty.desktop            # デスクトップエントリ（→ ~/.local/share/applications/）
│   │   ├── theme/
│   │   │   ├── tokyo-night.toml         # 配色テーマ（現在アクティブ）
│   │   │   ├── tokyo-night-storm.toml   # 配色テーマ（代替）
│   │   │   └── dracula.toml             # 配色テーマ（代替）
│   │   └── install.sh
│   ├── chrome/                           # Google Chrome CDPランチャー
│   ├── espanso/                          # espanso テキスト展開設定 + install.sh
│   │   ├── config/default.yml           # espanso 本体設定（→ ~/.config/espanso/）
│   │   ├── match/                       # トリガー定義
│   │   ├── espanso-toggle               # espanso トグルスクリプト
│   │   └── install.sh
│   ├── keyd/                             # keyd キーリマッパー設定 + install.sh
│   │   ├── default.conf                 # keyd 設定（→ /etc/keyd/）
│   │   └── install.sh
│   ├── mpv-player/                       # mpv music launcher（Python）+ 設定 + install.sh
│   │   ├── mpv-player.py
│   │   ├── mpv.conf                     # mpv 設定（→ ~/.config/mpv/）
│   │   ├── input.conf                   # mpv キーバインド設定
│   │   ├── install.sh
│   │   └── tests/
│   │       └── test_mpv_player.py
│   ├── youtube/                          # YouTube ランチャー
│   └── yt-dlp/                           # yt-dlp ダウンロード設定 + install.sh
│       ├── config                        # yt-dlp 設定（→ ~/.config/yt-dlp/）
│       └── install.sh
├── gnome-extensions/
│   └── gnome-overview-toggle/            # GNOME Overview トグル
│       ├── gnome-overview-toggle         # トグルスクリプト（→ ~/.local/bin/）
│       └── install.sh                   # symlink + GNOME ショートカット登録
└── scripts/
    ├── battery-alert/                    # バッテリー低下通知（Python + systemd timer）
    │   ├── battery_alert.py
    │   ├── .env.example
    │   ├── install.sh
    │   ├── README.md
    │   ├── tests/
    │   │   └── test_battery_alert.py
    │   └── .config/systemd/user/
    │       ├── battery-alert.service
    │       └── battery-alert.timer
    ├── mpv-player/                       # mpv music launcher（Python）
    │   ├── mpv-player.py
    │   ├── install.sh
    │   └── tests/
    │       └── test_mpv_player.py
    ├── voice-input/                      # whisper.cpp オフライン音声入力
    │   ├── voice-input.sh
    │   ├── install.sh
    │   ├── tests/
    │   │   └── test_voice_input.sh
    │   └── .config/systemd/user/
    │       └── voice-input-whisper.service
    ├── fep-switcher/                     # GNOME 入力ソース切替コア（D-Bus サービス）
    │   ├── extension.js
    │   └── metadata.json
    ├── app-switch-us-input/              # ウィンドウフォーカス時 US 切替クライアント
    │   ├── extension.js
    │   └── metadata.json
    ├── tmux-switch-us-input/             # tmux pane 切替時 US 切替クライアント
    │   └── switch-input-to-us
    └── vim-switch-us-input/              # Vim Insert mode 終了時 US 切替クライアント
        ├── plugin/
        │   └── vim-switch-us-input.vim
        └── tests/
            └── test-vim-switch-us-input.sh
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

### `applications/alacritty/`
`install.sh` が `~/.config/alacritty` → このディレクトリへのシンボリックリンクを作成し、
`Alacritty.desktop` を `~/.local/share/applications/` に配置する。
Alacritty のメイン設定 (`alacritty.toml`) と、3つの配色テーマファイル(`theme/*.toml`)を持つ。
`alacritty.toml` にはコメントで「T480s」と「MBP15」の2機種分のフォント設定が記載されており、
現在 T480s 用設定のみがアクティブ（MBP15 用はコメントアウト済み）。

### `applications/keyd/`
`install.sh` が `sudo ln -sf` で `/etc/keyd` → このディレクトリへのシンボリックリンクを作成する（`sudo` 必要）。

### `applications/espanso/`
`install.sh` が `~/.config/espanso` → このディレクトリへのシンボリックリンクを作成し、
`espanso-toggle` を `~/.local/bin/espanso-toggle` に配置する。
espanso が読む `config/default.yml`（`backend: Inject`）と `match/` 配下のトリガー定義を持つ。
`match/private.yml` はメールアドレス等を含むため gitignore 対象（`match/private.yml.example` からコピーして作成）。

### `applications/mpv-player/`
`install.sh` が `mpv-player.py` を `~/.local/bin/mpv-player` にリンクし、
`~/.config/mpv` → このディレクトリへのシンボリックリンクを作成する。

### `applications/yt-dlp/`
`install.sh` が `~/.config/yt-dlp` → このディレクトリへのシンボリックリンクを作成する。

### `gnome-extensions/gnome-overview-toggle/`
`install.sh` が `gnome-overview-toggle` を `~/.local/bin/gnome-overview-toggle` にリンクし、
`gsettings` で `Ctrl+Shift+Space` のカスタムキーバインドを登録する。
実行可能ビット付きの POSIX sh スクリプトで、`gdbus call` のみで
GNOME Shell の Overview 状態をトグルする外部依存のない単機能スクリプト。

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

### `scripts/fep-switcher/`
GNOME 入力ソース切替のコア拡張（`fep-switcher@local`）。
D-Bus サービス（`org.gnome.Shell.Extensions.FepSwitcher`）を公開し、
`SwitchToUs()` / `SwitchToJa()` メソッドを提供する。イベントハンドリングは持たない。
`install.sh` が `~/.local/share/gnome-shell/extensions/fep-switcher@local` へシンボリックリンクを作成する。

### `scripts/app-switch-us-input/`
ウィンドウフォーカスイベントのクライアント拡張（`app-switch-us-input@local`）。
`notify::focus-window` を監視し、端末アプリにフォーカスが移ったとき D-Bus 経由で
`fep-switcher@local` の `SwitchToUs()` を呼び出す。
`install.sh` が `~/.local/share/gnome-shell/extensions/app-switch-us-input@local` へシンボリックリンクを作成する。

### `scripts/tmux-switch-us-input/`
tmux pane 切替クライアントのシェルスクリプト。
`after-select-pane` フックから呼び出され、`gdbus call` で `fep-switcher@local` の
`SwitchToUs()` を呼び出す。
`install.sh` が `~/.local/bin/switch-input-to-us` へシンボリックリンクを作成する。
`~/.tmux.conf` への以下の行追記はユーザーが手動で行う:

```
set-hook -g after-select-pane 'run-shell "switch-input-to-us"'
```

### `scripts/vim-switch-us-input/`
Vim Insert mode 終了イベントのクライアント plugin。
`InsertLeave` autocmd から `dbus-send` を非同期実行し、D-Bus 経由で
`fep-switcher@local` の `SwitchToUs()` を直接呼び出す。
vim-plug ではリポジトリの runtime path を `scripts/vim-switch-us-input` に指定する。
`tests/test-vim-switch-us-input.sh` が偽の `dbus-send` を使って呼び出し引数を検証する。

### `scripts/mpv-player/`
`~/Music` 配下の音声/動画ファイルを検索し、`mpv --no-video` で再生する
Python 製 launcher 一式。`mpv-player.py` は起動時に main menu を表示し、
個別選択、fzf で絞り込まれた全件、前回 playlist のいずれかを再生対象にする。
新規 playlist は `~/Music/playlist/mpv-player.m3u` に上書き保存される。
`install.sh` は `mpv-player.py` を `~/.local/bin/music` へシンボリックリンク
する。`tests/test_mpv_player.py` に `unittest` ベースのテストがある。

### `scripts/voice-input/`
GNOMEカスタムショートカットで16kHzモノラルWAVの録音をトグルし、localhostの
`whisper-server` へ送信して文字起こし結果をWaylandクリップボードへコピーする。
`install.sh` はwhisper.cppとbaseモデルを配置し、モデルを常駐させる
`voice-input-whisper.service` をsystemdユーザーサービスとして有効化する。
`tests/test_voice_input.sh` は外部コマンドをモックして成功・サーバー停止時のフローを
検証する。

## 未確認事項

1. **過去に存在したと推測される MBP15 向けスクリプトの有無。**
   - 何が未確認か: `alacritty.toml` 内のコメント
     （`alacritty.toml:38-43`）から、過去に MBP15 用の設定が
     運用されていた可能性があるが、対応するセットアップスクリプトは
     現リポジトリに存在しない。
   - なぜ確定できないか: 本リポジトリはコマンド実行時点でコミット履歴が
     0件（`git log` が "does not have any commits yet" を返す）であり、
     `git log`/`git blame` による過去の確認ができない。
   - 何を見れば確定できるか: 別リポジトリやバックアップが存在するか、
     ユーザー本人に確認する。
