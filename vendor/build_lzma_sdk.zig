const std = @import("std");

pub fn create(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step.Compile {
    const lib = b.addLibrary(.{
        .name = "lzma_sdk",
        .linkage = .static,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
        }),
    });

    lib.linkLibC();

    // Build platform-specific flags
    const target_os = target.result.os.tag;
    const flags = switch (target_os) {
        .windows => &[_][]const u8{
            "-std=c99",
            "-D_7ZIP_ST", // Single-threaded version
            "-D_WIN32",
        },
        .macos => &[_][]const u8{
            "-std=c99",
            "-D_7ZIP_ST", // Single-threaded version
            "-D_DARWIN_C_SOURCE", // For BSD types on macOS
        },
        .linux => &[_][]const u8{
            "-std=c99",
            "-D_7ZIP_ST", // Single-threaded version
            "-D_POSIX_C_SOURCE=200809L", // For ssize_t and fileno on POSIX systems
            // Keep USE_HWCAP enabled for runtime CPU detection on Linux
        },
        else => &[_][]const u8{
            "-std=c99",
            "-D_7ZIP_ST", // Single-threaded version
            "-D_POSIX_C_SOURCE=200809L", // For ssize_t and fileno on POSIX systems
            "-UUSE_HWCAP", // Undefine HWCAP on BSD (asm/hwcap.h is Linux-only, BSD uses elf_aux_info)
        },
    };

    // viizip.c has POSIX-specific code, exclude it on Windows
    const files = if (target_os != .windows) &[_][]const u8{
        "7zAlloc.c",
        "7zArcIn.c",
        "7zBuf.c",
        "7zBuf2.c",
        "7zCrc.c",
        "7zCrcOpt.c",
        "7zDec.c",
        "7zFile.c",
        "7zStream.c",
        "Bcj2.c",
        "Bra.c",
        "Bra86.c",
        "BraIA64.c",
        "CpuArch.c",
        "Delta.c",
        "Lzma2Dec.c",
        "LzmaDec.c",
        "Ppmd7.c",
        "Ppmd7Dec.c",
        "viizip.c",
    } else &[_][]const u8{
        "7zAlloc.c",
        "7zArcIn.c",
        "7zBuf.c",
        "7zBuf2.c",
        "7zCrc.c",
        "7zCrcOpt.c",
        "7zDec.c",
        "7zFile.c",
        "7zStream.c",
        "Bcj2.c",
        "Bra.c",
        "Bra86.c",
        "BraIA64.c",
        "CpuArch.c",
        "Delta.c",
        "Lzma2Dec.c",
        "LzmaDec.c",
        "Ppmd7.c",
        "Ppmd7Dec.c",
    };

    // Use patched CpuArch.c for BSD platforms (fixes asm/hwcap.h Linux dependency)
    const use_bsd_compat = switch (target_os) {
        .freebsd, .netbsd, .openbsd, .dragonfly => true,
        else => false,
    };

    const lzma_root = if (use_bsd_compat)
        b.path("vendor/freebsd_compat/lzma/C")
    else
        b.path("vendor/ugrep/lzma/C");

    lib.addCSourceFiles(.{
        .root = lzma_root,
        .files = files,
        .flags = flags,
    });

    lib.addIncludePath(b.path("vendor/ugrep/lzma/C"));

    return lib;
}
