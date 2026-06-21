#!/bin/bash

# -----------------------------------------
# Install
# -----------------------------------------
echo '----------------------------'
echo 'Install dev tools ...'
echo '----------------------------'
sudo apt update && sudo apt install -y \
    build-essential \
    curl \
    tree \
    git \
    gh \
    tmux \
    fzf \
    bat \
    vim-gtk3 \
    jq \
    yq

# -----------------------------------------
# rofi          launcher    # deprected
# hyperfile     benchmaker
# rclone        google drive / dropbox
# gocryptfs     encript dir
# - gocryptfs ~/hoge.env ~/hoge     # mount
# - fusermount -u ~/hoge            # unmount
# gpaste-2 gir1.2-gpaste-2          # clipboard history
echo '----------------------------'
echo 'Install system utilities ...'
echo '----------------------------'
sudo apt install -y \
    hyperfile \
    rclone \
    gocryptfs \
    gpaste-2 gir1.2-gpaste-2

# -----------------------------------------
# htop:     Monitoring CPU and Memory Usage
# nethogs:  Monitor network traffic by process
# iftop:    Monitor network traffic by destination
# whois:    Perform a DNS reverse lookup
# arp-scan: List devices on the network
echo '----------------------------'
echo ' Install system monitor tools ...'
echo '----------------------------'
sudo apt install -y \
    htop \
    nethogs \
    iftop \
    whois \
    arp-scan


# -----------------------------------------
# yt-dlp        downloader
# ffmpeg        encoder
# mpv           music player
echo '----------------------------'
echo ' Install applications ...'
echo '----------------------------'
sudo apt install -y \
    yt-dlp \
    ffmpeg \
    mpv

echo '----------------------------'
echo ' Gnome Shell Extension'
echo '----------------------------'
sudo apt install gnome-shell-extension-manager

echo '----------------------------'
echo ' Install keyd ...'
echo '----------------------------'
# sudo keyd monitor
if ! command -v keyd >/dev/null 2>&1; then
    sudo add-apt-repository ppa:keyd-team/ppa
    sudo apt update
    sudo apt install keyd
    sudo systemctl enable --now keyd
else
    echo "keyd is already installd."
fi

echo '----------------------------'
echo 'Install mise & node.js ...'
echo '----------------------------'
MISE_BIN="$(command -v mise 2>/dev/null || true)"
if [[ -z "${MISE_BIN}" ]]; then
    curl https://mise.run | sh
    MISE_BIN="${HOME}/.local/bin/mise"
fi
"${MISE_BIN}" use -g node@24

echo '----------------------------'
echo 'Install gh ...'
echo '----------------------------'
if ! command -v gh >/dev/null 2>&1; then
    sudo mkdir -p -m 755 /etc/apt/keyrings
    wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update
    sudo apt install gh -y
else
    echo "gh is already installd."
fi

echo '----------------------------'
echo 'Install ghq ...'
echo '----------------------------'
if ! command -v ghq >/dev/null 2>&1; then
    echo "Installing ghq ..."
    cd /tmp || exit
    wget https://github.com/x-motemen/ghq/releases/latest/download/ghq_linux_amd64.zip
    unzip ghq_linux_amd64.zip
    sudo mv ghq_linux_amd64/ghq /usr/local/bin
    rm -rf ghq_linux_amd64
else
    echo "ghq is already installd."
fi

echo '----------------------------'
echo 'Install claude code ...'
echo '----------------------------'
if ! command -v claude >/dev/null 2>&1; then
    curl -fsSL https://claude.ai/install.sh | bash
else
    echo "claude code is already installd."
fi

echo '----------------------------'
echo 'Install codex ...'
echo '----------------------------'
if ! command -v codex >/dev/null 2>&1; then
    npm install -g @openai/codex
else
    echo "codex is already installd."
fi

echo '----------------------------'
echo 'Install chrome ...'
echo '----------------------------'
if ! command -v google-chrome >/dev/null 2>&1; then
    echo "Installing Google Chrome ..."
    cd /tmp || exit
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo apt install -y ./google-chrome-stable_current_amd64.deb
    rm google-chrome-stable_current_amd64.deb
else
    echo "Google Chrome is already installd."
fi

echo '----------------------------'
echo 'Install yt-dlp ...'
echo '----------------------------'
if ! command -v yt-dlp >/dev/null 2>&1; then
    echo "Installing yt-dlp ..."
    sudo wget https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -O /usr/local/bin/yt-dlp
    sudo chmod a+rx /usr/local/bin/yt-dlp
else
    echo "yt-dlp is already installed and try upgrade to new version if available..."
    sudo yt-dlp -U
fi
