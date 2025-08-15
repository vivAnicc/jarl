const std = @import("std");
const ast = @import("../../ast.zig");

name: []const u8,
type: ?*const ast.Expr,
expr: *const ast.Expr,

const Self = @This();

pub fn format(self: Self, writer: *std.Io.Writer) !void {
  try writer.print("let {s}", .{self.name});
  if (self.type) |t| {
    try writer.print(": {f}", .{t});
  }
  try writer.print(" = {f};", .{self.expr});
}
