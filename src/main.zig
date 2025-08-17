const std = @import("std");
const Tokenizer = @import("tokenizer");
const Interpreter = @import("interpreter");

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
  const token_slice = try Tokenizer.tokenize_all(file_name, &reader.interface, alloc);

  var parser = Interpreter.Parser.new(alloc, alloc, alloc, alloc);
  var tokens = Interpreter.Parser.Tokens.new(token_slice);

  var errors = Interpreter.Parser.Errors.new(alloc);

  const result = try parser.parseEvaluation(&tokens, &errors);
  if (result) |eval| {
    std.debug.print("{f}\n", .{eval});
  } else {
    std.debug.print("Errors encoutered:\n", .{});
    for (errors.list.items) |e| {
      std.debug.print("ERROR: {s}\n", .{e});
    }
    std.debug.print("\n", .{});
    std.process.exit(1);
  }

  if (tokens.slice.len != 0)
    unreachable;
}

test {
  std.testing.refAllDecls(@This());
}
