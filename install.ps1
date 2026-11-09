# Centurion Code installer for Windows (PowerShell).
#
#   irm https://raw.githubusercontent.com/Thecenturion-co/Centurion-Code/main/install.ps1 | iex
#
# The first install is the trust root, so this script verifies the release
# before trusting it: it downloads the signed manifest.json plus its detached
# Ed25519 signature manifest.json.sig, verifies the signature against the
# release public key baked in below (the same key `centurion update` uses),
# then checks the binary's sha256 and size against the SIGNED manifest.
# checksums.txt is never consulted: it ships in the same release as the
# binary, so whoever controls the release controls both.
#
# Signature verifier policy: .NET. Neither Windows PowerShell 5.1 nor
# PowerShell 7 expose Ed25519 through System.Security.Cryptography, so the
# verifier is implemented directly on System.Numerics.BigInteger plus SHA512,
# both in the framework on every supported PowerShell. Nothing is downloaded
# or compiled to make it work.
#
# Env overrides:
#   CENTURION_VERSION=v1.2.0        pin a specific release (default: latest)
#   CENTURION_INSTALL_DIR=...       install location (default: $env:LOCALAPPDATA\centurion\bin)
#   CENTURION_RELEASE_BASE=...     release base URL override (testing only)
#
# Copyright The Centurion LLC. Licensed under the Centurion Code EULA.
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Numerics

$repo       = "Thecenturion-co/Centurion-Code"
$arch       = if ([System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture -eq [System.Runtime.InteropServices.Architecture]::Arm64) { "arm64" } else { "x64" }
$asset      = "centurion-windows-$arch.exe"
$installDir = if ($env:CENTURION_INSTALL_DIR) { $env:CENTURION_INSTALL_DIR } else { "$env:LOCALAPPDATA\centurion\bin" }

# Ed25519 public key that signs every release manifest. The matching private
# key lives only in the release pipeline. Never read from the environment: the
# trust root is fixed in this file so nothing in a user's shell can swap it.
$PublicKeyPem = @"
-----BEGIN PUBLIC KEY-----
MCowBQYDK2VwAyEAGPE2F0CpFxygFf7raF/rJIv+VVrRA6oVM+o5ABbIigg=
-----END PUBLIC KEY-----
"@

# ---- Ed25519 verifier on System.Numerics.BigInteger -------------------------
# Equation checked: [S]B == R + [H(R || A || M) mod L]A over Edwards25519.
# All field math is mod p = 2^255 - 19; the curve parameter is
# d = -121665 / 121666 mod p. Correctness is covered by the repo test suite
# against real signatures.

function ConvertFrom-LittleEndian {
  # BigInteger(byte[]) reads little-endian two's complement; the trailing zero
  # byte keeps every decoded value positive.
  param([byte[]]$Bytes)
  $padded = New-Object byte[] ($Bytes.Length + 1)
  [Array]::Copy($Bytes, $padded, $Bytes.Length)
  return [System.Numerics.BigInteger]::new($padded)
}

function Ed-Mod {
  param([System.Numerics.BigInteger]$a, [System.Numerics.BigInteger]$p)
  $r = $a % $p
  if ($r -lt 0) { $r += $p }
  return $r
}

function Ed-ModPow {
  param([System.Numerics.BigInteger]$b, [System.Numerics.BigInteger]$e, [System.Numerics.BigInteger]$p)
  return [System.Numerics.BigInteger]::ModPow((Ed-Mod $b $p), $e, $p)
}

function Add-EdPoint {
  param([System.Numerics.BigInteger[]]$P1, [System.Numerics.BigInteger[]]$P2, [System.Numerics.BigInteger]$d, [System.Numerics.BigInteger]$p)
  $x1 = $P1[0]; $y1 = $P1[1]; $x2 = $P2[0]; $y2 = $P2[1]
  $t = Ed-Mod ($d * $x1 * $x2 * $y1 * $y2) $p
  $x3 = Ed-Mod (($x1 * $y2 + $y1 * $x2) * (Ed-ModPow (1 + $t) ($p - 2) $p)) $p
  $y3 = Ed-Mod (($y1 * $y2 + $x1 * $x2) * (Ed-ModPow (1 - $t) ($p - 2) $p)) $p
  return @($x3, $y3)
}

function Mul-EdPoint {
  param([System.Numerics.BigInteger[]]$Point, [System.Numerics.BigInteger]$Scalar, [System.Numerics.BigInteger]$d, [System.Numerics.BigInteger]$p)
  $qx = [System.Numerics.BigInteger]::Zero
  $qy = [System.Numerics.BigInteger]::One
  $bx = $Point[0]; $by = $Point[1]
  $e = $Scalar
  while ($e -gt 0) {
    if (-not $e.IsEven) {
      $r = Add-EdPoint @($qx, $qy) @($bx, $by) $d $p
      $qx = $r[0]; $qy = $r[1]
    }
    $r = Add-EdPoint @($bx, $by) @($bx, $by) $d $p
    $bx = $r[0]; $by = $r[1]
    $e = $e / 2
  }
  return @($qx, $qy)
}

function Recover-EdX {
  param([System.Numerics.BigInteger]$y, [System.Numerics.BigInteger]$d, [System.Numerics.BigInteger]$i, [System.Numerics.BigInteger]$p)
  $xx = Ed-Mod (($y * $y - 1) * (Ed-ModPow (Ed-Mod ($d * $y * $y + 1) $p) ($p - 2) $p)) $p
  $x = Ed-ModPow $xx (($p + 3) / 8) $p
  if ((Ed-Mod ($x * $x - $xx) $p) -ne 0) {
    $x = Ed-Mod ($x * $i) $p
    if ((Ed-Mod ($x * $x - $xx) $p) -ne 0) { return $null }
  }
  if (-not $x.IsEven) { $x = $p - $x }
  return $x
}

function Test-Ed25519Signature {
  param([byte[]]$Signature, [byte[]]$Message, [byte[]]$PublicKey)
  if ($Signature.Length -ne 64 -or $PublicKey.Length -ne 32) { return $false }

  $p = [System.Numerics.BigInteger]::Pow(2, 255) - 19
  $L = [System.Numerics.BigInteger]::Pow(2, 252) + [System.Numerics.BigInteger]::Parse("27742317777372353535851937790883648493")
  $d = Ed-Mod (-121665 * (Ed-ModPow 121666 ($p - 2) $p)) $p
  $i = Ed-ModPow 2 (($p - 1) / 4) $p

  $s = ConvertFrom-LittleEndian $Signature[32..63]
  if ($s -ge $L -or $s -lt 0) { return $false }

  $aBytes = [byte[]]$PublicKey.Clone()
  $aSign = $aBytes[31] -shr 7
  $aBytes[31] = $aBytes[31] -band 0x7F
  $ay = ConvertFrom-LittleEndian $aBytes
  if ($ay -ge $p) { return $false }

  $rBytes = [byte[]]($Signature[0..31])
  $rSign = $rBytes[31] -shr 7
  $rBytes[31] = $rBytes[31] -band 0x7F
  $ry = ConvertFrom-LittleEndian $rBytes
  if ($ry -ge $p) { return $false }

  $ax = Recover-EdX $ay $d $i $p
  if ($null -eq $ax) { return $false }
  if (($ax % 2) -ne $aSign) { $ax = $p - $ax }
  $rx = Recover-EdX $ry $d $i $p
  if ($null -eq $rx) { return $false }
  if (($rx % 2) -ne $rSign) { $rx = $p - $rx }

  # RFC 8032 challenge scalar: H(R || A || M) mod L.
  $challenge = New-Object byte[] (64 + $Message.Length)
  [Array]::Copy($Signature, 0, $challenge, 0, 32)
  [Array]::Copy($PublicKey, 0, $challenge, 32, 32)
  [Array]::Copy($Message, 0, $challenge, 64, $Message.Length)
  $hash = [System.Security.Cryptography.SHA512]::Create().ComputeHash($challenge)
  $h = Ed-Mod (ConvertFrom-LittleEndian $hash) $L

  $by = Ed-Mod (4 * (Ed-ModPow 5 ($p - 2) $p)) $p
  $bx = Recover-EdX $by $d $i $p
  if (-not $bx.IsEven) { $bx = $p - $bx }

  $left = Mul-EdPoint @($bx, $by) $s $d $p
  $rightA = Mul-EdPoint @($ax, $ay) $h $d $p
  $right = Add-EdPoint @($rx, $ry) $rightA $d $p
  return ($left[0] -eq $right[0] -and $left[1] -eq $right[1])
}

function Get-ReleasePublicKey {
  # PEM body is a DER SubjectPublicKeyInfo whose last 32 bytes are the raw key.
  $b64 = ($PublicKeyPem -split "`r?`n" | Where-Object { $_ -match '^[A-Za-z0-9+/=]+$' } | Select-Object -First 1)
  if (-not $b64) { throw "Release public key is missing from the installer." }
  $der = [Convert]::FromBase64String($b64)
  if ($der.Length -lt 32) { throw "Release public key is malformed." }
  $raw = New-Object byte[] 32
  [Array]::Copy($der, $der.Length - 32, $raw, 0, 32)
  return $raw
}

function Get-RemoteFile {
  param([string]$Uri, [string]$Dest)
  $u = [System.Uri]$Uri
  if ($u.IsFile) {
    [System.IO.File]::Copy($u.LocalPath, $Dest, $true)
  } else {
    Invoke-WebRequest -UseBasicParsing -Uri $Uri -OutFile $Dest
  }
}

# ---- resolve download base --------------------------------------------------
if ($env:CENTURION_RELEASE_BASE) {
  $base = $env:CENTURION_RELEASE_BASE.TrimEnd('/')
} elseif ($env:CENTURION_VERSION) {
  $base = "https://github.com/$repo/releases/download/$($env:CENTURION_VERSION)"
} else {
  Write-Host "=> Resolving latest release..."
  $tag = (Invoke-RestMethod "https://api.github.com/repos/$repo/releases/latest").tag_name
  $base = "https://github.com/$repo/releases/download/$tag"
}
Write-Host "=> Installing Centurion (windows/$arch) from $base"

New-Item -ItemType Directory -Force -Path $installDir | Out-Null
$dest = Join-Path $installDir "centurion.exe"
$alias = Join-Path $installDir "cen.exe"
$tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) ("centurion-install-" + [System.Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null

try {
  $manifestPath = Join-Path $tmpDir "manifest.json"
  $sigPath = Join-Path $tmpDir "manifest.json.sig"
  $assetPath = Join-Path $tmpDir $asset

  try { Get-RemoteFile "$base/manifest.json" $manifestPath }
  catch { throw "Could not fetch manifest.json from $base" }
  try { Get-RemoteFile "$base/manifest.json.sig" $sigPath }
  catch { throw "Could not fetch manifest.json.sig. Refusing to install an unsigned release." }

  # ---- verify the manifest signature before trusting its contents -----------
  $manifestBytes = [System.IO.File]::ReadAllBytes($manifestPath)
  $sigBytes = [System.IO.File]::ReadAllBytes($sigPath)
  if (-not (Test-Ed25519Signature $sigBytes $manifestBytes (Get-ReleasePublicKey))) {
    throw "manifest.json signature verification failed. Refusing to install."
  }
  Write-Host "=> Release signature verified (.NET Ed25519)."

  $manifest = (Get-Content -Raw $manifestPath) | ConvertFrom-Json
  $expected = $manifest.assets.PSObject.Properties[$asset].Value
  if ($null -eq $expected) { throw "manifest.json lists no asset named $asset." }
  if ([string]$expected.sha256 -notmatch '^[0-9a-fA-F]{64}$') {
    throw "manifest.json carries a malformed sha256 for $asset."
  }
  $expectedSize = [int64]$expected.size
  $expectedSha = ([string]$expected.sha256).ToLowerInvariant()

  # ---- download the binary, then check it against the signed manifest -------
  try { Get-RemoteFile "$base/$asset" $assetPath }
  catch { throw "Download failed: $base/$asset" }

  $actualSize = (Get-Item $assetPath).Length
  if ($actualSize -ne $expectedSize) {
    throw "Size mismatch for ${asset}: signed manifest says $expectedSize bytes, got $actualSize. Refusing to install."
  }
  $actualSha = (Get-FileHash -Algorithm SHA256 -Path $assetPath).Hash.ToLowerInvariant()
  if ($actualSha -ne $expectedSha) { throw "Checksum mismatch for $asset. Refusing to install." }
  Write-Host "=> Hash and size match the signed manifest."

  # ---- install ---------------------------------------------------------------
  Move-Item -Force $assetPath $dest
  Copy-Item -Force $dest $alias
} finally {
  Remove-Item -Recurse -Force $tmpDir -ErrorAction SilentlyContinue
}

$userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if (-not $env:CENTURION_RELEASE_BASE -and $userPath -notlike "*$installDir*") {
  # The release-base override marks a test install; it must not persist a temp
  # directory into the real user PATH.
  [Environment]::SetEnvironmentVariable("PATH", "$userPath;$installDir", "User")
  Write-Host "=> Added $installDir to your PATH (restart your terminal)."
}

Write-Host ""
Write-Host "Installed centurion -> $dest" -ForegroundColor Green
Write-Host "Installed cen       -> $alias" -ForegroundColor Green
Write-Host "Next: run 'centurion doctor' to check your engine CLIs."
