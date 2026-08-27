<div align="center">

<img src="./docs/assets/centurion-avatar.png" alt="Pixel-art centurion helmet" width="200">

# Centurion Code

### The autonomous coding workspace that has to prove it finished.

[![Latest release](https://img.shields.io/github/v/release/Thecenturion-co/Centurion-Code?display_name=tag&style=flat-square&color=8f8f8f)](https://github.com/Thecenturion-co/Centurion-Code/releases/latest)
[![Platforms](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-b7b7b7?style=flat-square)](#install)
[![Signed updates](https://img.shields.io/badge/updates-Ed25519%20verified-72ad78?style=flat-square)](#updates-and-integrity)

One terminal. OpenAI, Anthropic, xAI, and Google underneath it. A verification
loop above them that does not call the work done until your real checks pass.

[Install](#install) · [Capabilities](#what-centurion-code-does) · [How it works](./docs/HOW-IT-WORKS.md) · [Configuration](./docs/CONFIGURATION.md) · [Latest release](https://github.com/Thecenturion-co/Centurion-Code/releases/latest)

</div>

---

## Install

Centurion Code ships as one standalone binary. Node, pnpm, Bun, and a source
checkout are not required.

### macOS and Linux

```sh
curl -fsSL https://raw.githubusercontent.com/Thecenturion-co/Centurion-Code/main/install.sh | sh
```

### Windows PowerShell

```powershell
irm https://raw.githubusercontent.com/Thecenturion-co/Centurion-Code/main/install.ps1 | iex
```

The installers detect the operating system and CPU, download the matching
release asset, verify its SHA-256, and install both command names:

```text
centurion    full command
cen          short alias
```

Then inspect the machine and open the terminal workspace:

```sh
centurion doctor
centurion providers
centurion
```

<details>
<summary>Direct binary downloads</summary>

| Platform             | Release asset                 |
| -------------------- | ----------------------------- |
| macOS, Apple Silicon | `centurion-darwin-arm64`      |
| macOS, Intel         | `centurion-darwin-x64`        |
| Linux, x64           | `centurion-linux-x64`         |
| Linux, ARM64         | `centurion-linux-arm64`       |
| Windows, x64         | `centurion-windows-x64.exe`   |
| Windows, ARM64       | `centurion-windows-arm64.exe` |

Download them from the [latest release](https://github.com/Thecenturion-co/Centurion-Code/releases/latest).

</details>

## What Centurion Code does

| Surface                       | What it gives you                                                                                                                                |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Proven goals**              | Runs the project's real typecheck, lint, test, and build commands. `DONE` requires every required check to exit `0`.                             |
| **One multi-model workspace** | Uses your authenticated Codex, Claude, Grok, and Gemini CLIs. Switch provider, model, and supported effort without leaving the session.          |
| **Advisor and council**       | Ask connected models to critique the active model, answer a question in parallel, or collect read-only cross-model review before accepting a result. |
| **Parallel agents**           | Launch isolated workers, watch their live status and responses in the Agents panel, and reply into resumable worker threads.                     |
| **Durable sessions**          | Resume after a crash with the transcript, attempt ledger, task state, model identity, and verification evidence intact.                          |
| **Background work**           | Detach supported sessions into the local supervisor, inspect their logs, reattach, or stop the complete process tree.                            |
| **Native tools**              | Read, search, edit, patch, run commands, monitor jobs, inspect Git, and work with GitHub or GitLab through the controlled tool surface.          |
| **Operator controls**         | Explicit permission modes, allow/ask/deny rules, isolated worktrees, checkpoints, rewind, usage caps, and optional macOS workspace sandboxing.   |
| **Memory and context**        | Search and edit project or user memory, compact long sessions, ask disposable side questions, and keep recurring facts without duplicating them. |
| **Desktop handoff**           | A shared session/event protocol lets the Centurion desktop and remote-control surfaces mirror the terminal's real state.                         |

## The proof loop

Centurion treats the model's “finished” message as a claim, not a conclusion.

```text
 GOAL
   │
   ▼
 THINK ──▶ ACT ──▶ OBSERVE ──▶ VERIFY ───────────────▶ DONE
   ▲                             │                 every required
   │                             │                 check exited 0
   └──── REPAIR / RESUME ◀───────┘
                                 └──▶ ESCALATE when the budget is spent
```

The command behind each required check is snapshotted before the model gets its
first turn. Rewriting `"test"` to `"echo ok"` cannot manufacture a green result;
the verifier detects the changed proof surface and refuses it.

Every attempt records what changed, which checks ran, the failure signature,
and whether the run made measurable progress. A resumed goal continues from
that evidence instead of beginning again with an empty prompt.

[Read the complete loop and trust model →](./docs/HOW-IT-WORKS.md)

## Terminal workspace

The 1.2.16 interface is a responsive, centered terminal workspace with one
consistent steel-and-ink table system. Keyboard navigation reaches the command
picker and the working panels without turning slash commands into chat turns.

![Centurion Code 1.2.16 terminal workspace](./docs/assets/centurion-code-tui.png)

```text
Shells   running commands and captured output
Tasks    the live, durable goal ledger
Agents   active workers, model identity, status, and replies
Docs     project documentation discovered for the session
```

The same visual system is used for providers, models, effort, configuration,
resume, advisor selection, approvals, and command help. Narrow terminals
compact the header and tables instead of breaking their alignment.

## Start with these commands

```text
/goal <prompt>        run a goal to verified completion
/providers            inspect connected providers and select the active one
/model                choose a model supported by that provider
/effort               choose an effort supported by that model
/advisor              select a connected second model for critique
/swarm <task>         run isolated parallel workers
/verify               run the proof checks now
/status               inspect the loop, goal, and verifier state
/config               change actionable settings
/resume               continue a durable session
/compact              reclaim context with a durable summary
/rewind               restore a code and conversation checkpoint
/worktree             enter or leave an isolated Git worktree
/help                 browse the canonical command catalog
```

From a shell, use `centurion goal`, `doctor`, `providers`, `connect`,
`sessions`, `agents`, `logs`, `stop`, `schedule`, `env-sync`, and `update`.

## Providers

Centurion uses provider authentication already present on the machine. At least
one connected engine is required.

| Provider           | Existing login                            | API-key alternative                  |
| ------------------ | ----------------------------------------- | ------------------------------------ |
| OpenAI / Codex     | `codex` or `centurion connect codex`      | `OPENAI_API_KEY` or `CODEX_API_KEY`  |
| Anthropic / Claude | Claude Code or `centurion connect claude` | `ANTHROPIC_API_KEY`                  |
| xAI / Grok         | Grok CLI or `centurion connect grok`      | `XAI_API_KEY` or `GROK_API_KEY`      |
| Google / Gemini    | Gemini CLI or `centurion connect gemini`  | `GEMINI_API_KEY` or `GOOGLE_API_KEY` |

OAuth credential files are not copied. API keys are imported only when you ask
with `centurion env-sync apply`, and secret values are never printed.

## Updates and integrity

```sh
cen update --check    # query the signed latest-release channel now
cen update            # verify, install atomically, and refresh both aliases
```

Centurion also checks the latest-release channel in the background at most once
every 24 hours and shows an update notice when a newer version is available.
It does not install an update without your command.

Every release contains six platform binaries, `checksums.txt`,
`manifest.json`, and an Ed25519 `manifest.json.sig`. Before replacement,
Centurion verifies the manifest against the public key compiled into the
binary, then checks the selected asset's URL, size, and SHA-256. It refuses a
downgrade and swaps the executable atomically. On Windows it refreshes both
`centurion.exe` and `cen.exe`.

## Documentation

- [How it works](./docs/HOW-IT-WORKS.md) — proof, retry policy, ledgers,
  multi-model review, isolation, background sessions, and signed updates.
- [Configuration](./docs/CONFIGURATION.md) — state locations, provider/model
  settings, permissions, memory, compaction, and proof checks.
- [Security policy](./SECURITY.md) — report a vulnerability privately.

## Public repository boundary

This repository is the public download and documentation front door for
Centurion Code. It intentionally contains installers, release metadata, public
documentation, and privacy-safe product imagery, not the proprietary production
source. GitLab remains the private source of truth, and a guarded release job
publishes the exact signed binary bundle here.

[EULA](./EULA.md) · [Security policy](./SECURITY.md) · [Third-party notices](./THIRD_PARTY_NOTICES.md)

© The Centurion LLC. All rights reserved.
