#!/usr/bin/env bash
# Restore ugrep test reference outputs from git history
# These files are removed by cleanup-vendor.sh to reduce repository size
# but can be restored when you need to run the test suite

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

echo "==================================="
echo "Restoring ugrep test reference data"
echo "==================================="
echo ""

# Check if tests/out already exists
if [ -d "vendor/ugrep/tests/out" ]; then
    echo "⚠️  vendor/ugrep/tests/out already exists"
    echo ""
    read -p "Do you want to restore from git history? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 0
    fi
fi

# Find the most recent commit that has the test output files
echo "Finding commit with test reference outputs..."
COMMIT=$(git log --all --format=%H -- vendor/ugrep/tests/out | head -1)

if [ -z "$COMMIT" ]; then
    echo "❌ Error: Could not find test reference outputs in git history"
    echo ""
    echo "This might mean:"
    echo "  - The files were never committed"
    echo "  - You need to run: git subtree pull --prefix vendor/ugrep https://github.com/Genivia/ugrep.git master --squash"
    exit 1
fi

echo "Found test data in commit: ${COMMIT:0:8}"
echo ""

# Restore the directory from that commit
echo "Restoring vendor/ugrep/tests/out/..."
git checkout "$COMMIT" -- vendor/ugrep/tests/out

echo ""
echo "==================================="
echo "Restore complete!"
echo "==================================="
echo ""
echo "Test reference outputs restored to: vendor/ugrep/tests/out/"
du -sh vendor/ugrep/tests/out
echo ""
echo "You can now run tests with: ./scripts/run-tests.sh"
echo ""
echo "Note: These files are NOT staged for commit."
echo "      Add them to .gitignore if you want to keep them local only."
