# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install oh my zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install better find.
brew install fd

# Install fuzyy finder.
brew install fzf

# Install zoxide
brew install zoxide

# Install zplug
brew install zplug
export ZPLUG_HOME=/opt/homebrew/opt/zplug
source $ZPLUG_HOME/init.zsh

#Instal git
brew install git

#Install NeoVim
brew install neovim
git clone --depth 1 https://github.com/wbthomason/packer.nvim\
  ~/.local/share/nvim/site/pack/packer/start/packer.nvim

# Install alacritty
brew install --cask alacritty

#Install GNU stow
brew install stow

brew install ripgrep

brew install tmux
# Install Tmux Plugin Manager
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm # Press <leader> I to install plug-ins.

# Install tmux session manager
brew install joshmedeski/sesh/sesh

# Instal tldr - Cheat sheets
brew install tldr

# Cli json viewer.
brew install jless
