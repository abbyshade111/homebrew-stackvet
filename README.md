# Homebrew for StackVet

[StackVet](https://github.com/abbyshade111/StackVet)'s `sv` checks an app, written in any language, against the
OWASP security standards, and says plainly what it checked and what it did not.

This repository lets Homebrew install `sv` on a Mac or on Linux. Homebrew builds it on your own computer and
fetches what the build needs by itself. The first install compiles all of StackVet, so it takes a while (longer on an
older or busier computer), and it needs several gigabytes of free disk space while it builds. If your Mac says it has
run out of application memory, free some disk space first: macOS uses free disk as extra memory.

```bash
brew install abbyshade111/stackvet/sv
sv --version
```

That builds the latest numbered release of StackVet (0.2.0), and `sv --version` says so. To build StackVet's latest
code from its `main` instead, add `--HEAD`: `brew install --HEAD abbyshade111/stackvet/sv`.

To update later: `brew upgrade sv` for the next release, or `brew upgrade --fetch-HEAD sv` if you installed with
`--HEAD`.

**Windows:** Homebrew does not run on Windows. Install `sv` with Scoop instead, from the bucket
`abbyshade111/scoop-stack-vet` (see StackVet's `docs/GETTING-STARTED.md`), or use StackVet's Docker image.

The checks in `.github/workflows/test.yml` install `sv` both ways, the release and `--HEAD`, on a Mac and on Linux and run a real
check with it, on every change here and once a week. Each of those four jobs first checks that `main`'s rules require it by
its name, so a job renamed, or a system added to the matrix, fails until the ruleset requires it too.
