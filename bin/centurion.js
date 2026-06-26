#!/usr/bin/env node
// Thin launcher for the native Centurion binary. Self-repairs (downloads the
// binary) on first run if the npm postinstall was skipped (e.g. --ignore-scripts)
// or was offline at install time.
'use strict';

const { spawn } = require('node:child_process');
const fs = require('node:fs');
const { ensure, binPath } = require('../scripts/download.js');

async function main() {
  let bin = binPath();
  if (!fs.existsSync(bin) || fs.statSync(bin).size === 0) {
    try {
      bin = await ensure();
    } catch (e) {
      console.error(`centurion: failed to obtain the binary: ${e.message}`);
      console.error('Check your network/proxy, or install directly:');
      console.error('  curl -fsSL https://raw.githubusercontent.com/Thecenturion-co/Centurion-Code/main/install.sh | sh');
      process.exit(1);
    }
  }
  // Tell the binary it is npm-managed, so `centurion update` defers to `npm update -g`
  // instead of self-replacing a file inside node_modules.
  const child = spawn(bin, process.argv.slice(2), {
    stdio: 'inherit',
    env: { ...process.env, CENTURION_INSTALL_MODE: 'wrapper' },
  });
  child.on('exit', (code, signal) => {
    if (signal) process.kill(process.pid, signal);
    else process.exit(code ?? 0);
  });
  child.on('error', (e) => {
    console.error(`centurion: cannot execute binary: ${e.message}`);
    process.exit(1);
  });
}

main();
