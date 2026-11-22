# StackVet's `sv`, built from source on the person's own computer (Mac or Linux).
#
# Homebrew fetches Rust for the build itself, so nobody installs it by hand. The program and its data
# folder are kept together in Homebrew's own folder for `sv` (libexec), and `bin/sv` is a link to the
# program; `sv` follows the link back to its real place before looking for `data/` beside it
# (StackVet's ADR-036). The plain install builds the latest release; --HEAD builds StackVet's main:
#
#     brew install abbyshade111/stackvet/sv
#     brew install --HEAD abbyshade111/stackvet/sv
class Sv < Formula
  desc "Checks an app against OWASP ASVS 5.0, AISVS 1.0, and the Secure by Design checklist"
  homepage "https://github.com/abbyshade111/StackVet"
  url "https://github.com/abbyshade111/StackVet/archive/refs/tags/v0.3.1.tar.gz"
  sha256 "acecaa2ea89c76438cef20a9f304abd117c15d475078e06e8335df7c57f1688b"
  license "MIT"
  head "https://github.com/abbyshade111/StackVet.git", branch: "main"

  depends_on "rust" => :build

  def install
    # --locked: the versions in Cargo.lock, the ones StackVet's tests ran with.
    # --jobs 2: two crates compiled at a time rather than one per core. The build includes sixteen
    # tree-sitter grammars written in C, and compiling them all at once took more memory than a Mac with
    # little free disk could swap to: on 9 October 2026 the owner's Mac ran out of application memory
    # partway through the first install. Slower, and it finishes.
    system "cargo", "build", "--release", "--locked", "--jobs", "2", "-p", "sv-cli"
    libexec.install "target/release/sv"
    libexec.install "data"
    bin.install_symlink libexec/"sv"
  end

  test do
    # The data it reports is the copy installed beside the program, not a folder it was built in.
    version_output = shell_output("#{bin}/sv --version")
    assert_match "data: #{libexec}/data", version_output
    # A release build says the release's version; a --HEAD build says whatever main's is.
    assert_match "sv #{version}", version_output unless version.head?
    # A real check on a one-file app: it reads the file and says what it could not assess.
    (testpath/"app/main.py").write "print('hello')\n"
    output = shell_output("#{bin}/sv check #{testpath}/app")
    assert_match "Read 1 file looking for credentials", output
    assert_match "Not assessed", output
  end
end
