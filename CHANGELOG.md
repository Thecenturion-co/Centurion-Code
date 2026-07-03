# Changelog

All notable changes to Centurion Code releases are documented here.
This file is the source of release notes (`gh release create --notes-file CHANGELOG.md`).

## [1.1.24] - 2026-07-03
* Terminal UI now uses the terminal's native scrollback: mouse, trackpad, and PageUp
  scroll through history and text selection and copy work. The header no longer
  duplicates or disappears, the banner prints once, and the version, model, and working
  directory stay pinned in the status line.
* Reworked the footer navigation: the down-arrow opens a manage panel that reaches
  Shells, Tasks, Agents, and the command panels (the old `ctrl+s` shortcut is removed).
* The agent no longer loses track of an earlier request: every turn carries a compact
  summary of the prior conversation in this session, including on the native provider
  path. Queued and interrupted (Esc) messages are persisted, so they are not dropped and
  re-surface on resume.

## [1.1.23] - 2026-07-03
* Native web research: `web_search` and `web_extract` tools find and read live pages inside a run,
  with truncation, workspace caching, and on-demand paging for token efficiency. The search backend
  is swappable and defaults to a keyless backend (DuckDuckGo).
* Command artifacts: `artifact_create` / `artifact_update` / `artifact_list` produce self-contained
  HTML artifacts under the workspace, listed by `/artifact`. Artifacts use a strict CSP and are
  written inside a path jail.
* Grok adapter fixed so `grok` runs as a backing engine again, and `env-sync` no longer copies LLM
  provider OAuth keys (adds `--purge-llm-keys`).
* Terminal UI: reliable scrolling, a sticky header, a shells panel (Ctrl-S), interrupt that keeps the
  drafted message, and an in-TUI run recap.
* Fixes: restored Anthropic/Claude engine authentication, tightened the verifier and credential
  handling, honest local-memory reporting, and Codex headless turns no longer trigger desktop
  notifications.

## [1.1.19] - 2026-07-01
* Binary release matrix expanded and documented for macOS Apple Silicon, macOS Intel,
  Windows x64, Windows ARM64, Linux x64, and Linux ARM64.
* Public installers now create both `centurion` and `cen`, verify release checksums,
  and select the correct Windows architecture.
* Provider surface now documents OAuth and API-key paths for OpenAI/Codex,
  Anthropic/Claude, Google Gemini/Antigravity, and xAI/Grok.
* README refreshed as a binary-distribution front door with the current TUI,
  advisor/council/swarm workflows, signed-update model, and source boundary.

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
