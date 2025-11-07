const std = @import("std");

pub fn create(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    zlib: *std.Build.Step.Compile,
    lzma: *std.Build.Step.Compile,
    lz4: *std.Build.Step.Compile,
    zstd: *std.Build.Step.Compile,
    brotli: *std.Build.Step.Compile,
) *std.Build.Step.Compile {
    _ = lzma; // TODO: Use real LZMA library when configured

    // Generate platform-specific binary name
    const target_os = target.result.os.tag;
    const target_arch = target.result.cpu.arch;
    const exe_name = if (target.query.isNative())
        "ugrep"
    else
        b.fmt("ugrep-{s}-{s}", .{
            @tagName(target_arch),
            @tagName(target_os),
        });

    const exe = b.addExecutable(.{
        .name = exe_name,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
        }),
    });

    exe.linkLibC();
    exe.linkLibCpp();

    // Link Windows-specific libraries
    if (target_os == .windows) {
        exe.linkSystemLibrary("ws2_32"); // Winsock functions
        exe.subsystem = .Console; // Console application, not GUI
        // Disable automatic MinGW library linking which causes WinMain entry point issue
        exe.link_function_sections = true;
    }

    // Build libreflex static library first
    const libreflex = buildLibReflex(b, target, optimize);

    // Build LZMA SDK for 7zip support
    const build_lzma_sdk = @import("build_lzma_sdk.zig");
    const lzma_sdk = build_lzma_sdk.create(b, target, optimize);

    // Link compression libraries
    exe.linkLibrary(zlib);
    exe.linkLibrary(lz4);
    exe.linkLibrary(zstd);
    exe.linkLibrary(brotli);
    exe.linkLibrary(lzma_sdk);
    exe.linkLibrary(libreflex);

    // Build platform-specific compiler flags
    const cpp_flags = switch (target_os) {
        .macos => &[_][]const u8{
            "-std=c++11",
            "-Wall",
            "-Wextra",
            "-Wunused",
            "-DHAVE_CONFIG_H",
            "-DWITH_NO_INDENT",
            "-DHAVE_LIBZ",
            "-DHAVE_LIBLZ4",
            "-DHAVE_LIBZSTD",
            "-DHAVE_LIBBROTLI",
            "-DHAVE_F_RDAHEAD",
            "-DHAVE_PTHREAD_SET_QOS_CLASS_SELF_NP",
            "-DHAVE_STRUCT_STAT_ST_ATIMESPEC",
            "-DHAVE_STRUCT_STAT_ST_CTIMESPEC",
            "-DHAVE_STRUCT_STAT_ST_MTIMESPEC",
            "-DHAVE_SYS_STATVFS_H",
        },
        .windows => &[_][]const u8{
            // Windows: Don't use config.h, define only what we need
            "-std=c++11",
            "-Wall",
            "-Wextra",
            "-Wunused",
            "-DWITH_NO_INDENT",
            "-DWITH_NO_7ZIP", // Disable 7zip support on Windows (viizip.c is POSIX-only)
            "-DHAVE_LIBZ",
            "-DHAVE_LIBLZ4",
            "-DHAVE_LIBZSTD",
            "-DHAVE_LIBBROTLI",
            "-DHAVE_CXX11",
            "-DPACKAGE_VERSION=\"7.5.0\"",
            "-DOS_WIN", // Enable Windows-specific code paths
            // Force patched headers to be included FIRST (for MinGW/clang compatibility)
            "-I", "vendor/windows_compat/src",
            "-I", "vendor/windows_compat/lzma/C",
        },
        else => &[_][]const u8{
            // Linux, BSD, etc. use POSIX st_atim
            "-std=c++11",
            "-Wall",
            "-Wextra",
            "-Wunused",
            "-DHAVE_CONFIG_H",
            "-DWITH_NO_INDENT",
            "-DHAVE_LIBZ",
            "-DHAVE_LIBLZ4",
            "-DHAVE_LIBZSTD",
            "-DHAVE_LIBBROTLI",
            "-DHAVE_STRUCT_STAT_ST_ATIM",
            "-DHAVE_STRUCT_STAT_ST_CTIM",
            "-DHAVE_STRUCT_STAT_ST_MTIM",
            "-DHAVE_SYS_STATVFS_H",
        },
    };

    // Add ugrep C++ source files
    // For Windows, we need to use our compatibility-patched directory structure
    const src_root = if (target_os == .windows)
        b.path("vendor/windows_compat/src")
    else
        b.path("vendor/ugrep/src");

    exe.addCSourceFiles(.{
        .root = src_root,
        .files = &.{
            "cnf.cpp",
            "glob.cpp",
            "output.cpp",
            "query.cpp",
            "screen.cpp",
            "stats.cpp",
            "ugrep.cpp",
            "vkey.cpp",
        },
        .flags = cpp_flags,
    });

    // Add ugrep C source files separately
    const c_files: []const []const u8 = if (target_os == .windows)
        &.{ "zopen.c", "winmain_wrapper.c" } // Windows needs WinMain wrapper
    else
        &.{"zopen.c"};

    exe.addCSourceFiles(.{
        .root = src_root, // Use same root as C++ files (patched for Windows)
        .files = c_files,
        .flags = &.{
            "-std=c99",
            "-DHAVE_CONFIG_H",
            "-DHAVE_LIBZ",
            "-DHAVE_LIBLZ4",
            "-DHAVE_LIBZSTD",
            "-DHAVE_LIBBROTLI",
        },
    });

    // For Windows cross-compilation: Add patched headers FIRST to override originals
    // This fixes 42 compilation errors with MinGW/clang by providing guards for
    // type/function redefinitions (ssize_t, strcasecmp, popen, etc.)
    if (target_os == .windows) {
        exe.addIncludePath(b.path("vendor/windows_compat/src"));
        exe.addIncludePath(b.path("vendor/windows_compat/lzma/C"));
    }

    // Add include paths
    exe.addIncludePath(b.path("vendor/ugrep")); // For config.h
    exe.addIncludePath(b.path("vendor/ugrep/include"));
    exe.addIncludePath(b.path("vendor/ugrep/src"));
    exe.addIncludePath(b.path("vendor/ugrep/lzma/C")); // For viizip.h (7zip support)
    exe.addIncludePath(b.path("vendor/zlib"));
    exe.addIncludePath(b.path("vendor/xz/src/liblzma/api"));
    exe.addIncludePath(b.path("vendor/lz4/lib"));
    exe.addIncludePath(b.path("vendor/zstd/lib"));
    exe.addIncludePath(b.path("vendor/brotli/c/include"));

    return exe;
}

fn buildLibReflex(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step.Compile {
    const lib = b.addLibrary(.{
        .name = "reflex",
        .linkage = .static,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
        }),
    });

    lib.linkLibCpp();

    // Detect platform for SIMD support
    const cpu_arch = target.result.cpu.arch;
    const is_native = target.query.isNative();

    // Add reflex library source files with appropriate flags based on architecture
    // Note: We use conservative SIMD settings for cross-compilation (SSE2 only on x86_64)
    // to ensure compatibility. Native builds get full SIMD optimizations.
    const flags: []const []const u8 = switch (cpu_arch) {
        .x86_64 => if (is_native) &.{
            "-std=c++11",
            "-Wall",
            "-Wextra",
            "-Wunused",
            "-DWITH_NO_INDENT",
            "-DWITH_NO_CODEGEN",
            "-msse2",
            "-DHAVE_SSE2",
            "-DHAVE_AVX2",
            "-DHAVE_AVX512BW",
        } else &.{
            // Cross-compiling: use portable SSE2 only for maximum compatibility
            "-std=c++11",
            "-Wall",
            "-Wextra",
            "-Wunused",
            "-DWITH_NO_INDENT",
            "-DWITH_NO_CODEGEN",
            "-msse2",
            "-DHAVE_SSE2",
        },
        .aarch64 => &.{
            "-std=c++11",
            "-Wall",
            "-Wextra",
            "-Wunused",
            "-DWITH_NO_INDENT",
            "-DWITH_NO_CODEGEN",
            "-DHAVE_NEON",
        },
        .arm => &.{
            "-std=c++11",
            "-Wall",
            "-Wextra",
            "-Wunused",
            "-DWITH_NO_INDENT",
            "-DWITH_NO_CODEGEN",
            "-mfpu=neon",
            "-DHAVE_NEON",
        },
        else => &.{
            "-std=c++11",
            "-Wall",
            "-Wextra",
            "-Wunused",
            "-DWITH_NO_INDENT",
            "-DWITH_NO_CODEGEN",
        },
    };

    lib.addCSourceFiles(.{
        .root = b.path("vendor/ugrep/lib"),
        .files = &.{
            "convert.cpp",
            "debug.cpp",
            "error.cpp",
            "input.cpp",
            "matcher.cpp",
            "pattern.cpp",
            "posix.cpp",
            "simd.cpp",
            "unicode.cpp",
            "utf8.cpp",
            "block_scripts.cpp",
            "language_scripts.cpp",
            "letter_scripts.cpp",
            "letter_case.cpp",
            "composer.cpp",
        },
        .flags = flags,
    });

    // Add SIMD-optimized files for x86_64 (only when building natively)
    if (cpu_arch == .x86_64 and is_native) {
        lib.addCSourceFiles(.{
            .root = b.path("vendor/ugrep/lib"),
            .files = &.{
                "matcher_avx2.cpp",
                "simd_avx2.cpp",
            },
            .flags = &.{
                "-std=c++11",
                "-mavx2",
            },
        });

        lib.addCSourceFiles(.{
            .root = b.path("vendor/ugrep/lib"),
            .files = &.{
                "matcher_avx512bw.cpp",
                "simd_avx512bw.cpp",
            },
            .flags = &.{
                "-std=c++11",
                "-mavx512bw",
            },
        });
    }

    lib.addIncludePath(b.path("vendor/ugrep/include"));

    return lib;
}
