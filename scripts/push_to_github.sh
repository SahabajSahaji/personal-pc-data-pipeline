#!/bin/bash

PROJECT_DIR="$HOME/personal-pc-data-pipeline"

cd "$PROJECT_DIR" || exit 1

# Add generated data
git add data/system_metrics.csv
git add data/network_state.json

# Check if there is anything to commit
if git diff --cached --quiet; then
    echo "No changes to commit."
    exit 0
fi

# Commit changes
git commit -m "Daily PC metrics: $(date '+%Y-%m-%d %H:%M:%S')"

if [ $? -ne 0 ]; then
    echo "ERROR: Git commit failed."
    exit 1
fi

# Push to GitHub
git push origin main

if [ $? -ne 0 ]; then
    echo "ERROR: Git push failed."
    exit 1
fi

echo "GitHub push successful."
