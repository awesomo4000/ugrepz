#!/usr/bin/env bash
# Remove unnecessary files from vendored dependencies to reduce repository size
# Keeps: source code, man pages, shell completions, patterns, ugrep tests

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

echo "==================================="
echo "Cleaning up vendor directories"
echo "==================================="
echo ""

# Function to show size before/after
show_size() {
    local dir=$1
    du -sh "$dir" 2>/dev/null || echo "0B"
}

# ugrep: Remove pre-built binaries, .github, autotools artifacts, test reference outputs, Visual Studio files, m4 macros
# KEEP: test scripts (not reference outputs), man pages, completions, patterns, source code
echo "Cleaning vendor/ugrep..."
BEFORE=$(show_size vendor/ugrep)
rm -rf vendor/ugrep/bin                  # Pre-built binaries (8.5MB)
rm -rf vendor/ugrep/.github              # GitHub workflows (24KB)
rm -rf vendor/ugrep/tests/out            # Test reference outputs (16MB) - can restore with scripts/restore-test-data.sh
rm -rf vendor/ugrep/vs                   # Visual Studio projects (92KB)
rm -rf vendor/ugrep/msvc                 # MSVC projects (348KB)
rm -rf vendor/ugrep/m4                   # Autotools m4 macros (176KB)
# Keep: tests/ (scripts only), man/, completions/, patterns/, src/, lib/, include/, lzma/
# Remove autotools artifacts
rm -f vendor/ugrep/Makefile vendor/ugrep/Makefile.in
rm -f vendor/ugrep/configure vendor/ugrep/config.{log,status}
rm -f vendor/ugrep/aclocal.m4 vendor/ugrep/ar-lib vendor/ugrep/compile
rm -f vendor/ugrep/config.{guess,sub} vendor/ugrep/depcomp
rm -f vendor/ugrep/install-sh vendor/ugrep/missing vendor/ugrep/build.sh
AFTER=$(show_size vendor/ugrep)
echo "  Before: $BEFORE -> After: $AFTER"
echo "  Kept: tests/ (scripts only), man/, completions/, patterns/, src/, lib/, include/, lzma/"

# brotli: Remove language bindings (Go, Java, JS, Python, C#), tests, docs, research, tools, fuzz
# KEEP: C library (common, enc, dec, include only - no tools/fuzz)
echo "Cleaning vendor/brotli..."
BEFORE=$(show_size vendor/brotli)
rm -rf vendor/brotli/csharp              # C# bindings (800KB)
rm -rf vendor/brotli/go                  # Go bindings (508KB)
rm -rf vendor/brotli/java                # Java bindings (7.2MB!)
rm -rf vendor/brotli/js                  # JavaScript bindings (28MB!)
rm -rf vendor/brotli/python              # Python bindings (88KB)
rm -rf vendor/brotli/research            # Research code (8.9MB)
rm -rf vendor/brotli/docs                # Documentation (276KB)
rm -rf vendor/brotli/tests               # Tests
rm -rf vendor/brotli/.github
rm -rf vendor/brotli/c/tools             # Command-line tools (56KB)
rm -rf vendor/brotli/c/fuzz              # Fuzzing harnesses (52KB)
rm -rf vendor/brotli/scripts             # Build scripts (44KB)
rm -f vendor/brotli/BUILD.bazel vendor/brotli/MODULE.bazel
rm -f vendor/brotli/CMakeLists.txt vendor/brotli/Makefile.in
rm -f vendor/brotli/MANIFEST.in vendor/brotli/pyproject.toml
rm -f vendor/brotli/sbom.cdx.json
rm -rf vendor/brotli/fetch-spec
AFTER=$(show_size vendor/brotli)
echo "  Before: $BEFORE -> After: $AFTER"
echo "  Kept: c/ (common, enc, dec, include only)"

# zstd: Remove tests, programs, docs, contrib, examples
# KEEP: lib/ only
echo "Cleaning vendor/zstd..."
BEFORE=$(show_size vendor/zstd)
rm -rf vendor/zstd/tests
rm -rf vendor/zstd/programs              # Command-line tool
rm -rf vendor/zstd/doc
rm -rf vendor/zstd/contrib
rm -rf vendor/zstd/examples
rm -rf vendor/zstd/zlibWrapper
rm -rf vendor/zstd/.github
rm -rf vendor/zstd/build
rm -f vendor/zstd/Makefile
AFTER=$(show_size vendor/zstd)
echo "  Before: $BEFORE -> After: $AFTER"
echo "  Kept: lib/"

# lz4: Remove tests, programs, docs, examples
# KEEP: lib/ only
echo "Cleaning vendor/lz4..."
BEFORE=$(show_size vendor/lz4)
rm -rf vendor/lz4/tests
rm -rf vendor/lz4/programs               # Command-line tool
rm -rf vendor/lz4/doc
rm -rf vendor/lz4/examples
rm -rf vendor/lz4/.github
rm -rf vendor/lz4/build
rm -f vendor/lz4/Makefile
AFTER=$(show_size vendor/lz4)
echo "  Before: $BEFORE -> After: $AFTER"
echo "  Kept: lib/"

# zlib: Remove tests, examples, docs, contrib, platform-specific directories
# KEEP: Core library only
echo "Cleaning vendor/zlib..."
BEFORE=$(show_size vendor/zlib)
rm -rf vendor/zlib/test
rm -rf vendor/zlib/examples
rm -rf vendor/zlib/doc
rm -rf vendor/zlib/.github
rm -rf vendor/zlib/contrib              # Various contributed code (2MB) - minizip, vstudio, language bindings
rm -rf vendor/zlib/amiga                # Amiga-specific files (8KB)
rm -rf vendor/zlib/qnx                  # QNX-specific files (8KB)
rm -rf vendor/zlib/watcom               # Watcom compiler files (8KB)
rm -rf vendor/zlib/nintendods           # Nintendo DS files (12KB)
rm -rf vendor/zlib/msdos                # MS-DOS files (20KB)
rm -rf vendor/zlib/old                  # Old versions (36KB)
rm -rf vendor/zlib/os400                # OS/400 files (60KB)
rm -rf vendor/zlib/win32                # Win32 makefiles (60KB) - we use Zig
rm -f vendor/zlib/Makefile vendor/zlib/Makefile.in vendor/zlib/configure
AFTER=$(show_size vendor/zlib)
echo "  Before: $BEFORE -> After: $AFTER"
echo "  Kept: Core source files only"

# xz: Remove tests, docs, extra tools, translations, programs
# NOTE: We use ugrep's bundled LZMA SDK (vendor/ugrep/lzma/) for 7zip support
# KEEP: Minimal - only liblzma source in case it's needed
echo "Cleaning vendor/xz..."
BEFORE=$(show_size vendor/xz)
rm -rf vendor/xz/tests
rm -rf vendor/xz/doc
rm -rf vendor/xz/po                      # Translations
rm -rf vendor/xz/po4a                    # Translation documentation (1.9MB!)
rm -rf vendor/xz/.github
rm -rf vendor/xz/windows
rm -rf vendor/xz/dos
rm -rf vendor/xz/extra
rm -rf vendor/xz/doxygen
rm -rf vendor/xz/build                   # Build artifacts (252KB)
rm -rf vendor/xz/m4                      # Autotools m4 macros (92KB)
rm -rf vendor/xz/build-aux               # Autotools build-aux (24KB)
rm -rf vendor/xz/cmake                   # CMake files (44KB)
rm -rf vendor/xz/debug                   # Debug helpers (60KB)
rm -rf vendor/xz/lib                     # getopt_long implementation (64KB)
rm -rf vendor/xz/src/xz                  # xz command-line tool (620KB)
rm -rf vendor/xz/src/xzdec               # xzdec tool (44KB)
rm -rf vendor/xz/src/lzmainfo            # lzmainfo tool (32KB)
rm -rf vendor/xz/src/scripts             # Shell scripts (80KB)
rm -rf vendor/xz/src/common              # Common code for tools (248KB)
AFTER=$(show_size vendor/xz)
echo "  Before: $BEFORE -> After: $AFTER"
echo "  Kept: src/liblzma/ only (we use ugrep's bundled LZMA SDK instead)"

echo ""
echo "==================================="
echo "Cleanup complete!"
echo "==================================="
echo ""
echo "Total vendor size:"
du -sh vendor/
echo ""
echo "Breakdown by directory:"
du -sh vendor/*/ 2>/dev/null | sort -h
echo ""
echo "What was kept:"
echo "  ✅ All source code (.c, .cpp, .h, .hpp)"
echo "  ✅ vendor/ugrep/tests/ (scripts only, not reference outputs)"
echo "  ✅ vendor/ugrep/man/ (man pages)"
echo "  ✅ vendor/ugrep/completions/ (shell completions)"
echo "  ✅ vendor/ugrep/patterns/ (predefined regex patterns)"
echo "  ✅ Essential build files (config.h, etc.)"
echo ""
echo "What was removed:"
echo "  ❌ Pre-built binaries (~8.5MB)"
echo "  ❌ Test reference outputs (~16MB) - restore with scripts/restore-test-data.sh"
echo "  ❌ Language bindings: Go, Java (7MB), JS (28MB!), Python, C#, Pascal, Delphi, Ada"
echo "  ❌ Tests for compression libraries"
echo "  ❌ Documentation (except ugrep man pages)"
echo "  ❌ Examples, research code, and contributed code (~12MB)"
echo "  ❌ Visual Studio and MSVC project files (440KB)"
echo "  ❌ Autotools artifacts (configure, m4 macros, build-aux)"
echo "  ❌ Platform-specific files (Amiga, QNX, DOS, OS/400, etc.)"
echo "  ❌ Command-line tools for compression libraries (xz, brotli tools)"
echo "  ❌ Translation files (po, po4a - 1.9MB)"
echo "  ❌ Fuzz testing harnesses"
echo "  ❌ GitHub workflows"
echo ""
echo "Estimated space saved: ~85-95MB"
echo ""
echo "Note: You can restore test data with: ./scripts/restore-test-data.sh"
