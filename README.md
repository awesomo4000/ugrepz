# ugrepz

Ultra-fast grep with Zig build system - A rebuild of [ugrep](https://github.com/Genivia/ugrep) using Zig for cross-platform compilation.

## Features

- **Cross-platform builds** using Zig 0.15.2
- **Compression formats**: gz, Z, lz4, zstd, brotli, 7z (via bundled LZMA SDK)
- **SIMD optimizations**: Auto-detected (SSE2/AVX2/AVX512BW on x86_64, NEON on ARM)
- **Vendored dependencies**: Uses git subtrees for painless updates
- **Modular build system**: Clean separation of library builds

## Quick Start

```bash
# Build ugrep with all compression libraries
zig build

# Run ugrep
zig build run -- "pattern" files...

# Or use the built binary directly
./zig-out/bin/ugrep --help
```

## Building

Requires Zig 0.15.2:

```bash
# Install zig 0.15.2 first
# Then:
zig build              # Build everything (debug mode)
zig build libs         # Build only compression libraries
zig build run          # Build and run ugrep
zig build run-indexer  # Build and run ugrep-indexer

# Release modes (optimized builds)
zig build --release=safe   # Release with safety checks (2.3MB)
zig build --release=fast   # Fast release build (2.1MB)
zig build --release=small  # Smallest binary size (1.8MB)
```

### Cross-compilation

```bash
# Build for specific platforms
zig build -Dtarget=x86_64-linux --release=small
zig build -Dtarget=aarch64-linux --release=small
zig build -Dtarget=x86_64-windows --release=small
zig build -Dtarget=aarch64-windows --release=small
zig build -Dtarget=x86_64-freebsd --release=small
zig build -Dtarget=aarch64-freebsd --release=small
zig build -Dtarget=x86_64-netbsd --release=small
zig build -Dtarget=aarch64-netbsd --release=small
zig build -Dtarget=x86_64-macos --release=small
zig build -Dtarget=aarch64-macos --release=small

# Or build all platforms at once
./scripts/compile-all-platforms.sh
```

## Status

✅ **Fully Functional - All 10 Platforms Supported**

- ✅ Zig build system setup
- ✅ Vendor dependencies via git subtrees
- ✅ zlib, lz4, zstd, brotli libraries building
- ✅ Bundled LZMA SDK (7zip support on POSIX)
- ✅ ugrep builds and runs successfully
- ✅ Cross-compilation for 10 platforms (x86_64 + ARM64)
  - Linux, Windows, FreeBSD, NetBSD, macOS
- ✅ Platform-specific compatibility patches
  - Windows: MinGW/clang compatibility
  - BSD: LZMA SDK HWCAP fixes
- ⚠️  Testing and benchmarks (upcoming)

## Project Structure

```
.
├── build.zig                 # Main build file
├── vendor/
│   ├── build.zig            # Vendor build orchestration
│   ├── build_*.zig          # Individual library build files
│   ├── ugrep/               # ugrep source (git subtree)
│   ├── zlib/                # zlib source (git subtree)
│   ├── lz4/                 # lz4 source (git subtree)
│   ├── zstd/                # zstd source (git subtree)
│   ├── brotli/              # brotli source (git subtree)
│   └── xz/                  # xz/liblzma source (git subtree)
└── CLAUDE.md                # Developer documentation

```

## Testing

The test suite requires test reference data that is removed by the cleanup script to save space:

```bash
# First time: restore test reference outputs (~16MB)
./scripts/restore-test-data.sh

# Then run tests
./scripts/run-tests.sh
```

Note: Test data is restored from git history and not committed. Add `vendor/ugrep/tests/out/` to `.gitignore` if you want to keep it locally.

## Vendor Management

Vendor directories are kept minimal to reduce repository size:

```bash
# Clean up vendor directories (removes ~85-95MB)
./scripts/cleanup-vendor.sh

# Restore test reference data when needed
./scripts/restore-test-data.sh
```

The cleanup script removes:
- Pre-built binaries (~8.5MB)
- Test reference outputs (~16MB) - can be restored
- Language bindings for compression libraries (Go, Java, JS, Python, C#)
- Documentation (except ugrep man pages)
- Examples and research code

Kept files:
- All source code needed for building
- ugrep test scripts (not reference outputs)
- Man pages and shell completions
- Predefined regex patterns

## Why Zig?

- **Cross-compilation** out of the box
- **C/C++ interop** without complex build tools
- **Static linking** made easy
- **Fast builds** with caching
- **No CMake/Autotools** complexity

## Contributing

See [CLAUDE.md](./CLAUDE.md) for development guidelines and architecture details.

## License

This build system: MIT License
ugrep: BSD-3-Clause License
Compression libraries: Various (see individual vendor directories)

## Credits

- [ugrep](https://github.com/Genivia/ugrep) by Robert van Engelen
- Compression libraries by their respective authors
- Built with [Zig](https://ziglang.org/)
