const std = @import("std");

file: []const u8,
start: usize,
end: usize,

const Self = @This();

pub fn merge(first: Self, second: Self) !Self {
    if (!std.mem.eql(u8, first.file, second.file)) {
        return error.DifferentFile;
    }

    return .{
        .file = first.file,
        .start = @min(first.start, second.start),
        .end = @max(first.end, second.end),
    };
}
