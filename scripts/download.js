#!/usr/bin/env node
// Downloads the correct native Centurion binary from GitHub Releases and verifies
// its checksum. Used both as the npm `postinstall` step and as on-demand self-repair
// by bin/centurion.js (so it still works under `npm install --ignore-scripts`).
//
// No third-party dependencies. Node built-ins only.
'use strict';

const https = require('node:https');
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');

const REPO = 'Thecenturion-co/Centurion-Code';
const VERSION = process.env.CENTURION_VERSION || ''; // pin a tag, or '' for latest

function assetName() {
  const p = process.platform;
  const a = process.arch;
  const key = `${p}/${a}`;
  const map = {
    'darwin/arm64': 'centurion-darwin-arm64',
    'darwin/x64': 'centurion-darwin-x64',
    'linux/arm64': 'centurion-linux-arm64',
    'linux/x64': 'centurion-linux-x64',
    'win32/arm64': 'centurion-windows-arm64.exe',
    'win32/x64': 'centurion-windows-x64.exe',
  };
  if (!map[key]) throw new Error(`Unsupported platform: ${key}`);
  return map[key];
}

function binPath() {
  const dir = path.join(__dirname, '..', 'bin');
  return path.join(dir, process.platform === 'win32' ? 'centurion-bin.exe' : 'centurion-bin');
}

function baseUrl() {
  return VERSION
    ? `https://github.com/${REPO}/releases/download/${VERSION}`
    : `https://github.com/${REPO}/releases/latest/download`;
}

function get(url, redirects = 0) {
  return new Promise((resolve, reject) => {
    if (redirects > 10) return reject(new Error('Too many redirects'));
    https
      .get(url, { headers: { 'User-Agent': 'centurion-installer' } }, (res) => {
        if ([301, 302, 303, 307, 308].includes(res.statusCode) && res.headers.location) {
          res.resume();
          const next = new URL(res.headers.location, url).toString();
          return resolve(get(next, redirects + 1));
        }
        if (res.statusCode !== 200) {
          res.resume();
          return reject(new Error(`HTTP ${res.statusCode} for ${url}`));
        }
        const chunks = [];
        res.on('data', (c) => chunks.push(c));
        res.on('end', () => resolve(Buffer.concat(chunks)));
        res.on('error', reject);
      })
      .on('error', reject);
  });
}

async function ensure({ quiet = false } = {}) {
  const dest = binPath();
  if (fs.existsSync(dest) && fs.statSync(dest).size > 0) return dest;

  const asset = assetName();
  const base = baseUrl();
  if (!quiet) console.error(`Centurion: downloading ${asset}...`);

  const [bin, checksums] = await Promise.all([
    get(`${base}/${asset}`),
    get(`${base}/checksums.txt`).then((b) => b.toString('utf8')),
  ]);

  const line = checksums.split('\n').find((l) => l.trim().endsWith(asset));
  if (!line) {
    throw new Error(`No checksum entry for ${asset}`);
  }
  const expected = line.trim().split(/\s+/)[0];
  const actual = crypto.createHash('sha256').update(bin).digest('hex');
  if (expected !== actual) {
    throw new Error(`Checksum mismatch for ${asset} (expected ${expected}, got ${actual})`);
  }

  fs.mkdirSync(path.dirname(dest), { recursive: true });
  fs.writeFileSync(dest, bin, { mode: 0o755 });
  if (!quiet) console.error(`Centurion: installed -> ${dest}`);
  return dest;
}

module.exports = { ensure, binPath, assetName };

// When run directly (postinstall), never hard-fail the install: the bin shim
// will self-repair on first run if this was skipped or offline.
if (require.main === module) {
  ensure().catch((e) => {
    console.error(`Centurion: postinstall could not fetch the binary (${e.message}).`);
    console.error('It will be downloaded automatically the first time you run `centurion`.');
    process.exit(0);
  });
}
