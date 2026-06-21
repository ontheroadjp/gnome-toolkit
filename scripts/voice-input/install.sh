#!/bin/bash
# install.sh — Build whisper.cpp, download base model, register GNOME shortcut

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WHISPER_INSTALL_DIR="${HOME}/.local/lib/whisper.cpp"
WHISPER_SERVER_BIN="${WHISPER_INSTALL_DIR}/build/bin/whisper-server"
MODEL_DIR="${HOME}/.local/share/whisper-models"
MODEL_FILE="${MODEL_DIR}/ggml-base.bin"
MODEL_URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin"
VOICE_INPUT_SCRIPT="${REPO_DIR}/voice-input.sh"
SERVICE_SOURCE="${REPO_DIR}/.config/systemd/user/voice-input-whisper.service"
SYSTEMD_USER_DIR="${HOME}/.config/systemd/user"
SHORTCUT_BINDING="<Control><Shift>equal"
SHORTCUT_NAME="Voice Input"
DCONF_BASE="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"

_check_deps() {
    local missing=()
    for cmd in git cmake make gcc arecord curl wl-copy notify-send systemctl; do
        command -v "$cmd" &>/dev/null || missing+=("$cmd")
    done
    if [ ${#missing[@]} -gt 0 ]; then
        echo "ERROR: Missing dependencies: ${missing[*]}" >&2
        echo "Install with: sudo apt install build-essential cmake libasound2-dev curl wl-clipboard libnotify-bin git" >&2
        exit 1
    fi
}

_build_whisper() {
    if { [ -x "${WHISPER_INSTALL_DIR}/build/bin/whisper-cli" ] || \
         [ -x "${WHISPER_INSTALL_DIR}/build/bin/main" ]; } && \
       [ -x "$WHISPER_SERVER_BIN" ]; then
        echo "whisper.cpp already built, skipping."
        return
    fi

    echo "Cloning whisper.cpp..."
    if [ -d "$WHISPER_INSTALL_DIR" ]; then
        git -C "$WHISPER_INSTALL_DIR" pull --ff-only
    else
        git clone --depth 1 https://github.com/ggml-org/whisper.cpp.git "$WHISPER_INSTALL_DIR"
    fi

    echo "Building whisper.cpp..."
    cmake -B "${WHISPER_INSTALL_DIR}/build" -S "$WHISPER_INSTALL_DIR" \
        -DCMAKE_BUILD_TYPE=Release -DWHISPER_BUILD_EXAMPLES=ON
    cmake --build "${WHISPER_INSTALL_DIR}/build" --config Release -j"$(nproc)"
    echo "Build complete."
}

_install_whisper_service() {
    mkdir -p "$SYSTEMD_USER_DIR"
    ln -sf "$SERVICE_SOURCE" "$SYSTEMD_USER_DIR/voice-input-whisper.service"
    systemctl --user daemon-reload
    systemctl --user enable --now voice-input-whisper.service
    echo "Whisper server service enabled and started."
}

_download_model() {
    if [ -f "$MODEL_FILE" ]; then
        echo "Model already exists: $MODEL_FILE"
        return
    fi
    mkdir -p "$MODEL_DIR"
    echo "Downloading ggml-base model (~142 MB)..."
    curl -L --progress-bar -o "$MODEL_FILE" "$MODEL_URL"
    echo "Model saved to $MODEL_FILE"
}

_register_gnome_shortcut() {
    if ! command -v gsettings &>/dev/null; then
        echo "gsettings not found, skipping GNOME shortcut registration."
        return
    fi

    local existing_list
    existing_list=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null || echo "@as []")

    # Skip if this script is already registered (idempotent)
    local idx=0
    while [[ "$existing_list" == *"${DCONF_BASE}/custom${idx}/"* ]]; do
        local slot_cmd
        slot_cmd=$(gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"${DCONF_BASE}/custom${idx}/" command 2>/dev/null || echo "")
        if [[ "$slot_cmd" == *"voice-input.sh"* ]]; then
            echo "GNOME shortcut already registered at ${DCONF_BASE}/custom${idx}/, skipping."
            return
        fi
        idx=$((idx + 1))
    done

    local slot="${DCONF_BASE}/custom${idx}/"

    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"${slot}" \
        name "$SHORTCUT_NAME"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"${slot}" \
        command "${VOICE_INPUT_SCRIPT} toggle"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"${slot}" \
        binding "$SHORTCUT_BINDING"

    # Append new slot to the list
    local new_list
    if [ "$existing_list" = "@as []" ] || [ "$existing_list" = "[]" ]; then
        new_list="['${slot}']"
    else
        new_list="${existing_list%]}, '${slot}']"
    fi
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$new_list"

    echo "GNOME shortcut registered: ${SHORTCUT_BINDING} → ${VOICE_INPUT_SCRIPT} toggle"
    echo "Slot: ${slot}"
}

chmod +x "$VOICE_INPUT_SCRIPT"

echo "==> Checking dependencies..."
_check_deps

echo "==> Building whisper.cpp..."
_build_whisper

echo "==> Downloading model..."
_download_model

echo "==> Installing whisper server service..."
_install_whisper_service

echo "==> Registering GNOME shortcut..."
_register_gnome_shortcut

echo ""
echo "Installation complete."
echo "  Shortcut : Ctrl+Shift+= (${SHORTCUT_BINDING})"
echo "  Script   : ${VOICE_INPUT_SCRIPT}"
echo "  Model    : ${MODEL_FILE}"
echo "  Service  : voice-input-whisper.service"
echo ""
echo "Usage: Press Ctrl+Shift+= to start recording, press again to stop and transcribe."
echo "       Result is copied to clipboard — press Ctrl+V to paste."
echo "       Set VOICE_INPUT_LANGUAGE=auto to enable language detection (slower)."
