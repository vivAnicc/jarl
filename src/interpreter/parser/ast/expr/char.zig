const std = @import("std");
const ast = @import("../../ast.zig");

val: u8,

const Self = @This();

pub fn format(self: Self, writer: *std.Io.Writer) !void {
  try writer.print("'{c}'", .{self.val});
}
