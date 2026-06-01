#!/usr/bin/env bash
# cleanup-kustomize-demo-stale.sh
#
# One-time cleanup for files left behind when the Kustomize demo moved
# from Day 3 (15-min "Patch Kit" demo with per-student overlays) to Day 2
# (10-min v1 → v2 raft image bump). The authoring sandbox can't delete
# files; this script runs locally and removes the stale examples.
#
# Safe to re-run — it just calls `rm -f` on a known set of files.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEMO="$REPO_ROOT/docs/missions/day-02/kustomize-demo"

if [[ ! -d "$DEMO" ]]; then
  echo "✗ Expected $DEMO to exist. Aborting." >&2
  exit 1
fi

echo "Removing stale Day-3 example files from $DEMO ..."
rm -f  "$DEMO/base/deployment.yaml"
rm -f  "$DEMO/base/service.yaml"
rm -rf "$DEMO/overlays/student-01"
rm -rf "$DEMO/overlays/student-02"
rm -rf "$DEMO/overlays/harder-mode"

# Verify what's left matches the active demo's expected layout.
echo
echo "Remaining layout:"
find "$DEMO" -mindepth 1 -print | sed "s|$DEMO|kustomize-demo|"

echo
echo "✓ Cleanup complete. Verify the active demo still renders:"
echo "  cd $DEMO && kubectl kustomize overlays/all-students/"
