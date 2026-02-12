---
phase: quick-1
plan: 01
subsystem: infra
tags: [github-actions, ssh, rsync, deployment, duckdns]

# Dependency graph
requires:
  - phase: existing
    provides: "deploy-web.yml GitHub Pages workflow"
provides:
  - "Dual deployment pipeline: GitHub Pages + duckdns SSH/rsync"
  - "Shared build artifact pattern for parallel deployments"
affects: [deployment, ci-cd]

# Tech tracking
tech-stack:
  added: [rsync, ssh-keyscan]
  patterns: ["Single export job with artifact upload feeding parallel deploy jobs"]

key-files:
  created: []
  modified:
    - ".github/workflows/deploy-web.yml"

key-decisions:
  - "Split single job into 3 (export, deploy-pages, deploy-duckdns) for build-once-deploy-many"
  - "Job-level permissions for pages/id-token instead of top-level to follow least-privilege"
  - "1-day retention on build artifact since both deploys run immediately"

patterns-established:
  - "Artifact sharing: upload-artifact@v4 in build job, download-artifact@v4 in deploy jobs"

# Metrics
duration: 1min
completed: 2026-02-12
---

# Quick Task 1: Deploy to zycroft.duckdns.org/bucket Summary

**3-job CI pipeline: single Godot export feeding parallel GitHub Pages and duckdns SSH/rsync deployments**

## Performance

- **Duration:** 1 min
- **Started:** 2026-02-12T05:01:59Z
- **Completed:** 2026-02-12T05:02:56Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments
- Restructured monolithic export-and-deploy job into 3 independent jobs
- Export job builds once and uploads web-build artifact (1-day retention)
- Both deploy-pages and deploy-duckdns download the same artifact and deploy in parallel
- duckdns deploy uses SSH_PRIVATE_KEY secret with rsync --delete to /var/www/html/bucket/

## Task Commits

Each task was committed atomically:

1. **Task 1: Split workflow into export + two deploy jobs** - `0f98453` (feat)

## Files Created/Modified
- `.github/workflows/deploy-web.yml` - 3-job pipeline: export, deploy-pages, deploy-duckdns

## Decisions Made
- Split into 3 jobs rather than sequential steps to enable parallel deployment
- Moved pages/id-token write permissions to deploy-pages job level (least privilege)
- Used ssh-keyscan for host key verification rather than disabling strict checking
- 1-day artifact retention since both deploys trigger immediately after export

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required

**SSH key configuration required for duckdns deployment.** The deploy-duckdns job requires:

1. Generate an SSH keypair (ed25519 recommended)
2. Add the public key to `zycroft@zycroft.duckdns.org:~/.ssh/authorized_keys`
3. Add the private key as a GitHub repo secret named `SSH_PRIVATE_KEY` (Settings -> Secrets and variables -> Actions -> New repository secret)
4. Ensure `/var/www/html/bucket/` exists on the server and is writable by the zycroft user

**Verification:** Push to main and check GitHub Actions for both deploy jobs passing.

## Next Phase Readiness
- Workflow is ready to deploy once SSH_PRIVATE_KEY secret is configured
- GitHub Pages deployment behavior unchanged
- No blockers for Phase 8 or other planned work

---
*Quick Task: 1-deploy-game-to-zycroft-duckdns-org-bucke*
*Completed: 2026-02-12*

## Self-Check: PASSED
- [x] `.github/workflows/deploy-web.yml` exists
- [x] `1-SUMMARY.md` exists
- [x] Commit `0f98453` exists in git log
