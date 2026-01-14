//! Zig wrapper for ugrep binary
//! Provides a clean API for searching files using ugrep subprocess

const std = @import("std");
const fs = std.fs;
const mem = std.mem;
const process = std.process;
const Allocator = mem.Allocator;

/// Search configuration options
pub const SearchOptions = struct {
    /// Recursive directory search (-r)
    recursive: bool = true,
    /// Fixed string search, not regex (-F)
    fixed_strings: bool = true,
    /// Case-insensitive search (-i)
    ignore_case: bool = false,
    /// Lines of context before match (-B)
    context_before: u32 = 0,
    /// Lines of context after match (-A)
    context_after: u32 = 0,
    /// Lines of context before and after (-C), overrides context_before/after
    context: u32 = 0,
    /// Include line numbers in output (-n)
    line_numbers: bool = true,
    /// Maximum matches per file (-m)
    max_count: ?u32 = null,
    /// Maximum directory depth (--depth)
    max_depth: ?u32 = null,
    /// Include glob patterns (--include)
    include_globs: []const []const u8 = &.{},
    /// Exclude glob patterns (--exclude)
    exclude_globs: []const []const u8 = &.{},
    /// Custom ugrep binary path (null = auto-detect)
    binary_path: ?[]const u8 = null,
    /// Maximum output size in bytes (default 50MB)
    max_output_bytes: usize = 50 * 1024 * 1024,
};

/// A single match or context line from search results
pub const Match = struct {
    /// Path to the file containing this match
    filename: []const u8,
    /// 1-indexed line number
    line_number: u32,
    /// Content of the line
    content: []const u8,
    /// true if this is an actual match, false if context line
    is_match: bool,
};

/// Search results with matches grouped by file
pub const SearchResult = struct {
    /// All matches in order returned by ugrep
    matches: []Match,
    /// Matches grouped by filename
    files: std.StringHashMapUnmanaged([]Match),
    /// Arena allocator that owns all memory
    arena: std.heap.ArenaAllocator,

    /// Free all memory associated with this result
    pub fn deinit(self: *SearchResult) void {
        self.arena.deinit();
    }

    /// Get matches for a specific file
    pub fn getFileMatches(self: *const SearchResult, filename: []const u8) ?[]Match {
        return self.files.get(filename);
    }

    /// Get list of all files that had matches
    pub fn getFilenames(self: *const SearchResult, alloc: Allocator) ![][]const u8 {
        var list: std.ArrayList([]const u8) = .empty;
        var it = self.files.keyIterator();
        while (it.next()) |key| {
            try list.append(alloc, key.*);
        }
        return list.toOwnedSlice(alloc);
    }
};

/// Errors that can occur during search
pub const SearchError = error{
    BinaryNotFound,
    SpawnFailed,
    OutputTooLarge,
    OutOfMemory,
};

/// Parsed line result (internal)
const ParsedLine = struct {
    filename: []const u8,
    line_num: u32,
    content: []const u8,
    is_match: bool,
};

/// Parse a single line of ugrep output
/// Format: filename:linenum:content (match) or filename-linenum-content (context)
/// Returns null if line cannot be parsed
pub fn parseLine(line: []const u8) ?ParsedLine {
    if (line.len == 0) return null;
    if (mem.eql(u8, line, "--")) return null;

    // Find the separator between filename and line number
    // We need to handle filenames that may contain colons, dashes, and digit sequences
    // Scan from the END backwards to find the LAST <sep><digits><sep> pattern
    // This correctly handles filenames like: file-123-abc-456-def.txt:789:content
    // where -456- could be mistaken for a line number if scanning from start
    var sep_pos: ?usize = null;

    // Start from end, look for content separator then digits then filename separator
    // The pattern we're looking for (from right to left) is: <content>:<linenum>:<filename>
    // or <content>-<linenum>-<filename> for context lines
    if (line.len < 3) return null; // Minimum: "f:1:" or "f-1-"

    // Strategy: First look for :digits: (match pattern), then -digits- (context pattern)
    // This prevents content like "-100-" from being confused with line numbers
    // since match lines always use colons for their separators
    const separators = [_]u8{ ':', '-' };
    for (separators) |target_sep| {
        var i: usize = line.len - 1;
        while (i >= 2) : (i -= 1) {
            const c = line[i];
            // Look for the target separator type
            if (c == target_sep) {
                // Check if preceded by digits
                var j = i - 1;
                while (j > 0 and std.ascii.isDigit(line[j])) : (j -= 1) {}

                // j now points to character before the digits (or 0 if we hit start)
                // Check if there's at least one digit and MATCHING separator before them
                if (j < i - 1 and line[j] == target_sep) {
                    // Found pattern: <sep><digits><sep> with matching separators
                    // line[j] is first sep, line[j+1..i] is line number, line[i] is second sep
                    sep_pos = j;
                    break;
                }
            }
            if (i == 0) break;
        }
        if (sep_pos != null) break;
    }

    const first_sep = sep_pos orelse return null;
    const filename = line[0..first_sep];

    // Parse line number
    var num_end = first_sep + 1;
    while (num_end < line.len and std.ascii.isDigit(line[num_end])) : (num_end += 1) {}

    if (num_end >= line.len) return null;

    const line_num = std.fmt.parseInt(u32, line[first_sep + 1 .. num_end], 10) catch return null;
    const second_sep = line[num_end];
    const is_match = second_sep == ':';
    const content = if (num_end + 1 < line.len) line[num_end + 1 ..] else "";

    return .{
        .filename = filename,
        .line_num = line_num,
        .content = content,
        .is_match = is_match,
    };
}

/// Find the ugrep binary, checking common locations
pub fn findBinary(allocator: Allocator) ?[]const u8 {
    // Try to find relative to executable first
    var exe_dir_buf: [fs.max_path_bytes]u8 = undefined;
    if (fs.selfExeDirPath(&exe_dir_buf)) |exe_dir| {
        const ugrep_path = fs.path.join(allocator, &.{ exe_dir, "ugrep" }) catch return null;

        if (fs.cwd().access(ugrep_path, .{})) |_| {
            return ugrep_path;
        } else |_| {
            allocator.free(ugrep_path);
        }
    } else |_| {}

    // Try PATH
    const path_env = std.posix.getenv("PATH") orelse return null;
    var path_iter = mem.splitScalar(u8, path_env, ':');

    while (path_iter.next()) |dir| {
        const ugrep_path = fs.path.join(allocator, &.{ dir, "ugrep" }) catch continue;

        if (fs.cwd().access(ugrep_path, .{})) |_| {
            return ugrep_path;
        } else |_| {
            allocator.free(ugrep_path);
        }
    }

    return null;
}

/// Search for pattern in paths using ugrep
pub fn search(
    allocator: Allocator,
    pattern: []const u8,
    paths: []const []const u8,
    options: SearchOptions,
) SearchError!SearchResult {
    var result: SearchResult = .{
        .matches = &.{},
        .files = .{},
        .arena = std.heap.ArenaAllocator.init(allocator),
    };
    errdefer result.arena.deinit();

    const arena = result.arena.allocator();

    // Find or use provided binary path
    const binary_path = if (options.binary_path) |p|
        try arena.dupe(u8, p)
    else
        findBinary(arena) orelse return SearchError.BinaryNotFound;

    // Build argument list
    var args: std.ArrayList([]const u8) = .empty;

    try args.append(arena, binary_path);

    if (options.recursive) try args.append(arena, "-r");
    if (options.fixed_strings) try args.append(arena, "-F");
    if (options.ignore_case) try args.append(arena, "-i");
    if (options.line_numbers) try args.append(arena, "-n");

    // Context options
    if (options.context > 0) {
        try args.append(arena, "-C");
        try args.append(arena, try std.fmt.allocPrint(arena, "{d}", .{options.context}));
    } else {
        if (options.context_before > 0) {
            try args.append(arena, "-B");
            try args.append(arena, try std.fmt.allocPrint(arena, "{d}", .{options.context_before}));
        }
        if (options.context_after > 0) {
            try args.append(arena, "-A");
            try args.append(arena, try std.fmt.allocPrint(arena, "{d}", .{options.context_after}));
        }
    }

    if (options.max_count) |max| {
        try args.append(arena, "-m");
        try args.append(arena, try std.fmt.allocPrint(arena, "{d}", .{max}));
    }

    if (options.max_depth) |depth| {
        try args.append(arena, "--depth");
        try args.append(arena, try std.fmt.allocPrint(arena, "{d}", .{depth}));
    }

    for (options.include_globs) |glob| {
        try args.append(arena, "--include");
        try args.append(arena, glob);
    }

    for (options.exclude_globs) |glob| {
        try args.append(arena, "--exclude");
        try args.append(arena, glob);
    }

    // Always disable color for parsing
    try args.append(arena, "--color=never");

    // Separator to prevent pattern from being parsed as option
    try args.append(arena, "--");

    // Pattern and paths
    try args.append(arena, pattern);
    for (paths) |p| {
        try args.append(arena, p);
    }

    // Run ugrep
    const run_result = process.Child.run(.{
        .allocator = arena,
        .argv = args.items,
        .max_output_bytes = options.max_output_bytes,
    }) catch return SearchError.SpawnFailed;

    // ugrep returns 1 when no matches found - that's not an error
    if (run_result.term.Exited != 0 and run_result.stdout.len == 0) {
        return result; // Empty result, no matches
    }

    // Parse output
    var matches_list: std.ArrayList(Match) = .empty;
    var files_map: std.StringHashMapUnmanaged(std.ArrayList(Match)) = .empty;

    var lines = mem.splitScalar(u8, run_result.stdout, '\n');
    while (lines.next()) |line| {
        if (parseLine(line)) |parsed| {
            // Copy strings to arena
            const filename = try arena.dupe(u8, parsed.filename);
            const content = try arena.dupe(u8, parsed.content);

            const match = Match{
                .filename = filename,
                .line_number = parsed.line_num,
                .content = content,
                .is_match = parsed.is_match,
            };

            try matches_list.append(arena, match);

            // Group by file
            const gop = try files_map.getOrPut(arena, filename);
            if (!gop.found_existing) {
                gop.value_ptr.* = .empty;
            }
            try gop.value_ptr.append(arena, match);
        }
    }

    // Convert ArrayLists to slices for final result
    result.matches = try matches_list.toOwnedSlice(arena);

    var files_result: std.StringHashMapUnmanaged([]Match) = .empty;
    var it = files_map.iterator();
    while (it.next()) |entry| {
        try files_result.put(arena, entry.key_ptr.*, try entry.value_ptr.toOwnedSlice(arena));
    }
    result.files = files_result;

    return result;
}

// Tests
test "parseLine - basic match" {
    const result = parseLine("src/main.zig:42:    const x = 5;");
    try std.testing.expect(result != null);
    try std.testing.expectEqualStrings("src/main.zig", result.?.filename);
    try std.testing.expectEqual(@as(u32, 42), result.?.line_num);
    try std.testing.expectEqualStrings("    const x = 5;", result.?.content);
    try std.testing.expect(result.?.is_match);
}

test "parseLine - context line" {
    const result = parseLine("src/main.zig-40-    // comment");
    try std.testing.expect(result != null);
    try std.testing.expectEqualStrings("src/main.zig", result.?.filename);
    try std.testing.expectEqual(@as(u32, 40), result.?.line_num);
    try std.testing.expectEqualStrings("    // comment", result.?.content);
    try std.testing.expect(!result.?.is_match);
}

test "parseLine - filename with colon" {
    const result = parseLine("C:/Users/test/file.txt:10:content");
    try std.testing.expect(result != null);
    try std.testing.expectEqualStrings("C:/Users/test/file.txt", result.?.filename);
    try std.testing.expectEqual(@as(u32, 10), result.?.line_num);
}

test "parseLine - separator line" {
    const result = parseLine("--");
    try std.testing.expect(result == null);
}

test "parseLine - empty line" {
    const result = parseLine("");
    try std.testing.expect(result == null);
}

test "parseLine - filename with digit sequences that look like line numbers" {
    // This filename contains -6357- which could be mistaken for a line number
    const result = parseLine("data-export-aa.bbb.ccc.dd_3737-061584d1-6357-468e-abdc-e65da8b1dd80-report.md:123:actual content");
    try std.testing.expect(result != null);
    try std.testing.expectEqualStrings("data-export-aa.bbb.ccc.dd_3737-061584d1-6357-468e-abdc-e65da8b1dd80-report.md", result.?.filename);
    try std.testing.expectEqual(@as(u32, 123), result.?.line_num);
    try std.testing.expectEqualStrings("actual content", result.?.content);
    try std.testing.expect(result.?.is_match);
}

test "parseLine - filename with multiple dash-digit-dash patterns" {
    const result = parseLine("file-123-test-456-data.txt:789:content here");
    try std.testing.expect(result != null);
    try std.testing.expectEqualStrings("file-123-test-456-data.txt", result.?.filename);
    try std.testing.expectEqual(@as(u32, 789), result.?.line_num);
    try std.testing.expectEqualStrings("content here", result.?.content);
}

test "parseLine - content with hyphen-digit-hyphen pattern should not confuse parser" {
    // Content like "value is -100- degrees" has a -100- pattern that could be mistaken
    // for a line number, but since the separators are hyphens and not colons, it shouldn't match
    const result = parseLine("file.txt:45:the value is -100- degrees");
    try std.testing.expect(result != null);
    try std.testing.expectEqualStrings("file.txt", result.?.filename);
    try std.testing.expectEqual(@as(u32, 45), result.?.line_num);
    try std.testing.expectEqualStrings("the value is -100- degrees", result.?.content);
    try std.testing.expect(result.?.is_match);
}

test "parseLine - complex filename with UUID-like patterns and content starting with hyphen" {
    const result = parseLine("document-2021-27905-abc.def.ghi.jkl_9130-a1b2c3d4-e5f6-4e17-a37e-701f43316afa.md:45:- list item");
    try std.testing.expect(result != null);
    try std.testing.expectEqualStrings("document-2021-27905-abc.def.ghi.jkl_9130-a1b2c3d4-e5f6-4e17-a37e-701f43316afa.md", result.?.filename);
    try std.testing.expectEqual(@as(u32, 45), result.?.line_num);
    try std.testing.expectEqualStrings("- list item", result.?.content);
    try std.testing.expect(result.?.is_match);
}
