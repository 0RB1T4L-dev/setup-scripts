#!/usr/bin/env bash
# ==============================================================================
# Automated Shell & Terminal Setup Script
# Configures Zsh + Oh My Zsh + Powerlevel10k + Zsh Autosuggestions + Terminator
# ==============================================================================
set -e

GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[1;33m"
NC="\033[0m"

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

log_info "Starting shell configuration setup..."

# 1. Update package list & install core dependencies
log_info "Installing dependencies (zsh, git, curl, wget, fontconfig, terminator)..."
if command -v apt-get &>/dev/null; then
    sudo apt-get update -qq
    sudo apt-get install -y -qq zsh git curl wget fontconfig terminator btop eza
elif command -v dnf &>/dev/null; then
    sudo dnf install -y zsh git curl wget fontconfig terminator btop eza
elif command -v pacman &>/dev/null; then
    sudo pacman -Sy --noconfirm zsh git curl wget fontconfig terminator btop eza
else
    log_warn "Package manager not recognized. Ensure zsh, git, curl, wget, fontconfig, and terminator are installed."
fi

# 2. Download and install MesloLGS NF Fonts for Powerlevel10k
log_info "Installing MesloLGS NF fonts..."
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

FONTS=(
    "MesloLGS NF Regular.ttf"
    "MesloLGS NF Bold.ttf"
    "MesloLGS NF Italic.ttf"
    "MesloLGS NF Bold Italic.ttf"
)

BASE_FONT_URL="https://github.com/romkatv/powerlevel10k-media/raw/master"

for font in "${FONTS[@]}"; do
    if [ ! -f "$FONT_DIR/$font" ]; then
        ENCODED_FONT=$(echo "$font" | sed "s/ /%20/g")
        log_info "Downloading $font..."
        curl -fsSL "$BASE_FONT_URL/$ENCODED_FONT" -o "$FONT_DIR/$font"
    fi
done

if command -v fc-cache &>/dev/null; then
    log_info "Refreshing font cache..."
    fc-cache -f "$FONT_DIR"
fi

# 3. Install Oh My Zsh if not installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    log_info "Installing Oh My Zsh..."
    RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    log_info "Oh My Zsh is already installed."
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# 4. Install Powerlevel10k theme
if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
    log_info "Cloning Powerlevel10k theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
else
    log_info "Powerlevel10k theme already installed."
fi

# 5. Install zsh-autosuggestions plugin
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    log_info "Cloning zsh-autosuggestions plugin..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
else
    log_info "zsh-autosuggestions plugin already installed."
fi

# 6. Deploy Dotfiles (~/.zshrc, ~/.zshenv, ~/.p10k.zsh)
log_info "Writing ~/.zshrc..."


# 8. Set default shell to zsh
if [ "$SHELL" != "$(which zsh)" ]; then
    log_info "Changing default shell to zsh..."
    if command -v chsh &>/dev/null; then
        sudo chsh -s "$(which zsh)" "$USER" || chsh -s "$(which zsh)"
    fi
fi

log_success "Shell configuration complete! Restart your terminal or run zsh to apply changes."
