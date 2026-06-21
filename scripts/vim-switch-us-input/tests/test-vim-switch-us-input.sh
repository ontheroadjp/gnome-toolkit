#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PLUGIN_ROOT=$(dirname "$SCRIPT_DIR")
TEST_DIR=$(mktemp -d)
DBUS_SEND_LOG="$TEST_DIR/dbus-send.log"

cleanup() {
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

mkdir "$TEST_DIR/bin"
cat >"$TEST_DIR/bin/dbus-send" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >"$DBUS_SEND_LOG"
EOF
chmod +x "$TEST_DIR/bin/dbus-send"

export DBUS_SEND_LOG
PATH="$TEST_DIR/bin:$PATH" timeout 10s vim \
    -Nu NONE \
    -U NONE \
    -i NONE \
    -n \
    -X \
    -es \
    "+set runtimepath^=$PLUGIN_ROOT" \
    '+runtime plugin/vim-switch-us-input.vim' \
    '+doautocmd InsertLeave' \
    '+sleep 100m' \
    '+quitall!'

EXPECTED_ARGS='--session --type=method_call --dest=org.gnome.Shell.Extensions.FepSwitcher /org/gnome/Shell/Extensions/FepSwitcher org.gnome.Shell.Extensions.FepSwitcher.SwitchToUs'
ACTUAL_ARGS=$(cat "$DBUS_SEND_LOG")

if [ "$ACTUAL_ARGS" != "$EXPECTED_ARGS" ]; then
    printf 'unexpected dbus-send arguments:\n%s\n' "$ACTUAL_ARGS" >&2
    exit 1
fi

printf 'vim-switch-us-input test passed\n'
