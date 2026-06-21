#!/bin/bash

TOTAL=14

# -----------------------------------------
echo ""
echo "[1/${TOTAL}] Installing dev tools ..."
# unzip: needed for ghq install below
# gh removed here — installed via GitHub keyring below for latest version
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
# rofi          launcher    # deprected
# hyperfine     benchmaker
# rclone        google drive / dropbox
# gocryptfs     encript dir
# - gocryptfs ~/hoge.env ~/hoge     # mount
# - fusermount -u ~/hoge            # unmount
echo ""
echo "[2/${TOTAL}] Installing system utilities ..."
sudo apt install -y \
    hyperfine \
    rclone \
    gocryptfs

# gpaste-2: may not be available in all Ubuntu 24.04 setups
# gpaste-2 gir1.2-gpaste-2          # clipboard history
sudo apt install -y gpaste-2 gir1.2-gpaste-2 || echo "[WARN] gpaste-2 not available, skipping."
echo "[2/${TOTAL}] Done."

# -----------------------------------------
# htop:     Monitoring CPU and Memory Usage
# nethogs:  Monitor network traffic by process
# iftop:    Monitor network traffic by destination
# whois:    Perform a DNS reverse lookup
# arp-scan: List devices on the network
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
# ffmpeg        encoder
# mpv           music player
# yt-dlp removed here — installed via wget below for latest version
echo ""
echo "[4/${TOTAL}] Installing applications (ffmpeg, mpv) ..."
sudo apt install -y \
    ffmpeg \
    mpv
echo "[4/${TOTAL}] Done."

# -----------------------------------------
echo ""
echo "[5/${TOTAL}] Installing GNOME Shell Extension Manager ..."
sudo apt install -y gnome-shell-extension-manager
echo "[5/${TOTAL}] Done."

# -----------------------------------------
# sudo keyd monitor
echo ""
echo "[6/${TOTAL}] Installing keyd ..."
if ! command -v keyd >/dev/null 2>&1; then
    sudo add-apt-repository ppa:keyd-team/ppa
    sudo apt update
    sudo apt install keyd
    sudo systemctl enable --now keyd
    echo "[6/${TOTAL}] Done."
else
    echo "[6/${TOTAL}] keyd is already installed. Skipped."
fi

# -----------------------------------------
echo ""
echo "[7/${TOTAL}] Installing mise & node.js ..."
MISE_BIN="$(command -v mise 2>/dev/null || true)"
if [[ -z "${MISE_BIN}" ]]; then
    curl https://mise.run | sh
    MISE_BIN="${HOME}/.local/bin/mise"
fi
"${MISE_BIN}" use -g node@24
echo "[7/${TOTAL}] Done."

# -----------------------------------------
echo ""
echo "[8/${TOTAL}] Installing gh ..."
if ! command -v gh >/dev/null 2>&1; then
    sudo mkdir -p -m 755 /etc/apt/keyrings
    wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update
    sudo apt install gh -y
    echo "[8/${TOTAL}] Done."
else
    echo "[8/${TOTAL}] gh is already installed. Skipped."
fi

# -----------------------------------------
echo ""
echo "[9/${TOTAL}] Installing ghq ..."
if ! command -v ghq >/dev/null 2>&1; then
    cd /tmp || exit
    wget https://github.com/x-motemen/ghq/releases/latest/download/ghq_linux_amd64.zip
    unzip ghq_linux_amd64.zip
    sudo mv ghq_linux_amd64/ghq /usr/local/bin
    rm -rf ghq_linux_amd64
    rm -f ghq_linux_amd64.zip
    echo "[9/${TOTAL}] Done."
else
    echo "[9/${TOTAL}] ghq is already installed. Skipped."
fi

# -----------------------------------------
echo ""
echo "[10/${TOTAL}] Installing claude code ..."
if ! command -v claude >/dev/null 2>&1; then
    curl -fsSL https://claude.ai/install.sh | bash
    echo "[10/${TOTAL}] Done."
else
    echo "[10/${TOTAL}] claude code is already installed. Skipped."
fi

# -----------------------------------------
echo ""
echo "[11/${TOTAL}] Installing codex ..."
if ! command -v codex >/dev/null 2>&1; then
    "${MISE_BIN}" exec node@24 -- npm install -g @openai/codex
    echo "[11/${TOTAL}] Done."
else
    echo "[11/${TOTAL}] codex is already installed. Skipped."
fi

# -----------------------------------------
echo ""
echo "[12/${TOTAL}] Installing Google Chrome ..."
if ! command -v google-chrome >/dev/null 2>&1; then
    cd /tmp || exit
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo apt install -y ./google-chrome-stable_current_amd64.deb
    rm google-chrome-stable_current_amd64.deb
    echo "[12/${TOTAL}] Done."
else
    echo "[12/${TOTAL}] Google Chrome is already installed. Skipped."
fi

# -----------------------------------------
echo ""
echo "[13/${TOTAL}] Installing yt-dlp ..."
if ! command -v yt-dlp >/dev/null 2>&1; then
    sudo wget https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -O /usr/local/bin/yt-dlp
    sudo chmod a+rx /usr/local/bin/yt-dlp
    echo "[13/${TOTAL}] Done."
else
    echo "[13/${TOTAL}] yt-dlp is already installed. Upgrading ..."
    sudo yt-dlp -U
    echo "[13/${TOTAL}] Done."
fi

# -----------------------------------------
echo ""
echo "[14/${TOTAL}] Installing espanso ..."
if ! command -v espanso >/dev/null 2>&1; then
    cd /tmp || exit
    wget https://github.com/espanso/espanso/releases/latest/download/espanso-debian-wayland-amd64.deb
    sudo apt install -y ./espanso-debian-wayland-amd64.deb
    rm espanso-debian-wayland-amd64.deb
    echo "[14/${TOTAL}] Done."
else
    echo "[14/${TOTAL}] espanso is already installed. Skipped."
fi

echo ""
echo "=============================="
echo "All done. (${TOTAL}/${TOTAL})"
echo "=============================="
