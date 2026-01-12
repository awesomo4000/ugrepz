//! ugrepz library - Zig wrapper for ugrep
//!
//! This module provides a clean Zig API for searching files using ugrep.
//!
//! ## Example Usage
//!
//! ```zig
//! const ugrepz = @import("ugrepz");
//!
//! var results = try ugrepz.search(allocator, "TODO", &.{"src/"}, .{
//!     .ignore_case = true,
//!     .context = 2,
//! });
//! defer results.deinit();
//!
//! for (results.matches) |match| {
//!     std.debug.print("{s}:{d}: {s}\n", .{
//!         match.filename, match.line_number, match.content,
//!     });
//! }
//! ```

pub const ugrep = @import("ugrep.zig");

// Re-export main types and functions for convenience
pub const search = ugrep.search;
pub const findBinary = ugrep.findBinary;
pub const parseLine = ugrep.parseLine;
pub const SearchOptions = ugrep.SearchOptions;
pub const SearchResult = ugrep.SearchResult;
pub const SearchError = ugrep.SearchError;
pub const Match = ugrep.Match;

test {
    @import("std").testing.refAllDecls(@This());
}
