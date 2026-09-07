# How it works

## The loop

Centurion treats the engine's "I am finished" as a claim, not a conclusion.

```
   ┌──────────────────────────────────────────────────────────┐
   │  an envelope: a user message, a finished job, a timer,    │
   │  a worker report, a peer message, a monitor signal        │
   └───────────────────────────┬──────────────────────────────┘
                               ▼
        ASSEMBLE CONTEXT ──▶ MODEL ──▶ TOOL CALLS ──┐
               ▲              compact first          │
               │              when it must           │
               └──── IDLE ◀──── the turn ends when ◀─┘
                                the model asks for
                                no more tools
```

Every entry point submits an envelope into one session loop. The loop assembles
context, calls the model, runs the tool calls it asks for, and ends the turn when
it asks for none. Then it goes idle and waits for the next envelope.

There is no top-level DONE state, because a finished turn is not a finished run.
That distinction is the whole point: a model that stops talking has stopped
talking, which is not the same as having proved anything.

## Why proof is a tool and not a state

**`verify`** is a native tool the model can call, and a Stop hook that runs when a
worker tries to finish. It runs your real commands as real subprocesses and
collects the exit codes. Nothing else can stand in for it, and no amount of model
confidence substitutes for it.

The command behind each required check is snapshotted before the engine gets its
first turn. Rewriting `"test"` to `"echo ok"` cannot manufacture a green result;
the verifier detects the changed proof surface and refuses it.

**The failure signature** is a hash of what actually went wrong. It is how a run
tells the difference between converging and spinning. If you take one failing test
file from 40 failures to 5 to 1, the file you touched and the count of passing
checks never change, but the signature does, and that counts as progress.

**Ceilings are configuration, not constants.** `maxModelCallsPerEnvelope`,
`maxToolCallsPerIteration`, `maxEnvelopeWallMs`, `maxDeliveryAttempts`,
`maxWorkersInFlight` and `maxWorkerDepth` all live under `code.sessionLoop`. A run
cannot exceed them, and you decide what they are.

## The record

A session is durable. Its events are appended as they happen: what changed, which
checks ran, the failure signature, and whether the attempt made measurable
progress. That is what makes a crashed run resumable. It picks up the history
instead of starting from zero, and the prompt it rebuilds names the checks that
actually failed.

## The previous loop

Before 1.3.0 the top layer was a goal state machine that ran THINK, ACT, OBSERVE
and VERIFY toward a DONE state. It is retained for one release behind
`code.sessionLoop.enabled` set to `false`, and is scheduled for removal in 1.3.1.
The session loop above is what runs by default.

## More than one model

- **`/consult`** asks other engines about the current state without changing yours.
- **`/swarm`** races several engines on the same task, each in its own git worktree, and keeps the
  one that proves itself.
- **`/advisor`** selects a connected second model that reviews the first. Provider/model pairs are
  validated before a request can start.
- **`/council`** gathers a read-only cross-model review when one opinion is not enough.

These are read-only unless you ask otherwise. The engine you chose stays the engine that writes.

The TUI's Agents panel shows every live worker, the provider and model that actually ran, its status,
and the response stream. Resumable worker handles let a later message continue the same engine
thread instead of silently starting a new one.

## Background sessions and jobs

Long-running command tools are durable jobs. `job_list`, `job_output`, and `job_kill` address the
same registry shown by `/bashes`, and a timed-out command can keep running without becoming an
unowned process.

The optional local supervisor extends that ownership beyond one terminal:

```sh
centurion daemon start
centurion agents
centurion logs --follow <id>
centurion agents attach <id>
centurion stop <id>
```

The supervisor records process identity, keeps byte-capped logs, and stops the complete process
tree. When liveness cannot be proven it reports `unknown`; it never guesses that a process stopped.

## Isolation

`/worktree` runs a goal inside a git worktree, so a bad turn touches a scratch checkout instead of
your working tree. `/rewind` restores a checkpoint of both the code and the conversation.

Each session also gets its own provider state directory, so two sessions using the same vendor CLI
cannot tread on each other's credentials or history.

Native file and command tools run through Centurion's permission surface. Allow, ask, and deny rules
are matched to both the tool and its argument; deny always wins. On macOS, a project can additionally
put native commands in a `sandbox-exec` workspace-write profile that denies network unless the
project explicitly enables it. A sandbox that cannot be applied fails closed instead of quietly
running unsandboxed.

## Updates

Releases are signed. `manifest.json` lists every artifact with its size and SHA-256, and
`manifest.json.sig` is an Ed25519 signature over those exact bytes. The public key is compiled into
the binary and cannot be overridden from the environment.

Before replacing anything, `cen update` verifies the signature, checks the hash and size of what it
downloaded, refuses to move you backwards, and swaps the file atomically. A compromised release host
still cannot hand you a forgery.
