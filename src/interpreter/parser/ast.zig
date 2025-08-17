const std = @import("std");
const Token = @import("tokenizer").Token;

const Ident = @import("ast/expr/ident.zig");
const Int = @import("ast/expr/int.zig");
const Float = @import("ast/expr/float.zig");
const String = @import("ast/expr/string.zig");
const Char = @import("ast/expr/char.zig");
const Name = @import("ast/expr/name.zig");
pub const Expr = union(enum) {
  ident: Ident,
  int: Int,
  float: Float,
  string: String,
  char: Char,
  name: Name,

  pub fn format(self: Expr, writer: *std.Io.Writer) !void {
    // try writer.print("{s}: ", .{@tagName(self)});
    switch (self) {
      inline else => |expr| try writer.print("{f}", .{expr}),
    }
  }
};

const Let = @import("ast/stmt/let.zig");
pub const Stmt = union(enum) {
  let: Let,
  expr: Expr,

  pub fn format(self: Stmt, writer: *std.Io.Writer) !void {
    // try writer.print("{s}: ", .{@tagName(self)});
    switch (self) {
      .expr => |expr| try writer.print("{f};", .{expr}),
      inline else => |stmt| try writer.print("{f}", .{stmt}),
    }
  }
};

pub const Evaluation = struct {
  stmts: []const Stmt,
  expr: ?*const Expr,

  pub fn format(self: Evaluation, writer: *std.Io.Writer) !void {
    for (self.stmts, 0..) |stmt, idx| {
      if (idx != 0) {
        try writer.print("\n", .{});
      }
      try writer.print("{f}", .{stmt});
    }

    if (self.expr) |expr| {
      if (self.stmts.len != 0) {
        try writer.print("\n", .{});
      }
      try writer.print("{f}", .{expr});
    }
  }
};

pub const Block = union(enum) {
  simple: []const Token,

  pub fn format(self: Block, writer: *std.Io.Writer) !void {
    // try writer.print("{s}: ", .{@tagName(self)});
    switch (self) {
      .simple => try writer.print("{{ ... }}", .{}),
      inline else => |block| try writer.print("{f}", .{block}),
    }
  }
};

test {
  std.testing.refAllDecls(@This());
}
