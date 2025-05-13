const std = @import("std");
const Tokenizer = @import("tokenizer");
const Parser = @import("parser");

pub fn main() !void {
    var args_iter = std.process.args();
    const exe_name = args_iter.next().?;

    const file_name = args_iter.next() orelse {
        std.debug.print("ERROR: incorrect usage\nCorrect usage: {s} <file>\n", .{exe_name});
        return;
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var temp_arena = std.heap.ArenaAllocator.init(gpa.allocator());
    var tokens_arena = std.heap.ArenaAllocator.init(gpa.allocator());

    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var tokenizer = try Tokenizer.new(file_name, file.reader(), &temp_arena);
    const tokens = try tokenizer.get_tokens(tokens_arena.allocator());

    for (tokenizer.errors.items) |err| {
        std.debug.print("{s}\n", .{err});
    }

    temp_arena.deinit();

    std.debug.print("{any}\n", .{tokens});

    var ast_arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer ast_arena.deinit();

    const parser = Parser.new(@ptrCast(tokens), &ast_arena);
    _ = parser;
    
    tokens_arena.deinit();
}
