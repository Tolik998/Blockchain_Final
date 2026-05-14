import { execSync } from 'node:child_process';
import { readdirSync, statSync } from 'node:fs';
import path from 'node:path';

function walk(dir) {
  /** @type {string[]} */
  const out = [];
  for (const name of readdirSync(dir)) {
    const p = path.join(dir, name);
    if (statSync(p).isDirectory()) out.push(...walk(p));
    else if (name.endsWith('.sol')) out.push(p);
  }
  return out;
}

const files = walk('contracts');
if (!files.length) {
  console.error('No Solidity files found under contracts/');
  process.exit(1);
}

const chunkSize = 12;
for (let i = 0; i < files.length; i += chunkSize) {
  const batch = files.slice(i, i + chunkSize);
  execSync(`npx solhint ${batch.map((f) => JSON.stringify(f)).join(' ')}`, {
    stdio: 'inherit',
    shell: true,
  });
}
