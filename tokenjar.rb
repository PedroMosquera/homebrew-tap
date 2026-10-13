class Tokenjar < Formula
  desc "Menu bar app showing how much of each AI plan's usage limit is left"
  homepage "https://github.com/PedroMosquera/tokenjar"
  url "https://github.com/PedroMosquera/tokenjar/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "a3e5411565ef18b0201d99db100269e4c848de96d018b71f136e9418269dcdce"
  license "MIT"

  # Swift 6.2 ships with Command Line Tools 26, which need macOS 15.6 or later.
  depends_on macos: :sequoia

  uses_from_macos "swift" => :build

  deny_network_access!

  def install
    # SwiftPM cannot nest its sandbox in Homebrew's, and a local manifest cache keeps the build out of ~/Library.
    system "make", "app", "SWIFT_FLAGS=--disable-sandbox --manifest-cache local"
    prefix.install "build/Tokenjar.app"
    # Homebrew cannot write to ~/Applications, so the user copies the app later with the script make install uses.
    libexec.install "Scripts/install.sh"
    (bin/"tokenjar-install-app").write_env_script libexec/"install.sh", TOKENJAR_APP: opt_prefix/"Tokenjar.app"
  end

  def caveats
    <<~EOS
      Homebrew does not put apps in ~/Applications. To copy Tokenjar.app
      there and open it, run:
        tokenjar-install-app
      It first quits the Tokenjar running from ~/Applications.
      Run it again after every upgrade or reinstall of tokenjar. Until
      you do, the previous version keeps running.

      Turn on Launch at login from that copy, in Settings > General.
      Every build has a new ad-hoc signature, so after each upgrade macOS
      asks once more for Keychain access to any API key pasted in Settings.

      `brew uninstall tokenjar` removes Homebrew's copy and
      tokenjar-install-app, not the copy in ~/Applications. Tokenjar's
      README lists what else to delete.
    EOS
  end

  test do
    app = prefix/"Tokenjar.app"
    plist = app/"Contents/Info.plist"
    system "plutil", "-lint", plist
    assert_equal "com.pedromosquera.tokenjar",
                 shell_output("plutil -extract CFBundleIdentifier raw -o - #{plist}").chomp
    assert_equal version.to_s,
                 shell_output("plutil -extract CFBundleShortVersionString raw -o - #{plist}").chomp
    assert_predicate app/"Contents/MacOS/Tokenjar", :executable?
    assert_path_exists app/"Contents/Resources/LICENSE"
    assert_path_exists app/"Contents/Resources/THIRD_PARTY_NOTICES.md"
    system "codesign", "--verify", "--strict", app
    assert_predicate bin/"tokenjar-install-app", :executable?
    assert_predicate libexec/"install.sh", :executable?
  end
end
