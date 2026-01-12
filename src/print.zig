//! Simple print utilities for Zig 0.15.2
//! Provides convenience functions for stdout/stderr printing

const std = @import("std");
const File = std.fs.File;

var stdout_buffer: [4096]u8 = undefined;
var stderr_buffer: [4096]u8 = undefined;

pub fn print(comptime format: []const u8, args: anytype) void {
    var writer = File.stdout().writer(&stdout_buffer);
    writer.interface.print(format, args) catch {};
    writer.interface.flush() catch {};
}

pub fn println(comptime format: []const u8, args: anytype) void {
    var writer = File.stdout().writer(&stdout_buffer);
    writer.interface.print(format, args) catch {};
    writer.interface.writeByte('\n') catch {};
    writer.interface.flush() catch {};
}

pub fn eprint(comptime format: []const u8, args: anytype) void {
    var writer = File.stderr().writer(&stderr_buffer);
    writer.interface.print(format, args) catch {};
    writer.interface.flush() catch {};
}

pub fn eprintln(comptime format: []const u8, args: anytype) void {
    var writer = File.stderr().writer(&stderr_buffer);
    writer.interface.print(format, args) catch {};
    writer.interface.writeByte('\n') catch {};
    writer.interface.flush() catch {};
}
