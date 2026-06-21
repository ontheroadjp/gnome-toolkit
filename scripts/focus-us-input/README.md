# US Input for Terminals

GNOME 46で端末ウィンドウへフォーカスが移ったとき、入力ソースを`us`へ切り替えるローカル拡張です。

## インストール

```sh
mkdir -p ~/.local/share/gnome-shell/extensions/focus-us-input@local
cp extension.js metadata.json ~/.local/share/gnome-shell/extensions/focus-us-input@local/
gnome-extensions enable focus-us-input@local
```

Waylandセッションでは、初回インストール後にログアウト・ログインしてから有効化が必要な場合があります。

対象アプリを変更する場合は、`extension.js`の`TERMINAL_IDENTIFIERS`を編集します。
