const std = @import("std");
const Tokenizer = @import("tokenizer");

pub fn main() !void {
  var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
  defer _ = gpa.deinit();

  var arena = std.heap.ArenaAllocator.init(gpa.allocator());
  defer arena.deinit();

  const alloc = arena.allocator();

  const file_name = "test.jarl";
  const file = try std.fs.cwd().openFile(file_name, .{ .mode = .read_only });

  var buf: [64]u8 = undefined;

  var reader = file.reader(&buf);
  const tokens = try Tokenizer.tokenize_all(file_name, &reader.interface, alloc);

  for (tokens) |token| {
    std.debug.print("{f}\n", .{token});
  }
}

test {
  std.testing.refAllDecls(@This());
}
