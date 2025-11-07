# FreeBSD Compatibility Patches

This directory contains patched versions of LZMA SDK files to enable BSD cross-compilation with Zig.

## Why This Is Needed

The LZMA SDK's ARM CPU feature detection code (`CpuArch.c`) uses Linux-specific headers:
- `<asm/hwcap.h>` - Linux-only header for hardware capabilities
- `getauxval()` - Linux-specific function (BSD uses `elf_aux_info()` instead)

## Implementation (COMPLETED ✅)

### Patched Files

**`lzma/C/CpuArch.c`** - ARM CPU feature detection
- Wrapped HWCAP code in `#ifdef __linux__`
- Added stub implementations for BSD platforms
- Falls back to assuming no ARM features (conservative but safe)

### Changes

```c
// ORIGINAL: Unconditionally used Linux headers on all non-Apple platforms
#include <sys/auxv.h>
#define USE_HWCAP
#include <asm/hwcap.h>  // Linux-only!

// PATCHED: Only use HWCAP on Linux
#ifdef __linux__
#include <sys/auxv.h>
#define USE_HWCAP
#include <asm/hwcap.h>
// ... Linux HWCAP detection ...
#else // BSD platforms
// Stub implementations (could use elf_aux_info() for runtime detection)
BoolInt CPU_IsSupported_CRC32(void) { return 0; }
BoolInt CPU_IsSupported_NEON(void) { return 0; }
// ... etc ...
#endif // __linux__
```

### Build Integration

Updated `vendor/build_lzma_sdk.zig` to:
- Detect BSD targets (FreeBSD, NetBSD, OpenBSD, DragonFlyBSD)
- Use patched LZMA SDK files from `vendor/freebsd_compat/lzma/C/` for BSD
- Use original files from `vendor/ugrep/lzma/C/` for Linux/macOS/Windows

### Results

Successfully building for BSD ARM64:
- FreeBSD ARM64: 1.6MB
- NetBSD ARM64: 1.6MB
- Linux still gets full HWCAP runtime detection
- Conservative fallback (no features) for BSD

## Future Improvements

Could implement proper BSD runtime CPU detection using:
- `elf_aux_info(AT_HWCAP, ...)` on FreeBSD 12+
- `sysctlbyname("hw.optional.neon", ...)` on older BSD versions

For now, the conservative approach (assume no features) works correctly.

## Build Commands

```bash
# Cross-compile for BSD ARM64
zig build -Dtarget=aarch64-freebsd --release=small
zig build -Dtarget=aarch64-netbsd --release=small

# Compile all platforms
./scripts/compile-all-platforms.sh
```
