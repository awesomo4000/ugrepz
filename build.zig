const std = @import("std");

/// ugrepz build - exports the Zig wrapper module for ugrep
///
/// For building the ugrep binary from source, run: ./build_ugrep.sh
/// or: zig build -f build_ugrep.zig
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Export library module for dependent projects
    // Usage: const ugrepz = b.dependency("ugrepz", .{}).module("ugrepz");
    _ = b.addModule("ugrepz", .{
        .root_source_file = b.path("src/root.zig"),
    });

    // Unit tests for the library
    const lib_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/root.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    const run_lib_tests = b.addRunArtifact(lib_tests);
    const test_step = b.step("test", "Run library unit tests");
    test_step.dependOn(&run_lib_tests.step);
}
