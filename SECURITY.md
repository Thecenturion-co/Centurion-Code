# Security Policy

## Reporting a vulnerability

Please report security issues privately. Do not open a public issue.

Use GitHub's private "Report a vulnerability" feature on this repository
(Security tab, "Report a vulnerability"). Please include a description, reproduction
steps, the affected version (`centurion --version`), and your platform. We aim to
acknowledge within 72 hours.

## Verifying your download

Every release ships a `checksums.txt`. Verify before running:

```sh
# macOS / Linux
shasum -a 256 -c checksums.txt 2>/dev/null | grep centurion
```

macOS binaries are code-signed with an Apple Developer ID. You can confirm the signature:

```sh
codesign -dvv /path/to/centurion 2>&1 | grep "Authority=Developer ID Application"
spctl --assess --type execute --verbose /path/to/centurion
```

## Supported versions

The latest released version receives security fixes.
