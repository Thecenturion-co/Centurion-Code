# Changelog

All notable changes to Centurion Code releases are documented here.
The private source changelog is the release-note authority. This public copy keeps the downloadable
product history readable without publishing the production source tree.

## [1.3.3] - 2026-09-11

v1.3.3 lets the workspace see and steer its agents. An in-process advisor
answers beside the main agent. Sub-agent teams span providers. Agents View
shows live and saved sessions full screen. Every provider can use Centurion's
monitor and command tools. Fresh sessions recall the previous conversation.

### Added

- Native turns can ask a standing `/advisor` counterpart through `advisor_consult`. A bold live
  line shows the advisor model, elapsed time, and output tokens, then leaves a receipt.
- Cross-provider sub-agent teams launch one seat per provider through `agent_launch` from
  `/code-review` and `/goal` team requests, and return one merged report.
- Agents View: press LEFT on an empty prompt to open a full-screen view of live agents and saved
  sessions.
- Native turns on every provider, including Gemini auto, can use Centurion's `monitor` and
  `run_command`, recorded on the process table.
- Plug-and-play providers register a generic CLI adapter and prove cache, plan-mode refusal,
  effort, and tool results against shared conformance fixtures. `centurion doctor --probe`
  reports the capability matrix.
- `send_feedback` drafts a structured, redacted feedback item that stays queued locally and is
  never sent.
- Fresh sessions recall the previous conversation in the same directory through a bounded
  digest, and `memory_search` covers session recaps and summaries.
- `/code-review` answers a fixed senior engineering checklist item by item.

### Changed

- Grok follow-up turns resume the vendor session instead of starting cold. Grok launches deny
  provider-native scheduler and monitor tools that Centurion cannot see.
- Failed provider calls share one failure class and message shape across Codex, Claude, Grok,
  and Gemini, with the vendor error kept as detail.
- Status headline tokens count generated output, not context occupancy. Gemini thinking is
  reported beside output.
- Session summaries always carry Task, Decisions, Files touched, Open threads, and Exact resume
  steps.
- Plan mode shows a blue footer chip. Mode-toggle commands echo once in the transcript.
- CLI tables honor a terminal-wide width budget.
- Turn receipts stop at `cooked for`, and the config panel Advisor row shows the advisor model
  or `none`.
- `/help` lists every command in its catalog group, and `/focus` refuses outside the TUI.

### Fixed

- `/init` no longer saves a start-ladder fallback as the project's active engine.
- A live `/model` pick is no longer overwritten by a leftover legacy `config.model`, so the
  Effort picker and welcome banner follow the chosen model.
- Tool call status matches results by call id, so parallel calls keep their own verdicts.
- OTLP/HTTP JSON export sends numeric status and span kind values a strict collector accepts.
- Delayed Windows process-tree cleanup leaves a process alone unless it can prove the process is
  its own.
- The schedule executor stops cleanly when a store read fails during shutdown.
- Binary release builds verify the size and format of every produced artifact.
- `/rewind` restores a retained Git checkpoint after `git gc`.
- A stalled sync-server subscriber can no longer grow the relay send buffer without bound.
- A canceled or failed Codex or streaming turn waits for the vendor process before cleanup.

### Notes

- The wire protocol moves to 0.31.0. GoalSpec no longer carries `acceptance` or `retryBudget`.

## [1.3.2] - 2026-09-09

v1.3.2 makes 1.3.1 actually runnable. Harness control text stays out of chat.
Plain conversational turns stay out of goal runs. Codex, Claude, Grok, and
Gemini share one usage observability contract. The activity line shows the live
token figure and thinking state.

### Added

- Provider usage observability now shares one contract across Codex, Claude, Grok, and Gemini.
  Cache the engine does not report is shown as unavailable, not as zero.
- The activity line enters a declared-effort thinking state before provider output, and its live
  token figure comes from that shared ledger.
- Session turns can raise structured questions. The terminal and desktop can answer them.
  Headless runs can answer them through `--interaction-handler` before the session continues.

### Changed

- Harness control comments stay out of transcripts and recaps. Durable session logs reach chat
  only when they are marked for the user.
- Chat turns keep bare generic coding keywords such as `test` on the conversational path until the
  prompt gives them context.
- Tool success markers render green. The welcome header moves into scrollback when the first
  prompt starts.
- `/feedback` leaves unknown draft fields blank, quotes the operator's words as said, and does
  not send, submit, approve, or post a draft.
- Isolation cleanup keeps worktrees that still have changes. Explicit merge and discard still
  remove them.

### Notes

- 1.3.1 removed the pre-1.3.0 goal driver. `code.sessionLoop.enabled` remains in the schema but no
  longer selects a second driver.

## [1.3.0] - 2026-09-07

### Changed

- The top layer is now a session loop. Every entry point submits an envelope, a user message, a
  finished job, a timer, a worker report, a peer message or a monitor signal, into one loop. The
  loop assembles context, calls the model, runs the tool calls it asks for, and ends the turn when
  it asks for none. There is no top-level DONE state, because a finished turn is not a finished run.
- Verification is a native `verify` tool the model can call, plus a Stop hook on workers, rather
  than a state the run passes through. It still runs your real commands as real subprocesses, and
  the command behind each required check is still snapshotted before the engine gets a turn.
- Ceilings are configuration under `code.sessionLoop`: `maxModelCallsPerEnvelope`,
  `maxToolCallsPerIteration`, `maxEnvelopeWallMs`, `maxDeliveryAttempts`, `maxWorkersInFlight` and
  `maxWorkerDepth`.
- Swarm and workflow work runs on session workers.
- Every catalog command carries a status and emits `command.completed`, with a generated contract
  test that fails the build on catalog or registry drift.

### Fixed

- `/verify` reports a failed verification as failed. The result is bound to the current verification
  run, so a passing verification from an earlier turn can no longer be read as this one's.
- `centurion -p --output-format json` reports usage, cost and latency again instead of null, and
  plain text output is the literal model answer rather than the redacted transcript copy. Persisted
  transcripts stay redacted, and the JSON envelope keeps persistence-grade redaction.
- Terminal lifecycle events are appended before lease release, so a release failure can no longer
  swallow them.

### Notes

- The pre-1.3.0 goal state machine is retained for one release behind `code.sessionLoop.enabled`
  set to `false`. Its removal is scheduled for 1.3.1.
- Releases 1.2.17, 1.2.18 and 1.2.19 were published without an entry in this public changelog. Their
  changes are carried forward in 1.3.0 rather than reconstructed here.

## [1.2.16] - 2026-08-27

The reliability and collaboration release.

### Added

- Clipboard image paste now follows the same attachment flow as `/attach`, with terminal drag-and-drop
  and `/learn` keeping local paths out of provider prompts. Unsupported terminals receive a direct
  `/attach <path>` fallback. Attachment reads that cannot be inlined now produce an unreadable marker
  instead of failing the turn.
- `/advisor <question>` can query connected models in parallel, show which model answered, and make
  disagreement visible. `/advisor off` and `/advisor reset` now also clear the saved advisor selection.
- `/consult` now uses a provider-aware default synthesizer, gives each provider an appropriate time
  budget, and shows when a response was cut off instead of counting it as a silent vote.
- Running sessions can exchange messages with another coding agent through
  `centurion peer register|list|send|inbox`. The exchange is bounded and clearly attributed, and peer
  input stays separate from operator input and durable memory.
- A model can launch bounded, isolated workers during a turn. Shells and Agents panels now record
  work from the actual launch site, and failed worker cleanup is reported.

### Changed

- Token and context reporting now separates usage from cache occupancy. Token displays count input and
  output, context pressure remains cache-inclusive, and the active line shows current-turn reasoning
  and effort, using provider-reported reasoning counts when available.
- Scheduled `/loop` runs now check their context budget at every iteration, compact when possible, and
  deliver escalating low-context alerts when compaction is disabled or cannot keep up. Cancellation is
  rechecked before another turn is sent.
- The terminal, desktop, and mobile surfaces now agree on turn outcomes: an intentional interruption is
  shown as an interruption, a timeout remains a failure, and commands settle once with the handler's
  actual result. Casual chat also follows the available tool-mode fallback instead of aborting.
- Help output and the headless entry point now use the same command catalog as the TUI. Tool activity
  includes every tool, and the Docs panel lists artifacts the session actually produced.
- Provider discovery and selection are more honest about authentication, partial model listings,
  retired model pins, and quota failures, so unavailable or incomplete provider state is not presented
  as ready to use. Failed tool calls now surface as failures rather than hanging.

### Fixed

- Timeouts and cancellation now clean up entire process trees, including Windows probe trees and command
  descendants, while background work keeps a durable record when teardown is not yet proven.
- Memory and local-state recovery now handles unsafe symlinks, custom homes, root directories, and
  cancellation without escaping the configured boundary or turning cleanup into an unhandled failure.
- Cross-engine conformance and reliability coverage now exercises cancellation, timeouts, usage
  reporting, wait budgets, process identity, and cleanup paths consistently.

## [1.2.15] - 2026-08-21

The operator-surface release.

### Added

- A centered, responsive terminal workspace with one filled steel-and-ink table system for commands,
  Shells, Tasks, Agents, Docs, providers, models, effort, configuration, resume, advisor, and
  approvals. Narrow terminals compact the header and tables instead of breaking their alignment.
- Actionable configuration rows and provider-aware model and effort pickers. Advisor selection is
  limited to models on connected providers, and the provider table reports the model and effort that
  actually run.
- A durable background-session supervisor with bounded logs, attach, stop, process-tree ownership,
  and honest `unknown` liveness. Native long-running commands also have durable job list, output, and
  kill tools.
- Native file, search, patch, monitoring, memory, and command surfaces continue to grow behind the
  same operator-controlled permission boundary. macOS can opt native commands into a fail-closed
  workspace-write sandbox.
- A guarded GitLab-to-GitHub publication job. A tag stays red unless all six binaries, checksums, the
  signed manifest, and its detached signature are validated and present on the public latest release.

### Changed

- The command catalog is the single source used by the TUI and protocol consumers, preventing help,
  desktop, and command execution from drifting apart.
- Memory rewrites update the same durable fact instead of accumulating duplicates. Provider fallback
  happens only before a turn begins; a started turn remains sticky to its provider.
- Update checks continue to use the signed GitHub latest-release manifest. The CLI refreshes in the
  background at most once per day, while `centurion update --check` queries it immediately.

## [1.2.14] - 2026-08-13

The operator-control release: trusted context boundaries, durable jobs and workflows, and model
surfaces that report what actually ran. It added Gemini 3.7 Flash as the default Gemini, memory
search/edit attribution, resumable swarm replies, durable background command jobs, provider-state
reconciliation, and tighter command and credential boundaries.

## [1.2.3] - 2026-07-25

A loop that stops giving up early, and an npm channel built ready to publish.

### Added

- **An npm install channel is now built into every release.** A meta package pulls exactly one native
  binary for your platform rather than all six, and both `centurion` and `cen` work immediately. Each
  platform package records its binary's SHA-256, checked once at install and again before the binary
  runs, so a truncated or tampered download is refused rather than executed. If npm skips the platform
  package, which it does silently for optional dependencies, the error names the package and prints
  the installer command that will work.

  The packages are built and verified as part of the release, but are not on the public npm registry
  yet. Until they are, use the installers above. This entry will name the exact command once it is
  live.

### Fixed

- **A repeated failure now gets the retry the policy promises.** The loop documents "same failure twice, resume the engine, then escalate to a human". That decision was being read _after_ an anti-livelock guard had already ended the run, so neither the resume nor the escalation ever happened. A goal whose typecheck failed the same way twice, which is what happens whenever the first repair does not touch the failing file, stopped on attempt 2 of 6 with two thirds of its budget unspent.

- **Progress inside a single failing check is no longer read as no progress.** A run taking one test file from 40 failures to 5 to 1 changed the same file every time and never flipped a check from red to green, so it scored as "no measurable progress" and was stopped, while the error was demonstrably different on every attempt.

- **A declared check is now protected from tampering, the same as a discovered one.** Pinning your proof surface in `CENTURION.md` is the documented, recommended way to do it, and it was the one path where the protection did not apply. An engine could rewrite its own `test` script to `echo ok`, the verifier would run the rewritten script, and the run would be reported as proven. In a workspace with several packages the snapshot now follows the check's own directory rather than the repository root.

- **A goal whose only writes were ignored by git is no longer closed as "workspace unchanged".** Regenerating a `dist/` folder looked to the loop like a run that changed nothing, and it was closed with a passing report on a workspace it had actually modified.

- **A resumed run no longer points the engine at the wrong check.** After a crash, the repair prompt reconstructed which checks had failed from the counts alone, so a run where only `typecheck` failed told the engine to fix the `build`, with the TypeScript error attached to it. A resumed run also gets the same retry budget as one that never crashed.

- **Stopping a turn now stops everything it started.** Cancelling a turn signalled only the vendor CLI, so the tool subprocesses and MCP servers it had launched kept running in the background for the life of the machine. They are now stopped as a group, and the stop escalates so a process that ignores the first signal cannot hang the turn instead.

- **A long session no longer gets slower the longer it runs.** Every turn re-read the entire history of the session, so cost grew with age. Turns now read only what that turn produced.

- **The credential store for the default engine is cleaned up, and no longer disappears mid-session.** It was never collected, so a directory accumulated per session, and a session left open for more than three days could have its store deleted underneath it, after which the engine reported "not logged in" and the run ended.

### Changed

- Code formatting is now part of the verify gate, so drift is caught in your working tree rather than in review.
- `centurion init` no longer pins a new project to a superseded model.

### Security

- When an MCP server is configured with a credential, the CLI now tells you that the value travels on the vendor's command line where any local process listing can read it. The alternative the code claimed to offer does not exist: the vendor gives its MCP servers a minimal environment that does not include the parent's, verified directly. Moving these values into the per-session config file is tracked as follow-up work.

## [1.2.2] - 2026-07-24

### Fixed

- On Windows, updating no longer leaves the `cen` command behind. The installer creates `cen.exe` as a copy of `centurion.exe` rather than a link, and self-update only replaced the file you invoked, so `centurion update` moved `centurion` to the new version while `cen` stayed on the old one indefinitely. Both commands are now refreshed together. If the alias cannot be refreshed the update still succeeds and says which file to fix. macOS and Linux were never affected, because there `cen` is a symlink that follows automatically.

If you are on Windows and already on 1.2.1 or earlier, run `centurion update` once to pick this up. If `cen --version` still disagrees with `centurion --version` afterwards, re-run the installer and both will be correct from then on.

## [1.2.1] - 2026-07-24

A correctness release. Every fix below was found by a cross-model audit of the shipped code,
confirmed against the source before anything was changed, and is covered by a test.

### Fixed: the verify loop

- The engine is now told which checks it will be judged by. A plain-language goal carries no checks of its own, so Centurion discovered typecheck, test and build while showing the engine nothing, and then graded it on commands it had never seen. Those checks now appear in the prompt, and a repair prompt also names the checks that are already passing and must stay that way.
- A second goal in the same session no longer inherits the first one's attempts. The attempt counter, failure history and progress streak were shared across every goal in a session, so later goals started part-way through their retry budget, were told to fix the previous request's failures, and eventually gave up instantly without ever starting the engine.
- Ordinary error text no longer ends a healthy run. Any output containing 401, login, or invalid token was read as lost authentication, so a stack trace line number or a routine syntax error could stop a run that was working fine.
- Verification commands now receive the environment variables Windows requires, so a check can no longer fail on Windows for reasons unrelated to your code.

### Fixed: commands that did not do what they said

- `/plan` waits for your answer. Previously the approval question was asked after the decision had already been made: without `--bypass` every plan was refused no matter what you typed, and with `--bypass` work started while the question was still on screen.
- `/resume` is now all-or-nothing. Resuming a session owned by another process used to move your working directory before the switch was refused, leaving you attached to the old session while pointed at the new one's files.
- `/apply --check` validates a patch without applying it. The flag was advertised in the error message but never read, so following that advice changed your files.
- `/undo` says plainly that it stashes the entire working tree, not only the last turn, and asks before doing it.
- `/help <command>` now explains the extension commands it already lists, instead of reporting them as unknown.
- `/run` documents that it launches a program directly and uses no shell, and warns when shell syntax would be passed through literally.
- `/diff` shows the actual diff, with `--stat` for the short summary.
- An unrecognized answer at an approval prompt now says what is accepted and asks again.
- `/handoff` describes what it really does: it picks the engine your next session starts on.

### Added

- Claude Opus 5 is selectable on the Claude provider.

### Changed

- The em-dash character is gone from the product, its documentation and its terminal output.
- Repository formatting is normalized, so routine changes stop carrying unrelated reformatting.
- A timing-sensitive test now measures the algorithm instead of the machine, so a busy CI host no longer reports a false failure.

## [1.2.0] - 2026-07-24

### Session and context

- `/compact` now creates real model-backed session summaries, supports steering, and can compact automatically between turns.
- `/branch` forks a conversation, while `/rewind` lets you move through the session checkpoint timeline.
- `/cd` changes the session's primary root, `/add-dir` adds extra read contexts, and `/worktree` can enter or leave a worktree, including at launch with `--worktree`.

### Commands and UX

- `/copy` copies assistant responses, and `/export` produces a human-readable session transcript.
- `/todos` renders the session todo ledger, backed by native task-list tools.
- `/attach` adds image and PDF inputs to chat turns.
- `centurion auth` and `/providers` now share one authentication service, with JSON output available for scripting.
- `centurion schedule add`, `list`, and `rm` manage stored schedules. This release stores schedules only; the execution daemon is not yet shipped.
- `--safe-mode` starts Centurion with all customizations disabled.
- `/focus` switches to an essentials-only view and `/color` sets the session accent.
- Goal runs now emit outcome notifications with a notify frame, so a finished or failed goal is announced instead of discovered.
- Usage now detects observed quota markers, catches Grok quota exhaustion even when the CLI exits successfully, and warns at the 80 percent soft cap.

### Agents and orchestration

- `/fork` starts a parallel read-only subagent and returns its result to the session.
- The TUI and web surface show a live activity tree for swarm agents.
- A desktop GUI bridge exposes a global session index, runtime identity, one-shot attach, and remote status for the desktop app.
- `/btw` asks a disposable side question without adding it to the session context, and can queue or use an alternate engine while a main turn is running.

### Models

- The model picker was refreshed from live provider probes. Gemini 3.6 Flash is the default runnable Gemini model, replacing the retired Gemini 3.1 Pro Preview option.

### Windows and CI hardening

- Windows handling is more portable across provider executable resolution, repository-relative guard paths, verifier grep proof paths, and session publication retries.
- CI now runs the real verify gate in merge requests and includes a native Windows verification lane.

### Memory

- Centurion now performs autonomous recall and presents a recap when a session starts.
- A `/btw` digest can seed session memory after a disposable side question.

## [1.1.27] - 2026-07-05

- Claude chat turns reuse a native warm session through `--resume`, so follow-ups send only fresh context. Centurion owns and cleans up its session files without disturbing Keychain authentication.
- The footer ledger now shows metered tokens, cache reads separately, cost, and context-window pressure, and restores this information when a session resumes.
- Centurion identity now lives in the system layer, so a riding Claude turn answers as Centurion without reaching into `~/.claude`.
- Casual turns use a lite path with tools off instead of starting the full agentic loop and resending the full preamble.
- The TUI shows each model's real supported effort level rather than treating the membership tier as its effort setting.
- The active thinking bar now has a premium metallic shimmer and ultra-purple treatment, with a clean non-truecolor and non-TTY fallback. Set `CENTURION_NO_ANIMATION=1` to freeze it.
- `CENTURION_OBSERVABILITY=1` enables structured hot-path instrumentation without logging prompts, paths, or IO, and has near-zero cost when disabled.
- Coding now rides the vendor CLI's own warm loop by default. The native oracle remains available for verification, jailed tools, and cross-provider work.

## [1.1.26] - 2026-07-04

- Token counting is now accurate and live on every path, including a plain chat message that runs
  the provider's own agentic loop. Real Claude turns stamp usage on each streamed step (nested under
  the message), which the counter now reads, so the number climbs during the turn and settles on the
  true total instead of freezing at a tiny estimate. A short read-two-files turn now reports tens of
  thousands of tokens (what it actually cost) rather than a handful.
- A tighter native loop. In a goal run the agent may now batch several independent read-only lookups
  (for example reading many known files) into one step instead of one round trip per file, which cuts
  wasted turns and tokens on read-heavy work. The batch is capped and only used for independent reads;
  anything that depends on a prior result, or that writes, still runs one step at a time.
- Autonomous memory tools. The agent can now search, read, and append its own local Centurion memory
  during a run (memory_search, memory_read, memory_write). Writes are appended only, jailed to the
  Centurion memory files, and secret-redacted; reads are redacted too so a stored secret is never
  echoed back. An activity summary line reflects what the turn did (read, searched, wrote memory).
- The loop-stall guard no longer falsely kills a run that legitimately re-reads the same context file
  each step; it still stops a genuine repeat of the same batch.

## [1.1.25] - 2026-07-03

- Redesigned the status line to be point-driven: the permission mode sits on the far left and a
  single manage affordance sits on the far right, showing the live shell count and highlighting when
  shells are running. The version, model, and working directory are no longer duplicated on the
  footer (they stay in the banner), and the down-arrow opens a navigable manage panel that descends
  into Shells, Tasks, Agents, and the command panels.
- Accurate token accounting. The native provider path now reports real input, output, and cache
  tokens, and a live usage signal updates the counter during a turn instead of only at the end, so
  the working indicator reflects true token expenditure rather than a tiny estimate.
- More reliable long turns. The per-step timeout is now an inactivity timeout with a generous
  absolute ceiling: a turn that keeps producing output is never killed mid-flight, while a genuinely
  stalled turn still stops with a clear reason. This fixes healthy turns on large prompts being
  cut off prematurely.

## [1.1.24] - 2026-07-03

- Terminal UI now uses the terminal's native scrollback: mouse, trackpad, and PageUp
  scroll through history and text selection and copy work. The header no longer
  duplicates or disappears, the banner prints once, and the version, model, and working
  directory stay pinned in the status line.
- Reworked the footer navigation: the down-arrow opens a manage panel that reaches
  Shells, Tasks, Agents, and the command panels (the old `ctrl+s` shortcut is removed).
- The agent no longer loses track of an earlier request: every turn carries a compact
  summary of the prior conversation in this session, including on the native provider
  path. Queued and interrupted (Esc) messages are persisted, so they are not dropped and
  re-surface on resume.

## [1.1.23] - 2026-07-03

- Native web research: `web_search` and `web_extract` tools find and read live pages inside a run,
  with truncation, workspace caching, and on-demand paging for token efficiency. The search backend
  is swappable and defaults to a keyless backend (DuckDuckGo).
- Command artifacts: `artifact_create` / `artifact_update` / `artifact_list` produce self-contained
  HTML artifacts under the workspace, listed by `/artifact`. Artifacts use a strict CSP and are
  written inside a path jail.
- Grok adapter fixed so `grok` runs as a backing engine again, and `env-sync` no longer copies LLM
  provider OAuth keys (adds `--purge-llm-keys`).
- Terminal UI: reliable scrolling, a sticky header, a shells panel (Ctrl-S), interrupt that keeps the
  drafted message, and an in-TUI run recap.
- Fixes: restored Anthropic/Claude engine authentication, tightened the verifier and credential
  handling, honest local-memory reporting, and Codex headless turns no longer trigger desktop
  notifications.

## [1.1.19] - 2026-07-01

- Binary release matrix expanded and documented for macOS Apple Silicon, macOS Intel,
  Windows x64, Windows ARM64, Linux x64, and Linux ARM64.
- Public installers now create both `centurion` and `cen`, verify release checksums,
  and select the correct Windows architecture.
- Provider surface now documents OAuth and API-key paths for OpenAI/Codex,
  Anthropic/Claude, Google Gemini/Antigravity, and xAI/Grok.
- README refreshed as a binary-distribution front door with the current TUI,
  advisor/council/swarm workflows, signed-update model, and source boundary.

## [0.1.1] - 2026-06-27

- Centurion is now the agent. It owns a THINK, ACT, OBSERVE loop and runs its own jailed tools;
  the vendor CLI is used as a read-only per-turn reasoner (default for the codex engine) instead of
  doing the work itself. The verify-until-proven gate still decides completion.
- `centurion connect` (alias `login`): pick a main reasoning engine and sign in through the vendor's
  own official login. Centurion never reads or stores a vendor token. First run on a terminal offers
  the picker; the banner shows real login readiness; startup fails loud with the fix command when the
  main engine is not signed in.
- The terminal UI is the default on a TTY: a bordered input box with a live slash-command
  autocomplete dropdown, and a clean fallback to the plain prompt when a TTY is unavailable.
- Safety hardening: a credential-path denylist on the file tools (refuses reading or writing `.env`,
  private keys, `auth.json`, and similar, while still allowing `.env.example` and ordinary source);
  honest verification when a goal defines no checks; and first-run guards against scanning a home
  directory.

## [0.1.0] - 2026-06-27

- Initial public distribution: signed macOS, Linux, and Windows binaries, the `install.sh` and
  `install.ps1` installers, and the npm convenience wrapper.
- `centurion update`: self-update from signed releases. Each release ships a signed manifest
  (Ed25519); the binary verifies the signature against a key compiled into it, then verifies size
  and SHA-256, then atomically replaces itself. Refuses to downgrade and defers to `npm` when
  installed that way.
