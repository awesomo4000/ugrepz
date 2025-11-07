const std = @import("std");
const build_zlib = @import("build_zlib.zig");
const build_lz4 = @import("build_lz4.zig");
const build_zstd = @import("build_zstd.zig");
const build_brotli = @import("build_brotli.zig");
const build_xz = @import("build_xz.zig");
const build_lzma_sdk = @import("build_lzma_sdk.zig");
const build_ugrep = @import("build_ugrep.zig");
const build_ugrep_indexer = @import("build_ugrep_indexer.zig");

pub const VendorLibs = struct {
    zlib: *std.Build.Step.Compile,
    lzma: *std.Build.Step.Compile,
    lz4: *std.Build.Step.Compile,
    zstd: *std.Build.Step.Compile,
    brotli: *std.Build.Step.Compile,
};

/// Build all vendor libraries
pub fn buildLibraries(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) VendorLibs {
    const zlib = build_zlib.create(b, target, optimize);
    // TODO: XZ config.h needs to be generated separately
    const lzma = createStubLibrary(b, target, optimize, "lzma");
    const lz4 = build_lz4.create(b, target, optimize);
    const zstd = build_zstd.create(b, target, optimize);
    const brotli = build_brotli.create(b, target, optimize);

    // Install libraries
    b.installArtifact(zlib);
    b.installArtifact(lzma);
    b.installArtifact(lz4);
    b.installArtifact(zstd);
    b.installArtifact(brotli);

    return .{
        .zlib = zlib,
        .lzma = lzma,
        .lz4 = lz4,
        .zstd = zstd,
        .brotli = brotli,
    };
}

/// Create a stub library for libraries that aren't ready yet
fn createStubLibrary(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, name: []const u8) *std.Build.Step.Compile {
    const lib = b.addLibrary(.{
        .name = name,
        .linkage = .static,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
        }),
    });
    lib.linkLibC();
    lib.addCSourceFile(.{
        .file = b.path("vendor/stub.c"),
        .flags = &.{"-std=c99"},
    });
    return lib;
}

/// Build ugrep executable with all compression libraries
pub fn buildUgrep(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    libs: VendorLibs,
) *std.Build.Step.Compile {
    return build_ugrep.create(
        b,
        target,
        optimize,
        libs.zlib,
        libs.lzma,
        libs.lz4,
        libs.zstd,
        libs.brotli,
    );
}

/// Build ugrep-indexer executable with compression libraries
pub fn buildUgrepIndexer(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    libs: VendorLibs,
) *std.Build.Step.Compile {
    return build_ugrep_indexer.create(
        b,
        target,
        optimize,
        libs.zlib,
        libs.lzma,
        libs.lz4,
        libs.zstd,
        libs.brotli,
    );
}
