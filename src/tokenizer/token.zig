const std = @import("std");
pub const Span = @import("span.zig");

value: Value,
span: Span,

pub const Type = enum {
    ident, // Ident
    int, // Int
    float, // Float
    string, // String
    char, // Char
    invalid, // Invalid

    plus, // +
    dash, // -
    slash, // /
    start, // *
    percent, // %
    bar, // |
    bar_bar, // ||
    ampersand, // &
    ampersand_ampersand, // &&
    colon, // :
    colon_colon, // ::
    colon_equals, // :=
    arrow, // ->
    equals, // =
    equals_equals, // ==
    bang, // !
    question, // ?
    bang_equals, // !=
    less, // <
    less_equals, // <=
    greater, // >
    greater_equals, // >=
    underscore, // _
    comma, // ,
    dot, // .
    dot_dot, // ..
    dot_dot_dot, // ...
    semi, // ;

    kw_ctx, // ctx
    kw_else, // else
    kw_null, // null
    kw_or, // or
    kw_and, // and
    kw_return, // return
    kw_let, // let

    paren_group, // (...)
    bracket_group, // [...]
    brace_group, // {...}
};

pub const Value = union(Type) {
    ident: []const u8, // Ident
    int: i128, // Int
    float: f128, // Float
    string: []const u8, // String
    char: u8, // Char
    invalid: u8, // Invalid

    plus, // +
    dash, // -
    slash, // /
    start, // *
    percent, // %
    bar, // |
    bar_bar, // ||
    ampersand, // &
    ampersand_ampersand, // &&
    colon, // :
    colon_colon, // ::
    colon_equals, // :=
    arrow, // ->
    equals, // =
    equals_equals, // ==
    bang, // !
    question, // ?
    bang_equals, // !=
    less, // <
    less_equals, // <=
    greater, // >
    greater_equals, // >=
    underscore, // _
    comma, // ,
    dot, // .
    dot_dot, // ..
    dot_dot_dot, // ...
    semi, // ;

    kw_ctx, // ctx
    kw_else, // else
    kw_null, // null
    kw_or, // or
    kw_and, // and
    kw_return, // return
    kw_let, // let

    paren_group: []const Value, // (...)
    bracket_group: []const Value, // [...]
    brace_group: []const Value, // {...}

    pub fn format(self: Value, writer: *std.Io.Writer) !void {
        switch (self) {
            .paren_group => |group| {
                try writer.print("paren_group: \n", .{});
                for (group) |token| {
                    try writer.print("{f}\n", .{token});
                }
                try writer.print("end paren_group", .{});
            },
            .bracket_group => |group| {
                try writer.print("bracket_group: \n", .{});
                for (group) |token| {
                    try writer.print("{f}\n", .{token});
                }
                try writer.print("end bracket_group", .{});
            },
            .brace_group => |group| {
                try writer.print("brace_group: \n", .{});
                for (group) |token| {
                    try writer.print("{f}\n", .{token});
                }
                try writer.print("end brace_group", .{});
            },

            .ident => |ident| try writer.print("ident: {s}", .{ident}),
            .int => |int| try writer.print("{}", .{int}),
            .float => |float| try writer.print("{}", .{float}),
            .string => |string| try writer.print("\"{s}\"", .{string}),
            .char => |char| try writer.print("'{c}'", .{char}),
            .invalid => |invalid| try writer.print("invalid: '{c}'", .{invalid}),

            .kw_ctx => try writer.print("ctx", .{}),
            .kw_else => try writer.print("else", .{}),
            .kw_null => try writer.print("null", .{}),
            .kw_or => try writer.print("or", .{}),
            .kw_and => try writer.print("and", .{}),
            .kw_return => try writer.print("return", .{}),
            .kw_let => try writer.print("let", .{}),

            .plus => try writer.print("+", .{}),
            .dash => try writer.print("-", .{}),
            .slash => try writer.print("/", .{}),
            .start => try writer.print("*", .{}),
            .percent => try writer.print("%", .{}),
            .bar => try writer.print("|", .{}),
            .bar_bar => try writer.print("||", .{}),
            .ampersand => try writer.print("&", .{}),
            .ampersand_ampersand => try writer.print("&&", .{}),
            .colon => try writer.print(":", .{}),
            .colon_colon => try writer.print("::", .{}),
            .colon_equals => try writer.print(":=", .{}),
            .arrow => try writer.print("->", .{}),
            .equals => try writer.print("=", .{}),
            .equals_equals => try writer.print("==", .{}),
            .bang => try writer.print("!", .{}),
            .question => try writer.print("?", .{}),
            .bang_equals => try writer.print("!=", .{}),
            .less => try writer.print("<", .{}),
            .less_equals => try writer.print("<=", .{}),
            .greater => try writer.print(">", .{}),
            .greater_equals => try writer.print(">=", .{}),
            .underscore => try writer.print("_", .{}),
            .comma => try writer.print(",", .{}),
            .dot => try writer.print(".", .{}),
            .dot_dot => try writer.print("..", .{}),
            .dot_dot_dot => try writer.print("...", .{}),
            .semi => try writer.print(";", .{}),
        }
    }
};

pub fn format(self: @This(), writer: *std.Io.Writer) !void {
    try writer.print("{f}", .{self.value});
}
