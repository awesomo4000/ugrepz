# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`ugrepz` is a project to rebuild [ugrep](https://github.com/Genivia/ugrep) using the Zig build system for cross-platform compilation. ugrep is an ultra-fast, user-friendly grep replacement with support for searching compressed archives, Unicode patterns, fuzzy search, and more.

## Build System Architecture

This project uses **Zig 0.15.2** with a modular build system:

### Build File Structure

```
build.zig                    # Main build entry point
vendor/
  ├── build.zig             # Vendor library orchestration
  ├── build_zlib.zig        # zlib compression library
  ├── build_lz4.zig         # lz4 compression library
  ├── build_zstd.zig        # zstd compression library
  ├── build_brotli.zig      # brotli compression library
  ├── build_xz.zig          # xz/liblzma compression library (not used)
  ├── build_lzma_sdk.zig    # Bundled LZMA SDK for 7zip support
  └── build_ugrep.zig       # ugrep executable and libreflex
```

### Build Commands

```bash
# Build everything (ugrep + all compression libraries)
zig build                      # Debug mode (14MB binary)

# Release modes (optimized)
zig build --release=safe       # Release with safety checks (2.3MB)
zig build --release=fast       # Fast release build (2.1MB)
zig build --release=small      # Smallest binary size (1.8MB)

# Build only compression libraries
zig build libs

# Run ugrep (after building)
zig build run -- [ugrep arguments]

# Clean build artifacts
rm -rf zig-out .zig-cache
```

## Dependency Management

Dependencies are vendored using **git subtrees** (not submodules):

### Vendored Dependencies

- **ugrep**: The main ugrep source code (includes bundled LZMA SDK for 7zip support)
- **zlib**: gzip/deflate compression (from madler/zlib)
- **lz4**: Extremely fast compression (from lz4/lz4)
- **zstd**: Facebook's Zstandard compression (from facebook/zstd)
- **brotli**: Google's Brotli compression (from google/brotli)
- **xz**: LZMA/XZ compression (from tukaani-project/xz) - **NOTE: Not currently used; ugrep's bundled LZMA SDK provides 7zip support instead**

### Updating Dependencies

To update a vendored dependency:

```bash
# Update ugrep
git subtree pull --prefix vendor/ugrep https://github.com/Genivia/ugrep.git master --squash

# Update zlib
git subtree pull --prefix vendor/zlib https://github.com/madler/zlib.git master --squash

# Update lz4
git subtree pull --prefix vendor/lz4 https://github.com/lz4/lz4.git dev --squash

# Update zstd
git subtree pull --prefix vendor/zstd https://github.com/facebook/zstd.git dev --squash

# Update brotli
git subtree pull --prefix vendor/brotli https://github.com/google/brotli.git master --squash

# Update xz
git subtree pull --prefix vendor/xz https://github.com/tukaani-project/xz.git master --squash
```

### Why Git Subtrees?

Git subtrees were chosen over submodules because:
1. **Simpler for contributors** - everything is just there, no submodule confusion
2. **Still trackable** - can update from upstream with subtree commands
3. **Better for Zig build** - build.zig can reference vendored paths directly
4. **Self-contained** - cloning the repo gives you everything immediately

## Cross-Platform Support

The build system detects the target architecture and enables appropriate SIMD optimizations:

- **x86_64**: SSE2, AVX2, AVX512BW support
- **aarch64**: NEON support
- **arm**: NEON with `-mfpu=neon`
- **other**: Falls back to portable code

SIMD flags are automatically set in `vendor/build_ugrep.zig` based on the target.

## Build Status

✅ **Currently Working:**
- All compression libraries build successfully (zlib, lz4, zstd, brotli)
- Bundled LZMA SDK builds for 7zip support
- libreflex (RE/flex regex engine) builds with SIMD optimizations
- ugrep executable builds and runs correctly
- Cross-platform SIMD detection (x86_64 AVX2/AVX512BW, ARM NEON)

## Known Issues / TODO

1. **External XZ/liblzma**: The external xz library is vendored but not currently used. The bundled LZMA SDK in ugrep's source provides 7zip support instead. This could be revisited if external liblzma support is desired for additional features.

2. **Disabled Features**:
   - **PCRE2**: Optional PCRE2 support for Perl-compatible regex (ugrep `-P` flag) is not included
   - **bzip2**: bzip2 compression support is not included (can be added if needed)

3. **Testing**: Build verification tests need to be added

4. **Cross-platform Testing**: While the build system supports cross-compilation, it needs testing on:
   - Linux (x86_64, ARM64)
   - Windows (x86_64)
   - macOS (x86_64, ARM64)

## Ugrep Source Structure

- `vendor/ugrep/src/`: Main ugrep executable sources
- `vendor/ugrep/lib/`: RE/flex regex library (libreflex)
- `vendor/ugrep/include/reflex/`: RE/flex headers
- `vendor/ugrep/patterns/`: Predefined regex patterns
- `vendor/ugrep/tests/`: Test suite

## Important Build Details

### Zig 0.15.2 API Changes

This project uses Zig 0.15.2, which introduced significant breaking changes to the build API:

- `addStaticLibrary` → `addLibrary` with `.linkage = .static`
- Executables and libraries now require `.root_module = b.createModule(...)`
- Target/optimize must be set in the root_module, not at the top level

### C/C++ Integration

- All C libraries use `.linkLibC()`
- ugrep uses `.linkLibCpp()` for C++11 support
- Compression libraries are pure C (C99)
- ugrep and libreflex are C++11

### SIMD Compilation

Special SIMD-optimized files are compiled separately with specific flags:
- `matcher_avx2.cpp` and `simd_avx2.cpp`: Compiled with `-mavx2`
- `matcher_avx512bw.cpp` and `simd_avx512bw.cpp`: Compiled with `-mavx512bw`

## Development Workflow

1. Make changes to build files in `vendor/`
2. Test with `zig build --verbose` to see full compiler commands
3. Test cross-compilation: `zig build -Dtarget=aarch64-linux`
4. Commit with descriptive messages following the existing git history

## Architecture Decisions

- **Modular build files**: Each library has its own build file for clarity and maintainability
- **No external package manager**: All dependencies vendored for reproducibility
- **Pure Zig build**: No CMake, Make, or Autotools - everything in Zig's build system
- **Cross-platform first**: SIMD detection and cross-compilation support built-in

## Configuration Details

### Generated config.h

The `vendor/ugrep/config.h` file was generated by running:
```bash
cd vendor/ugrep
CC="zig cc" CXX="zig c++" ./configure
```

Key configuration options:
- `HAVE_LIBZ=1` - zlib compression enabled
- `HAVE_LIBLZ4=1` - lz4 compression enabled
- `HAVE_LIBZSTD=1` - zstd compression enabled
- `HAVE_LIBBROTLI=1` - brotli compression enabled
- `HAVE_PCRE2` - undefined (PCRE2 not included)
- `HAVE_LIBBZ2` - undefined (bzip2 not included)
- `HAVE_LIBLZMA` - undefined (using bundled LZMA SDK instead)

### LZMA SDK Integration

Instead of using external liblzma, we use ugrep's bundled LZMA SDK located in `vendor/ugrep/lzma/C/`. This provides 7zip archive support without requiring complex XZ library configuration. The bundled SDK is simpler to build and sufficient for ugrep's needs.

## Cross-Compilation Status

### ✅ Working Platforms
- **Linux x86_64**: Fully tested, statically linked (1.8MB)
- **FreeBSD x86_64**: Fully tested, dynamically linked (1.7MB)
- **NetBSD x86_64**: Fully tested, dynamically linked (1.7MB)
- **macOS x86_64/ARM64**: Native builds with full SIMD (AVX2/AVX512BW/NEON)

### ⚠️ Windows x86_64
**Status**: Not currently supported
**Issue**: ugrep's Windows code is designed for MSVC and has 42 header conflicts with Zig's mingw/clang toolchain

**To Fix** (following zig-erlang pattern):
1. Create patched versions of problematic files in `vendor/windows_compat/`
2. Guard type/function redefinitions for clang compatibility
3. Update `build_ugrep.zig` to use patched files when `target.result.os.tag == .windows`

See `vendor/windows_compat/README.md` for implementation details.

## Future Enhancements

- [ ] Windows cross-compilation support (via compatibility patches)
- [ ] Add external liblzma support (if needed for additional .xz features)
- [ ] Add PCRE2 support for `-P` flag (Perl regex)
- [ ] Add bzip2 support for .bz2 files
- [ ] Create automated tests
- [ ] Benchmark against official ugrep builds
- [ ] Package for multiple platforms (Linux, macOS, Windows)
- [ ] Add ugrep-indexer support
