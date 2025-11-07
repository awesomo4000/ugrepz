const std = @import("std");
const vendor = @import("vendor/build.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Build all vendor libraries (zlib, lzma, lz4, zstd, brotli)
    const libs = vendor.buildLibraries(b, target, optimize);

    // Build ugrep executable with all compression libraries
    const ugrep_exe = vendor.buildUgrep(b, target, optimize, libs);
    b.installArtifact(ugrep_exe);

    // Build ugrep-indexer executable with compression libraries
    const ugrep_indexer_exe = vendor.buildUgrepIndexer(b, target, optimize, libs);
    b.installArtifact(ugrep_indexer_exe);

    // Create run step for ugrep
    const run_step = b.step("run", "Run ugrep");
    const run_cmd = b.addRunArtifact(ugrep_exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    run_step.dependOn(&run_cmd.step);

    // Create run step for ugrep-indexer
    const run_indexer_step = b.step("run-indexer", "Run ugrep-indexer");
    const run_indexer_cmd = b.addRunArtifact(ugrep_indexer_exe);
    run_indexer_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_indexer_cmd.addArgs(args);
    }

    run_indexer_step.dependOn(&run_indexer_cmd.step);

    // Create a step to just build the libraries
    const libs_step = b.step("libs", "Build only the compression libraries");
    libs_step.dependOn(&libs.zlib.step);
    libs_step.dependOn(&libs.lzma.step);
    libs_step.dependOn(&libs.lz4.step);
    libs_step.dependOn(&libs.zstd.step);
    libs_step.dependOn(&libs.brotli.step);
}
