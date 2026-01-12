//! ugrepz CLI demo - demonstrates the Zig wrapper API
//!
//! Usage: zig build run-demo -- <pattern> [paths...]
//!
//! Example: zig build run-demo -- "TODO" src/

const std = @import("std");
const ugrep = @import("ugrep.zig");
const print = @import("print.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        print.eprintln(
            \\ugrepz - Zig wrapper for ugrep
            \\
            \\Usage: {s} <pattern> [paths...]
            \\
            \\Options are hardcoded for demo purposes:
            \\  - Recursive search
            \\  - Fixed strings (literal match)
            \\  - Case insensitive
            \\  - 2 lines of context
            \\
            \\Example:
            \\  {s} "TODO" src/
            \\  {s} "error" .
        , .{ args[0], args[0], args[0] });
        return;
    }

    const pattern = args[1];
    const paths: []const []const u8 = if (args.len > 2) args[2..] else &.{"."};

    // Find binary
    print.println("Looking for ugrep binary...", .{});
    const binary_path = ugrep.findBinary(allocator);
    defer if (binary_path) |path| allocator.free(path);

    if (binary_path) |path| {
        print.println("Found: {s}\n", .{path});
    } else {
        print.println("Not found in PATH, will try zig-out/bin/ugrep\n", .{});
    }

    // Perform search
    print.println("Searching for \"{s}\" in {d} path(s)...\n", .{ pattern, paths.len });

    var result = ugrep.search(allocator, pattern, paths, .{
        .recursive = true,
        .fixed_strings = true,
        .ignore_case = true,
        .context = 2,
        .binary_path = binary_path orelse "zig-out/bin/ugrep",
    }) catch |err| {
        switch (err) {
            ugrep.SearchError.BinaryNotFound => {
                print.eprintln("Error: ugrep binary not found. Run 'zig build' first.", .{});
            },
            ugrep.SearchError.SpawnFailed => {
                print.eprintln("Error: Failed to spawn ugrep process.", .{});
            },
            else => {
                print.eprintln("Error: {}", .{err});
            },
        }
        return;
    };
    defer result.deinit();

    // Print summary
    print.println("Found {d} matches in {d} file(s)", .{ result.matches.len, result.files.count() });
    print.println("{s}", .{"=" ** 60});

    // Print results grouped by file
    var file_it = result.files.iterator();
    while (file_it.next()) |entry| {
        const filename = entry.key_ptr.*;
        const matches = entry.value_ptr.*;

        print.println("\n{s}:", .{filename});

        for (matches) |match| {
            const prefix: []const u8 = if (match.is_match) ">" else " ";
            print.println("{s} {d:>5}: {s}", .{ prefix, match.line_number, match.content });
        }
    }

    print.println("\n{s}", .{"=" ** 60});
    print.println("Total: {d} matches", .{result.matches.len});
}
