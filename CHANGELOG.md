# Changelog

All notable changes to Centurion Code releases are documented here.
This file is the source of release notes (`gh release create --notes-file CHANGELOG.md`).

## [1.2.3] - 2026-07-25

Install with npm, and a loop that stops giving up early.

### Added

* **`npm i -g @thecenturion/code`.** Until now the only ways in were a curl script or a manual binary download. The npm package pulls exactly one native binary for your platform rather than all six, and both `centurion` and `cen` work immediately.

  npm treats a failed optional dependency as a *successful* install, which is how a wrapper ends up reporting success while the command is missing or truncated. So both failure paths are explicit here. Every platform package records its binary's SHA-256, and it is checked once at install and again before the binary runs: a truncated or tampered download is refused rather than executed. If the platform package is missing entirely, the error names the package, explains why npm let the install pass, and prints the curl command that will work.

### Fixed

* **A repeated failure now gets the retry the policy promises.** The loop documents "same failure twice, resume the engine, then escalate to a human". That decision was being read *after* an anti-livelock guard had already ended the run, so neither the resume nor the escalation ever happened. A goal whose typecheck failed the same way twice, which is what happens whenever the first repair does not touch the failing file, stopped on attempt 2 of 6 with two thirds of its budget unspent.

* **Progress inside a single failing check is no longer read as no progress.** A run taking one test file from 40 failures to 5 to 1 changed the same file every time and never flipped a check from red to green, so it scored as "no measurable progress" and was stopped, while the error was demonstrably different on every attempt.

* **A declared check is now protected from tampering, the same as a discovered one.** Pinning your proof surface in `CENTURION.md` is the documented, recommended way to do it, and it was the one path where the protection did not apply. An engine could rewrite its own `test` script to `echo ok`, the verifier would run the rewritten script, and the run would be reported as proven. In a workspace with several packages the snapshot now follows the check's own directory rather than the repository root.

* **A goal whose only writes were ignored by git is no longer closed as "workspace unchanged".** Regenerating a `dist/` folder looked to the loop like a run that changed nothing, and it was closed with a passing report on a workspace it had actually modified.

* **A resumed run no longer points the engine at the wrong check.** After a crash, the repair prompt reconstructed which checks had failed from the counts alone, so a run where only `typecheck` failed told the engine to fix the `build`, with the TypeScript error attached to it. A resumed run also gets the same retry budget as one that never crashed.

* **Stopping a turn now stops everything it started.** Cancelling a turn signalled only the vendor CLI, so the tool subprocesses and MCP servers it had launched kept running in the background for the life of the machine. They are now stopped as a group, and the stop escalates so a process that ignores the first signal cannot hang the turn instead.

* **A long session no longer gets slower the longer it runs.** Every turn re-read the entire history of the session, so cost grew with age. Turns now read only what that turn produced.

* **The credential store for the default engine is cleaned up, and no longer disappears mid-session.** It was never collected, so a directory accumulated per session, and a session left open for more than three days could have its store deleted underneath it, after which the engine reported "not logged in" and the run ended.

### Changed

* Code formatting is now part of the verify gate, so drift is caught in your working tree rather than in review.
* `centurion init` no longer pins a new project to a superseded model.

### Security

* When an MCP server is configured with a credential, the CLI now tells you that the value travels on the vendor's command line where any local process listing can read it. The alternative the code claimed to offer does not exist: the vendor gives its MCP servers a minimal environment that does not include the parent's, verified directly. Moving these values into the per-session config file is tracked as follow-up work.

## [1.2.2] - 2026-07-24

### Fixed

* On Windows, updating no longer leaves the `cen` command behind. The installer creates `cen.exe` as a copy of `centurion.exe` rather than a link, and self-update only replaced the file you invoked, so `centurion update` moved `centurion` to the new version while `cen` stayed on the old one indefinitely. Both commands are now refreshed together. If the alias cannot be refreshed the update still succeeds and says which file to fix. macOS and Linux were never affected, because there `cen` is a symlink that follows automatically.

If you are on Windows and already on 1.2.1 or earlier, run `centurion update` once to pick this up. If `cen --version` still disagrees with `centurion --version` afterwards, re-run the installer and both will be correct from then on.

## [1.2.1] - 2026-07-24

A correctness release. Every fix below was found by a cross-model audit of the shipped code,
confirmed against the source before anything was changed, and is covered by a test.

### Fixed: the verify loop

* The engine is now told which checks it will be judged by. A plain-language goal carries no checks of its own, so Centurion discovered typecheck, test and build while showing the engine nothing, and then graded it on commands it had never seen. Those checks now appear in the prompt, and a repair prompt also names the checks that are already passing and must stay that way.
* A second goal in the same session no longer inherits the first one's attempts. The attempt counter, failure history and progress streak were shared across every goal in a session, so later goals started part-way through their retry budget, were told to fix the previous request's failures, and eventually gave up instantly without ever starting the engine.
* Ordinary error text no longer ends a healthy run. Any output containing 401, login, or invalid token was read as lost authentication, so a stack trace line number or a routine syntax error could stop a run that was working fine.
* Verification commands now receive the environment variables Windows requires, so a check can no longer fail on Windows for reasons unrelated to your code.

### Fixed: commands that did not do what they said

* `/plan` waits for your answer. Previously the approval question was asked after the decision had already been made: without `--bypass` every plan was refused no matter what you typed, and with `--bypass` work started while the question was still on screen.
* `/resume` is now all-or-nothing. Resuming a session owned by another process used to move your working directory before the switch was refused, leaving you attached to the old session while pointed at the new one's files.
* `/apply --check` validates a patch without applying it. The flag was advertised in the error message but never read, so following that advice changed your files.
* `/undo` says plainly that it stashes the entire working tree, not only the last turn, and asks before doing it.
* `/help <command>` now explains the extension commands it already lists, instead of reporting them as unknown.
* `/run` documents that it launches a program directly and uses no shell, and warns when shell syntax would be passed through literally.
* `/diff` shows the actual diff, with `--stat` for the short summary.
* An unrecognized answer at an approval prompt now says what is accepted and asks again.
* `/handoff` describes what it really does: it picks the engine your next session starts on.

### Added

* Claude Opus 5 is selectable on the Claude provider.

### Changed

* The em-dash character is gone from the product, its documentation and its terminal output.
* Repository formatting is normalized, so routine changes stop carrying unrelated reformatting.
* A timing-sensitive test now measures the algorithm instead of the machine, so a busy CI host no longer reports a false failure.

## [1.2.0] - 2026-07-24

### Session and context
* `/compact` now creates real model-backed session summaries, supports steering, and can compact automatically between turns.
* `/branch` forks a conversation, while `/rewind` lets you move through the session checkpoint timeline.
* `/cd` changes the session's primary root, `/add-dir` adds extra read contexts, and `/worktree` can enter or leave a worktree, including at launch with `--worktree`.

### Commands and UX
* `/copy` copies assistant responses, and `/export` produces a human-readable session transcript.
* `/todos` renders the session todo ledger, backed by native task-list tools.
* `/attach` adds image and PDF inputs to chat turns.
* `centurion auth` and `/providers` now share one authentication service, with JSON output available for scripting.
* `centurion schedule add`, `list`, and `rm` manage stored schedules. This release stores schedules only; the execution daemon is not yet shipped.
* `--safe-mode` starts Centurion with all customizations disabled.
* `/focus` switches to an essentials-only view and `/color` sets the session accent.
* Goal runs now emit outcome notifications with a notify frame, so a finished or failed goal is announced instead of discovered.
* Usage now detects observed quota markers, catches Grok quota exhaustion even when the CLI exits successfully, and warns at the 80 percent soft cap.

### Agents and orchestration
* `/fork` starts a parallel read-only subagent and returns its result to the session.
* The TUI and web surface show a live activity tree for swarm agents.
* A desktop GUI bridge exposes a global session index, runtime identity, one-shot attach, and remote status for the desktop app.
* `/btw` asks a disposable side question without adding it to the session context, and can queue or use an alternate engine while a main turn is running.

### Models
* The model picker was refreshed from live provider probes. Gemini 3.6 Flash is the default runnable Gemini model, replacing the retired Gemini 3.1 Pro Preview option.

### Windows and CI hardening
* Windows handling is more portable across provider executable resolution, repository-relative guard paths, verifier grep proof paths, and session publication retries.
* CI now runs the real verify gate in merge requests and includes a native Windows verification lane.

### Memory
* Centurion now performs autonomous recall and presents a recap when a session starts.
* A `/btw` digest can seed session memory after a disposable side question.

## [1.1.27] - 2026-07-05
* Claude chat turns reuse a native warm session through `--resume`, so follow-ups send only fresh context. Centurion owns and cleans up its session files without disturbing Keychain authentication.
* The footer ledger now shows metered tokens, cache reads separately, cost, and context-window pressure, and restores this information when a session resumes.
* Centurion identity now lives in the system layer, so a riding Claude turn answers as Centurion without reaching into `~/.claude`.
* Casual turns use a lite path with tools off instead of starting the full agentic loop and resending the full preamble.
* The TUI shows each model's real supported effort level rather than treating the membership tier as its effort setting.
* The active thinking bar now has a premium metallic shimmer and ultra-purple treatment, with a clean non-truecolor and non-TTY fallback. Set `CENTURION_NO_ANIMATION=1` to freeze it.
* `CENTURION_OBSERVABILITY=1` enables structured hot-path instrumentation without logging prompts, paths, or IO, and has near-zero cost when disabled.
* Coding now rides the vendor CLI's own warm loop by default. The native oracle remains available for verification, jailed tools, and cross-provider work.

## [1.1.26] - 2026-07-04
* Token counting is now accurate and live on every path, including a plain chat message that runs
  the provider's own agentic loop. Real Claude turns stamp usage on each streamed step (nested under
  the message), which the counter now reads, so the number climbs during the turn and settles on the
  true total instead of freezing at a tiny estimate. A short read-two-files turn now reports tens of
  thousands of tokens (what it actually cost) rather than a handful.
* A tighter native loop. In a goal run the agent may now batch several independent read-only lookups
  (for example reading many known files) into one step instead of one round trip per file, which cuts
  wasted turns and tokens on read-heavy work. The batch is capped and only used for independent reads;
  anything that depends on a prior result, or that writes, still runs one step at a time.
* Autonomous memory tools. The agent can now search, read, and append its own local Centurion memory
  during a run (memory_search, memory_read, memory_write). Writes are appended only, jailed to the
  Centurion memory files, and secret-redacted; reads are redacted too so a stored secret is never
  echoed back. An activity summary line reflects what the turn did (read, searched, wrote memory).
* The loop-stall guard no longer falsely kills a run that legitimately re-reads the same context file
  each step; it still stops a genuine repeat of the same batch.

## [1.1.25] - 2026-07-03
* Redesigned the status line to be point-driven: the permission mode sits on the far left and a
  single manage affordance sits on the far right, showing the live shell count and highlighting when
  shells are running. The version, model, and working directory are no longer duplicated on the
  footer (they stay in the banner), and the down-arrow opens a navigable manage panel that descends
  into Shells, Tasks, Agents, and the command panels.
* Accurate token accounting. The native provider path now reports real input, output, and cache
  tokens, and a live usage signal updates the counter during a turn instead of only at the end, so
  the working indicator reflects true token expenditure rather than a tiny estimate.
* More reliable long turns. The per-step timeout is now an inactivity timeout with a generous
  absolute ceiling: a turn that keeps producing output is never killed mid-flight, while a genuinely
  stalled turn still stops with a clear reason. This fixes healthy turns on large prompts being
  cut off prematurely.

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
