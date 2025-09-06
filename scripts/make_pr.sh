#!/usr/bin/env bash
set -euo pipefail
DAY=${1:?Usage: ./make_pr.sh <DAY_NUMBER>}
BR="grit/day-${DAY}"
git checkout -b "$BR"
git add -A
git commit -m "GRIT Day ${DAY} — update"
git push -u origin "$BR"
gh pr create --fill --title "GRIT Day ${DAY} — update" --base main --head "$BR" || true
