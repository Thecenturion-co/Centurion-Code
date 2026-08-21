# Configuration

Everything Centurion stores lives under `~/.centurion` (or `%USERPROFILE%\.centurion` on Windows).
Nothing is written outside your home directory and the project you point it at.

## Where things live

| Path                                      | What it is                                                 |
| ----------------------------------------- | ---------------------------------------------------------- |
| `~/.centurion/config.json`                | Your settings, the table below                             |
| `~/.centurion/sessions/<id>/`             | One directory per session                                  |
| `~/.centurion/sessions/<id>/events.jsonl` | Append-only event log. The session, exactly as it happened |
| `~/.centurion/sessions/<id>/ledger.jsonl` | One row per verification attempt. The evidence trail       |
| `~/.centurion/sessions/<id>/recap.md`     | Human-readable summary written when a goal ends            |
| `~/.centurion/provider-state/`            | Per-session isolation for the vendor CLIs                  |
| `<project>/.centurion/`                   | Project-local state, ignored by git                        |
| `<project>/CENTURION.md`                  | Your project's instructions, commands, and pinned checks   |
| `<project>/goal.yaml`                     | A goal definition, when you want one on disk               |

## Settings

Read or change any of these with `/config <key>` and `/config <key> <value>` in the TUI, or
`centurion config` from your shell.

| Key                           | What it does                                                          |
| ----------------------------- | --------------------------------------------------------------------- |
| `activeEngine`                | Which vendor CLI runs your turns: `codex`, `claude`, `gemini`, `grok` |
| `model`                       | Legacy global model fallback; provider-specific `models` wins         |
| `models`                      | A remembered model per provider, so switching keeps your choice       |
| `effort`                      | Legacy global effort fallback                                         |
| `efforts`                     | A remembered native effort per provider and selected model            |
| `advisor`                     | A second model that reviews the first                                 |
| `oracleMode`                  | How the advisor is consulted                                          |
| `autoMode`                    | Whether goals run without stopping to ask                             |
| `disabledProviders`           | Engines to ignore even if they are logged in                          |
| `autoMemoryEnabled`           | Whether durable facts are recalled and written automatically          |
| `reasoningEnabled`            | Whether provider reasoning blocks render in the TUI                   |
| `autoCompactEnabled`          | Whether a long session summarizes itself to reclaim context           |
| `autoCompactThresholdPercent` | How full the context gets before that happens                         |
| `usageCaps`                   | Your own spend or usage ceilings                                      |
| `syncServerUrl`               | Where remote control and the mobile mirror connect                    |
| `tui`                         | Whether the full terminal UI is used                                  |
| `statusline`                  | Optional operator-supplied statusline command                         |
| `workflowConcurrency`         | Maximum concurrent workflow agent calls, from 1 to 32                 |

`/config` is an actionable table in the TUI. Move to a row and press Enter to use its picker or
editor; the active engine, model, and supported effort can also be changed directly through
`/providers`, `/model`, and `/effort`. Model and effort choices are filtered to what the selected
provider actually supports.

## Permissions and native command sandbox

Permission rules live with project instructions in `CENTURION.md`. Rules match a tool and optional
argument pattern and resolve to `allow`, `ask`, or `deny`. A more-specific allow can carve a safe
command out of a broad ask rule, while deny remains absolute. Wrapped shell commands and command
substitution are inspected rather than treated as opaque strings.

The optional macOS native-command sandbox is also project-owned:

```yaml
code:
  sandbox:
    mode: workspace-write
    network: false
```

`workspace-write` permits writes in the workspace and dedicated temporary area. Network stays
denied unless explicitly enabled. Other platforms currently report that the OS sandbox backend is
unavailable; their command behavior is otherwise unchanged.

## Pinning your proof surface

By default Centurion discovers your checks from `package.json`. To be explicit, declare them in
`CENTURION.md` and they become the contract a goal is judged against:

```yaml
code:
  checks:
    - id: typecheck
      kind: typecheck
      command: pnpm
      args: ["-r", "typecheck"]
      required: true
    - id: test
      kind: test
      command: pnpm
      args: ["test"]
      required: true
```

A `required` check must exit `0` before a goal can be DONE. Non-required checks are advisory.

The command behind each check is snapshotted before the engine gets its first turn. If the engine
rewrites that command mid-run, for example turning `"test"` into `"echo ok"`, the check fails with a
tampering error rather than passing. That is true whether the check was discovered or declared here,
and in a workspace with several packages the snapshot follows the check's own directory.

## Environment

| Variable                | Effect                                               |
| ----------------------- | ---------------------------------------------------- |
| `CENTURION_HOME`        | Move the state directory somewhere else              |
| `CENTURION_TELEMETRY=0` | Turn telemetry off. See `centurion telemetry status` |
| `CENTURION_UPDATE_REPO` | Point updates at a mirror                            |
| `OPENAI_API_KEY`        | API-key path for Codex, instead of the OAuth login   |
| `ANTHROPIC_API_KEY`     | API-key path for Claude                              |
| `GEMINI_API_KEY`        | API-key path for Gemini                              |
| `XAI_API_KEY`           | API-key path for Grok                                |

Centurion never copies OAuth token files. It reads them only as evidence that you are logged in.
API-key values are imported into project state only when you ask, with `centurion env-sync apply`,
and secret values are never printed.
