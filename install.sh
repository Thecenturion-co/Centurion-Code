#!/bin/sh
# Centurion Code installer. POSIX sh, no dependencies beyond curl.
#
#   curl -fsSL https://raw.githubusercontent.com/Thecenturion-co/Centurion-Code/main/install.sh | sh
#
# The first install is the trust root, so this script verifies the release
# before trusting it: it downloads the signed manifest.json plus its detached
# Ed25519 signature manifest.json.sig, verifies the signature against the
# release public key baked in below (the same key `centurion update` uses),
# then checks the binary's sha256 and size against the SIGNED manifest.
# checksums.txt is never consulted: it ships in the same release as the binary,
# so whoever controls the release controls both.
#
# Env overrides:
#   CENTURION_VERSION=v1.2.0        pin a specific release (default: latest)
#   CENTURION_INSTALL_DIR=...       install location (default: $HOME/.local/bin)
#   CENTURION_RELEASE_BASE=...      release base URL override (testing only)
#   CENTURION_INSTALL_VERIFY=...    signature backend: auto (default), openssl,
#                                   node, bc
#
# Signature verifier policy (auto order): a real OpenSSL `pkeyutl -rawin`
# (OpenSSL 1.1.1+/3.x; LibreSSL, which stock macOS ships, cannot do it), then
# `node` (crypto.verify), then a pure-bc Ed25519 verifier as the dependency-free
# last resort. If no backend is usable the install fails closed and names the
# options.
#
# Copyright The Centurion LLC. Licensed under the Centurion Code EULA.
set -eu

REPO="Thecenturion-co/Centurion-Code"
BINARY_NAME="centurion"
INSTALL_DIR="${CENTURION_INSTALL_DIR:-$HOME/.local/bin}"

# Ed25519 public key that signs every release manifest. The matching private
# key lives only in the release pipeline. Never read from the environment: the
# trust root is fixed in this file so nothing in a user's shell can swap it.
PUBLIC_KEY_PEM='-----BEGIN PUBLIC KEY-----
MCowBQYDK2VwAyEAGPE2F0CpFxygFf7raF/rJIv+VVrRA6oVM+o5ABbIigg=
-----END PUBLIC KEY-----'

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
# GitHub's direct latest-download redirect avoids the unauthenticated API rate
# limit. Pin a version with CENTURION_VERSION; CENTURION_RELEASE_BASE overrides
# the whole base (used by the test suite with a local file:// fixture).
if [ "${CENTURION_RELEASE_BASE:-}" != "" ]; then
  base="${CENTURION_RELEASE_BASE%/}"
elif [ "${CENTURION_VERSION:-}" != "" ]; then
  base="https://github.com/${REPO}/releases/download/${CENTURION_VERSION}"
else
  base="https://github.com/${REPO}/releases/latest/download"
fi
info "Installing Centurion (${os}/${arch}) from ${base}"

# ---- download into a temp dir ----------------------------------------------
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT INT TERM

dl() {
  # dl <url> <dest>: pinned to https for real releases; file:// bases (tests)
  # would be rejected by --proto '=https'.
  case "$base" in
    file://*) curl -fsSL "$1" -o "$2" ;;
    *) curl -fsSL --proto '=https' --tlsv1.2 "$1" -o "$2" ;;
  esac
}

dl "${base}/manifest.json" "${tmp}/manifest.json" \
  || err "Could not fetch manifest.json from ${base}"
dl "${base}/manifest.json.sig" "${tmp}/manifest.json.sig" \
  || err "Could not fetch manifest.json.sig. Refusing to install an unsigned release."

# ---- verify the manifest signature ------------------------------------------
printf '%s\n' "$PUBLIC_KEY_PEM" > "${tmp}/release-pubkey.pem"

have_openssl() {
  # Ed25519 verification needs pkeyutl -rawin, which exists only in real
  # OpenSSL (1.1.1+). LibreSSL (stock macOS) answers `openssl` but lacks it.
  command -v openssl >/dev/null 2>&1 \
    && openssl version 2>/dev/null | grep -q '^OpenSSL' \
    && openssl pkeyutl -help 2>&1 | grep -q -- '-rawin'
}
have_node() { command -v node >/dev/null 2>&1; }
have_bc() { command -v bc >/dev/null 2>&1 && command -v od >/dev/null 2>&1; }

sig_check_openssl() {
  openssl pkeyutl -verify -rawin -pubin -inkey "${tmp}/release-pubkey.pem" \
    -sigfile "${tmp}/manifest.json.sig" -in "${tmp}/manifest.json" >/dev/null 2>&1
}

sig_check_node() {
  node -e '
    const fs = require("fs");
    const crypto = require("crypto");
    const [pub, sig, msg] = process.argv.slice(1);
    const ok = crypto.verify(null, fs.readFileSync(msg), fs.readFileSync(pub, "utf8"),
      fs.readFileSync(sig));
    process.exit(ok ? 0 : 1);
  ' "${tmp}/release-pubkey.pem" "${tmp}/manifest.json.sig" "${tmp}/manifest.json" \
    >/dev/null 2>&1
}

sha512_hex() {
  # sha512_hex <file> -> lowercase hex digest on stdout
  if command -v sha512sum >/dev/null 2>&1; then
    sha512sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 512 "$1" | awk '{print $1}'
  elif command -v openssl >/dev/null 2>&1; then
    openssl dgst -sha512 -r "$1" | awk '{print $1}'
  elif command -v perl >/dev/null 2>&1; then
    perl -MDigest::SHA=sha512_hex -0777 -e 'print sha512_hex(<STDIN>)' < "$1"
  else
    return 1
  fi
}

hex_of() { od -A n -v -t x1 "$1" | tr -d ' \n'; }

le_to_be_hex() {
  # Reverse hex byte pairs: little-endian field -> big-endian hex for bc.
  printf '%s' "$1" | fold -w2 \
    | awk '{ a[NR] = $1 } END { for (i = NR; i > 0; i--) printf "%s", a[i]; printf "\n" }' \
    | tr 'a-f' 'A-F'
}

point_params() {
  # point_params <32-byte little-endian point file> -> "BEHEX SIGN"
  # y is the encoded field with the x sign bit stripped; sign is bit 255.
  enc_hex="$(hex_of "$1")"
  last_byte_hex="$(printf '%s' "$enc_hex" | cut -c63-64)"
  last_byte=$((0x$last_byte_hex))
  sign=$(( last_byte >= 128 ? 1 : 0 ))
  masked="$(printf '%02X' $((last_byte & 127)))"
  y_hex="$(printf '%s' "$enc_hex" | cut -c1-62)${masked}"
  printf '%s %s' "$(le_to_be_hex "$y_hex")" "$sign"
}

decode_b64() {
  # decode_b64 <base64 string> <dest>: the PEM body is binary DER, so decoders
  # write straight to the file (a shell variable cannot carry NUL bytes).
  if printf '%s' "$1" | base64 -d > "$2" 2>/dev/null; then return 0; fi
  if printf '%s' "$1" | base64 -D > "$2" 2>/dev/null; then return 0; fi
  if command -v openssl >/dev/null 2>&1 \
    && printf '%s' "$1" | openssl base64 -d > "$2" 2>/dev/null; then return 0; fi
  if command -v perl >/dev/null 2>&1 \
    && printf '%s' "$1" | perl -MMIME::Base64 -e 'print decode_base64(join "", <STDIN>)' \
      > "$2" 2>/dev/null; then return 0; fi
  return 1
}

sig_check_bc() {
  # Pure-bc Ed25519 verifier: the dependency-free last resort. Ed25519 verify
  # is the equation [S]B == R + [H(R||A||M) mod L]A over the Edwards25519 curve.
  # Correctness is covered by the repo test suite against real signatures.
  pub_b64="$(printf '%s' "$PUBLIC_KEY_PEM" | sed -n '2p')"
  decode_b64 "$pub_b64" "${tmp}/pubkey.der" || return 1
  [ "$(wc -c < "${tmp}/pubkey.der" | tr -d ' ')" -ge 32 ] || return 1

  tail -c 32 "${tmp}/pubkey.der" > "${tmp}/a.bin"
  head -c 32 "${tmp}/manifest.json.sig" > "${tmp}/r.bin"
  tail -c 32 "${tmp}/manifest.json.sig" > "${tmp}/s.bin"

  a_params="$(point_params "${tmp}/a.bin")"
  r_params="$(point_params "${tmp}/r.bin")"
  a_be="${a_params% *}"
  a_sign="${a_params#* }"
  r_be="${r_params% *}"
  r_sign="${r_params#* }"
  s_be="$(le_to_be_hex "$(hex_of "${tmp}/s.bin")")"

  # RFC 8032 challenge scalar: H(R || A || M) mod L.
  cat "${tmp}/r.bin" "${tmp}/a.bin" "${tmp}/manifest.json" > "${tmp}/challenge.bin"
  h_hex="$(sha512_hex "${tmp}/challenge.bin")" || return 1
  [ -n "$h_hex" ] || return 1
  h_be="$(le_to_be_hex "$h_hex")"

  {
    # ibase=A is the ibase-16 reset idiom: "10" under ibase 16 would read as
    # hex (16), silently corrupting every decimal constant that follows.
    printf 'ibase=16\nay=%s\ns=%s\nry=%s\nh=%s\nibase=A\nas=%s\nrs=%s\n' \
      "$a_be" "$s_be" "$r_be" "$h_be" "$a_sign" "$r_sign"
    cat <<'BCEOF'
p = 2^255 - 19
l = 2^252 + 27742317777372353535851937790883648493
define m(a) {
  auto r
  r = a % p
  if (r < 0) r += p
  return r
}
define powmod(b, e) {
  auto r, x
  r = 1
  x = m(b)
  while (e > 0) {
    if (e % 2 == 1) r = m(r * x)
    x = m(x * x)
    e /= 2
  }
  return r
}
define inv(a) {
  return powmod(a, p - 2)
}
d = m((0 - 121665) * inv(121666))
i = powmod(2, (p - 1) / 4)
define add() {
  auto t
  t = m(d * x1 * x2 * y1 * y2)
  x3 = m((x1 * y2 + y1 * x2) * inv(1 + t))
  y3 = m((y1 * y2 + x1 * x2) * inv(1 - t))
}
define xrecover(y) {
  auto xx, x
  xx = m((y * y - 1) * inv(m(d * y * y + 1)))
  x = powmod(xx, (p + 3) / 8)
  if (m(x * x - xx) != 0) x = m(x * i)
  if (x % 2 == 1) x = p - x
  return x
}
define scalarmult() {
  qx = 0
  qy = 1
  while (e > 0) {
    if (e % 2 == 1) {
      x2 = qx
      y2 = qy
      add()
      qx = x3
      qy = y3
    }
    x2 = x1
    y2 = y1
    add()
    x1 = x3
    y1 = y3
    e /= 2
  }
}
bad = 0
if (s >= l) bad = 1
if (ay >= p || ry >= p) bad = 1
h = h % l
if (bad == 0) {
  ax = xrecover(ay)
  if (ax % 2 != as) ax = p - ax
  rx = xrecover(ry)
  if (rx % 2 != rs) rx = p - rx
  bx = xrecover(m(4 * inv(5)))
  if (bx % 2 != 0) bx = p - bx
  by = m(4 * inv(5))
  x1 = bx
  y1 = by
  e = s
  scalarmult()
  p1x = qx
  p1y = qy
  x1 = ax
  y1 = ay
  e = h
  scalarmult()
  x1 = qx
  y1 = qy
  x2 = rx
  y2 = ry
  add()
  if (x3 == p1x && y3 == p1y) print "VERIFY_OK\n" else print "VERIFY_FAIL\n"
}
if (bad != 0) print "VERIFY_FAIL\n"
BCEOF
  } | bc 2>/dev/null | grep -q '^VERIFY_OK$'
}

verifier="${CENTURION_INSTALL_VERIFY:-auto}"
case "$verifier" in
  auto)
    verifiers=""
    have_openssl && verifiers="${verifiers} openssl"
    have_node && verifiers="${verifiers} node"
    have_bc && verifiers="${verifiers} bc"
    [ -n "$verifiers" ] || err "No signature verifier available. Install OpenSSL 3 (e.g. brew install openssl), node, or bc, then retry."
    ;;
  openssl|node|bc)
    "have_${verifier}" || err "CENTURION_INSTALL_VERIFY=${verifier} but that verifier is not usable on this system."
    verifiers=" $verifier"
    ;;
  *)
    err "Unknown CENTURION_INSTALL_VERIFY=${verifier} (expected auto, openssl, node, or bc)."
    ;;
esac

verified=""
for v in $verifiers; do
  if "sig_check_${v}"; then verified="$v"; break; fi
done
[ -n "$verified" ] || err "manifest.json signature verification failed. Refusing to install."
info "Release signature verified (${verified})."

# ---- read sha256/size for this asset out of the signed manifest -------------
# Read this asset's sha256/size out of the signed manifest. Both fields are
# captured before the asset object closes so the parse does not depend on
# their order inside it.
read -r expected_sha expected_size <<EOF
$(awk -v target="$asset" '
    !f && $0 ~ "^[[:space:]]*\"" target "\"[[:space:]]*:" { f = 1; next }
    f && /"sha256"/ {
      sub(/.*"sha256"[[:space:]]*:[[:space:]]*"/, "")
      sub(/".*/, "")
      sha = $0
    }
    f && /"size"/ {
      sub(/.*"size"[[:space:]]*:[[:space:]]*/, "")
      sub(/[^0-9].*/, "")
      size = $0
    }
    f && /^[[:space:]]*}/ {
      if (sha != "" && size != "") print sha, size
      exit
    }
  ' "${tmp}/manifest.json")
EOF
[ -n "$expected_sha" ] || err "manifest.json lists no asset named ${asset}."
case "$expected_sha" in
  *[!0-9a-fA-F]*) err "manifest.json carries a malformed sha256 for ${asset}." ;;
esac
[ "${#expected_sha}" -eq 64 ] || err "manifest.json carries a malformed sha256 for ${asset}."
case "$expected_size" in
  ''|*[!0-9]*) err "manifest.json carries a malformed size for ${asset}." ;;
esac
expected_sha="$(printf '%s' "$expected_sha" | tr 'A-F' 'a-f')"

# ---- download the binary, then check it against the signed manifest ---------
dl "${base}/${asset}" "${tmp}/${asset}" \
  || err "Download failed: ${base}/${asset}"
actual_size="$(wc -c < "${tmp}/${asset}" | tr -d ' ')"
[ "$actual_size" = "$expected_size" ] \
  || err "Size mismatch for ${asset}: signed manifest says ${expected_size} bytes, got ${actual_size}. Refusing to install."
if command -v sha256sum >/dev/null 2>&1; then
  actual_sha="$(sha256sum "${tmp}/${asset}" | awk '{print $1}')"
elif command -v shasum >/dev/null 2>&1; then
  actual_sha="$(shasum -a 256 "${tmp}/${asset}" | awk '{print $1}')"
elif command -v openssl >/dev/null 2>&1; then
  actual_sha="$(openssl dgst -sha256 -r "${tmp}/${asset}" | awk '{print $1}')"
else
  err "No sha256 tool (sha256sum/shasum/openssl) available to verify the download."
fi
[ "$expected_sha" = "$actual_sha" ] \
  || err "Checksum mismatch for ${asset}. Refusing to install."
info "Hash and size match the signed manifest."

# ---- install ----------------------------------------------------------------
mkdir -p "$INSTALL_DIR"
install -m 0755 "${tmp}/${asset}" "${INSTALL_DIR}/${BINARY_NAME}" 2>/dev/null \
  || { cp "${tmp}/${asset}" "${INSTALL_DIR}/${BINARY_NAME}"; chmod 0755 "${INSTALL_DIR}/${BINARY_NAME}"; }
ln -sf "${INSTALL_DIR}/${BINARY_NAME}" "${INSTALL_DIR}/cen"

# A notarized+stapled macOS binary clears Gatekeeper on its own. Strip the
# quarantine xattr as a belt-and-suspenders for older macOS / edge cases.
if [ "$os" = "darwin" ]; then
  xattr -dr com.apple.quarantine "${INSTALL_DIR}/${BINARY_NAME}" 2>/dev/null || true
fi

printf '\n\033[32mInstalled\033[0m %s -> %s\n' "$BINARY_NAME" "${INSTALL_DIR}/${BINARY_NAME}"
printf '\033[32mInstalled\033[0m cen -> %s\n' "${INSTALL_DIR}/cen"
case ":$PATH:" in
  *":$INSTALL_DIR:"*) : ;;
  *) printf '\nAdd this to your shell profile:\n  export PATH="%s:$PATH"\n' "$INSTALL_DIR" ;;
esac
printf '\nNext: run \033[36mcenturion doctor\033[0m to check your engine CLIs.\n'
