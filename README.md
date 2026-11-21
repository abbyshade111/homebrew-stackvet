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

That builds the latest numbered release of StackVet (0.3.0), and `sv --version` says so. To build StackVet's latest
code from its `main` instead, add `--HEAD`: `brew install --HEAD abbyshade111/stackvet/sv`.

To update later: `brew upgrade sv` for the next release, or `brew upgrade --fetch-HEAD sv` if you installed with
`--HEAD`.

**ConfigVet's `cv`**, StackVet's companion for an app's deployment files (Dockerfiles, compose files, Kubernetes
manifests, and Terraform plans), is here too, from StackVet v0.3.0:

```bash
brew install abbyshade111/stackvet/cv
cv --version
```

`--HEAD` builds it from `main` instead.

`cv check` also runs hadolint, Checkov, and Trivy where they are installed (`brew install hadolint checkov trivy`), and
says so where they are not.

**Windows:** Homebrew does not run on Windows. Install `sv` with Scoop instead, from the bucket
`abbyshade111/scoop-stack-vet` (see StackVet's `docs/GETTING-STARTED.md`), or use StackVet's Docker image.

The checks in `.github/workflows/test.yml` install `sv` both ways, the release and `--HEAD`, and `cv`'s release, on a Mac
and on Linux and run a real check with each, on every change here and once a week. Each of those six jobs first checks that `main`'s rules require it by
its name, so a job renamed, or a system added to the matrix, fails until the ruleset requires it too.

A `--HEAD` install builds StackVet's `main` as it is that minute. When a commit lands on `main` while it builds, Homebrew
installs it under the new commit's name but then looks for the old one, and says "Empty installation" about a complete
install. `.github/scripts/install-sv.sh` retries that one case once, and says so in the run; any other failure is not
retried. `.github/scripts/test-install-sv.sh` checks both, with a stand-in for `brew`.
