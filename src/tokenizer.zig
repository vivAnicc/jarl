const std = @import("std");
pub const Token = @import("tokenizer/token.zig");

pub const Error = error {
  ReadFailed,
  OutOfMemory,
};

pub fn tokenize_all(
  file_name: []const u8,
  reader: *std.Io.Reader,
  alloc: std.mem.Allocator,
) Error![]const Token {
  const result = tokenize(
    file_name,
    reader,
    alloc,
    &.{},
  ) catch |err| switch (err) {
    error.EndOfStream => unreachable,
    error.ReadFailed, error.OutOfMemory => |e| return e,
  };
  errdefer alloc.free(result);

  _ = reader.peekByte() catch |err| switch (err) {
    error.EndOfStream => return result,
    inline else => |e| return e,
  };

  // assert that we consumed the whole input
  unreachable;
}

const TokenizeError = std.Io.Reader.Error || std.mem.Allocator.Error;

fn tokenize(
  file_name: []const u8,
  reader: *std.Io.Reader,
  alloc: std.mem.Allocator,
  comptime stop: []const u8,
) TokenizeError![]const Token {
  var result = std.ArrayList(Token).init(alloc);
  errdefer result.deinit();

  lexing: while (true) {
    const char = reader.takeByte() catch |err| switch (err) {
      error.EndOfStream => break :lexing,
      else => |e| return e,
    };

    inline for (stop) |s| {
      if (char == s) {
        break :lexing;
      }
    }

    var value: Token.Value = .invalid;
    const start = reader.seek - 1;

    char_switch: switch (char) {
      '+' => value = .plus,
      // dash could be an arrow
      '/' => value = .slash,
      '*' => value = .start,
      '%' => value = .percent,
      '~' => value = .tilde,
      '?' => value = .question,
      '_' => value = .underscore,
      ',' => value = .comma,
      ';' => value = .semi,

      '(' => {
        const group = try tokenize(
          file_name,
          reader,
          alloc,
          &.{')'}
        );
        value = .{ .paren_group = group };
      },

      '[' => {
        const group = try tokenize(
          file_name,
          reader,
          alloc,
          &.{']'}
        );
        value = .{ .bracket_group = group };
      },

      '{' => {
        const group = try tokenize(
          file_name,
          reader,
          alloc,
          &.{'}'}
        );
        value = .{ .brace_group = group };
      },

      '|' => {
        switch (reader.peekByte() catch |err| switch (err) {
          error.EndOfStream => ' ',
          else => |e| return e,
        }) {
          '|' => {
            try reader.discardAll(1);
            value = .bar_bar;
          },
          else => {
            value = .bar;
          },
        }
      },

      '&' => {
        switch (reader.peekByte() catch |err| switch (err) {
          error.EndOfStream => ' ',
          else => |e| return e,
        }) {
          '&' => {
            try reader.discardAll(1);
            value = .ampersand_ampersand;
          },
          else => {
            value = .ampersand;
          },
        }
      },

      ':' => {
        switch (reader.peekByte() catch |err| switch (err) {
          error.EndOfStream => ' ',
          else => |e| return e,
        }) {
          ':' => {
            try reader.discardAll(1);
            value = .colon_colon;
          },
          '=' => {
            try reader.discardAll(1);
            value = .colon_equals;
          },
          else => {
            value = .colon;
          },
        }
      },

      '-' => {
        switch (reader.peekByte() catch |err| switch (err) {
          error.EndOfStream => ' ',
          else => |e| return e,
        }) {
          '>' => {
            try reader.discardAll(1);
            value = .arrow;
          },
          else => {
            value = .dash;
          },
        }
      },

      '=' => {
        switch (reader.peekByte() catch |err| switch (err) {
          error.EndOfStream => ' ',
          else => |e| return e,
        }) {
          '=' => {
            try reader.discardAll(1);
            value = .equals_equals;
          },
          else => {
            value = .equals;
          },
        }
      },

      '!' => {
        switch (reader.peekByte() catch |err| switch (err) {
          error.EndOfStream => ' ',
          else => |e| return e,
        }) {
          '=' => {
            try reader.discardAll(1);
            value = .bang_equals;
          },
          else => {
            value = .bang;
          },
        }
      },

      '<' => {
        switch (reader.peekByte() catch |err| switch (err) {
          error.EndOfStream => ' ',
          else => |e| return e,
        }) {
          '=' => {
            try reader.discardAll(1);
            value = .less_equals;
          },
          else => {
            value = .less;
          },
        }
      },

      '>' => {
        switch (reader.peekByte() catch |err| switch (err) {
          error.EndOfStream => ' ',
          else => |e| return e,
        }) {
          '=' => {
            try reader.discardAll(1);
            value = .greater_equals;
          },
          else => {
            value = .greater;
          },
        }
      },

      '.' => {
        switch (reader.peekByte() catch |err| switch (err) {
          error.EndOfStream => ' ',
          else => |e| return e,
        }) {
          '.' => {
            switch (reader.peekByte() catch |err| switch (err) {
              error.EndOfStream => ' ',
              else => |e| return e,
            }) {
              '.' => {
                try reader.discardAll(2);
                value = .dot_dot_dot;
              },
              else => {
                try reader.discardAll(1);
                value = .dot_dot;
              },
            }
          },
          else => {
            value = .dot;
          },
        }
      },
      
      '\'' => {
        const c = escaped_char(reader) catch |err| switch (err) {
          error.EndOfStream, error.InvalidChar => break :char_switch,
          inline else => |e| return e,
        };

        const quote = reader.peekByte() catch |err| switch (err) {
          error.EndOfStream => break :char_switch,
          inline else => |e| return e,
        };

        if (quote != '\'') {
          break :char_switch;
        }

        try reader.discardAll(1);
        value = .{ .char = c };
      },
      
      '"' => {
        var string = std.ArrayList(u8).init(alloc);
        errdefer string.deinit();

        build_string: while (true) {
          const next = reader.peekByte() catch |err| switch (err) {
            error.EndOfStream => break :build_string,
            inline else => |e| return e,
          };

          if (next != '"') {
            try string.append(escaped_char(reader) catch |err| switch (err) {
              error.EndOfStream => break :build_string,
              error.InvalidChar => break :char_switch,
              inline else => |e| return e,
            });
          } else {
            break :build_string;
          }
        }

        const quote = reader.peekByte() catch |err| switch (err) {
          error.EndOfStream => break :char_switch,
          inline else => |e| return e,
        };

        if (quote != '"') {
          break :char_switch;
        }

        try reader.discardAll(1);
        value = .{ .string = try string.toOwnedSlice() };
        break :char_switch;
      },

      else => {
        if (std.ascii.isAlphabetic(char) or char == '_') {
          var string = std.ArrayList(u8).init(alloc);
          errdefer string.deinit();

          try string.append(char);

          build_string: while (true) {
            const next = reader.peekByte() catch |err| switch (err) {
              error.EndOfStream => break :build_string,
              inline else => |e| return e,
            };

            if (std.ascii.isAlphanumeric(next) or next == '_') {
              try string.append(try reader.takeByte());
            } else {
              break :build_string;
            }
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

        if (std.ascii.isDigit(char)) {
          var num = std.ArrayList(u8).init(alloc);
          errdefer num.deinit();

          var int = true;

          try num.append(char);

          build_num: while (true) {
            const next = reader.peekByte() catch |err| switch (err) {
              error.EndOfStream => break :build_num,
              inline else => |e| return e,
            };

            if (std.ascii.isDigit(next)) {
              try num.append(try reader.takeByte());
            } else if (next == '.') {
              const after = reader.peek(2) catch |err| switch (err) {
                error.EndOfStream => break :build_num,
                inline else => |e| return e,
              };

              if (std.ascii.isDigit(after[1])) {
                int = false;
                const ns = try reader.take(2);
                try num.appendSlice(ns);
              } else {
                break :build_num;
              }
            } else {
              break :build_num;
            }
          }

          if (int) {
            const parsed = std.fmt.parseInt(i128, num.items, 10) catch unreachable;
            num.deinit();

            value = .{ .int = parsed };
          } else {
            const parsed = std.fmt.parseFloat(f128, num.items) catch unreachable;
            num.deinit();

            value = .{ .float = parsed };
          }

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

fn escaped_char(reader: *std.Io.Reader) !u8 {
  const next = try reader.takeByte();
  switch (next) {
    '\\' => {
      const escaped = try reader.takeByte();
      return switch (escaped) {
        'n' => '\n',
        'r' => '\r',
        't' => '\t',
        '0' => 0,

        else => |char| char,
      };
    },

    '\n', '\r', '\t', 0 => return error.InvalidChar,

    else => return next,
  }
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

// const symbols = &.{
//   .{ Token.Value.plus, "+" },
//   .{ Token.Value.dash, "-" },
//   .{ Token.Value.slash, "/" },
//   .{ Token.Value.start, "*" },
//   .{ Token.Value.percent, "%" },
//   .{ Token.Value.bar, "|" },
//   .{ Token.Value.bar_bar, "||" },
//   .{ Token.Value.ampersand, "&" },
//   .{ Token.Value.ampersand_ampersand, "&&" },
//   .{ Token.Value.colon, ":" },
//   .{ Token.Value.colon_colon, "::" },
//   .{ Token.Value.colon_equals, ":=" },
//   .{ Token.Value.arrow, "->" },
//   .{ Token.Value.equals, "=" },
//   .{ Token.Value.equals_equals, "==" },
//   .{ Token.Value.question, "?" },
//   .{ Token.Value.bang, "!" },
//   .{ Token.Value.bang_equals, "!=" },
//   .{ Token.Value.less, "<" },
//   .{ Token.Value.less_equals, "<=" },
//   .{ Token.Value.greater, ">" },
//   .{ Token.Value.greater_equals, ">=" },
//   .{ Token.Value.underscore, "_" },
//   .{ Token.Value.comma, "," },
//   .{ Token.Value.dot, "." },
//   .{ Token.Value.dot_dot, ".." },
//   .{ Token.Value.dot_dot_dot, "..." },
//   .{ Token.Value.semi, ";" },

//   .{ Token.Value.kw_ctx, "ctx" },
//   .{ Token.Value.kw_else, "else" },
//   .{ Token.Value.kw_null, "null" },
//   .{ Token.Value.kw_or, "or" },
//   .{ Token.Value.kw_and, "and" },
//   .{ Token.Value.kw_return, "return" },
//   .{ Token.Value.kw_let, "let" },
// };

test {
  std.testing.refAllDecls(@This());
  std.testing.refAllDecls(Token);
  std.testing.refAllDecls(Token.Span);
  std.testing.refAllDecls(Token.Value);
}
