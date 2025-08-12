const std = @import("std");
pub const Token = @import("token.zig");

pub fn tokenize(
    file_name: []const u8,
    reader: *std.Io.Reader,
    alloc: std.mem.Allocator,
) ![]const Token {
    var result = std.ArrayList(Token).init(alloc);
    errdefer result.deinit();

    lexing: while (true) {
        const char = reader.takeByte() catch |err| switch (err) {
            error.EndOfStream => break :lexing,
            else => |e| return e,
        };

        var value = Token.Value{ .invalid = char };
        const start = reader.seek - 1;

        char_switch: switch (char) {
            '+' => value = .plus,
            '-' => value = .dash,
            '/' => value = .slash,
            '*' => value = .start,
            '%' => value = .percent,
            '?' => value = .question,
            '_' => value = .underscore,
            ',' => value = .comma,
            ';' => value = .semi,

            else => {
                if (std.ascii.isAlphabetic(char)) {
                    var string = std.ArrayList(u8).init(alloc);
                    errdefer string.deinit();

                    try string.append(char);

                    build_string: while (true) {
                        const next = reader.peekByte() catch |err| switch (err) {
                            error.EndOfStream => break :build_string,
                            inline else => |e| return e,
                        };

                        if (!std.ascii.isAlphabetic(next))
                            break :build_string;

                        try string.append(try reader.takeByte());
                    }

                    inline for (keywords) |kw| {
                        if (std.mem.eql(u8, string.items, kw[1])) {
                            value = kw[0];
                            string.deinit();
                            break :char_switch;
                        }
                    }

                    value = .{ .ident = try string.toOwnedSlice() };
                    break :char_switch;
                }
                if (std.ascii.isWhitespace(char))
                    continue :lexing;
            },
        }

        const token = Token{
            .span = .{
                .file = file_name,
                .start = start,
                .end = reader.seek,
            },
            .value = value,
        };
        try result.append(token);
    }

    return try result.toOwnedSlice();
}

const keywords = &.{
    .{ Token.Value.kw_ctx, "ctx" },
    .{ Token.Value.kw_else, "else" },
    .{ Token.Value.kw_null, "null" },
    .{ Token.Value.kw_or, "or" },
    .{ Token.Value.kw_and, "and" },
    .{ Token.Value.kw_return, "return" },
    .{ Token.Value.kw_let, "let" },
};

const symbols = &.{
    .{ Token.Value.plus, "+" },
    .{ Token.Value.dash, "-" },
    .{ Token.Value.slash, "/" },
    .{ Token.Value.start, "*" },
    .{ Token.Value.percent, "%" },
    .{ Token.Value.bar, "|" },
    .{ Token.Value.bar_bar, "||" },
    .{ Token.Value.ampersand, "&" },
    .{ Token.Value.ampersand_ampersand, "&&" },
    .{ Token.Value.colon, ":" },
    .{ Token.Value.colon_colon, "::" },
    .{ Token.Value.colon_equals, ":=" },
    .{ Token.Value.arrow, "->" },
    .{ Token.Value.equals, "=" },
    .{ Token.Value.equals_equals, "==" },
    .{ Token.Value.bang, "!" },
    .{ Token.Value.question, "?" },
    .{ Token.Value.bang_equals, "!=" },
    .{ Token.Value.less, "<" },
    .{ Token.Value.less_equals, "<=" },
    .{ Token.Value.greater, ">" },
    .{ Token.Value.greater_equals, ">=" },
    .{ Token.Value.underscore, "_" },
    .{ Token.Value.comma, "," },
    .{ Token.Value.dot, "." },
    .{ Token.Value.dot_dot, ".." },
    .{ Token.Value.dot_dot_dot, "..." },
    .{ Token.Value.semi, ";" },

    .{ Token.Value.kw_ctx, "ctx" },
    .{ Token.Value.kw_else, "else" },
    .{ Token.Value.kw_null, "null" },
    .{ Token.Value.kw_or, "or" },
    .{ Token.Value.kw_and, "and" },
    .{ Token.Value.kw_return, "return" },
    .{ Token.Value.kw_let, "let" },
};

test {
    std.testing.refAllDecls(@This());
    std.testing.refAllDecls(Token);
    std.testing.refAllDecls(Token.Span);
}
