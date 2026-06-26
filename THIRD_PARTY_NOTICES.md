# Third-Party Notices

Centurion Code is built with and orchestrates third-party software. This file lists notable
components. It is regenerated per release from the source project's dependency manifest.

## Bundled open-source components

The Centurion Code binary is compiled with [Bun](https://bun.sh) and embeds the following
runtime dependencies, all permissively licensed (MIT, ISC, BSD, or Apache-2.0 unless noted):

| Component | Purpose | License |
|-----------|---------|---------|
| Bun runtime | embedded JS/TS runtime | MIT |
| zod | schema validation | MIT |
| ws | websocket transport | MIT |
| picocolors | terminal color | ISC |
| mri | argument parsing | MIT |
| pngjs | image decoding | MIT |

The authoritative, version-pinned list is generated at release time.

## Orchestrated tools (not bundled)

Centurion Code invokes vendor command-line tools that you install and authenticate separately.
They are not distributed with Centurion Code and remain governed by their own licenses and terms
of service:

* Anthropic `claude`
* OpenAI `codex`
* Google `gemini`
* xAI `grok`

You are responsible for complying with each vendor's terms and maintaining your own accounts.

© The Centurion LLC.
