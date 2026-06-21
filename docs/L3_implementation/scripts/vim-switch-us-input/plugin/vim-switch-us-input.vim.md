# `scripts/vim-switch-us-input/plugin/vim-switch-us-input.vim`

## Purpose

Vim が Insert mode を離れたとき、GNOME の入力ソースを US に切り替える
Vim plugin。

## Behavior

- 二重ロードを防止する loaded guard を設定する
  (`vim-switch-us-input.vim:1-4`)。
- `InsertLeave` autocmd から script-local 関数を呼ぶ
  (`vim-switch-us-input.vim:30-33`)。
- `dbus-send` で
  `org.gnome.Shell.Extensions.FepSwitcher.SwitchToUs` を呼ぶ
  (`vim-switch-us-input.vim:6-13`)。
- `job_start()` を使い、stdin/stdout/stderr を切り離してバックグラウンド実行する
  (`vim-switch-us-input.vim:15-28`)。

## Design decisions

- tmux 用クライアントを経由せず、Vim plugin から FEP switcher の D-Bus
  メソッドを直接呼ぶ。各イベントクライアントを独立させるため。
- reply を待たない `dbus-send` と `InsertLeave` を使用する。入力ソース切替によって
  Insert mode からの遷移を遅延させないため。
- D-Bus サービス停止時のエラーは編集操作へ表示しない。入力ソース切替は
  best-effort とし、Vim の操作継続を優先するため
  (`vim-switch-us-input.vim:21-27`)。

## Integration points

- 呼び出し元: Vim の `InsertLeave` イベント。
- 呼び出し先: session bus 上の
  `org.gnome.Shell.Extensions.FepSwitcher` D-Bus サービス。
- runtime path: vim-plug などから `scripts/vim-switch-us-input` を追加する。

## Limitations

- `job_start()` を持つ `+job` 対応 Vim が必要。非対応時はエラーを表示する
  (`vim-switch-us-input.vim:16-19`)。
- `dbus-send` と `fep-switcher@local` GNOME Shell extension が必要。
- `InsertLeave` は Insert mode の終了後に発火するため、切替完了は非同期となる。

## 変更履歴（git log より自動生成）

- 7a815b6 feat(#20): switch input source after leaving Vim Insert mode
