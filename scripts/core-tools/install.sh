#!/bin/bash
set -eu

TOTAL=9

# -----------------------------------------
echo ""
echo "[1/${TOTAL}] Installing dev tools ..."
sudo apt update && sudo apt install -y \
    build-essential \
    curl \
    unzip \
    tree \
    git \
    tmux \
    fzf \
    bat \
    vim-gtk3 \
    jq \
    yq
echo "[1/${TOTAL}] Done."

# -----------------------------------------
echo ""
echo "[2/${TOTAL}] Installing system utilities ..."
sudo apt install -y \
    hyperfine \
    rclone \
    gocryptfs

sudo apt install -y gpaste-2 gir1.2-gpaste-2 || echo "[WARN] gpaste-2 not available, skipping."
echo "[2/${TOTAL}] Done."

# -----------------------------------------
echo ""
echo "[3/${TOTAL}] Installing system monitor tools ..."
sudo apt install -y \
    htop \
    nethogs \
    iftop \
    whois \
    arp-scan
echo "[3/${TOTAL}] Done."

# -----------------------------------------
echo ""
echo "[4/${TOTAL}] Installing GNOME Shell Extension Manager ..."
sudo apt install -y gnome-shell-extension-manager
echo "[4/${TOTAL}] Done."

# -----------------------------------------
echo ""
echo "[5/${TOTAL}] Installing mise & node.js ..."
MISE_BIN="$(command -v mise 2>/dev/null || true)"
if [[ -z "${MISE_BIN}" ]]; then
    curl https://mise.run | sh
    MISE_BIN="${HOME}/.local/bin/mise"
fi
"${MISE_BIN}" use -g node@24
echo "[5/${TOTAL}] Done."

# -----------------------------------------
echo ""
echo "[6/${TOTAL}] Installing gh ..."
if ! command -v gh >/dev/null 2>&1; then
    sudo mkdir -p -m 755 /etc/apt/keyrings
    wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update
    sudo apt install gh -y
    echo "[6/${TOTAL}] Done."
else
    echo "[6/${TOTAL}] gh is already installed. Skipped."
fi

# -----------------------------------------
echo ""
echo "[7/${TOTAL}] Installing ghq ..."
if ! command -v ghq >/dev/null 2>&1; then
    cd /tmp || exit
    wget https://github.com/x-motemen/ghq/releases/latest/download/ghq_linux_amd64.zip
    unzip ghq_linux_amd64.zip
    sudo mv ghq_linux_amd64/ghq /usr/local/bin
    rm -rf ghq_linux_amd64
    rm -f ghq_linux_amd64.zip
    echo "[7/${TOTAL}] Done."
else
    echo "[7/${TOTAL}] ghq is already installed. Skipped."
fi

# -----------------------------------------
echo ""
echo "[8/${TOTAL}] Installing claude code ..."
if ! command -v claude >/dev/null 2>&1; then
    curl -fsSL https://claude.ai/install.sh | bash
    echo "[8/${TOTAL}] Done."
else
    echo "[8/${TOTAL}] claude code is already installed. Skipped."
fi

# -----------------------------------------
echo ""
echo "[9/${TOTAL}] Installing codex ..."
if ! command -v codex >/dev/null 2>&1; then
    MISE_BIN="$(command -v mise 2>/dev/null || echo "${HOME}/.local/bin/mise")"
    "${MISE_BIN}" exec node@24 -- npm install -g @openai/codex
    echo "[9/${TOTAL}] Done."
else
    echo "[9/${TOTAL}] codex is already installed. Skipped."
fi

echo ""
echo "=============================="
echo "All done. (${TOTAL}/${TOTAL})"
echo "=============================="
