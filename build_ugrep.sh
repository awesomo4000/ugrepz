#!/bin/bash
# Build ugrep binary from source
#
# Usage:
#   ./build_ugrep.sh                    # Build debug
#   ./build_ugrep.sh --release=fast     # Build release
#   ./build_ugrep.sh run -- [args]      # Run ugrep
#   ./build_ugrep.sh test-api           # Run integration tests

set -e
cd "$(dirname "$0")"
exec zig build --build-file build_ugrep.zig "$@"
