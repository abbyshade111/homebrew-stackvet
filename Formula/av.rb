# AgentVet's `av`, StackVet's companion that reads what an AI coding tool did while it built an app, built from
# source on the person's own computer (Mac or Linux).
#
# As for `sv` and `cv`: Homebrew fetches Rust for the build, and the program and its data folder are kept together
# in Homebrew's own folder for `av` (libexec), with `bin/av` a link to the program, which follows the link back to
# its real place before looking for `data/` beside it (StackVet's ADR-036). `av` cuts keys out of what it records
# with `sv`'s own rules for secrets, which are in that data.
#
# The plain install builds the latest release, from v0.3.1, the first to package `av` (StackVet's backlog 0724);
# --HEAD builds StackVet's main:
#
#     brew install abbyshade111/stackvet/av
#     brew install --HEAD abbyshade111/stackvet/av
#
# `av` belongs on the person's own computer rather than in `sv`'s container: `av proxy` starts the AI tool's servers,
# and `av report` reads records kept in the person's own folders.
class Av < Formula
  desc "Says what the records show an AI coding tool did while it built an app"
  homepage "https://github.com/abbyshade111/StackVet"
  url "https://github.com/abbyshade111/StackVet/archive/refs/tags/v0.3.1.tar.gz"
  sha256 "acecaa2ea89c76438cef20a9f304abd117c15d475078e06e8335df7c57f1688b"
  license "MIT"
  head "https://github.com/abbyshade111/StackVet.git", branch: "main"

  depends_on "rust" => :build

  def install
    # --locked and --jobs 2, as `sv`'s formula says why: the versions StackVet's tests ran with, and two crates at a
    # time, since `av` builds `sv-check` and its tree-sitter grammars too.
    system "cargo", "build", "--release", "--locked", "--jobs", "2", "-p", "av-cli"
    libexec.install "target/release/av"
    libexec.install "data"
    bin.install_symlink libexec/"av"
  end

  test do
    # A release build says the release's version; a --HEAD build says whatever main's is.
    version_output = shell_output("#{bin}/av --version")
    assert_match(/^av \d+\.\d+\.\d+/, version_output)
    assert_match "av #{version}", version_output unless version.head?
    # Its records are kept in the test's own folder, never the person's.
    ENV["XDG_STATE_HOME"] = (testpath/"state").to_s
    ENV["XDG_CONFIG_HOME"] = (testpath/"config").to_s
    (testpath/"app").mkpath
    # A report on a folder with nothing about a tool exits 2 and says what it did not look at.
    output = shell_output("#{bin}/av report #{testpath}/app 2>&1", 2)
    assert_match "Not looked at", output
    # The pass-through loads the rules that cut keys before it starts anything, so in front of a program that only
    # prints and ends (av itself) it ends 0 only when it found its data beside it.
    pipe_output("#{bin}/av proxy --app #{testpath}/app -- #{bin}/av --version 2>&1", "", 0)
  end
end
