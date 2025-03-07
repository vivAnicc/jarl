const std = @import("std");
const Tokenizer = @import("tokenizer");

pub fn main() !void {
    const file_name = "example.jarl";

    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();

    var tokenizer = try Tokenizer.new(file_name, file.reader(), &arena);
    const tokens = try tokenizer.get_tokens(arena.allocator());

    std.debug.print("tokens: {any}\n", .{tokens});
}
