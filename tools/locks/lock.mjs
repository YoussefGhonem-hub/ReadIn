#!/usr/bin/env node
// File locks for the Claude Code sessions that share D:\freelancer\ReadIn on `dev` (see CLAUDE.md, SPEC §29).
//
// Hooks (wired in .claude/settings.json):
//   pre      PreToolUse  Edit|Write|MultiEdit|NotebookEdit: lock the file for this session; if another session holds it,
//            wait for it to be committed (up to READIN_LOCK_WAIT_SECONDS, default 120) and otherwise block the edit.
//   post     PostToolUse Bash|PowerShell: after a `git commit`, release this session's locks on files that are now clean.
//   session  SessionStart: tell the session its id (for `lock`) and which files other sessions hold.
// CLI (node tools/locks/lock.mjs ...):
//   status                              list the locks
//   lock <paths...> --session <id>      lock files a generator or a shell command will rewrite (same rules as Edit)
//   release <paths...> --session <id>   release your own locks early (e.g. you reverted the change)
//   release <paths...> --force          the user frees a lock left by a session that is gone
//   prune                               drop stale locks (file clean and lock older than 2 minutes)
// Locks live in <git dir>/file-locks/, one JSON file per path; nothing here is committed.
import { execFileSync } from 'node:child_process';
import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';

const ROOT = trueCase(path.resolve(process.env.CLAUDE_PROJECT_DIR || git(['rev-parse', '--show-toplevel'], process.cwd())));
const LOCKS = path.join(path.resolve(ROOT, git(['rev-parse', '--git-common-dir'], ROOT)), 'file-locks');
const WAIT_MS = 1000 * Number(process.env.READIN_LOCK_WAIT_SECONDS ?? 120);
const POLL_MS = 2000;
const STALE_MS = 2 * 60 * 1000; // a lock on a file with no uncommitted changes is stale after this

function git(args, cwd) {
  return execFileSync('git', args, { cwd, encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).trim();
}

/** The path as it is spelled on disk (case, 8.3 short names); a file that doesn't exist yet keeps its own name. */
function trueCase(abs) {
  try {
    return fs.realpathSync.native(abs);
  } catch {
    const dir = path.dirname(abs);
    return dir === abs ? abs : path.join(trueCase(dir), path.basename(abs));
  }
}

/** Repo-relative path with forward slashes, or null when the file is outside the shared tree. */
function relPath(p) {
  if (!p) return null;
  let abs = String(p).replace(/^\/([a-zA-Z])\//, '$1:/'); // Git Bash /d/... → D:/...
  abs = trueCase(path.resolve(ROOT, abs));
  const rel = path.relative(ROOT, abs);
  if (!rel || rel.startsWith('..') || path.isAbsolute(rel)) return null;
  const posix = rel.split(path.sep).join('/');
  if (posix === '.git' || posix.startsWith('.git/')) return null;
  return posix;
}

const keyOf = (rel) => crypto.createHash('sha1').update(process.platform === 'win32' ? rel.toLowerCase() : rel).digest('hex');
const fileOf = (rel) => path.join(LOCKS, `${keyOf(rel)}.json`);

function readLock(rel) {
  try {
    return JSON.parse(fs.readFileSync(fileOf(rel), 'utf8'));
  } catch {
    return null;
  }
}

function allLocks() {
  let names = [];
  try {
    names = fs.readdirSync(LOCKS).filter((n) => n.endsWith('.json'));
  } catch {
    return [];
  }
  return names
    .map((n) => {
      try {
        return JSON.parse(fs.readFileSync(path.join(LOCKS, n), 'utf8'));
      } catch {
        return null;
      }
    })
    .filter(Boolean);
}

/** True when git sees no uncommitted change (staged, unstaged or untracked) in the file. */
function isClean(rel) {
  try {
    return git(['status', '--porcelain', '--untracked-files=all', '--', `:(literal)${rel}`], ROOT) === '';
  } catch {
    return false;
  }
}

const isStale = (lock) => Date.now() - Date.parse(lock.at) > STALE_MS && isClean(lock.path);

function writeLock(rel, session, tool, exclusive) {
  fs.mkdirSync(LOCKS, { recursive: true });
  const body = JSON.stringify({ path: rel, session, tool, at: new Date().toISOString() });
  fs.writeFileSync(fileOf(rel), body, { flag: exclusive ? 'wx' : 'w' });
}

/** Lock rel for session, waiting up to waitMs for another session's lock. Returns null or the blocking lock. */
async function acquire(rel, session, tool, waitMs) {
  const deadline = Date.now() + waitMs;
  for (;;) {
    try {
      writeLock(rel, session, tool, true);
      return null;
    } catch (e) {
      if (e.code !== 'EEXIST') throw e;
    }
    const held = readLock(rel);
    if (held && held.session === session) {
      writeLock(rel, session, tool, false); // refresh: the holder is still working on it
      return null;
    }
    if (!held || isStale(held)) {
      fs.rmSync(fileOf(rel), { force: true });
      continue;
    }
    if (Date.now() >= deadline) return held;
    await new Promise((r) => setTimeout(r, POLL_MS));
  }
}

function release(rel, session, force) {
  const held = readLock(rel);
  if (!held) return false;
  if (!force && held.session !== session) return false;
  fs.rmSync(fileOf(rel), { force: true });
  return true;
}

async function stdinJson() {
  let s = '';
  for await (const chunk of process.stdin) s += chunk;
  try {
    return JSON.parse(s || '{}');
  } catch {
    return {};
  }
}

const short = (id) => String(id ?? '?').slice(0, 8);
const age = (at) => `${Math.round((Date.now() - Date.parse(at)) / 60000)} min`;

async function hookPre() {
  const input = await stdinJson();
  const ti = input.tool_input ?? {};
  const rel = relPath(ti.file_path ?? ti.notebook_path);
  if (!rel || !input.session_id) return 0;
  const held = await acquire(rel, input.session_id, input.tool_name, WAIT_MS);
  if (!held) return 0;
  process.stderr.write(
    `🔒 ${rel} is locked by another session (${short(held.session)}, since ${age(held.at)} ago) and has uncommitted ` +
      `changes there. Wait until that session commits it, then retry this edit. Don't work around the lock ` +
      `(no shell edits, no copies). Check with: node tools/locks/lock.mjs status\n`,
  );
  return 2;
}

async function hookPost() {
  const input = await stdinJson();
  const cmd = String(input.tool_input?.command ?? '');
  if (!input.session_id || !/\bgit\b[^\n]*\bcommit\b/.test(cmd)) return 0;
  for (const l of allLocks()) if (l.session === input.session_id && isClean(l.path)) release(l.path, l.session, false);
  return 0;
}

async function hookSession() {
  const input = await stdinJson();
  const others = allLocks().filter((l) => l.session !== input.session_id && !isStale(l));
  const lines = [
    `Shared-tree file locks (CLAUDE.md): your lock session id is ${input.session_id}. Edit/Write lock a file for you ` +
      `and the lock is released once you commit it. Before a generator or shell command rewrites tracked files, run ` +
      `node tools/locks/lock.mjs lock <paths> --session ${input.session_id}`,
  ];
  if (others.length) lines.push(`Locked by other sessions now: ${others.map((l) => l.path).join(', ')}`);
  process.stdout.write(
    JSON.stringify({ hookSpecificOutput: { hookEventName: 'SessionStart', additionalContext: lines.join('\n') } }),
  );
  return 0;
}

function opt(args, name) {
  const i = args.indexOf(name);
  if (i < 0) return undefined;
  const v = args[i + 1];
  args.splice(i, 2);
  return v;
}

async function cli(cmd, args) {
  const force = args.includes('--force');
  args = args.filter((a) => a !== '--force');
  const session = opt(args, '--session');
  switch (cmd) {
    case 'status': {
      const locks = allLocks();
      if (!locks.length) console.log('No locks.');
      for (const l of locks.sort((a, b) => a.path.localeCompare(b.path))) {
        const state = isClean(l.path) ? (isStale(l) ? 'clean, stale' : 'clean') : 'uncommitted';
        console.log(`${l.path}  session ${short(l.session)}  ${age(l.at)} ago  ${state}`);
      }
      return 0;
    }
    case 'lock': {
      if (!session) return usage('lock needs --session <id> (your id is in the SessionStart note)');
      let code = 0;
      for (const p of args) {
        const rel = relPath(p);
        if (!rel) continue;
        const held = await acquire(rel, session, 'cli', WAIT_MS);
        if (held) {
          console.error(`🔒 ${rel} is locked by session ${short(held.session)}; wait until it is committed.`);
          code = 1;
        }
      }
      return code;
    }
    case 'release': {
      if (!session && !force) return usage('release needs --session <id>, or --force for a lock whose session is gone');
      for (const p of args) {
        const rel = relPath(p);
        if (rel && !release(rel, session, force)) console.error(`not released (not yours, or not locked): ${rel}`);
      }
      return 0;
    }
    case 'prune': {
      for (const l of allLocks()) if (isStale(l)) release(l.path, l.session, true);
      return 0;
    }
    default:
      return usage();
  }
}

function usage(msg) {
  if (msg) console.error(msg);
  console.error('usage: lock.mjs status | lock <paths> --session <id> | release <paths> (--session <id> | --force) | prune');
  return 1;
}

const [cmd, ...args] = process.argv.slice(2);
const hooks = { pre: hookPre, post: hookPost, session: hookSession };
const run = hooks[cmd] ?? (() => cli(cmd, args));
run().then(
  (code) => process.exit(code),
  (err) => {
    // A broken lock tool must not stop every edit: report it and let the tool call through.
    process.stderr.write(`lock.mjs: ${err?.stack ?? err}\n`);
    process.exit(cmd === 'pre' ? 1 : 0);
  },
);
