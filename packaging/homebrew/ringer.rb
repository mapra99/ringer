# Formula for the mapra99/homebrew-tap repository. After tagging a release,
# fill in the tarball URL and its sha256 (shasum -a 256 <tarball>).
class Ringer < Formula
  desc "Schedule calls from the macOS Phone app and speak a message when answered"
  homepage "https://github.com/mapra99/ringer"
  url "https://github.com/mapra99/ringer/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "REPLACE_WITH_TARBALL_SHA256"
  license "MIT"

  depends_on :macos
  depends_on "switchaudio-osx"

  def install
    bin.install "bin/ringer"
  end

  def caveats
    <<~EOS
      Run `ringer setup` to grant Accessibility permission and pick your audio devices.
      Install ffmpeg as well if you want setup to measure that the mic hears the speaker.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/ringer --version")
  end
end
