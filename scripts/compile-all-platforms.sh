#!/usr/bin/env bash
# Compile ugrep for all supported platforms

set -e

echo "==================================="
echo "Compiling ugrep for all platforms"
echo "==================================="
echo ""

# Array of targets to build
TARGETS=(
    "x86_64-linux"
    "aarch64-linux"
    "x86_64-windows"
    "aarch64-windows"
    "x86_64-freebsd"
    "aarch64-freebsd"
    "x86_64-netbsd"
    "aarch64-netbsd"
    "x86_64-macos"
    "aarch64-macos"
)

# Build each target
for target in "${TARGETS[@]}"; do
    echo "Building for $target..."
    zig build -Dtarget="$target" --release=small
    echo "✓ $target complete"
    echo ""
done

echo "==================================="
echo "All builds complete!"
echo "==================================="
echo ""
echo "Binaries located in: zig-out/bin/"
echo ""
echo "ugrep binaries:"
ls -lh zig-out/bin/ugrep* | grep -v indexer
echo ""
echo "ugrep-indexer binaries:"
ls -lh zig-out/bin/*indexer*
