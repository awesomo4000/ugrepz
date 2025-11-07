#!/usr/bin/env bash
# Run ugrep test suite

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

UGREP_BINARY="${UGREP_BINARY:-$PROJECT_ROOT/zig-out/bin/ugrep}"
CONFIG_H="$PROJECT_ROOT/vendor/ugrep/config.h"
TEST_DATA="$PROJECT_ROOT/vendor/ugrep/tests/out"

if [ ! -x "$UGREP_BINARY" ]; then
    echo "Error: ugrep binary not found at $UGREP_BINARY"
    echo "Please build first with: zig build"
    exit 1
fi

if [ ! -f "$CONFIG_H" ]; then
    echo "Error: config.h not found at $CONFIG_H"
    exit 1
fi

if [ ! -d "$TEST_DATA" ]; then
    echo "Error: Test reference outputs not found at $TEST_DATA"
    echo ""
    echo "The test reference data was removed by cleanup-vendor.sh to save space."
    echo "Please restore it with: ./scripts/restore-test-data.sh"
    exit 1
fi

echo "==================================="
echo "Running ugrep test suite"
echo "==================================="
echo "Binary: $UGREP_BINARY"
echo "Config: $CONFIG_H"
echo ""

cd "$PROJECT_ROOT/vendor/ugrep/tests"

env UGREP_ABS_PATH="$UGREP_BINARY" CONFIGH_ABS_PATH="$CONFIG_H" ./verify.sh

echo ""
echo "==================================="
echo "All tests completed!"
echo "==================================="
