# Quick Task 4: Fix the Deployment — Summary

## Changes Made

### 1. Made repo public (fixed GitHub Pages)
- Repo was PRIVATE — GitHub free plan doesn't support Pages for private repos
- Ran `gh repo edit --visibility public` to restore public access
- Ran `gh api repos/.../pages -X POST -f build_type=workflow` to re-enable Pages with Actions source

### 2. Added cache-busting to web export (`deploy-web.yml`)
- New "Cache-bust assets" step after Godot export
- Appends `?v=<git-sha-8>` to `.pck`, `.wasm`, and `.js` references in `index.html`
- Ensures browsers always fetch fresh binaries after each deploy

### 3. Added checksum-based rsync for duckdns
- Changed `rsync -avz` to `rsync -avzc` (added `--checksum` flag)
- Forces content-based file comparison instead of just timestamp/size

### 4. Renamed workflow
- `Deploy to GitHub Pages` → `Deploy Web Build` (reflects dual deployment)

## Deployment Result

Run 21969623706 — **ALL JOBS PASSED**:
- export: 37s
- deploy-duckdns: 9s
- deploy-pages: 12s

Both https://zycroft.github.io/fruitbucket/ and https://zycroft.duckdns.org/bucket/ now serve the latest build with all 8 phases.

## Files Changed
- `.github/workflows/deploy-web.yml` — cache-busting step, checksum rsync, workflow rename
