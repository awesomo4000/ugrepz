const std = @import("std");

pub fn create(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step.Compile {
    const lib = b.addLibrary(.{
        .name = "lzma",
        .linkage = .static,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
        }),
    });

    lib.linkLibC();

    // Add liblzma source files
    lib.addCSourceFiles(.{
        .root = b.path("vendor/xz/src/liblzma"),
        .files = &.{
            // Common files
            "common/common.c",
            "common/block_util.c",
            "common/easy_preset.c",
            "common/filter_common.c",
            "common/hardware_physmem.c",
            "common/index.c",
            "common/stream_flags_common.c",
            "common/string_conversion.c",
            "common/vli_size.c",
            "common/hardware_cputhreads.c",
            "common/alone_encoder.c",
            "common/block_buffer_encoder.c",
            "common/block_encoder.c",
            "common/block_header_encoder.c",
            "common/easy_buffer_encoder.c",
            "common/easy_encoder.c",
            "common/easy_encoder_memusage.c",
            "common/filter_buffer_encoder.c",
            "common/filter_encoder.c",
            "common/filter_flags_encoder.c",
            "common/index_encoder.c",
            "common/stream_buffer_encoder.c",
            "common/stream_encoder.c",
            "common/stream_flags_encoder.c",
            "common/vli_encoder.c",
            "common/alone_decoder.c",
            "common/auto_decoder.c",
            "common/block_buffer_decoder.c",
            "common/block_decoder.c",
            "common/block_header_decoder.c",
            "common/easy_decoder_memusage.c",
            "common/file_info.c",
            "common/filter_buffer_decoder.c",
            "common/filter_decoder.c",
            "common/filter_flags_decoder.c",
            "common/index_decoder.c",
            "common/index_hash.c",
            "common/stream_buffer_decoder.c",
            "common/stream_decoder.c",
            "common/stream_flags_decoder.c",
            "common/vli_decoder.c",
            // Check files
            "check/check.c",
            "check/crc32_fast.c",
            "check/crc64_fast.c",
            "check/sha256.c",
            // LZ files
            "lz/lz_encoder.c",
            "lz/lz_encoder_mf.c",
            "lz/lz_decoder.c",
            // LZMA files
            "lzma/lzma_encoder.c",
            "lzma/lzma_encoder_presets.c",
            "lzma/lzma_encoder_optimum_fast.c",
            "lzma/lzma_encoder_optimum_normal.c",
            "lzma/fastpos_table.c",
            "lzma/lzma_decoder.c",
            "lzma/lzma2_encoder.c",
            "lzma/lzma2_decoder.c",
            // Range coder
            "rangecoder/price_table.c",
            // Delta
            "delta/delta_common.c",
            "delta/delta_encoder.c",
            "delta/delta_decoder.c",
            // Simple filters
            "simple/simple_coder.c",
            "simple/simple_encoder.c",
            "simple/simple_decoder.c",
            "simple/x86.c",
            "simple/powerpc.c",
            "simple/ia64.c",
            "simple/arm.c",
            "simple/armthumb.c",
            "simple/arm64.c",
            "simple/sparc.c",
            "simple/riscv.c",
        },
        .flags = &.{
            "-std=c99",
            "-DHAVE_CONFIG_H",
        },
    });

    lib.addIncludePath(b.path("vendor/xz")); // For config.h
    lib.addIncludePath(b.path("vendor/xz/src/liblzma/api"));
    lib.addIncludePath(b.path("vendor/xz/src/liblzma/common"));
    lib.addIncludePath(b.path("vendor/xz/src/liblzma/check"));
    lib.addIncludePath(b.path("vendor/xz/src/liblzma/lz"));
    lib.addIncludePath(b.path("vendor/xz/src/liblzma/rangecoder"));
    lib.addIncludePath(b.path("vendor/xz/src/liblzma/lzma"));
    lib.addIncludePath(b.path("vendor/xz/src/liblzma/delta"));
    lib.addIncludePath(b.path("vendor/xz/src/liblzma/simple"));
    lib.addIncludePath(b.path("vendor/xz/src/common"));

    lib.installHeadersDirectory(b.path("vendor/xz/src/liblzma/api"), ".", .{});

    return lib;
}
