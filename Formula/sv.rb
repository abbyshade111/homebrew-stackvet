# StackVet's `sv`, built from source on the person's own computer (Mac or Linux).
#
# Homebrew fetches Rust for the build itself, so nobody installs it by hand. The program and its data
# folder are kept together in Homebrew's own folder for `sv` (libexec), and `bin/sv` is a link to the
# program; `sv` follows the link back to its real place before looking for `data/` beside it
# (StackVet's ADR-036). Until StackVet has its first release this is a head-only formula:
#
#     brew install --HEAD abbyshade111/stackvet/sv
class Sv < Formula
  desc "Checks an app against OWASP ASVS 5.0, AISVS 1.0, and the Secure by Design checklist"
  homepage "https://github.com/abbyshade111/StackVet"
  license "MIT"
  head "https://github.com/abbyshade111/StackVet.git", branch: "main"

  depends_on "rust" => :build

  def install
    # --locked: the versions in Cargo.lock, the ones StackVet's tests ran with.
    system "cargo", "build", "--release", "--locked", "-p", "sv-cli"
    libexec.install "target/release/sv"
    libexec.install "data"
    bin.install_symlink libexec/"sv"
  end

  test do
    # The data it reports is the copy installed beside the program, not a folder it was built in.
    assert_match "data: #{libexec}/data", shell_output("#{bin}/sv --version")
    # A real check on a one-file app: it reads the file and says what it could not assess.
    (testpath/"app/main.py").write "print('hello')\n"
    output = shell_output("#{bin}/sv check #{testpath}/app")
    assert_match "Read 1 file looking for credentials", output
    assert_match "Not assessed", output
  end
end
