const std = @import("std");
const vendor = @import("vendor/build.zig");

/// Build ugrep and related binaries from source
///
/// Usage: zig build --build-file build_ugrep.zig [options]
///
/// Or use the convenience script: ./build_ugrep.sh
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

    // Build demo executable that uses the wrapper API
    const demo_exe = b.addExecutable(.{
        .name = "ugrepz-demo",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    b.installArtifact(demo_exe);

    // Create run step for demo
    const run_demo_step = b.step("run-demo", "Run the ugrepz API demo");
    const run_demo_cmd = b.addRunArtifact(demo_exe);
    run_demo_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_demo_cmd.addArgs(args);
    }
    run_demo_step.dependOn(&run_demo_cmd.step);

    // Integration tests (requires built binary)
    const integration_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/test_ugrep.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    const run_integration_tests = b.addRunArtifact(integration_tests);
    run_integration_tests.step.dependOn(b.getInstallStep());

    const test_api_step = b.step("test-api", "Run API integration tests");
    test_api_step.dependOn(&run_integration_tests.step);
}
