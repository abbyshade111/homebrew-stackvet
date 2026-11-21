#!/usr/bin/env bash
# Installs the sv formula as the `install` job does, and retries a --HEAD install once in one case only: Homebrew
# called it an "Empty installation" because StackVet's main moved while it built (StackVet backlog 0697).
#
# Why: for a --HEAD build Homebrew names the version from GitHub's latest commit on main when it starts
# ("Formula sv (HEAD-e7a0a6b)"), the build itself asks again and installs under that answer, and the check after the
# build looks for the first name. When a commit lands on main in between, the install is complete in the second
# folder and the check finds no first one, and says "Empty installation" (seen on 21 November 2026: named HEAD-e7a0a6b,
# installed into HEAD-2dfff8b, which merged on main 40 seconds after the build was named). Homebrew's own code:
# formula_installer.rb raises it after `formula.update_head_version`, and GitHubGitDownloadStrategy#last_commit asks
# the GitHub API.
#
# The retry happens only when the log says "Empty installation", the folder Homebrew named does not exist, and
# another HEAD folder under the Cellar holds the install. It says so, with the folder's listing, so a run that passes
# on the retry still shows it happened. Any other failure, a release build, or a retry that fails, fails the step.
#
#     .github/scripts/install-sv.sh release|head
#     BREW=/path/to/a/fake/brew .github/scripts/install-sv.sh head    # what the tests do
set -u -o pipefail
BREW="${BREW:-brew}"
formula=abbyshade111/stackvet/sv
case "${1:-}" in
  release) flags=(--verbose) ;;
  head) flags=(--HEAD --verbose) ;;
  *) echo "usage: install-sv.sh release|head" >&2; exit 2 ;;
esac
log="$(mktemp "${TMPDIR:-/tmp}/install-sv.XXXXXX")" || { echo "::error::install-sv.sh could not make a file for the install's log" >&2; exit 1; }
trap 'rm -f "$log"' EXIT
if "$BREW" install "${flags[@]}" "$formula" 2>&1 | tee "$log"; then
  exit 0
fi
[ "$1" = head ] || exit 1
grep -q "sv: Empty installation" "$log" || exit 1
named="$(grep -oE 'Formula sv \(HEAD-[0-9a-f]+\)' "$log" | head -1 | grep -oE 'HEAD-[0-9a-f]+' || true)"
cellar="$("$BREW" --cellar)/sv"
built=""
for folder in "$cellar"/HEAD-*; do
  if [ -d "$folder" ] && [ -n "$(ls -A "$folder")" ]; then
    built="$(basename "$folder")"
  fi
done
if [ -z "$named" ] || [ -z "$built" ] || [ "$named" = "$built" ] || [ -e "$cellar/$named" ]; then
  echo "::error::Homebrew said \"Empty installation\", and it was not main moving during the build (named: ${named:-none}, installed: ${built:-nothing}), so it is not retried."
  exit 1
fi
echo "::warning title=Empty installation, retried once::Homebrew named this build $named, then installed it into $built: StackVet's main moved while it built, so Homebrew's own check looked in a folder that was never made (StackVet backlog 0697). The install is retried once."
ls -laR "$cellar" 2>&1 | head -40
"$BREW" uninstall --force "$formula" || true
"$BREW" install "${flags[@]}" "$formula"
