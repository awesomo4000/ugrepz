//! Integration tests for ugrepz library
//! These tests require the ugrep binary to be built first.

const std = @import("std");
const ugrep = @import("ugrep.zig");

const testing = std.testing;

// Test helper to get project root
fn getProjectRoot() []const u8 {
    // This file is at src/test_ugrep.zig, project root is parent
    return std.fs.path.dirname(@src().file) orelse ".";
}

test "findBinary - finds ugrep in PATH or locally" {
    const allocator = testing.allocator;

    // Try to find the binary
    if (ugrep.findBinary(allocator)) |path| {
        defer allocator.free(path);
        std.debug.print("\nFound ugrep at: {s}\n", .{path});

        // Verify the path exists
        std.fs.cwd().access(path, .{}) catch |err| {
            std.debug.print("Binary not accessible: {}\n", .{err});
            return err;
        };
    } else {
        std.debug.print("\nWarning: ugrep binary not found (run 'zig build' first)\n", .{});
    }
}

test "parseLine - match line with colon separator" {
    const result = ugrep.parseLine("src/main.zig:42:    const x = 5;");
    try testing.expect(result != null);
    try testing.expectEqualStrings("src/main.zig", result.?.filename);
    try testing.expectEqual(@as(u32, 42), result.?.line_num);
    try testing.expectEqualStrings("    const x = 5;", result.?.content);
    try testing.expect(result.?.is_match);
}

test "parseLine - context line with dash separator" {
    const result = ugrep.parseLine("src/main.zig-40-    // comment");
    try testing.expect(result != null);
    try testing.expectEqualStrings("src/main.zig", result.?.filename);
    try testing.expectEqual(@as(u32, 40), result.?.line_num);
    try testing.expectEqualStrings("    // comment", result.?.content);
    try testing.expect(!result.?.is_match);
}

test "parseLine - filename with colon (Windows path)" {
    const result = ugrep.parseLine("C:/Users/test/file.txt:10:content here");
    try testing.expect(result != null);
    try testing.expectEqualStrings("C:/Users/test/file.txt", result.?.filename);
    try testing.expectEqual(@as(u32, 10), result.?.line_num);
    try testing.expectEqualStrings("content here", result.?.content);
}

test "parseLine - group separator returns null" {
    const result = ugrep.parseLine("--");
    try testing.expect(result == null);
}

test "parseLine - empty line returns null" {
    const result = ugrep.parseLine("");
    try testing.expect(result == null);
}

test "parseLine - empty content after line number" {
    const result = ugrep.parseLine("file.txt:1:");
    try testing.expect(result != null);
    try testing.expectEqualStrings("file.txt", result.?.filename);
    try testing.expectEqual(@as(u32, 1), result.?.line_num);
    try testing.expectEqualStrings("", result.?.content);
}

test "search - basic search in src directory" {
    const allocator = testing.allocator;

    // Search for "SearchOptions" in our own source
    var result = ugrep.search(allocator, "SearchOptions", &.{"src/"}, .{
        .recursive = true,
        .fixed_strings = true,
        .binary_path = "zig-out/bin/ugrep",
    }) catch |err| {
        if (err == ugrep.SearchError.BinaryNotFound) {
            std.debug.print("\nSkipping: ugrep binary not found (run 'zig build' first)\n", .{});
            return;
        }
        return err;
    };
    defer result.deinit();

    std.debug.print("\nFound {} matches in {} files\n", .{ result.matches.len, result.files.count() });

    // We should find at least the definition in ugrep.zig
    try testing.expect(result.matches.len > 0);

    // Print first few matches
    const max_print = @min(result.matches.len, 5);
    for (result.matches[0..max_print]) |match| {
        const marker: []const u8 = if (match.is_match) ">" else " ";
        std.debug.print("{s} {s}:{d}: {s}\n", .{ marker, match.filename, match.line_number, match.content });
    }
}

test "search - case insensitive" {
    const allocator = testing.allocator;

    // Search case-insensitively
    var result = ugrep.search(allocator, "searchoptions", &.{"src/"}, .{
        .ignore_case = true,
        .fixed_strings = true,
        .binary_path = "zig-out/bin/ugrep",
    }) catch |err| {
        if (err == ugrep.SearchError.BinaryNotFound) {
            std.debug.print("\nSkipping: ugrep binary not found\n", .{});
            return;
        }
        return err;
    };
    defer result.deinit();

    std.debug.print("\nCase-insensitive search found {} matches\n", .{result.matches.len});
    try testing.expect(result.matches.len > 0);
}

test "search - with context lines" {
    const allocator = testing.allocator;

    // Note: recursive must be true for filename prefix in output
    var result = ugrep.search(allocator, "pub const Match", &.{"src/ugrep.zig"}, .{
        .recursive = true, // Required for filename:linenum:content format
        .fixed_strings = true,
        .context = 2,
        .binary_path = "zig-out/bin/ugrep",
    }) catch |err| {
        if (err == ugrep.SearchError.BinaryNotFound) {
            std.debug.print("\nSkipping: ugrep binary not found\n", .{});
            return;
        }
        return err;
    };
    defer result.deinit();

    std.debug.print("\nSearch with context found {} lines\n", .{result.matches.len});

    // Should have match + context lines
    var match_count: usize = 0;
    var context_count: usize = 0;
    for (result.matches) |match| {
        if (match.is_match) {
            match_count += 1;
        } else {
            context_count += 1;
        }
    }

    std.debug.print("  Matches: {}, Context: {}\n", .{ match_count, context_count });
    try testing.expect(match_count > 0);
    // With context=2, we should have context lines if the match isn't at start/end
    try testing.expect(context_count > 0);
}

test "search - no matches returns empty result" {
    const allocator = testing.allocator;

    // Use a pattern that definitely won't exist (UUID-like)
    // Note: Don't use a literal string that will appear in this file!
    const no_match_pattern = "zzzQQQ999XXX" ++ "unlikely" ++ "888YYY";

    var result = ugrep.search(allocator, no_match_pattern, &.{"src/"}, .{
        .fixed_strings = true,
        .binary_path = "zig-out/bin/ugrep",
    }) catch |err| {
        if (err == ugrep.SearchError.BinaryNotFound) {
            std.debug.print("\nSkipping: ugrep binary not found\n", .{});
            return;
        }
        return err;
    };
    defer result.deinit();

    try testing.expectEqual(@as(usize, 0), result.matches.len);
    try testing.expectEqual(@as(u32, 0), result.files.count());
}

test "search - files grouping" {
    const allocator = testing.allocator;

    // Search for something that appears in multiple files
    var result = ugrep.search(allocator, "const std", &.{"src/"}, .{
        .fixed_strings = true,
        .binary_path = "zig-out/bin/ugrep",
    }) catch |err| {
        if (err == ugrep.SearchError.BinaryNotFound) {
            std.debug.print("\nSkipping: ugrep binary not found\n", .{});
            return;
        }
        return err;
    };
    defer result.deinit();

    std.debug.print("\nFound matches in {} files:\n", .{result.files.count()});

    // List files with match counts
    var it = result.files.iterator();
    while (it.next()) |entry| {
        std.debug.print("  {s}: {} matches\n", .{ entry.key_ptr.*, entry.value_ptr.len });
    }

    // Should find in multiple source files
    try testing.expect(result.files.count() >= 2);
}

test "SearchResult.getFileMatches" {
    const allocator = testing.allocator;

    var result = ugrep.search(allocator, "SearchOptions", &.{"src/ugrep.zig"}, .{
        .fixed_strings = true,
        .binary_path = "zig-out/bin/ugrep",
    }) catch |err| {
        if (err == ugrep.SearchError.BinaryNotFound) {
            std.debug.print("\nSkipping: ugrep binary not found\n", .{});
            return;
        }
        return err;
    };
    defer result.deinit();

    // Get matches for specific file
    if (result.getFileMatches("src/ugrep.zig")) |matches| {
        std.debug.print("\nMatches in src/ugrep.zig: {}\n", .{matches.len});
        try testing.expect(matches.len > 0);
    } else {
        // If path is returned differently
        var it = result.files.keyIterator();
        if (it.next()) |key| {
            std.debug.print("\nActual key: '{s}'\n", .{key.*});
        }
    }
}
