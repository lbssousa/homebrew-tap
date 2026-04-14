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
