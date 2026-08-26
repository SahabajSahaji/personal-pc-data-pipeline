#!/bin/bash

PROJECT_DIR="$HOME/personal-pc-data-pipeline"

cd "$PROJECT_DIR" || exit 1

git add data/system_metrics.csv
git add data/network_state.json

if git diff --cached --quiet; then
    echo "No changes to commit."
    exit 0
fi

git commit -m "Daily PC metrics: $(date '+%Y-%m-%d %H:%M:%S')"

git push origin main
