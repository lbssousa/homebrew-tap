class BigParentalControls < Formula
  desc "Parental controls for BigLinux — supervised accounts, app filters, time limits and web filtering"
  homepage "https://github.com/biglinux/big-parental-controls"
  url "https://github.com/biglinux/big-parental-controls/archive/refs/tags/big-parental-controls-26.04.02-0200-x86_64.tar.gz"
  sha256 "b2a51464e0cbdb1d483989bff072aa76a2f2117b0d1de5306e9fa141dfec09d0"
  version "26.04.02"
  license "GPL-3.0-or-later"

  bottle :unneeded

  livecheck do
    url "https://github.com/biglinux/big-parental-controls/tags"
    regex(/big-parental-controls-(\d+(?:\.\d+)+)/i)
  end

  depends_on "gtk4"
  depends_on "libadwaita"
  depends_on "pygobject3"
  depends_on "python@3.13"
  depends_on "rust" => :build
  depends_on :linux

  def python3
    Formula["python@3.13"].opt_bin/"python3"
  end

  def install
    # Build the unified Rust daemon (age signal + parental monitor)
    cd "big-age-signal" do
      system "cargo", "build", "--release", "--locked"
    end

    # Install the Python package without pulling in PyGObject/pycairo via pip
    # (they are provided by the pygobject3 Homebrew formula)
    system python3, "-m", "pip", "install",
      "--prefix", prefix,
      "--no-build-isolation",
      "--no-deps",
      "."

    # Rust daemon
    (lib/"big-parental-controls").install "big-age-signal/target/release/big-parental-daemon"

    # Privileged helper scripts
    %w[acl-reapply group-helper pam-time-message time-check].each do |helper|
      (lib/"big-parental-controls").install "big-parental-controls/usr/lib/big-parental-controls/#{helper}"
    end
    chmod 0755, Dir["#{lib}/big-parental-controls/*"]

    # Main launcher — rewrite the python3 call to use Homebrew's interpreter
    launcher = buildpath/"big-parental-controls/usr/bin/big-parental-controls"
    inreplace launcher, /^exec python3 /, "exec #{python3} "
    bin.install launcher

    # Symlink daemon binary for backward compatibility (matches upstream PKGBUILD)
    bin.install_symlink lib/"big-parental-controls/big-parental-daemon" => "big-age-signal"

    # Desktop integration
    (share/"applications").install Dir["big-parental-controls/usr/share/applications/*.desktop"]
    (share/"icons").install Dir["big-parental-controls/usr/share/icons/hicolor"]

    # D-Bus service and interface descriptions
    (share/"dbus-1").install Dir["big-parental-controls/usr/share/dbus-1/*"]

    # Polkit actions and rules
    (share/"polkit-1").install Dir["big-parental-controls/usr/share/polkit-1/*"]

    # Locale files
    (share/"locale").install Dir["big-parental-controls/usr/share/locale/*"]

    # systemd units (stored under Homebrew prefix; see caveats for activation)
    (lib/"systemd/system").install Dir["big-parental-controls/usr/lib/systemd/system/*"]
    (lib/"systemd/user").install Dir["big-parental-controls/usr/lib/systemd/user/*"] \
      if Dir["big-parental-controls/usr/lib/systemd/user/*"].any?

    # State directories required at runtime
    (var/"lib/big-parental-controls").mkpath
    (var/"lib/big-parental-controls/activity").mkpath
  end

  def caveats
    <<~EOS
      big-parental-controls is a Linux-only application that integrates
      deeply with several system services. After installation you must
      perform the following steps as root:

      1. Register the D-Bus system service:
           sudo cp #{share}/dbus-1/system.d/*.conf /etc/dbus-1/system.d/
           sudo systemctl reload dbus

      2. Register the polkit policy and rules:
           sudo cp #{share}/polkit-1/actions/*.policy \
                    /usr/share/polkit-1/actions/
           sudo cp #{share}/polkit-1/rules.d/*.rules \
                    /usr/share/polkit-1/rules.d/

      3. Enable and start the background daemon:
           sudo cp #{lib}/systemd/system/big-parental-daemon.service \
                    /usr/lib/systemd/system/
           sudo systemctl daemon-reload
           sudo systemctl enable --now big-parental-daemon.service

      4. Make helper binaries available to polkit/PAM (must live at the
         expected system path):
           sudo mkdir -p /usr/lib/big-parental-controls
           for f in acl-reapply group-helper pam-time-message time-check; do
             sudo ln -sf #{lib}/big-parental-controls/$f \
                          /usr/lib/big-parental-controls/$f
           done

      Runtime system dependencies that are NOT managed by Homebrew and
      must be installed via your system package manager:
        • polkit          (pacman -S polkit)
        • accountsservice (pacman -S accountsservice)
        • libmalcontent   (pacman -S libmalcontent)
        • acl             (pacman -S acl)
        • nftables        (pacman -S nftables)   ← optional, for DNS filtering
    EOS
  end

  test do
    assert_predicate bin/"big-parental-controls", :exist?
    assert_predicate bin/"big-age-signal", :exist?
    assert_predicate lib/"big-parental-controls/group-helper", :exist?
  end
end
