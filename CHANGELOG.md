# Changelog

All notable changes to Centurion Code releases are documented here.
This file is the source of release notes (`gh release create --notes-file CHANGELOG.md`).

## [0.1.0] - 2026-06-27
* Initial public distribution: signed macOS, Linux, and Windows binaries, the `install.sh` and
  `install.ps1` installers, and the npm convenience wrapper.
* `centurion update`: self-update from signed releases. Each release ships a signed manifest
  (Ed25519); the binary verifies the signature against a key compiled into it, then verifies size
  and SHA-256, then atomically replaces itself. Refuses to downgrade and defers to `npm` when
  installed that way.
