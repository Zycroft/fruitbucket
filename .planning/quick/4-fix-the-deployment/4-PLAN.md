# Quick Task 4: Fix the Deployment

## Goal
Fix both deployment targets so the latest game build (all 8 phases) is served correctly.

## Root Causes
1. **GitHub Pages**: Repo is PRIVATE — free GitHub plan doesn't support Pages for private repos. `configure-pages@v4` fails with "Get Pages site failed".
2. **duckdns**: Deploy rsync reports SUCCESS but serves stale .pck file. Likely browser/CDN caching of the Godot .pck binary.

## Tasks

### Task 1: Fix GitHub Pages — make repo public
The repo was public before (confirmed in CLAUDE.md and memory). Re-publicize it so Pages works again.

**Steps:**
1. Run `gh repo edit Zycroft/fruitbucket --visibility public` to make the repo public
2. Run `gh api repos/Zycroft/fruitbucket/pages -X POST -f build_type=workflow` to enable Pages with GitHub Actions source
3. Verify with `gh api repos/Zycroft/fruitbucket/pages`

**Commit:** None (no code changes)

### Task 2: Add cache-busting to web export
Prevent stale .pck file serving by appending a build timestamp to asset URLs in the exported HTML.

**Steps:**
1. Add a post-export step in `.github/workflows/deploy-web.yml` that appends a query string (`?v=<timestamp>`) to the .pck and .wasm references in `build/web/index.html`
2. This ensures browsers always fetch fresh binaries after each deploy

**Changes:**
- `.github/workflows/deploy-web.yml` — add sed step after export to inject cache-busting query params

**Commit:** `fix(deploy): add cache-busting to web export assets`

### Task 3: Re-trigger deployment
Push changes to trigger a fresh deploy with both fixes active.

**Steps:**
1. The commit from Task 2 will trigger the workflow automatically on push to main
2. Verify both deploy-pages and deploy-duckdns jobs succeed via `gh run watch`

**Commit:** None (triggered by Task 2 commit)
