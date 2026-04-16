class EpsonPrinterUtility < Formula
  desc "Printer Utility program for Epson Printer Driver"
  homepage "https://support.epson.net/linux/Printer/LSB_distribution_pages/en/utility.php"
  url "https://download3.ebz.epson.net/dsc/f/03/00/16/74/30/9067c71049e81fbbee48a4695c5c0acf308b9f18/epson-printer-utility_1.2.2-1_amd64.deb"
  sha256 "f0e1b61ef6beec5180f6cf31ffbb87f4831b81181ecface5e73d57037d914492"
  version "1.2.2"
  license :cannot_represent

  livecheck do
    url "https://aur.archlinux.org/rpc/v5/info/epson-printer-utility"
    regex(/"Version":"(\d+(?:\.\d+)+)/i)
  end

  depends_on "libusb"

  def install
    raise "#{name} is only available on Linux (x86_64)." unless OS.linux? && Hardware::CPU.intel?

    # The .deb file is an ar archive; extract it to obtain the data tarball.
    system "ar", "x", cached_download

    # The data archive may use .gz, .xz, or .bz2 compression depending on the version.
    data_archive = Dir["data.tar.*"].first
    raise "No data archive found inside .deb" if data_archive.nil?

    system "tar", "xf", data_archive

    # Install the main GUI binary.
    bin.install "opt/epson-printer-utility/bin/epson-printer-utility"

    # Install bundled libraries shipped with the package (if any).
    bundled_libs = Dir["opt/epson-printer-utility/lib/*.so*"]
    (lib/"epson-printer-utility").install(*bundled_libs) unless bundled_libs.empty?

    # Install the backend daemon and its supporting files (ecbd).
    backend_files = Dir["usr/lib/epson-backend/*"]
    (lib/"epson-backend").install(*backend_files) unless backend_files.empty?

    # Extract and install the systemd service file (if present), rewriting the
    # hard-coded /usr/lib/epson-backend path to the actual Homebrew prefix path.
    service_files = Dir["lib/systemd/system/*.service"] + Dir["usr/lib/systemd/system/*.service"]
    unless service_files.empty?
      service_files.each do |sf|
        inreplace sf, "/usr/lib/epson-backend", (lib/"epson-backend").to_s
      end
      (lib/"systemd/system").install(*service_files)
    end

    # Install the .desktop launcher (optional, may not be present in all releases).
    desktop = "usr/share/applications/epson-printer-utility.desktop"
    (share/"applications").install desktop if File.exist?(desktop)

    # Install the application icon (optional).
    icon = "usr/share/pixmaps/epson-printer-utility.png"
    (share/"pixmaps").install icon if File.exist?(icon)
  end

  service do
    run lib/"epson-backend/ecbd"
    keep_alive true
    log_path var/"log/ecbd.log"
    error_log_path var/"log/ecbd-error.log"
  end

  def caveats
    <<~EOS
      epson-printer-utility requires Qt 5 libraries at runtime.
      Install them via your system package manager if not already present:
        Debian/Ubuntu: sudo apt-get install libqt5widgets5
        Fedora/RHEL:   sudo dnf install qt5-qtbase

      The application communicates with the printer through the ecbd backend
      service. The recommended way to enable it is via brew services (requires
      root so that the service starts at boot and can access printer hardware):
        sudo brew services start epson-printer-utility

      Alternatively, install the service file manually and enable it with systemd:
        sudo cp #{lib}/systemd/system/ecbd.service /etc/systemd/system/
        sudo systemctl daemon-reload
        sudo systemctl enable ecbd.service
        sudo systemctl start ecbd.service

      Also ensure that CUPS is running:
        sudo systemctl enable cups.service
        sudo systemctl start cups.service
    EOS
  end

  test do
    assert_predicate bin/"epson-printer-utility", :exist?
  end
end
