#!/usr/bin/env node
// Regenerates agent/commander.md from scripts/commander.template.md plus the
// roster derived from agent/*.md frontmatter descriptions. The roster's single
// source of truth is the `description` field in each agent file — edit those
// (or the template), then rerun this script. Never hand-edit agent/commander.md.
import { readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = dirname(dirname(fileURLToPath(import.meta.url)));
const agentDir = join(root, 'agent');
const outPath = join(agentDir, 'commander.md');

const template = readFileSync(join(root, 'scripts', 'commander.template.md'), 'utf8');

const brief = (d) => {
  const s = d.trim().replace(/^["']|["']$/g, '');
  const first = s.split(/(?<=[.!?])\s/)[0];
  return first.length > 220 ? `${first.slice(0, 217).replace(/\s+\S*$/, '')}…` : first;
};

const entries = readdirSync(agentDir)
  .filter((f) => f.endsWith('.md') && f !== 'commander.md')
  .sort()
  .map((f) => {
    const fm = readFileSync(join(agentDir, f), 'utf8').match(/^---\n([\s\S]*?)\n---/)?.[1] ?? '';
    const desc = fm.match(/^description:\s*(.+)$/m)?.[1] ?? '';
    if (!desc) {
      console.error(`WARN: no description in agent/${f}`);
      return null;
    }
    return { name: f.replace(/\.md$/, ''), line: `- \`${f.replace(/\.md$/, '')}\` — ${brief(desc)}` };
  })
  .filter(Boolean);

const roster = entries.map((e) => e.line).join('\n');

const out = template.replace('%%ROSTER%%', roster).replaceAll('%%COUNT%%', String(entries.length));

writeFileSync(outPath, out);
console.log(`Wrote ${outPath} with ${entries.length} subagents`);
