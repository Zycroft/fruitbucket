---
name: z-verify
description: Validate the deployed Fruitbucket game via Playwright CLI using DOM elements and console logs. Use after pushing changes to verify the live site works correctly.
---

# Verify Deployed Build

Validate the deployed Fruitbucket game at the URL from CLAUDE.md using Playwright CLI.
Use DOM inspection, JavaScript evaluation, and console log analysis. Do NOT use screenshots.

## Deployment Timing

The site deploys automatically on push to `main`. It may take up to 5 minutes for changes to go live. If the page shows stale content, wait and retry.

## Validation Steps

### 1. Open the deployed site

```bash
playwright-cli open <URL from CLAUDE.md Verification section>
```

### 2. Wait for Godot engine to load

The page has these key DOM elements:
- `<canvas id="canvas">` — Game rendering surface
- `<div id="status">` — Loading overlay (hidden when game is ready)
- `<progress id="status-progress">` — Loading bar
- `<div id="status-notice">` — Error messages

Wait for the engine to finish loading by polling the status div:

```bash
# Check if status overlay is still visible (display !== 'none' means still loading)
playwright-cli eval "document.querySelector('#status').style.display"
```

When the game is loaded, `#status` will have `display: none`.

If `#status-notice` contains text, the engine failed to load — report the error text:

```bash
playwright-cli eval "document.querySelector('#status-notice').textContent"
```

### 3. Verify canvas is active

```bash
# Check canvas dimensions match expected viewport (1080x1920 or window override 540x960)
playwright-cli eval "JSON.stringify({w: document.querySelector('#canvas').width, h: document.querySelector('#canvas').height})"
```

### 4. Capture console output

```bash
# Get all console messages (Godot prints errors/warnings here)
playwright-cli console
```

Analyze console output for:
- **CRITICAL errors**: `ERROR:`, `SCRIPT ERROR:`, `flushing queries`, `contact monitoring` — these indicate bugs
- **Warnings**: `WARNING:` — note but don't fail
- **Expected**: `SFX bus not found` (1 occurrence, has graceful fallback) — ignore
- **Expected**: `WebGL: INVALID_ENUM` or `ReadPixels` GPU stalls — cosmetic, ignore

### 5. Interact with the game

The game renders everything on a `<canvas>` element. Interact via mouse clicks on the canvas:

```bash
# Get canvas position for click targeting
playwright-cli eval "JSON.stringify(document.querySelector('#canvas').getBoundingClientRect())"
```

**Starter card pick** (first screen after load):
- The starter kit selection is displayed on the canvas
- Click in the lower portion of the canvas to pick a starter card
- After picking, the game should enter DROPPING state

**Drop fruits** (gameplay):
- Click the upper portion of the canvas to drop fruits
- Drop several fruits and wait for merges to happen
- Check console for new errors after each interaction

```bash
# Click at a position on the canvas (x, y relative to viewport)
playwright-cli click <canvas-ref>
# Wait briefly for physics
# Check console again
playwright-cli console
```

### 6. Check for the game freeze bug (regression test)

Play until score approaches 1500 (or just play for a while with many drops). If the game freezes (console shows no new output, clicks don't produce any response), report it as a regression.

### 7. Report results

Summarize findings:

```
## Verification Report

**URL:** <tested URL>
**Date:** <date>
**Status:** PASS / FAIL

### Checks
| Check | Result | Notes |
|-------|--------|-------|
| Page loads | PASS/FAIL | |
| Engine initializes | PASS/FAIL | |
| Canvas active | PASS/FAIL | dimensions |
| Console errors | PASS/FAIL | error count |
| Starter pick works | PASS/FAIL | |
| Fruit dropping works | PASS/FAIL | |
| Merging works | PASS/FAIL | |
| No game freeze | PASS/FAIL | |

### Console Errors (if any)
<list critical errors>

### Warnings (if any)
<list warnings>
```

### 8. Clean up

```bash
playwright-cli close
```

## Error Classification

| Pattern | Severity | Action |
|---------|----------|--------|
| `SCRIPT ERROR` | CRITICAL | Report as bug |
| `contact monitoring` | MAJOR | Physics callback bug |
| `flushing queries` | MAJOR | Physics callback bug |
| `SFX bus not found` | IGNORE | Known, has fallback |
| `WebGL` / `ReadPixels` | IGNORE | Browser cosmetic |
| `WARNING:` | LOW | Note in report |
