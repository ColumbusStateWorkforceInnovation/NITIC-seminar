#!/usr/bin/env bash
# Removes the now-obsolete docs/missions/book-readings.md.
# Storytime page references moved into each day's instructor guide
# (2026-06-02 prep for Day 2 of the NITIC seminar).
#
# Run from the repo root:  ./scripts/cleanup-book-readings.sh
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

if git ls-files --error-unmatch docs/missions/book-readings.md >/dev/null 2>&1; then
  git rm docs/missions/book-readings.md
  echo "✅ git rm'd docs/missions/book-readings.md"
else
  echo "ℹ️  docs/missions/book-readings.md is not tracked; nothing to remove."
fi

# Sanity-check for lingering references.
echo
echo "🔎 Searching for any remaining 'book-readings' references…"
if rg -n "book-readings" --hidden --no-ignore -g '!.git' .; then
  echo "⚠️  References found above. Resolve those before committing."
  exit 1
fi
echo "✅ No remaining references."

echo
echo "Next: git commit -m 'docs: inline storytime page refs in instructor guides; drop book-readings.md'"
