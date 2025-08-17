const std = @import("std");
const Span = @import("tokenizer").Token.Span;

const Errors = @This();

list: std.ArrayListUnmanaged([]const u8),
alloc: std.mem.Allocator,

pub fn new(alloc: std.mem.Allocator) Errors {
  return Errors{
    .list = .{},
    .alloc = alloc,
  };
}

pub fn format(
  self: *Errors,
  span: Span,
  comptime string: []const u8,
  args: anytype,
) std.mem.Allocator.Error!void {
  const msg = try std.fmt.allocPrint(
    self.alloc, "{s}:{}-{}: " ++ string, .{
      span.file,
      span.start,
      span.end,
    } ++ args,
  );
  try self.list.append(self.alloc, msg);
}
