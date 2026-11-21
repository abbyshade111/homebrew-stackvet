#!/usr/bin/env bash
# The tests of install-sv.sh (StackVet backlog 0697), with a stand-in for `brew` that plays each case: the race is
# retried once and passes, saying so; any other failure, an "Empty installation" that is not the race, a release
# build, and a retry that fails again are not retried, or fail. Run by the `install` job before it installs, and by
# hand: .github/scripts/test-install-sv.sh
set -u
here="$(cd "$(dirname "$0")" && pwd)"
work="$(mktemp -d "${TMPDIR:-/tmp}/install-sv-tests.XXXXXX")" || { echo "install-sv tests: could not make a scratch folder, so nothing was tested"; exit 1; }
trap 'rm -rf "$work"' EXIT
fake="$work/brew"
cat > "$fake" <<'FAKE'
#!/usr/bin/env bash
# Plays `brew` for one case, $CASE, writing each call to $CALLS.
echo "$*" >> "$CALLS"
cellar="$WORK/Cellar"
case "$1" in
  --cellar) echo "$cellar"; exit 0 ;;
  uninstall) rm -rf "$cellar/sv"; exit 0 ;;
esac
n=$(grep -c '^install' "$CALLS")
echo "✔︎ Formula sv (HEAD-aaaaaaa)"
case "$CASE:$n" in
  race:1|race-again:*)
    mkdir -p "$cellar/sv/HEAD-bbbbbbb/bin" && touch "$cellar/sv/HEAD-bbbbbbb/bin/sv"
    echo "Error: abbyshade111/stackvet/sv: Empty installation"; exit 1 ;;
  race:2) mkdir -p "$cellar/sv/HEAD-aaaaaaa/bin" && touch "$cellar/sv/HEAD-aaaaaaa/bin/sv"; exit 0 ;;
  other:*)
    # Everything the race leaves, but another message: not retried.
    mkdir -p "$cellar/sv/HEAD-bbbbbbb/bin" && touch "$cellar/sv/HEAD-bbbbbbb/bin/sv"
    echo "Error: abbyshade111/stackvet/sv: failed to build"; exit 1 ;;
  same-folder:*)
    # "Empty installation" with the install in the folder Homebrew named: not the race, not retried.
    mkdir -p "$cellar/sv/HEAD-aaaaaaa/bin" && touch "$cellar/sv/HEAD-aaaaaaa/bin/sv"
    echo "Error: abbyshade111/stackvet/sv: Empty installation"; exit 1 ;;
  empty-really:*)
    # "Empty installation" with only an empty folder under another name: not retried.
    mkdir -p "$cellar/sv/HEAD-bbbbbbb"; echo "Error: abbyshade111/stackvet/sv: Empty installation"; exit 1 ;;
  release-race:*)
    # Everything the race leaves, on a release build, which names no HEAD: not retried.
    mkdir -p "$cellar/sv/HEAD-bbbbbbb/bin" && touch "$cellar/sv/HEAD-bbbbbbb/bin/sv"
    echo "Error: abbyshade111/stackvet/sv: Empty installation"; exit 1 ;;
esac
exit 1
FAKE
chmod +x "$fake" && [ -x "$fake" ] || { echo "install-sv tests: the stand-in brew could not be made, so nothing was tested"; exit 1; }
failed=0
# case, build, the exit wanted, the installs wanted, words the output must hold
check() {
  local case=$1 build=$2 want=$3 installs=$4 words=$5
  rm -rf "$work/Cellar" "$work/calls"; touch "$work/calls"
  out="$(CASE=$case WORK=$work CALLS=$work/calls BREW=$fake "$here/install-sv.sh" "$build" 2>&1)"
  got=$?
  made=$(grep -c '^install' "$work/calls")
  if [ "$got" != "$want" ] || [ "$made" != "$installs" ] || ! grep -qF -- "$words" <<<"$out"; then
    echo "FAILED $case ($build): exit $got (wanted $want), $made installs (wanted $installs), wanted \"$words\" in:"
    echo "$out" | sed 's/^/    /'
    failed=1
  else
    echo "ok     $case ($build): exit $got, $made installs"
  fi
}
check race head 0 2 "retried once"
check race-again head 1 2 "retried once"
check other head 1 1 "failed to build"
check same-folder head 1 1 "it is not retried"
check empty-really head 1 1 "it is not retried"
check release-race release 1 1 "Empty installation"
if [ "$failed" = 0 ]; then echo "install-sv tests: ok"; else echo "install-sv tests: FAILED"; exit 1; fi
