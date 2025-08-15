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
};

const Let = @import("ast/stmt/let.zig");
pub const Stmt = union(enum) {
  let: Let,
  expr: Expr,
};

pub const Block = union(enum) {
  simple: []const Token,
};

test {
  std.testing.refAllDecls(@This());
}
