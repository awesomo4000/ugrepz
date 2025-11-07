const std = @import("std");

pub fn create(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step.Compile {
    const lib = b.addLibrary(.{
        .name = "z",
        .linkage = .static,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
        }),
    });

    lib.linkLibC();

    // Add zlib source files
    lib.addCSourceFiles(.{
        .root = b.path("vendor/zlib"),
        .files = &.{
            "adler32.c",
            "compress.c",
            "crc32.c",
            "deflate.c",
            "gzclose.c",
            "gzlib.c",
            "gzread.c",
            "gzwrite.c",
            "infback.c",
            "inffast.c",
            "inflate.c",
            "inftrees.c",
            "trees.c",
            "uncompr.c",
            "zutil.c",
        },
        .flags = &.{
            "-DHAVE_UNISTD_H",
            "-D_LARGEFILE64_SOURCE=1",
        },
    });

    lib.addIncludePath(b.path("vendor/zlib"));
    lib.installHeadersDirectory(b.path("vendor/zlib"), ".", .{
        .include_extensions = &.{".h"},
    });

    return lib;
}
