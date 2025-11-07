const std = @import("std");

pub fn create(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step.Compile {
    const lib = b.addLibrary(.{
        .name = "zstd",
        .linkage = .static,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
        }),
    });

    lib.linkLibC();

    // Add zstd common files
    lib.addCSourceFiles(.{
        .root = b.path("vendor/zstd/lib/common"),
        .files = &.{
            "debug.c",
            "entropy_common.c",
            "error_private.c",
            "fse_decompress.c",
            "pool.c",
            "threading.c",
            "xxhash.c",
            "zstd_common.c",
        },
        .flags = &.{"-std=c99"},
    });

    // Add zstd compress files
    lib.addCSourceFiles(.{
        .root = b.path("vendor/zstd/lib/compress"),
        .files = &.{
            "fse_compress.c",
            "hist.c",
            "huf_compress.c",
            "zstd_compress.c",
            "zstd_compress_literals.c",
            "zstd_compress_sequences.c",
            "zstd_compress_superblock.c",
            "zstd_double_fast.c",
            "zstd_fast.c",
            "zstd_lazy.c",
            "zstd_ldm.c",
            "zstd_opt.c",
            "zstdmt_compress.c",
        },
        .flags = &.{"-std=c99"},
    });

    // Add zstd decompress files
    lib.addCSourceFiles(.{
        .root = b.path("vendor/zstd/lib/decompress"),
        .files = &.{
            "huf_decompress.c",
            "zstd_ddict.c",
            "zstd_decompress.c",
            "zstd_decompress_block.c",
        },
        .flags = &.{ "-std=c99", "-DZSTD_DISABLE_ASM" }, // Disable assembly for cross-compilation
    });

    lib.addIncludePath(b.path("vendor/zstd/lib"));
    lib.addIncludePath(b.path("vendor/zstd/lib/common"));
    lib.installHeadersDirectory(b.path("vendor/zstd/lib"), ".", .{
        .include_extensions = &.{".h"},
    });

    return lib;
}
