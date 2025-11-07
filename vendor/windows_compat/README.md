# Windows Compatibility Patches

This directory contains patched versions of ugrep source files to enable Windows cross-compilation with Zig/MinGW/clang.

## Why This Is Needed

ugrep's Windows code is designed for MSVC and has conflicts with MinGW/clang headers:
- Type redefinitions (ssize_t)
- Function redefinitions (strcasecmp, strncasecmp, popen, pclose)
- Entry point conflicts (WinMain vs main)

## Implementation (COMPLETED ✅)

### 1. Source File Copying
Copied all ugrep source files to `vendor/windows_compat/src/`:
- All `.cpp` and `.hpp` files
- All `.c` files
- Added `winmain_wrapper.c` for entry point compatibility

### 2. Header Patches
Modified `ugrep.hpp` with guards for MinGW/clang compatibility:

```c
// Include MinGW in OS_WIN definition
#if (defined(__WIN32__) || defined(_WIN32) || ... || defined(__MINGW32__) || defined(__MINGW64__)) && !defined(__CYGWIN__)
# define OS_WIN
#endif

// Guard type definitions for MinGW
#if !defined(ssize_t) && !defined(_SSIZE_T_DEFINED) && !defined(_SSIZE_T_) && defined(_MSC_VER)
typedef int ssize_t;
#endif

// Guard function definitions for MinGW
#if !defined(strcasecmp) && defined(_MSC_VER)
inline int strcasecmp(const char *s1, const char *s2) { ... }
#endif
// Similar guards for strncasecmp, popen, pclose
```

### 3. Build System Integration
Updated `vendor/build_ugrep.zig` to:
- Use patched source directory for Windows builds
- Add `-DWITH_NO_7ZIP` (viizip.c is POSIX-only)
- Link `ws2_32` library for Winsock functions
- Set console subsystem
- Include WinMain wrapper for entry point compatibility

### 4. Results
Successfully building 1.5MB Windows executable with:
- All compression support (gz, lz4, zstd, brotli)
- SIMD optimizations (SSE2 for cross-compile)
- Console application entry point
- No 7zip support (POSIX-only)

## Files Patched

- `src/ugrep.hpp` - Main header with Windows compatibility guards
- `src/*.cpp` - All source files copied for consistent compilation
- `src/winmain_wrapper.c` - NEW: Entry point wrapper for MinGW compatibility
- `lzma/C/viizip.h` - Patched but not used (7zip disabled on Windows)

## Build Commands

```bash
# Cross-compile for Windows
zig build -Dtarget=x86_64-windows --release=small

# Output: zig-out/bin/ugrep.exe (1.5MB)
```

