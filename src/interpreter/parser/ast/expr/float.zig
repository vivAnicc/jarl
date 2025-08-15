const std = @import("std");
const ast = @import("../../ast.zig");

val: f128,

const Self = @This();

pub fn format(self: Self, writer: *std.Io.Writer) !void {
  try writer.print("{}", .{self.val});
}
