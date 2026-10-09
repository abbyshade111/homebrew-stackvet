# Homebrew for StackVet

[StackVet](https://github.com/abbyshade111/StackVet)'s `sv` checks an app, written in any language, against the
OWASP security standards, and says plainly what it checked and what it did not.

This repository lets Homebrew install `sv` on a Mac or on Linux. Homebrew builds it on your own computer and
fetches what the build needs by itself. The first install compiles all of StackVet, so it takes a while (longer on an
older or busier computer), and it needs several gigabytes of free disk space while it builds. If your Mac says it has
run out of application memory, free some disk space first: macOS uses free disk as extra memory.

```bash
brew install --HEAD abbyshade111/stackvet/sv
sv --version
```

`--HEAD` builds the latest StackVet. StackVet has no numbered release yet; when it does, `brew install
abbyshade111/stackvet/sv` will install that, and `--HEAD` will stay for the latest code.

To update later: `brew upgrade --fetch-HEAD sv`.

**Windows:** Homebrew does not run on Windows, and `sv` has not yet been built or tried there. Use StackVet's
Docker image for now (see StackVet's `docs/GETTING-STARTED.md`).

The checks in `.github/workflows/test.yml` install `sv` this way on a Mac and on Linux and run a real check with
it, on every change here and once a week.
