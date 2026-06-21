#!/bin/bash
# voice-input.sh — Toggle-record → whisper.cpp transcribe → wl-copy

WHISPER_BIN_DIR="${HOME}/.local/lib/whisper.cpp/build/bin"
WHISPER_MODEL="${HOME}/.local/share/whisper-models/ggml-base.bin"
RECORD_FILE="/tmp/voice-input-record.wav"
PID_FILE="/tmp/voice-input.pid"
ARECORD_RATE=16000
ARECORD_CHANNELS=1
ARECORD_FORMAT="S16_LE"
NOTIFICATION_APP="Voice Input"

_notify() {
    notify-send -a "$NOTIFICATION_APP" "$1" "$2"
}

_whisper_bin() {
    if [ -x "${WHISPER_BIN_DIR}/whisper-cli" ]; then
        echo "${WHISPER_BIN_DIR}/whisper-cli"
    elif [ -x "${WHISPER_BIN_DIR}/main" ]; then
        echo "${WHISPER_BIN_DIR}/main"
    else
        echo ""
    fi
}

_start_recording() {
    rm -f "$RECORD_FILE"
    arecord -f "$ARECORD_FORMAT" -r "$ARECORD_RATE" -c "$ARECORD_CHANNELS" \
        -t wav "$RECORD_FILE" &>/dev/null &
    echo $! > "$PID_FILE"
    _notify "Recording..." "Speak now. Press shortcut again to stop."
}

_stop_and_transcribe() {
    local pid
    pid=$(cat "$PID_FILE" 2>/dev/null)

    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
        kill "$pid"
        wait "$pid" 2>/dev/null
    fi
    rm -f "$PID_FILE"

    if [ ! -f "$RECORD_FILE" ]; then
        _notify "Error" "No recording found."
        exit 1
    fi

    local whisper_bin
    whisper_bin=$(_whisper_bin)
    if [ -z "$whisper_bin" ]; then
        _notify "Error" "whisper-cli not found. Run install.sh first."
        exit 1
    fi

    if [ ! -f "$WHISPER_MODEL" ]; then
        _notify "Error" "Model not found: $WHISPER_MODEL"
        exit 1
    fi

    _notify "Transcribing..." ""

    local result
    result=$("$whisper_bin" \
        --model "$WHISPER_MODEL" \
        --language auto \
        --no-timestamps \
        --no-prints \
        --file "$RECORD_FILE" \
        2>/dev/null | grep -v '^\[' | sed 's/^[[:space:]]*//' | tr '\n' ' ' | sed 's/[[:space:]]*$//')

    if [ -z "$result" ]; then
        _notify "Done" "(empty — nothing recognized)"
        exit 0
    fi

    echo -n "$result" | wl-copy
    _notify "Copied to clipboard" "$result"
    rm -f "$RECORD_FILE"
}

_toggle() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        _stop_and_transcribe
    else
        _start_recording
    fi
}

case "${1:-toggle}" in
    toggle) _toggle ;;
    start)  _start_recording ;;
    stop)   _stop_and_transcribe ;;
    *)
        echo "Usage: $(basename "$0") [toggle|start|stop]" >&2
        exit 1
        ;;
esac
