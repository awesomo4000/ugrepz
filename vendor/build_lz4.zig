const std = @import("std");

pub fn create(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step.Compile {
    const lib = b.addLibrary(.{
        .name = "lz4",
        .linkage = .static,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
        }),
    });

    lib.linkLibC();

    // Add lz4 library source files
    lib.addCSourceFiles(.{
        .root = b.path("vendor/lz4/lib"),
        .files = &.{
            "lz4.c",
            "lz4hc.c",
            "lz4frame.c",
            "xxhash.c",
        },
        .flags = &.{
            "-std=c99",
            "-O3",
        },
    });

    lib.addIncludePath(b.path("vendor/lz4/lib"));
    lib.installHeadersDirectory(b.path("vendor/lz4/lib"), ".", .{
        .include_extensions = &.{".h"},
    });

    return lib;
}
