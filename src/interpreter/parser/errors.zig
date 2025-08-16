const std = @import("std");

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
  comptime string: []const u8,
  args: anytype,
) std.mem.Allocator.Error!void {
  const msg = try std.fmt.allocPrint(
    self.alloc, string, args,
  );
  try self.list.append(self.alloc, msg);
}
