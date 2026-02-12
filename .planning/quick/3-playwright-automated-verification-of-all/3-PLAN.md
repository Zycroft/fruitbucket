# Quick Task 3: Playwright Automated Verification

## Goal
Verify all 8 phases of Bucket work correctly on the deployed site (zycroft.duckdns.org/bucket/) using Playwright browser automation with screenshot capture and console log analysis.

## Constraints
- Godot 4.5 renders everything to a single `<canvas>` element — no HTML DOM elements to inspect
- Verification relies on: canvas input simulation, screenshots, console log capture
- Physics is non-deterministic — verify stability, not exact positions
- Previous session (Feb 9) found physics `call_deferred` errors in console

## Test Plan

### Test 1: Smoke Test & Page Load
- Navigate to https://zycroft.duckdns.org/bucket/
- Wait for canvas to render (game loaded)
- Screenshot initial state
- Check console for critical errors (not warnings)
- **Verifies:** Game deploys and loads without crash

### Test 2: Starter Kit Selection (Phase 8)
- Verify starter kit selection overlay appears on load
- Screenshot the kit selection screen
- Click to select a kit
- **Verifies:** Phase 8 starter kits

### Test 3: Fruit Drop & Physics (Phase 1)
- Click on canvas to drop fruits (multiple drops)
- Wait for physics settling
- Screenshot fruit stacking
- **Verifies:** Phase 1 drop, physics, stacking

### Test 4: Merging & Score (Phases 1-2)
- Drop same-tier fruits to trigger merges
- Check if score updates visible in screenshots
- **Verifies:** Phase 1 merging, Phase 2 scoring

### Test 5: Visual Feedback (Phase 3)
- Observe merge effects in screenshots (particles, visual changes)
- **Verifies:** Phase 3 merge feedback

### Test 6: HUD Elements (Phases 2, 5)
- Screenshot HUD area (score, coins, card slots, next preview)
- Verify visible UI elements
- **Verifies:** Phase 2 HUD, Phase 5 card slots

### Test 7: Pause Menu (Phase 4)
- Click pause button area (top-right of canvas)
- Screenshot pause overlay
- Click resume
- **Verifies:** Phase 4 pause/resume

### Test 8: Console Error Analysis (All Phases)
- Collect all console errors/warnings throughout session
- Categorize: critical vs non-critical
- Flag any physics callback errors
- **Verifies:** Overall stability across all phases

## Output
- Screenshots saved to `.playwright-cli/`
- Console logs captured
- Verification report in 3-SUMMARY.md
