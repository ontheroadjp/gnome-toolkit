#!/bin/bash
# voice-input.sh — Toggle-record → whisper.cpp transcribe → wl-copy

WHISPER_MODEL="${HOME}/.local/share/whisper-models/ggml-base.bin"
WHISPER_LANGUAGE="${VOICE_INPUT_LANGUAGE:-ja}"
WHISPER_SERVER_URL="${VOICE_INPUT_SERVER_URL:-http://127.0.0.1:8178/inference}"
RECORD_FILE="${VOICE_INPUT_RECORD_FILE:-/tmp/voice-input-record.wav}"
PID_FILE="${VOICE_INPUT_PID_FILE:-/tmp/voice-input.pid}"
NOTIFICATION_ID_FILE="${VOICE_INPUT_NOTIFICATION_ID_FILE:-/tmp/voice-input-notification.id}"
ARECORD_RATE=16000
ARECORD_CHANNELS=1
ARECORD_FORMAT="S16_LE"
NOTIFICATION_APP="Voice Input"

_notify() {
    local notification_id new_notification_id
    notification_id=$(cat "$NOTIFICATION_ID_FILE" 2>/dev/null)

    if [[ "$notification_id" =~ ^[0-9]+$ ]]; then
        new_notification_id=$(notify-send -p -r "$notification_id" \
            -a "$NOTIFICATION_APP" "$1" "$2")
    else
        new_notification_id=$(notify-send -p -a "$NOTIFICATION_APP" "$1" "$2")
    fi

    if [[ "$new_notification_id" =~ ^[0-9]+$ ]]; then
        echo "$new_notification_id" > "$NOTIFICATION_ID_FILE"
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

    if [ ! -f "$WHISPER_MODEL" ]; then
        _notify "Error" "Model not found: $WHISPER_MODEL"
        exit 1
    fi

    _notify "Transcribing..." ""

    local raw_result result
    if ! raw_result=$(curl --fail --silent --show-error \
        --form "file=@${RECORD_FILE};type=audio/wav" \
        --form "language=${WHISPER_LANGUAGE}" \
        --form "best_of=1" \
        --form "no_timestamps=true" \
        --form "response_format=text" \
        "$WHISPER_SERVER_URL"); then
        _notify "Error" "Transcription server is unavailable. Run install.sh."
        exit 1
    fi
    result=$(printf '%s' "$raw_result" | grep -v '^\[' | sed 's/^[[:space:]]*//' | tr '\n' ' ' | sed 's/[[:space:]]*$//')

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
