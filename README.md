# homebrew-tap

My personal Homebrew tap.

## Usage

```bash
brew tap lbssousa/tap
```

## Formulae

### epson-printer-utility

Printer Utility program for Epson Printer Driver. Allows you to check ink
levels, view error messages and other printer status information, and manage
settings for Epson printers.

- **Version**: 1.2.2
- **License**: Proprietary (Seiko Epson Corporation)
- **Platform**: Linux x86_64 only
- **Source**: [Epson Linux download portal](https://support.epson.net/linux/Printer/LSB_distribution_pages/en/utility.php)
- **AUR package**: [epson-printer-utility](https://aur.archlinux.org/packages/epson-printer-utility/)

#### Installation

```bash
brew install lbssousa/tap/epson-printer-utility
```

#### Runtime requirements

- Qt 5 libraries (`libqt5widgets5` on Debian/Ubuntu, `qt5-qtbase` on Fedora/RHEL)
- CUPS (`cups`)

#### Post-install setup

Enable and start the `ecbd` backend service so the utility can communicate
with the printer:

```bash
sudo systemctl enable ecbd.service
sudo systemctl start ecbd.service
```

### big-parental-controls

Parental controls for BigLinux — supervised accounts, app filters, time limits
and web filtering.

- **Version**: 26.04.02
- **License**: GPL-3.0-or-later
- **Platform**: Linux x86_64 only
- **Source**: [biglinux/big-parental-controls](https://github.com/biglinux/big-parental-controls)

#### Installation

```bash
brew install lbssousa/tap/big-parental-controls
```

#### Runtime requirements

The following system packages are **not** managed by Homebrew and must be
installed via your system package manager:

- `polkit` (`pacman -S polkit`)
- `accountsservice` (`pacman -S accountsservice`)
- `libmalcontent` (`pacman -S libmalcontent`)
- `acl` (`pacman -S acl`)
- `nftables` (`pacman -S nftables`) — optional, for DNS filtering

#### Post-install setup

After installation, perform the following steps as root:

1. **Register the D-Bus system service:**

   ```bash
   sudo cp $(brew --prefix)/share/dbus-1/system.d/*.conf /etc/dbus-1/system.d/
   sudo systemctl reload dbus
   ```

2. **Register the polkit policy and rules:**

   ```bash
   sudo cp $(brew --prefix)/share/polkit-1/actions/*.policy /usr/share/polkit-1/actions/
   sudo cp $(brew --prefix)/share/polkit-1/rules.d/*.rules /usr/share/polkit-1/rules.d/
   ```

3. **Enable and start the background daemon:**

   ```bash
   sudo cp $(brew --prefix)/lib/systemd/system/big-parental-daemon.service /usr/lib/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable --now big-parental-daemon.service
   ```

4. **Make helper binaries available to polkit/PAM:**

   ```bash
   sudo mkdir -p /usr/lib/big-parental-controls
   for f in acl-reapply group-helper pam-time-message time-check; do
     sudo ln -sf $(brew --prefix)/lib/big-parental-controls/$f /usr/lib/big-parental-controls/$f
   done
   ```
