# Centurion Code installer for Windows (PowerShell).
#
#   irm https://raw.githubusercontent.com/Thecenturion-co/Centurion-Code/main/install.ps1 | iex
#
# Copyright The Centurion LLC. Licensed under the Centurion Code EULA.
$ErrorActionPreference = "Stop"

$repo       = "Thecenturion-co/Centurion-Code"
$asset      = "centurion-windows-x64.exe"
$installDir = if ($env:CENTURION_INSTALL_DIR) { $env:CENTURION_INSTALL_DIR } else { "$env:LOCALAPPDATA\centurion\bin" }

if ($env:CENTURION_VERSION) {
  $tag = $env:CENTURION_VERSION
} else {
  Write-Host "=> Resolving latest release..."
  $tag = (Invoke-RestMethod "https://api.github.com/repos/$repo/releases/latest").tag_name
}

$base = "https://github.com/$repo/releases/download/$tag"
Write-Host "=> Installing Centurion $tag (windows/x64)"

New-Item -ItemType Directory -Force -Path $installDir | Out-Null
$dest = Join-Path $installDir "centurion.exe"
$tmp  = Join-Path ([System.IO.Path]::GetTempPath()) $asset

Invoke-WebRequest -Uri "$base/$asset" -OutFile $tmp
$checksums = (Invoke-WebRequest -Uri "$base/checksums.txt").Content

$line = ($checksums -split "`n" | Where-Object { $_ -match [regex]::Escape($asset) } | Select-Object -First 1)
if (-not $line) { throw "No checksum listed for $asset" }
$expected = ($line -split '\s+')[0].ToLower()
$actual   = (Get-FileHash -Algorithm SHA256 $tmp).Hash.ToLower()
if ($expected -ne $actual) { throw "Checksum mismatch. Refusing to install." }
Write-Host "=> Checksum verified."

Move-Item -Force $tmp $dest

$userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($userPath -notlike "*$installDir*") {
  [Environment]::SetEnvironmentVariable("PATH", "$userPath;$installDir", "User")
  Write-Host "=> Added $installDir to your PATH (restart your terminal)."
}

Write-Host ""
Write-Host "Installed centurion -> $dest" -ForegroundColor Green
Write-Host "Next: run 'centurion doctor' to check your engine CLIs."
