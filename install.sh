#!/bin/sh
# Centurion Code installer. POSIX sh, no dependencies beyond curl and a sha256 tool.
#
#   curl -fsSL https://raw.githubusercontent.com/Thecenturion-co/Centurion-Code/main/install.sh | sh
#
# Env overrides:
#   CENTURION_VERSION=v0.1.0      pin a specific release (default: latest)
#   CENTURION_INSTALL_DIR=...     install location (default: $HOME/.local/bin)
#
# Copyright The Centurion LLC. Licensed under the Centurion Code EULA.
set -eu

REPO="Thecenturion-co/Centurion-Code"
BINARY_NAME="centurion"
INSTALL_DIR="${CENTURION_INSTALL_DIR:-$HOME/.local/bin}"

err() { printf '\033[31merror:\033[0m %s\n' "$1" >&2; exit 1; }
info() { printf '\033[36m=>\033[0m %s\n' "$1"; }

command -v curl >/dev/null 2>&1 || err "curl is required."

# ---- detect OS / arch -------------------------------------------------------
os="$(uname -s)"
arch="$(uname -m)"
case "$os" in
  Linux)  os="linux" ;;
  Darwin) os="darwin" ;;
  *) err "Unsupported OS: $os (Windows users: use install.ps1)" ;;
esac
case "$arch" in
  x86_64|amd64)  arch="x64" ;;
  aarch64|arm64) arch="arm64" ;;
  *) err "Unsupported architecture: $arch" ;;
esac
asset="${BINARY_NAME}-${os}-${arch}"

# ---- resolve download base --------------------------------------------------
# Use GitHub's direct latest-download redirect (no API call -> no 60-req/hr
# unauthenticated rate limit). Pin a version with CENTURION_VERSION.
if [ "${CENTURION_VERSION:-}" != "" ]; then
  base="https://github.com/${REPO}/releases/download/${CENTURION_VERSION}"
  info "Installing Centurion ${CENTURION_VERSION} (${os}/${arch})"
else
  base="https://github.com/${REPO}/releases/latest/download"
  info "Installing latest Centurion (${os}/${arch})"
fi

# ---- download into a temp dir ----------------------------------------------
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT INT TERM
curl -fSL --proto '=https' --tlsv1.2 --progress-bar "${base}/${asset}" -o "${tmp}/${asset}" \
  || err "Download failed: ${base}/${asset}"
curl -fsSL --proto '=https' --tlsv1.2 "${base}/checksums.txt" -o "${tmp}/checksums.txt" \
  || err "Could not fetch checksums.txt"

# ---- verify checksum --------------------------------------------------------
expected="$(grep " ${asset}\$" "${tmp}/checksums.txt" | awk '{print $1}')"
[ -n "$expected" ] || err "No checksum listed for ${asset}"
if command -v sha256sum >/dev/null 2>&1; then
  actual="$(sha256sum "${tmp}/${asset}" | awk '{print $1}')"
elif command -v shasum >/dev/null 2>&1; then
  actual="$(shasum -a 256 "${tmp}/${asset}" | awk '{print $1}')"
else
  err "No sha256 tool (sha256sum/shasum) available to verify the download."
fi
[ "$expected" = "$actual" ] || err "Checksum mismatch. Refusing to install. expected=$expected got=$actual"
info "Checksum verified."

# ---- install ----------------------------------------------------------------
mkdir -p "$INSTALL_DIR"
install -m 0755 "${tmp}/${asset}" "${INSTALL_DIR}/${BINARY_NAME}" 2>/dev/null \
  || { cp "${tmp}/${asset}" "${INSTALL_DIR}/${BINARY_NAME}"; chmod 0755 "${INSTALL_DIR}/${BINARY_NAME}"; }

# A notarized+stapled macOS binary clears Gatekeeper on its own. Strip the
# quarantine xattr as a belt-and-suspenders for older macOS / edge cases.
if [ "$os" = "darwin" ]; then
  xattr -dr com.apple.quarantine "${INSTALL_DIR}/${BINARY_NAME}" 2>/dev/null || true
fi

printf '\n\033[32mInstalled\033[0m %s -> %s\n' "$BINARY_NAME" "${INSTALL_DIR}/${BINARY_NAME}"
case ":$PATH:" in
  *":$INSTALL_DIR:"*) : ;;
  *) printf '\nAdd this to your shell profile:\n  export PATH="%s:$PATH"\n' "$INSTALL_DIR" ;;
esac
printf '\nNext: run \033[36mcenturion doctor\033[0m to check your engine CLIs.\n'
