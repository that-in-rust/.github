#!/bin/bash

# Test script to verify cleanup functionality
echo "Testing cleanup functionality..."

# Run the script and capture temp file creation
output=$(./git-union-merge --dry-run --verbose 2>&1)
echo "Script output:"
echo "$output"

# Extract temp file path from output
temp_file=$(echo "$output" | grep "Created temporary analysis file:" | sed 's/.*Created temporary analysis file: //')

echo ""
echo "Checking if temp file was cleaned up..."
if [[ -n "$temp_file" && -f "$temp_file" ]]; then
    echo "❌ FAIL: Temp file still exists: $temp_file"
    exit 1
else
    echo "✅ PASS: Temp file was properly cleaned up"
fi

echo ""
echo "Testing JSON output with cleanup..."
json_output=$(./git-union-merge --dry-run --json 2>/dev/null)
echo "JSON output: $json_output"

# Verify JSON is valid
if echo "$json_output" | jq . >/dev/null 2>&1; then
    echo "✅ PASS: JSON output is valid"
else
    echo "❌ FAIL: JSON output is invalid"
    exit 1
fi

echo ""
echo "All cleanup tests passed! ✅"