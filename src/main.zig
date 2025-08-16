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

  const save = try parser.probe(Interpreter.Parser.parseExpr, &tokens);

  if (save) |s| {
    std.debug.print("Probe successful: ", .{});
    tokens = s;
  }

  const result = try parser.parseExpr(&tokens);
  if (result) |expr| {
    std.debug.print("{f}\n\n", .{expr});
  } else {
    std.debug.print("null\n\n", .{});
  }

  for (tokens.slice) |token| {
    std.debug.print("{f}\n", .{token});
  }
}

test {
  std.testing.refAllDecls(@This());
}
