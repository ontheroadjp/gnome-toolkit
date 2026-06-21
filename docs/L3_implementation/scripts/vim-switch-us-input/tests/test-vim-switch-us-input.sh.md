# `scripts/vim-switch-us-input/tests/test-vim-switch-us-input.sh`

## Purpose

Vim plugin の `InsertLeave` autocmd が FEP switcher の D-Bus メソッドを
正しい引数で呼ぶことを検証するシェルテスト。

## Behavior

- 一時ディレクトリに偽の `dbus-send` を作成し、受け取った引数を記録する
  (`test-vim-switch-us-input.sh:7-22`)。
- isolated な Vim を Ex mode で起動し、plugin をロードして `InsertLeave` を発火する
  (`test-vim-switch-us-input.sh:23-34`)。
- destination、object path、method を含む実引数が期待値と一致することを検証する
  (`test-vim-switch-us-input.sh:36-42`)。

## Design decisions

- 実際の GNOME Shell と D-Bus サービスには接続しない。テストをデスクトップの
  セッション状態から独立させるため。
- Vim が終了しない場合に備えて `timeout` を使用する
  (`test-vim-switch-us-input.sh:23`)。

## Integration points

- テスト対象:
  `scripts/vim-switch-us-input/plugin/vim-switch-us-input.vim`。
- 実行コマンド:
  `scripts/vim-switch-us-input/tests/test-vim-switch-us-input.sh`。

## Limitations

- Vim、`timeout`、POSIX shell が必要。
- GNOME Shell による実際の入力ソース切替は検証せず、D-Bus クライアントへ渡す
  引数までを検証する。

## 変更履歴（git log より自動生成）

- 7a815b6 feat(#20): switch input source after leaving Vim Insert mode
