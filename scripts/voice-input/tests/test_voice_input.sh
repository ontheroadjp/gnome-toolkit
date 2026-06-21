#!/bin/bash

set -euo pipefail

TEST_DIR=$(mktemp -d)
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
export HOME="${TEST_DIR}/home"
export TEST_CLIPBOARD_FILE="${TEST_DIR}/clipboard.txt"
export TEST_CURL_ARGS_FILE="${TEST_DIR}/curl-args.txt"
export TEST_NOTIFICATION_FILE="${TEST_DIR}/notifications.txt"
export VOICE_INPUT_RECORD_FILE="${TEST_DIR}/record.wav"
export VOICE_INPUT_PID_FILE="${TEST_DIR}/record.pid"
export VOICE_INPUT_NOTIFICATION_ID_FILE="${TEST_DIR}/notification.id"

cleanup() {
    local recorder_pid
    recorder_pid=$(cat "$VOICE_INPUT_PID_FILE" 2>/dev/null || true)
    if [ -n "$recorder_pid" ] && kill -0 "$recorder_pid" 2>/dev/null; then
        kill "$recorder_pid"
    fi
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

arecord() {
    local output_file="${*: -1}"
    : > "$output_file"
    trap 'exit 0' TERM INT
    while true; do
        sleep 1
    done
}

curl() {
    printf '%s\n' "$@" > "$TEST_CURL_ARGS_FILE"
    if [ "${TEST_CURL_SHOULD_FAIL:-0}" = "1" ]; then
        return 7
    fi
    printf '%s\n' "テスト入力"
}

notify-send() {
    printf '%s\n' "$*" >> "$TEST_NOTIFICATION_FILE"
    printf '%s\n' "42"
}

wl-copy() {
    tee "$TEST_CLIPBOARD_FILE" >/dev/null
}

export -f arecord curl notify-send wl-copy

mkdir -p "$HOME/.local/share/whisper-models"
touch "$HOME/.local/share/whisper-models/ggml-base.bin"

"$SCRIPT_DIR/voice-input.sh" start
recorder_pid=$(cat "$VOICE_INPUT_PID_FILE")
kill -0 "$recorder_pid"
test -f "$VOICE_INPUT_RECORD_FILE"

"$SCRIPT_DIR/voice-input.sh" stop

test "$(cat "$TEST_CLIPBOARD_FILE")" = "テスト入力"
grep -Fx -- "http://127.0.0.1:8178/inference" "$TEST_CURL_ARGS_FILE"
grep -Fx -- "language=ja" "$TEST_CURL_ARGS_FILE"
grep -Fx -- "response_format=text" "$TEST_CURL_ARGS_FILE"
test ! -e "$VOICE_INPUT_PID_FILE"
test ! -e "$VOICE_INPUT_RECORD_FILE"

: > "$VOICE_INPUT_RECORD_FILE"
export TEST_CURL_SHOULD_FAIL=1
if "$SCRIPT_DIR/voice-input.sh" stop; then
    echo "voice-input should fail when the transcription server is unavailable" >&2
    exit 1
fi
grep -F -- "Transcription server is unavailable" "$TEST_NOTIFICATION_FILE"

echo "voice-input integration test passed"
