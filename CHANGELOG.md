# Changelog

All notable changes to Centurion Code releases are documented here.
This file is the source of release notes (`gh release create --notes-file CHANGELOG.md`).

## [0.1.1] - 2026-06-27
* Centurion is now the agent. It owns a THINK, ACT, OBSERVE loop and runs its own jailed tools;
  the vendor CLI is used as a read-only per-turn reasoner (default for the codex engine) instead of
  doing the work itself. The verify-until-proven gate still decides completion.
* `centurion connect` (alias `login`): pick a main reasoning engine and sign in through the vendor's
  own official login. Centurion never reads or stores a vendor token. First run on a terminal offers
  the picker; the banner shows real login readiness; startup fails loud with the fix command when the
  main engine is not signed in.
* The terminal UI is the default on a TTY: a bordered input box with a live slash-command
  autocomplete dropdown, and a clean fallback to the plain prompt when a TTY is unavailable.
* Safety hardening: a credential-path denylist on the file tools (refuses reading or writing `.env`,
  private keys, `auth.json`, and similar, while still allowing `.env.example` and ordinary source);
  honest verification when a goal defines no checks; and first-run guards against scanning a home
  directory.

## [0.1.0] - 2026-06-27
* Initial public distribution: signed macOS, Linux, and Windows binaries, the `install.sh` and
  `install.ps1` installers, and the npm convenience wrapper.
* `centurion update`: self-update from signed releases. Each release ships a signed manifest
  (Ed25519); the binary verifies the signature against a key compiled into it, then verifies size
  and SHA-256, then atomically replaces itself. Refuses to downgrade and defers to `npm` when
  installed that way.
