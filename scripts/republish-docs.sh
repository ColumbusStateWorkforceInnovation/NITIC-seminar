#!/usr/bin/env bash
# ============================================================
# Republish docs.wagbiz.org from the current repo state
# ------------------------------------------------------------
# Use after editing anything under docs/ or mkdocs.yml.
# Steps:
#   1. Commit + push to GitHub (so the public repo matches).
#   2. `just seed-docs` — pushes HEAD to the in-cluster Gitea
#      branch `maindeck`; docs-hub's git-sync pulls within ~10s
#      and MkDocs rebuilds.
#
# Requires:  lab.env populated with GITEA_ADMIN_PASSWORD, SERVER_IP,
#            SERVER_SSH_KEY (everything `just seed-docs` already needs).
# ============================================================
set -euo pipefail

cd "$(dirname "$0")/.."

# 1. Commit if there's anything staged or modified.
if ! git diff --quiet || ! git diff --cached --quiet; then
  git add docs/ mkdocs.yml
  git commit -m "docs: republish — fix stale syllabus nav link"
else
  echo "✓ nothing to commit (working tree clean)"
fi

# 2. Push to GitHub.
git push origin main

# 3. Seed the in-cluster Gitea + bounce docs-hub.
just seed-docs

echo
echo "✅ docs.wagbiz.org should refresh within ~10s."
echo "   Verify: curl -sI https://docs.wagbiz.org/ | head -1"
