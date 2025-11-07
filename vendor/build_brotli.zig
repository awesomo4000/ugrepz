const std = @import("std");

pub fn create(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step.Compile {
    const lib = b.addLibrary(.{
        .name = "brotli",
        .linkage = .static,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
        }),
    });

    lib.linkLibC();

    // Add brotli common files
    lib.addCSourceFiles(.{
        .root = b.path("vendor/brotli/c/common"),
        .files = &.{
            "constants.c",
            "context.c",
            "dictionary.c",
            "platform.c",
            "shared_dictionary.c",
            "transform.c",
        },
        .flags = &.{"-std=c99"},
    });

    // Add brotli decoder files
    lib.addCSourceFiles(.{
        .root = b.path("vendor/brotli/c/dec"),
        .files = &.{
            "bit_reader.c",
            "decode.c",
            "huffman.c",
            "state.c",
            "prefix.c",
            "static_init.c",
        },
        .flags = &.{"-std=c99"},
    });

    // Add brotli encoder files
    lib.addCSourceFiles(.{
        .root = b.path("vendor/brotli/c/enc"),
        .files = &.{
            "backward_references.c",
            "backward_references_hq.c",
            "bit_cost.c",
            "block_splitter.c",
            "brotli_bit_stream.c",
            "cluster.c",
            "command.c",
            "compound_dictionary.c",
            "compress_fragment.c",
            "compress_fragment_two_pass.c",
            "dictionary_hash.c",
            "encode.c",
            "encoder_dict.c",
            "entropy_encode.c",
            "fast_log.c",
            "histogram.c",
            "literal_cost.c",
            "memory.c",
            "metablock.c",
            "static_dict.c",
            "utf8_util.c",
        },
        .flags = &.{"-std=c99"},
    });

    lib.addIncludePath(b.path("vendor/brotli/c/include"));
    lib.installHeadersDirectory(b.path("vendor/brotli/c/include"), ".", .{});

    return lib;
}
