<div align="center">

# Centurion Code

**The autonomous coding agent that orchestrates the AI CLIs you already pay for.**

Centurion drives your own `claude`, `codex`, `gemini`, and `grok` command-line tools over your
existing subscriptions to plan, write, and verify code on a run-until-proven loop. One terminal,
every model, your accounts.

</div>

## Install

**macOS / Linux**
```sh
curl -fsSL https://raw.githubusercontent.com/Thecenturion-co/Centurion-Code/main/install.sh | sh
```

**Windows (PowerShell)**
```powershell
irm https://raw.githubusercontent.com/Thecenturion-co/Centurion-Code/main/install.ps1 | iex
```

**Homebrew** (coming soon)
```sh
brew install Thecenturion-co/tap/centurion
```

**npm** (for Node developers; installs the native binary, not source)
```sh
npm install -g @thecenturion/code
```

Then:
```sh
centurion doctor    # checks which engine CLIs are installed and logged in
centurion           # start
```

## Requirements

Centurion is an orchestrator. It runs the AI CLIs on your machine over your logins. You need at
least one of these installed and authenticated:

| Engine | CLI |
|--------|-----|
| Anthropic | `claude` |
| OpenAI | `codex` |
| Google | `gemini` |
| xAI | `grok` |

Run `centurion doctor` and it tells you exactly what is present and what to set up. Centurion never
asks for an API key for these. It uses the CLIs' own logins.

## What it is and isn't

Centurion Code is a single, self-contained binary. No Node runtime is required to run it.

It is not open source. Centurion Code is proprietary software (see [EULA.md](./EULA.md)). You are free
to download and use it. The source is not published.

This repository is the public front door. It hosts the installers and the release binaries. The
source lives in a private repository.

## Links

* Releases and downloads: the [Releases](https://github.com/Thecenturion-co/Centurion-Code/releases) tab
* Website: [thecenturion.co](https://thecenturion.co)
* Security: [SECURITY.md](./SECURITY.md)
* License: [EULA.md](./EULA.md)
* Third-party notices: [THIRD_PARTY_NOTICES.md](./THIRD_PARTY_NOTICES.md)

---

© The Centurion LLC. All rights reserved.
