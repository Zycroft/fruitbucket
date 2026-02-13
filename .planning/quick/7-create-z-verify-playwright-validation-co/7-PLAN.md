# Quick Task 7: Create /z:verify Playwright Validation Command

## Overview

Create a Claude Code skill `/z:verify` that uses Playwright CLI to validate the deployed Godot web game via DOM elements and console logs (no screenshots).

## Tasks

### Task 1: Add website URL to CLAUDE.md

Add a `## Verification` section to CLAUDE.md with the deployed URL and deployment timing note.

### Task 2: Create the /z:verify skill

Create `.claude/skills/z-verify/SKILL.md` with:

**Validation strategy (DOM-based, no screenshots):**
- Page load: `<canvas id="canvas">` exists, `<div id="status">` hidden after load
- Console errors: `playwright-cli console` captures Godot errors/warnings
- DOM state: `playwright-cli eval` checks `document.querySelector('#status-notice').textContent`
- Canvas active: eval `document.querySelector('#canvas').width` matches expected viewport
- Game interaction: click canvas to trigger game events, monitor console for errors
- Network: `playwright-cli network` checks all assets loaded (index.pck, index.wasm, index.js)

**Workflow:**
1. Wait for deployment (remind user it may take up to 5 minutes after push)
2. Open site, wait for Godot engine to finish loading
3. Verify DOM state (canvas present, no error notices)
4. Check console for critical errors (physics, script crashes)
5. Interact: click to pick starter card, drop fruits, trigger merges
6. Report: pass/fail with error summary

### Task 3: Commit

Commit both files atomically.
