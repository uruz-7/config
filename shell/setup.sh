#!/bin/bash

set -e

# ============================================
#  🚀 All-in-One Setup Script
#  - Docker
#  - Zsh
#  - Oh My Zsh
#  - Custom .zshrc settings
# ============================================

# --- Color Definitions ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_step() {
    echo -e "\n${GREEN}===================================================${NC}"
    echo -e "${GREEN}  ✅ $1${NC}"
    echo -e "${GREEN}===================================================${NC}\n"
}

print_warn() {
    echo -e "${YELLOW}  ⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}  ❌ $1${NC}"
}

# --- Check if running as root or with sudo ---
if [ "$EUID" -ne 0 ]; then
    print_error "Please run this script with root privileges (sudo ./setup.sh)"
    exit 1
fi

# Get the actual user (even when running with sudo)
ACTUAL_USER="${SUDO_USER:-$USER}"
ACTUAL_HOME=$(eval echo "~${ACTUAL_USER}")

# ============================================
# Install Docker
# ============================================
print_step "Installing Docker"

if command -v docker &> /dev/null; then
    print_warn "Docker is already installed. Skipping."
    docker --version
else
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm -f get-docker.sh

    # Add user to docker group (so user can run docker without sudo)
    usermod -aG docker "$ACTUAL_USER"
    print_step "User '$ACTUAL_USER' added to docker group"
fi

# Enable and start Docker service
systemctl enable docker
systemctl start docker
print_step "Docker service enabled and started"


# ============================================
# Install Zsh
# ============================================
print_step "Installing Zsh"

if command -v zsh &> /dev/null; then
    print_warn "Zsh is already installed. Skipping."
    zsh --version
else
    apt install -y zsh
    print_step "Zsh installation complete"
fi


# ============================================
# Install LF File Manager
# ============================================
print_step "Installing LF File Manager"

if command -v lf &> /dev/null; then
    print_warn "LF is already installed. Skipping."
    lf -version
else
    # Install lf from apt
    apt install -y lf
    print_step "LF installed via apt"
fi


# ============================================
# Install Build Essential
# ============================================
print_step "Installing Build Essential"

if dpkg -l | grep -q build-essential; then
    print_warn "Build Essential is already installed. Skipping."
else
    apt install -y build-essential
    print_step "Build Essential installation complete"
fi


# ============================================
# Install Eza (modern ls replacement)
# ============================================
print_step "Installing Eza"

if command -v eza &> /dev/null; then
    print_warn "Eza is already installed. Skipping."
    eza --version
else
    # Install GPG if not present
    apt update
    apt install -y gpg

    # Add eza repository
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
    sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list

    # Install eza
    apt update
    apt install -y eza
    print_step "Eza installation complete"
fi


# ============================================
# Install Lazygit
# ============================================
print_step "Installing Lazygit"

if command -v lazygit &> /dev/null; then
    print_warn "Lazygit is already installed. Skipping."
    lazygit --version
else
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*')
    LAZYGIT_ARCH=$(uname -m | sed -e 's/aarch64/arm64/')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_${LAZYGIT_ARCH}.tar.gz"
    tar xf lazygit.tar.gz lazygit
    install lazygit -D -t /usr/local/bin/
    rm -f lazygit.tar.gz
    print_step "Lazygit installation complete"
fi


# ============================================
# Install Lazydocker
# ============================================
print_step "Installing Lazydocker"

if command -v lazydocker &> /dev/null; then
    print_warn "Lazydocker is already installed. Skipping."
    lazydocker --version
else
    curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
    print_step "Lazydocker installation complete"
fi


# ============================================
# Install Neovim
# ============================================
print_step "Installing Neovim"

if command -v nvim &> /dev/null; then
    print_warn "Neovim is already installed. Skipping."
    nvim --version | head -1
else
    # Download Neovim AppImage
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage
    chmod u+x nvim-linux-x86_64.appimage

    # Create directory and move AppImage
    mkdir -p /opt/nvim
    mv nvim-linux-x86_64.appimage /opt/nvim/nvim

    # Add to PATH in .zshrc
    echo 'export PATH="$PATH:/opt/nvim/"' >> "${ACTUAL_HOME}/.zshrc"

    print_step "Neovim installation complete"
fi


# ============================================
# Install LazyVim Starter Configuration
# ============================================
print_step "Installing LazyVim Starter Configuration"

if [ -d "${ACTUAL_HOME}/.config/nvim" ]; then
    print_warn "Neovim config directory already exists. Skipping LazyVim setup."
else
    # Clone LazyVim starter configuration
    sudo -u "$ACTUAL_USER" git clone https://github.com/LazyVim/starter "${ACTUAL_HOME}/.config/nvim"
    # Remove .git to make it a personal config
    rm -rf "${ACTUAL_HOME}/.config/nvim/.git"
    print_step "LazyVim starter configuration installed"
fi


# ============================================
# Install Oh My Zsh
# ============================================
print_step "Installing Oh My Zsh"

if [ -d "${ACTUAL_HOME}/.oh-my-zsh" ]; then
    print_warn "Oh My Zsh is already installed. Skipping."
else
    # Install Oh My Zsh in unattended mode (no shell change yet)
    sudo -u "$ACTUAL_USER" sh -c \
        'export RUNZSH=no; export CHSH=no; curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh'
    print_step "Oh My Zsh installation complete"
fi


# ============================================
# Install Zsh Plugins
# ============================================
print_step "Installing Zsh Plugins"

ZSH_CUSTOM="${ACTUAL_HOME}/.oh-my-zsh/custom"

# zsh-autosuggestions
if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" ]; then
    sudo -u "$ACTUAL_USER" git clone https://github.com/zsh-users/zsh-autosuggestions \
        "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
    echo "  ✔ zsh-autosuggestions installed"
fi

# zsh-syntax-highlighting
if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" ]; then
    sudo -u "$ACTUAL_USER" git clone https://github.com/zsh-users/zsh-syntax-highlighting \
        "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"
    echo "  ✔ zsh-syntax-highlighting installed"
fi

# powerlevel10k theme
if [ ! -d "${ZSH_CUSTOM}/themes/powerlevel10k" ]; then
    sudo -u "$ACTUAL_USER" git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
        "${ZSH_CUSTOM}/themes/powerlevel10k"
    echo "  ✔ powerlevel10k theme installed"
fi

# ============================================
# Configure .zshrc
# ============================================
print_step "Configuring .zshrc"

ZSHRC="${ACTUAL_HOME}/.zshrc"

# Backup existing .zshrc
if [ -f "$ZSHRC" ]; then
    cp "$ZSHRC" "${ZSHRC}.backup.$(date +%Y%m%d%H%M%S)"
    print_warn "Existing .zshrc has been backed up"
fi

# --- Change Theme ---
# Default: robbyrussell → powerlevel10k/powerlevel10k
# To configure powerlevel10k, run: p10k configure
sed -i 's/^ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC"
echo "  ✔ Theme changed to 'powerlevel10k'"

# --- Enable Plugins ---
sed -i 's/^plugins=(git)/plugins=(git docker docker-compose zsh-autosuggestions zsh-syntax-highlighting command-not-found history history-substring-search sudo z terraform )/' "$ZSHRC"
echo "  ✔ Plugins configured"

# --- Append Custom Settings ---
cat >> "$ZSHRC" << 'EOF'

# ============================================
# Custom Settings (added by setup script)
# ============================================

export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# --- History Settings ---
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS       # Ignore duplicate entries
setopt HIST_IGNORE_ALL_DUPS   # Remove older duplicate entries
setopt SHARE_HISTORY          # Share history across all sessions

# --- Aliases ---
alias ls="eza"
alias ll='ls -alF --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias cl="clear"
alias c='code .'
alias s="explorer.exe ."
alias lzg="lazygit"
alias lzd="lazydocker"
alias nv="nvim"

# Docker aliases
alias dps='docker ps'
alias dpsa='docker ps -a'
alias dimg='docker images'
alias dexec='docker exec -it'
alias dlogs='docker logs -f'
alias dstop='docker stop $(docker ps -q)'
alias dprune='docker system prune -af'
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dcl='docker compose logs -f'

# git
alias gs="git status"
alias gf="git fetch origin --prune"
alias gsp="git stash pop"
alias gbc="git branch --merged | egrep -v \"(^\*|master|main|dev)\" | xargs git branch -d"
alias gdl='cbr=$(git branch --show-current); if [ "$cbr" != "main" ]; then git switch main && git branch -d "$cbr"; fi; git fetch origin --prune && git pull'
# clean local branches (https://stackoverflow.com/questions/6127328/how-do-i-delete-all-git-branches-which-have-been-merged)

# --- LF File Manager ---
export PATH="$PATH:$HOME/.config/lf/lf"
lfcd () {
    # `command` is needed in case `lfcd` is aliased to `lf`
    cd "$(command lf -print-last-dir "$@")"
}
alias lf='lfcd'

# --- Auto-correction ---
setopt CORRECT
setopt CORRECT_ALL

# --- Directory Navigation ---
setopt AUTO_CD            # cd by typing directory name only
setopt AUTO_PUSHD         # Automatically pushd on cd
setopt PUSHD_IGNORE_DUPS  # Ignore duplicate pushd entries

# --- Completion ---
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'  # Case-insensitive matching

# --- Autosuggestions ---
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666,underline"
ZSH_AUTOSUGGEST_STRATEGY=history
bindkey '^F' forward-word

# --- Git set ---
function gituruz7() {
  git config --global user.name "uruz7" || echo "Failed to set user.name"
  git config --global user.email "z@gmail.com" || echo "Failed to set user.email"
  git config --global user.signingkey ~/.ssh/id_ed25519_uruz7.pub || echo "Failed to set user.signingkey"
}

# ============================================
EOF

echo "  ✔ Custom settings appended"

# Fix ownership
chown "$ACTUAL_USER":"$ACTUAL_USER" "$ZSHRC"


# ============================================
# Change Default Shell to Zsh
# ============================================
print_step "Changing default shell to Zsh"

chsh -s "$(which zsh)" "$ACTUAL_USER"
echo "  ✔ Default shell for '$ACTUAL_USER' changed to Zsh"
