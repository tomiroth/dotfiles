#!/usr/bin/env bash
set -euo pipefail

ENABLE_VM=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --vm) ENABLE_VM=true; shift ;;
    -h|--help) echo "Usage: $0 [--vm]"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# Set default shell to zsh (CachyOS defaults to zsh, this is a guard).
chsh -s /usr/bin/zsh "$USER"

# Install Ghostty and set it as the default terminal in KDE Plasma.
sudo pacman -S --needed ghostty
kwriteconfig6 --file kdeglobals --group General \
  --key TerminalApplication com.mitchellh.ghostty.desktop

# Enable Linux-only Ghostty settings via the optional include in config.ghostty.
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$HOME/.config/ghostty-os"
ln -sfn "$repo_root/install/ghostty/linux.ghostty" "$HOME/.config/ghostty-os/config"

# Install terminal and dev packages from the official repos.
sudo pacman -S --needed neovim tmux stow zoxide go npm glow valgrind \
  tree-sitter-cli openbsd-netcat composer packer keyd flatpak docker \
  brave-bin obsidian signal-desktop prettier ranger

# Install AUR packages via paru (CachyOS default AUR helper).
paru -S --needed sesh-bin llm prettierd unixbench nordvpn-bin \
  desktopify-lite zsa-keymapp-bin


# Enable services.
sudo systemctl enable --now keyd.service nordvpnd.service
sudo systemctl enable docker.service
sudo usermod -aG docker "$USER"

# Write keyd config for ZSA keyboard (258a:013b). Guarded so existing config is kept.
[ -f /etc/keyd/default.conf ] || sudo tee /etc/keyd/default.conf <<'EOF'
[ids]
258a:013b

[main]
capslock = backspace
backspace = capslock
alt = layer(alt)

[alt]
j = down
k = up
h = left
l = right
y = C-left
u = C-up
i = C-down
o = C-right
EOF
sudo systemctl restart keyd 2>/dev/null || true

# Install zplug (zsh plugin manager).
[ -d ~/.zplug ] || git clone https://github.com/zplug/zplug ~/.zplug

# Install Tmux Plugin Manager.
[ -d ~/.tmux/plugins/tpm ] || \
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
# Press <leader> I to install plug-ins.

# Install Go tools.
go install github.com/a-h/templ@latest
go install github.com/air-verse/air@latest

# Install Flatpak apps.
flatpak install -y flathub com.google.Chrome \
  io.github.thetumultuousunicornofdarkness.cpu-x org.telegram.desktop

if $ENABLE_VM; then
  # KVM + libvirt desktop virtualization (see cachy-os.md).
  sudo pacman -S --needed virt-manager qemu-desktop edk2-ovmf \
    dnsmasq virt-viewer swtpm
  sudo systemctl enable --now libvirtd.socket
  sudo usermod -aG libvirt,kvm "$USER"
fi

