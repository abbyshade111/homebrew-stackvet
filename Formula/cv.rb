# ConfigVet's `cv`, StackVet's companion for an app's deployment files, built from source on the person's
# own computer (Mac or Linux).
#
# As for `sv`: Homebrew fetches Rust for the build, and the program and its data folder are kept together in
# Homebrew's own folder for `cv` (libexec), with `bin/cv` a link to the program, which follows the link back
# to its real place before looking for `data/` beside it (StackVet's ADR-036).
#
# The plain install builds the latest release, from v0.3.0, the first to package `cv` (StackVet's backlog
# 0694); --HEAD builds StackVet's main:
#
#     brew install abbyshade111/stackvet/cv
#     brew install --HEAD abbyshade111/stackvet/cv
#
# `cv check` runs hadolint, Checkov, and Trivy where they are installed, and says so where they are not;
# they are not installed with it (`brew install hadolint checkov trivy` adds them).
class Cv < Formula
  desc "Reviews an app's deployment files for unsafe and missing settings"
  homepage "https://github.com/abbyshade111/StackVet"
  url "https://github.com/abbyshade111/StackVet/archive/refs/tags/v0.3.0.tar.gz"
  sha256 "015d4c401adba8f12a7d92163f28af11bdd401edf7f84e44c2aff3a7752e8b12"
  license "MIT"
  head "https://github.com/abbyshade111/StackVet.git", branch: "main"

  depends_on "rust" => :build

  def install
    # --locked and --jobs 2, as `sv`'s formula says why: the versions StackVet's tests ran with, and two crates
    # at a time, since `cv` builds `sv-check` and its sixteen tree-sitter grammars too.
    system "cargo", "build", "--release", "--locked", "--jobs", "2", "-p", "cv-cli"
    libexec.install "target/release/cv"
    libexec.install "data"
    bin.install_symlink libexec/"cv"
  end

  test do
    # A release build says the release's version; a --HEAD build says whatever main's is.
    version_output = shell_output("#{bin}/cv --version")
    assert_match(/^cv \d+\.\d+\.\d+/, version_output)
    assert_match "cv #{version}", version_output unless version.head?
    # A real check of a one-file folder: it reads the Dockerfile with the data installed beside it.
    (testpath/"app/Dockerfile").write "FROM node:24-alpine\nCMD [\"node\", \"index.js\"]\n"
    output = shell_output("#{bin}/cv check #{testpath}/app --no-tools --out #{testpath}/report")
    assert_match "Read 1 deployment files", output
    assert_path_exists testpath/"report/report.json"
  end
end
