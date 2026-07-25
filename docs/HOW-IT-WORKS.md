# How it works

## The loop

Centurion treats the engine's "I am finished" as a claim, not a conclusion.

```
                ┌──────────────────────────────────────────────┐
                │  a goal, from a prompt or goal.yaml          │
                │  checks: from the goal, then CENTURION.md,   │
                │  then discovered from your package manifest  │
                └───────────────────┬──────────────────────────┘
                                    │  the command behind each check is
                                    │  snapshotted HERE, before the engine
                                    │  gets a turn
                                    ▼
  ┌──────▶ THINK ──▶ ACT ──▶ OBSERVE ──▶ VERIFY ─────────┬──▶ DONE
  │          ▲                             │             │   every required
  │          │                             ▼             │   check exited 0
  │          │                    ┌────────────────┐     │
  │          │                    │ classify the   │     │
  │          │                    │ failure, hash  │     │
  │          │                    │ its signature  │     │
  │          │                    └───────┬────────┘     │
  │          │        ┌───────────────────┴───────────┐  │
  │          │        ▼                               ▼  │
  │          │   signature moved?                same signature
  │          │   that is progress                1st repeat   2nd repeat
  │          │        │                               │          │
  │   REPAIR_PROMPT ◀─┘                       RESUME_ENGINE   GIVE_UP
  │          │                                        │
  └──────────┴────────────────────────────────────────┘
                                                      │
                     one attempt left in budget ──▶ ESCALATE, a human is needed
```

Every goal has a retry budget, and nothing above can exceed it.

## Why the states exist

**VERIFY** runs your real commands as real subprocesses and collects the exit codes. It is the only
thing that can produce DONE. No amount of model confidence substitutes for it.

**The failure signature** is a hash of what actually went wrong. It is how the loop tells the
difference between a run that is converging and a run that is spinning. If you take one failing test
file from 40 failures to 5 to 1, the file you touched and the count of passing checks never change,
but the signature does, and that counts as progress.

**RESUME_ENGINE** continues the same engine thread with the evidence attached, rather than starting a
fresh prompt. It is what happens the first time a failure repeats exactly.

**ESCALATE** is the loop saying a human is needed, distinct from GIVE_UP, which is the budget running
out.

## The ledger

Every attempt appends one row: the tree hash, which files changed, how many checks passed, the
failure signature, and a verdict for whether it was progress. That is what makes a crashed run
resumable. It picks up the attempt counter, the failure history and the progress streak instead of
starting from zero, and the repair prompt it builds names the checks that actually failed.

`recap.md` is the same story in prose, written when the goal ends.

## More than one model

- **`/consult`** asks other engines about the current state without changing yours.
- **`/swarm`** races several engines on the same task, each in its own git worktree, and keeps the
  one that proves itself.
- **`advisor`** is a standing second model that reviews the first.

These are read-only unless you ask otherwise. The engine you chose stays the engine that writes.

## Isolation

`/worktree` runs a goal inside a git worktree, so a bad turn touches a scratch checkout instead of
your working tree. `/rewind` restores a checkpoint of both the code and the conversation.

Each session also gets its own provider state directory, so two sessions using the same vendor CLI
cannot tread on each other's credentials or history.

## Updates

Releases are signed. `manifest.json` lists every artifact with its size and SHA-256, and
`manifest.json.sig` is an Ed25519 signature over those exact bytes. The public key is compiled into
the binary and cannot be overridden from the environment.

Before replacing anything, `cen update` verifies the signature, checks the hash and size of what it
downloaded, refuses to move you backwards, and swaps the file atomically. A compromised release host
still cannot hand you a forgery.
