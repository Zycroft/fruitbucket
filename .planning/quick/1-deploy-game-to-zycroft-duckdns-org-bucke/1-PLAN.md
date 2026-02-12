---
phase: quick-1
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - .github/workflows/deploy-web.yml
autonomous: true
user_setup:
  - service: GitHub Actions SSH
    why: "SSH access to deploy server"
    env_vars:
      - name: SSH_PRIVATE_KEY
        source: "Generate an SSH keypair, add public key to zycroft@zycroft.duckdns.org:~/.ssh/authorized_keys, then add private key as GitHub repo secret named SSH_PRIVATE_KEY (Settings -> Secrets and variables -> Actions -> New repository secret)"
must_haves:
  truths:
    - "Push to main triggers both GitHub Pages AND duckdns deployment"
    - "Godot export runs once and both deploys use the same build artifacts"
    - "Game files land in /var/www/html/bucket/ on the server"
  artifacts:
    - path: ".github/workflows/deploy-web.yml"
      provides: "Combined GitHub Pages + duckdns SSH deployment workflow"
      contains: "rsync"
  key_links:
    - from: ".github/workflows/deploy-web.yml"
      to: "zycroft.duckdns.org"
      via: "SSH key from GitHub secret"
      pattern: "SSH_PRIVATE_KEY"
---

<objective>
Add SSH/rsync deployment to zycroft.duckdns.org/bucket alongside the existing GitHub Pages deployment.

Purpose: Make the game available at zycroft.duckdns.org/bucket in addition to the existing GitHub Pages URL.
Output: Updated deploy-web.yml that exports once and deploys to both targets.
</objective>

<execution_context>
@/home/zycroft/.claude/get-shit-done/workflows/execute-plan.md
@/home/zycroft/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.github/workflows/deploy-web.yml
</context>

<tasks>

<task type="auto">
  <name>Task 1: Split workflow into export + two deploy jobs</name>
  <files>.github/workflows/deploy-web.yml</files>
  <action>
Restructure the existing workflow into 3 jobs:

1. **export** job (reuses all existing Godot cache/install/import/export steps):
   - Runs all steps from Checkout through "Export Web"
   - After export, uploads build/web/ as a workflow artifact using `actions/upload-artifact@v4` with name `web-build` and retention-days 1

2. **deploy-pages** job (existing GitHub Pages deployment):
   - `needs: export`
   - Downloads the `web-build` artifact using `actions/download-artifact@v4`
   - Runs Configure Pages, Upload Pages Artifact, Deploy to GitHub Pages steps (same as current)
   - Keep the `environment` block with github-pages name and URL output
   - This job needs the `pages: write` and `id-token: write` permissions (use job-level permissions)

3. **deploy-duckdns** job (new SSH/rsync deployment):
   - `needs: export`
   - `runs-on: ubuntu-latest`
   - Steps:
     a. Download the `web-build` artifact using `actions/download-artifact@v4` into `build/web/`
     b. Set up SSH: create ~/.ssh, write `${{ secrets.SSH_PRIVATE_KEY }}` to ~/.ssh/id_ed25519, chmod 600, run ssh-keyscan for zycroft.duckdns.org and append to known_hosts
     c. rsync: `rsync -avz --delete build/web/ zycroft@zycroft.duckdns.org:/var/www/html/bucket/`

Move `contents: read` to top-level permissions. Move `pages: write` and `id-token: write` to the deploy-pages job level.

Keep the existing concurrency group. Keep workflow_dispatch trigger.
  </action>
  <verify>Run `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/deploy-web.yml'))"` or equivalent to validate YAML syntax. Visually confirm 3 jobs exist: export, deploy-pages, deploy-duckdns.</verify>
  <done>Workflow has 3 jobs. Export runs once, both deploys download the artifact. GitHub Pages deploy unchanged in behavior. duckdns deploy uses SSH_PRIVATE_KEY secret and rsync to /var/www/html/bucket/.</done>
</task>

</tasks>

<verification>
- YAML is valid
- `export` job contains Godot install + export steps and uploads artifact
- `deploy-pages` job downloads artifact and deploys to GitHub Pages
- `deploy-duckdns` job downloads artifact, sets up SSH, and rsyncs to server
- Both deploy jobs have `needs: export`
- SSH_PRIVATE_KEY referenced as `${{ secrets.SSH_PRIVATE_KEY }}`
- rsync target is `zycroft@zycroft.duckdns.org:/var/www/html/bucket/`
</verification>

<success_criteria>
Updated deploy-web.yml with 3-job pipeline: single Godot export feeding both GitHub Pages and duckdns SSH/rsync deployments in parallel.
</success_criteria>

<output>
After completion, create `.planning/quick/1-deploy-game-to-zycroft-duckdns-org-bucke/1-SUMMARY.md`
</output>
