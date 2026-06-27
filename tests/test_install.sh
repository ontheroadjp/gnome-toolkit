#!/bin/bash

set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

PASS=0
FAIL=0

pass() { echo "PASS  $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL  $1"; FAIL=$((FAIL + 1)); }

INSTALL_SCRIPTS=(
    "scripts/core-tools/install.sh"
    "applications/keyd/install.sh"
    "applications/alacritty/install.sh"
    "applications/mpv-player/install.sh"
    "applications/yt-dlp/install.sh"
    "applications/espanso/install.sh"
    "applications/chrome/install.sh"
    "install.sh"
)

# -----------------------------------------
echo "--- Test 1: syntax check (shellcheck or bash -n) ---"

if command -v shellcheck >/dev/null 2>&1; then
    CHECKER="shellcheck"
else
    CHECKER="bash_n"
fi

for script in "${INSTALL_SCRIPTS[@]}"; do
    f="${REPO_DIR}/${script}"
    if [ ! -f "$f" ]; then
        fail "not found: ${script}"
        continue
    fi
    if [ "$CHECKER" = "shellcheck" ]; then
        if shellcheck "$f" 2>/dev/null; then
            pass "shellcheck: ${script}"
        else
            fail "shellcheck: ${script}"
        fi
    else
        if bash -n "$f" 2>/dev/null; then
            pass "bash -n: ${script}"
        else
            fail "bash -n: ${script}"
        fi
    fi
done

# -----------------------------------------
echo ""
echo "--- Test 2: referenced files exist ---"

check_file() {
    local label="$1" path="$2"
    [ -f "$path" ] && pass "$label" || fail "$label (not found: $path)"
}

check_file "mpv-player.py exists"         "${REPO_DIR}/applications/mpv-player/mpv-player.py"
check_file "espanso-toggle exists"        "${REPO_DIR}/applications/espanso/espanso-toggle"
check_file "google-chrome-cdp exists"     "${REPO_DIR}/applications/chrome/google-chrome-cdp"
check_file "google-chrome-cdp.desktop"   "${REPO_DIR}/applications/chrome/google-chrome-cdp.desktop"
check_file "keyd/default.conf exists"    "${REPO_DIR}/applications/keyd/default.conf"
check_file "alacritty.toml exists"       "${REPO_DIR}/applications/alacritty/alacritty.toml"
check_file "Alacritty.desktop exists"    "${REPO_DIR}/applications/alacritty/Alacritty.desktop"
check_file "yt-dlp config exists"        "${REPO_DIR}/applications/yt-dlp/config"
check_file "fep-switcher extension.js"   "${REPO_DIR}/scripts/fep-switcher/extension.js"
check_file "app-switch extension.js"     "${REPO_DIR}/scripts/app-switch-us-input/extension.js"
check_file "switch-input-to-us exists"   "${REPO_DIR}/scripts/tmux-switch-us-input/switch-input-to-us"

# -----------------------------------------
echo ""
echo "--- Test 3: install.sh calls all per-app scripts ---"

EXPECTED_CALLS=(
    "scripts/core-tools/install.sh"
    "applications/keyd/install.sh"
    "applications/alacritty/install.sh"
    "applications/mpv-player/install.sh"
    "applications/yt-dlp/install.sh"
    "applications/espanso/install.sh"
    "applications/chrome/install.sh"
)

ROOT_INSTALL="${REPO_DIR}/install.sh"
for expected in "${EXPECTED_CALLS[@]}"; do
    if grep -qF "${expected}" "$ROOT_INSTALL"; then
        pass "install.sh calls: ${expected}"
    else
        fail "install.sh missing call: ${expected}"
    fi
done

# -----------------------------------------
echo ""
echo "--- Test 4: tool coverage (old t480s-apps-install.sh → new scripts) ---"

NEW_SCRIPTS_CONTENT=$(cat \
    "${REPO_DIR}/scripts/core-tools/install.sh" \
    "${REPO_DIR}/applications/keyd/install.sh" \
    "${REPO_DIR}/applications/mpv-player/install.sh" \
    "${REPO_DIR}/applications/yt-dlp/install.sh" \
    "${REPO_DIR}/applications/espanso/install.sh" \
    "${REPO_DIR}/applications/chrome/install.sh")

TOOLS=(
    build-essential tmux fzf bat vim-gtk3 jq
    hyperfine rclone gocryptfs htop nethogs
    keyd mise ghq claude codex
    google-chrome yt-dlp espanso ffmpeg mpv
    gnome-shell-extension-manager
)

for tool in "${TOOLS[@]}"; do
    if echo "${NEW_SCRIPTS_CONTENT}" | grep -q "${tool}"; then
        pass "covered: ${tool}"
    else
        fail "not covered: ${tool}"
    fi
done

# -----------------------------------------
echo ""
echo "--- Test 5: t480s-apps-install.sh is removed ---"

OLD_SCRIPT="${REPO_DIR}/t480s/t480s-apps-install.sh"
if [ ! -f "$OLD_SCRIPT" ]; then
    pass "t480s-apps-install.sh removed"
else
    fail "t480s-apps-install.sh still exists"
fi

# -----------------------------------------
echo ""
echo "=============================="
echo "Results: ${PASS} passed, ${FAIL} failed"
echo "=============================="
[ "$FAIL" -eq 0 ]
