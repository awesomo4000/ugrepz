# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### 11/07/2025
- Initial working build of ugrep using Zig 0.15.2 build system
- Vendored dependencies using git subtrees: ugrep, zlib, lz4, zstd, brotli, xz
- Built compression libraries: zlib, lz4, zstd, brotli
- Integrated ugrep's bundled LZMA SDK for 7zip support
- Built libreflex (RE/flex regex engine) with SIMD optimizations
- Cross-platform SIMD support: x86_64 (SSE2/AVX2/AVX512BW), ARM (NEON)
- Successfully built and tested ugrep executable
- Verified compression format support: gz, lz4, zstd, brotli, 7z
- Generated config.h using `CC="zig cc" CXX="zig c++" ./configure`
- Disabled optional features: PCRE2, bzip2, external liblzma
- Created modular build system with separate build files per library
- **Binary sizes** (all compression libraries statically linked):
  - Debug mode: 14MB
  - Release-safe: 2.3MB
  - Release-fast: 2.1MB
  - Release-small: 1.8MB
- Verified all release modes build and function correctly
- **Cross-compilation support** (tested and verified - all 10 platforms):
  - ✅ Linux (x86_64, ARM64) - Fully working, statically linked (1.7-1.8MB)
  - ✅ FreeBSD (x86_64, ARM64) - Fully working, dynamically linked (1.6-1.7MB)
  - ✅ NetBSD (x86_64, ARM64) - Fully working, dynamically linked (1.6-1.7MB)
  - ✅ macOS (x86_64, ARM64) - Fully working, dynamically linked (1.7-1.8MB)
  - ✅ Windows (x86_64, ARM64) - Fully working with compatibility patches (1.3-1.5MB)
    - Fixed 42 header conflicts with MinGW/clang (ssize_t, strcasecmp, popen, etc.)
    - Patched ugrep source in `vendor/windows_compat/` for cross-compiler compatibility
    - Disabled 7zip support on Windows (viizip.c is POSIX-only)
    - Added WinMain wrapper for console entry point
    - Linked ws2_32 for Winsock functions
  - BSD platforms use patched LZMA SDK in `vendor/freebsd_compat/` (fixes Linux-only asm/hwcap.h dependency)
- Platform-specific config handling in build.zig for proper cross-compilation
- SIMD optimizations: AVX2/AVX512BW for native builds, SSE2 for cross-compilation

### Project Structure
- Main build entry: `build.zig`
- Vendor orchestration: `vendor/build.zig`
- Library builds: `vendor/build_zlib.zig`, `build_lz4.zig`, `build_zstd.zig`, `build_brotli.zig`, `build_lzma_sdk.zig`
- Main executable: `vendor/build_ugrep.zig`
- Documentation: `CLAUDE.md`, `README.md`

### Tested Features
- ✅ **All 61 tests from ugrep test suite passing** (`./scripts/run-tests.sh`)
- ✅ Basic grep functionality (`ugrep "pattern" file`)
- ✅ Gzip compressed files (`ugrep -z "pattern" file.gz`)
- ✅ LZ4 compressed files (`ugrep -z "pattern" file.lz4`)
- ✅ Zstandard compressed files (`ugrep -z "pattern" file.zst`)
- ✅ Brotli compressed files (`ugrep -z "pattern" file.br`)
- ✅ Version information (`ugrep --version`)
- ✅ Help output (`ugrep --help`)

### Regex Engine
- ✅ **RE/flex** (libreflex) - Full POSIX ERE/BRE support (default, fully functional)
- ❌ PCRE2 not included (Perl regex `-P` flag unavailable, optional)
- ❌ Boost.Regex not included (optional alternative)

### Known Limitations
- bzip2 support not included (.bz2 files unsupported)
- External liblzma not used (bundled LZMA SDK provides 7zip support on POSIX)
- 7zip support disabled on Windows (viizip.c requires POSIX APIs)

### Build Commands
```bash
zig build                         # Build ugrep + all libraries
zig build libs                    # Build only libraries
zig build run                     # Build and run ugrep
./scripts/compile-all-platforms.sh # Build all 10 platforms
./scripts/run-tests.sh            # Run test suite (61 tests)
```

### Dependencies Versions
- ugrep: 7.5.0
- zlib: latest from madler/zlib master
- lz4: latest from lz4/lz4 dev
- zstd: latest from facebook/zstd dev
- brotli: latest from google/brotli master
- xz: latest from tukaani-project/xz master (vendored but not used)
