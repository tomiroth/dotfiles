# cachy-os.sh

Sets up a CachyOS machine with Tom's non-default configuration.

## Usage

```bash
./cachy-os.sh           # base install
./cachy-os.sh --vm      # base install + KVM/libvirt virtualization
```

## What it does

1. **Shell** — Sets the login shell to `zsh` (guard; CachyOS already defaults to zsh).
2. **Terminal** — Installs `ghostty` and sets it as the default terminal in KDE Plasma via `kwriteconfig6`.
3. **Official-repo packages** — `neovim`, `tmux`, `stow`, `zoxide`, `go`, `npm`, `glow`, `valgrind`, `tree-sitter-cli`, `openbsd-netcat`, `composer`, `packer`, `keyd`, `flatpak`, `docker`, `brave-bin`, `obsidian`, `signal-desktop`, `prettier`.
4. **AUR packages** (via `paru`) — `sesh-bin`, `llm`, `prettierd`, `unixbench`, `nordvpn-bin`, `desktopify-lite`, `zsa-keymapp-bin`.
5. **Services** — Enables `keyd`, `nordvpnd`, and `docker`; adds the user to the `docker` group.
6. **keyd config** — Writes `/etc/keyd/default.conf` for a ZSA keyboard (`258a:013b`: capslock/backspace swap + alt hjkl layer). Guarded so an existing config is never overwritten.
7. **zplug** — Clones the zsh plugin manager to `~/.zplug` if missing.
8. **TPM** — Clones the Tmux Plugin Manager to `~/.tmux/plugins/tpm` if missing. Press `<leader> I` in tmux to install plugins.
9. **Go tools** — Installs `templ` (templ language) and `air` (live reload) to `~/go/bin`.
10. **Flatpaks** — Google Chrome, CPU-X, Telegram.

## `--vm`: KVM + libvirt virtualization

The `--vm` flag adds desktop virtualization using kernel-native KVM (already loaded on this hardware).

Installs:

| Package | Purpose |
|---------|---------|
| `virt-manager` | GUI for managing libvirt VMs (also pulls in `libvirt` and `virt-install`) |
| `qemu-desktop` | QEMU metapackage for desktop use (pulls `qemu-system-x86` via `qemu-base`, plus audio/video/USB drivers) |
| `edk2-ovmf` | UEFI firmware for VMs (needed for modern OS guests, incl. Windows 11) |
| `dnsmasq` | DHCP/DNS for the default NAT network |
| `virt-viewer` | CLI SPICE/VNC console viewer |
| `swtpm` | Software TPM emulation (required for Windows 11) |

Then:
- **Socket-activates `libvirtd`** — the daemon stays dormant and starts on demand when you open `virt-manager`. Zero boot/idle cost.
- Adds the user to the `libvirt` and `kvm` groups (manage VMs without sudo)

### Post-install for `--vm`

Log out and back in for the new groups to take effect, then launch `virt-manager` to create VMs.

On first use, enable the default NAT network (provides DHCP/internet to VMs):

```bash
sudo virsh net-start default
sudo virsh net-autostart default
```

Or configure it through the virt-manager GUI (Edit → Connection Details → Virtual Networks).