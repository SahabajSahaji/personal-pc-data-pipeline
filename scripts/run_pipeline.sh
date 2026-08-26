#!/bin/bash

PROJECT_DIR="$HOME/personal-pc-data-pipeline"
LOG_FILE="$PROJECT_DIR/logs/pipeline.log"


echo "----------------------------------------" >> "$LOG_FILE"
echo "$(date '+%Y-%m-%d %H:%M:%S') - Pipeline started" >> "$LOG_FILE"

# Run Windows PowerShell collector

powershell.exe -ExecutionPolicy Bypass \
    -File "$(wslpath -w "$PROJECT_DIR/scripts/collect_windows_data.ps1")"

if [ $? -ne 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Collection FAILED" >> "$LOG_FILE"
    exit 1
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') - Windows data collected" >> "$LOG_FILE"

# Push data to GitHub


"$PROJECT_DIR/scripts/push_to_github.sh" >> "$LOG_FILE" 2>&1

if [ $? -ne 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - GitHub push FAILED" >> "$LOG_FILE"
    exit 1
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') - GitHub push successful" >> "$LOG_FILE"

echo "$(date '+%Y-%m-%d %H:%M:%S') - Pipeline completed" >> "$LOG_FILE"
