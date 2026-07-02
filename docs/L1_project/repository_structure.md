# リポジトリ構造

モノレポ構成ではない（`apps/` / `packages/` 等のワークスペース分割は存在しない。
トップレベルのディレクトリ・ファイルは以下のみ）。

```
.
├── install-all.sh                        # 全アプリ一括インストール（per-app install.sh を呼び出す）
├── tests/                                # install-all.sh 動作検証テスト群
│   ├── test_install.sh                  # install-all.sh の構文・参照ファイル・呼び出し構成を検証
│   └── lint_shell.sh                    # 全 install.sh / install-all.sh を shellcheck/bash -n で構文チェック
├── applications/
│   ├── alacritty/                        # Alacritty 設定 + install.sh
│   │   ├── alacritty.toml               # Alacritty 本体設定（→ ~/.config/alacritty/）
│   │   ├── theme/
│   │   │   ├── tokyo-night.toml         # 配色テーマ（現在アクティブ）
│   │   │   ├── tokyo-night-storm.toml   # 配色テーマ（代替）
│   │   │   └── dracula.toml             # 配色テーマ（代替）
│   │   └── install.sh
│   ├── chrome/                           # Google Chrome CDPランチャー + install.sh
│   │   ├── google-chrome-cdp            # CDPオプション付きランチャースクリプト
│   │   ├── google-chrome-cdp.desktop    # デスクトップエントリ
│   │   └── install.sh
│   ├── espanso/                          # espanso テキスト展開設定 + install.sh
│   │   ├── config/default.yml           # espanso 本体設定（→ ~/.config/espanso/）
│   │   ├── match/                       # トリガー定義
│   │   ├── espanso-toggle               # espanso トグルスクリプト
│   │   └── install.sh
│   ├── keyd/                             # keyd キーリマッパー設定 + install.sh
│   │   ├── default.conf                 # keyd 設定（→ /etc/keyd/）
│   │   └── install.sh
│   ├── mpv-player/                       # mpv music/video launcher（Python）+ 設定 + install.sh
│   │   ├── mpv-player.py
│   │   ├── mpv.conf                     # mpv 設定（→ ~/.config/mpv/）
│   │   ├── input.conf                   # mpv キーバインド設定
│   │   ├── install.sh
│   │   └── tests/
│   │       └── test_mpv_player.py
│   ├── youtube/                          # YouTube ランチャー + install.sh
│   └── yt-dlp/                           # yt-dlp ダウンロード設定 + install.sh
│       ├── config                        # yt-dlp 設定（→ ~/.config/yt-dlp/）
│       └── install.sh
├── gnome-extensions/
│   ├── gnome-overview-toggle/            # GNOME Overview トグル
│   │   ├── gnome-overview-toggle         # トグルスクリプト（→ ~/.local/bin/）
│   │   └── install.sh                   # symlink + GNOME ショートカット登録
│   └── search-light/                     # search-light 拡張インストーラ
│       ├── trigger-search-light
│       └── install.sh
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
    ├── core-gnome-settings/              # 機種不問の GNOME 設定（gsettings）
    │   ├── apply-settings.sh            # gsettings 一括適用（sudo 不要）
    │   └── README.md
    ├── core-t480s-settings/              # ThinkPad 固有設定（thinkpad_acpi 必須）
    │   ├── apply-settings.sh            # バッテリー充電閾値設定（sudo 必須）
    │   └── README.md
    ├── core-tools/                       # 汎用CLIツール一括インストール（設定ファイルなし）
    │   └── install.sh
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

### `install-all.sh`（ルート）
全アプリの一括インストールオーケストレータ。`scripts/core-tools/install.sh` を最初に呼び出し、
次いで `applications/{keyd,alacritty,mpv-player,yt-dlp,espanso,chrome}/install.sh` を順に実行する
（`install-all.sh:13-38`、全 `applications/*/` のうち `youtube/` は含まれない）。最後に GNOME 拡張（fep-switcher,
app-switch-us-input）のシンボリックリンク作成・有効化と tmux-switch-us-input のリンクを張る。
core-gnome-settings / core-t480s-settings は手動実行が必要な旨を表示する。
`applications/youtube/install.sh`・`gnome-extensions/search-light/install.sh`・
`gnome-extensions/gnome-overview-toggle/install.sh` はいずれも個別実行が必要
（`install-all.sh` 全体を確認済み）。

### `scripts/core-gnome-settings/apply-settings.sh`
全行 `gsettings set/reset` で構成される（`apply-settings.sh:6-51`）。
GNOME のアニメーション・キーボード・キーバインド・ワークスペース切替・フォントレンダリングを設定する。
`sudo` 不要、機種を問わず利用可能。

### `scripts/core-t480s-settings/apply-settings.sh`
ThinkPad 固有の sysfs 属性（`/sys/class/power_supply/BAT0/charge_start_threshold`・
`charge_stop_threshold`）へ `sudo tee` で充電閾値を書き込む（`apply-settings.sh:8-9`）。
`thinkpad_acpi` カーネルモジュールが提供するため ThinkPad 専用。再起動後は設定がリセットされる。
末尾のコメント（`apply-settings.sh:12-19`）に `tlp` を使った永続化手順がメモされているが、
実行コードではない（コメントアウト済み）。

### `applications/alacritty/`
`install.sh` が `~/.config/alacritty` → このディレクトリへのシンボリックリンクを作成する。
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
`install.sh` が `mpv-player.py` を `~/.local/bin/mpv-player` にリンクし（コマンド名は
`mpv-player`、`music`/`video` を引数に取る）、`~/.config/mpv` → このディレクトリへの
シンボリックリンクを作成する。
`tests/test_mpv_player.py` に `unittest` ベースのテストがある（21件）。

### `applications/yt-dlp/`
`install.sh` が `~/.config/yt-dlp` → このディレクトリへのシンボリックリンクを作成する。

### `applications/chrome/`
CDPオプション付きでGoogle Chromeを起動するランチャースクリプト（`google-chrome-cdp`）と
デスクトップエントリを提供する。`install.sh` がこれらを `~/.local/bin/` と
`~/.local/share/applications/` に配置する。未インストール時は `google-chrome-stable_current_amd64.deb`
を `wget` で取得し `sudo apt install` する（`install.sh:8-13`）。
ルートの `install-all.sh:38` から呼び出される。

### `applications/youtube/`
Chrome DevTools Protocol (CDP) 経由で YouTube タブを開閉・再利用する CLI ランチャー
（`youtube`）。`applications/chrome/` の `google-chrome-cdp`（`localhost:9222`）に接続し、
既存の YouTube タブがあれば `Page.navigate` で遷移、なければ `google-chrome-cdp` を新規起動する
（`youtube:9-44`）。`install.sh` が `~/.local/bin/` と `~/.local/share/applications/` に配置する。
ルートの `install-all.sh` からは呼び出されない（個別実行が必要）。

### `gnome-extensions/gnome-overview-toggle/`
`install.sh` が `gnome-overview-toggle` を `~/.local/bin/gnome-overview-toggle` にリンクし、
`gsettings` でカスタムキーバインドを登録する。
実行可能ビット付きの POSIX sh スクリプトで、`gdbus call` のみで
GNOME Shell の Overview 状態をトグルする外部依存のない単機能スクリプト。
（ルートの `install-all.sh` ではコメントアウトされており、個別実行が必要）

### `gnome-extensions/search-light/`
入力ソースを US に切り替えてから GNOME Shell の search-light 拡張オーバーレイをトグルする
スクリプト（`trigger-search-light`）。`gdbus` で `fep-switcher@local` の `SwitchToUs()` を
呼んだ後、50ms 待機し `org.gnome.Shell.Eval` 経由で `searchLight._toggle_search_light()` を
実行する（`trigger-search-light:1-15`）。`fep-switcher@local` と外部の search-light 拡張機能
（本リポジトリ外で別途インストール）の両方が有効であることが前提。
`install.sh` が `~/.local/bin/trigger-search-light` へシンボリックリンクを作成する。
ルートの `install-all.sh` からは呼び出されない（個別実行が必要）。

### `scripts/core-tools/`
このリポジトリに設定ファイルが存在しない汎用CLIツールのパッケージインストールを担う。
`apt`（build-essential, tmux, fzf, bat, vim-gtk3 等）、条件付きインストール（mise, gh,
ghq, Claude Code, Codex CLI）を9ステップで実行する。
設定ファイルの配置（symlink）は行わない。

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

### `scripts/fep-switcher/`
GNOME 入力ソース切替のコア拡張（`fep-switcher@local`）。
D-Bus サービス（`org.gnome.Shell.Extensions.FepSwitcher`）を公開し、
`SwitchToUs()` / `SwitchToJa()` メソッドを提供する。イベントハンドリングは持たない。
`install-all.sh`（ルート）が `~/.local/share/gnome-shell/extensions/fep-switcher@local` へシンボリックリンクを作成する。

### `scripts/app-switch-us-input/`
ウィンドウフォーカスイベントのクライアント拡張（`app-switch-us-input@local`）。
`notify::focus-window` を監視し、端末アプリにフォーカスが移ったとき D-Bus 経由で
`fep-switcher@local` の `SwitchToUs()` を呼び出す。
`install-all.sh`（ルート）が `~/.local/share/gnome-shell/extensions/app-switch-us-input@local` へシンボリックリンクを作成する。

### `scripts/tmux-switch-us-input/`
tmux pane 切替クライアントのシェルスクリプト。
`after-select-pane` フックから呼び出され、`gdbus call` で `fep-switcher@local` の
`SwitchToUs()` を呼び出す。
`install-all.sh`（ルート）が `~/.local/bin/switch-input-to-us` へシンボリックリンクを作成する。
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

### `scripts/voice-input/`
GNOMEカスタムショートカットで16kHzモノラルWAVの録音をトグルし、localhostの
`whisper-server` へ送信して文字起こし結果をWaylandクリップボードへコピーする。
`install.sh` はwhisper.cppとbaseモデルを配置し、モデルを常駐させる
`voice-input-whisper.service` をsystemdユーザーサービスとして有効化する。
`tests/test_voice_input.sh` は外部コマンドをモックして成功・サーバー停止時のフローを
検証する。

### `tests/`
リポジトリ全体の整合性を手動実行で検証するテスト群。
- `test_install.sh`: 全 `install.sh` / `install-all.sh` の構文チェック（shellcheck/bash -n）、
  参照ファイルの実在確認、`install-all.sh` が全 per-app スクリプトを呼び出していることの確認、
  ツールカバレッジ確認、`t480s-apps-install.sh` 削除確認（5テストスイート）
- `lint_shell.sh`: リポジトリ内全 `install.sh` を shellcheck または bash -n で構文チェック

## 未確認事項

1. **過去に存在したと推測される MBP15 向けスクリプトの有無。**
   - 何が未確認か: `applications/alacritty/alacritty.toml` 内のコメント
     （`alacritty.toml:38-43`）から、過去に MBP15 用の設定が
     運用されていた可能性があるが、対応するセットアップスクリプトは
     現リポジトリに存在しない。
   - なぜ確定できないか: git 履歴から `t480s-apps-install.sh` の削除が
     `0cbdcf8 chore: move t480s scripts into t480s/ subdirectory` で確認できるが、
     MBP15 向けスクリプトの有無は履歴を詳細に辿る必要がある。
   - 何を見れば確定できるか: `git log --all --full-history -- '*MBP*' '*mbp*'` で確認可能。
