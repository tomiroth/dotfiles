# Install oh my zsh.
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install better find.
sudo apt-get install fd-find

# Install fuzyy finder.
sudo apt-get install fzf

# Install better find.
sudo apt-get install zoxide

# Install tmux
supd apt-get install tmux

# Install zsh plug in manager
curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh


# Install Tmux Plugin Manager
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
# Press <leader> I to install plug-ins.

# Install GNU stow
sudo apt-get install stow

# Install Neovim.
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
sudo rm -rf /opt/nvim
sudo tar -C /opt -xzf nvim-linux64.tar.gz
