#!/bin/bash
# Daily auto-push: commits and pushes any changes to GitHub at noon

cd /Users/ceecer1/nanoclaw || exit 1

# Check for any changes (staged, unstaged, or untracked)
if [[ -z "$(git status --porcelain)" ]]; then
  echo "$(date): No changes to push."
  exit 0
fi

git add -A
git commit -m "chore: auto-commit $(date '+%Y-%m-%d')"
git push origin main
echo "$(date): Changes committed and pushed."
