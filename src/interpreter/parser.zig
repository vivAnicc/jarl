const std = @import("std");
pub const ast = @import("ast");
pub const Token = @import("tokenizer").Token;

const Parser = @This();

pub const Tokens = struct {
  slice: []const Token,

  pub fn new(slice: []const Token) Tokens {
    return Tokens{ .slice = slice };
  }

  fn peek(tokens: *const Tokens, offset: usize) ?Token.Value {
    if (tokens.slice.len <= offset)
      return null;
    return tokens.slice[offset].value;
  }

  fn take(tokens: *Tokens) ?Token {
    if (tokens.slice.len == 0)
      return null;
    const token = tokens.slice[0];
    tokens.slice = tokens.slice[1..];
    return token;
  }
};

ast_alloc: std.mem.Allocator,
symbols_alloc: std.mem.Allocator,
values_alloc: std.mem.Allocator,
temp_alloc: std.mem.Allocator,
// tokens: []const Token = &.{},
// cursor: usize = 0,

pub fn new(
  ast_alloc: std.mem.Allocator,
  symbols_alloc: std.mem.Allocator,
  values_alloc: std.mem.Allocator,
  temp_alloc: std.mem.Allocator,
) Parser {
  return Parser{
    .ast_alloc = ast_alloc,
    .symbols_alloc = symbols_alloc,
    .values_alloc = values_alloc,
    .temp_alloc = temp_alloc,
  };
}

pub const Error = error {
  OutOfMemory
};

pub fn find(self: *Parser, func: anytype, tokens: *Tokens) Error!bool {
  const ast_alloc = self.ast_alloc;
  const symbols_alloc = self.symbols_alloc;
  const values_alloc = self.values_alloc;
  const local_tokens = tokens.*;

  var arena = std.heap.ArenaAllocator.init(self.temp_alloc);
  self.ast_alloc = arena.allocator();
  self.symbols_alloc = arena.allocator();
  self.values_alloc = arena.allocator();

  defer {
    self.ast_alloc = ast_alloc;
    self.symbols_alloc = symbols_alloc;
    self.values_alloc = values_alloc;
    tokens.* = local_tokens;
    arena.deinit();
  }

  const result = try func(self, tokens);
  return result != null;
}

pub fn parseExprAlloc(self: *Parser, tokens: *Tokens) Error!?*const ast.Expr {
  const expr = self.parseExpr(tokens) orelse return null;
  const ptr = try self.ast_alloc.create(ast.Expr);
  ptr.* = expr;
  return ptr;
}

pub fn parseExpr(self: *Parser, tokens: *Tokens) Error!?ast.Expr {
  switch (tokens.peek(0) orelse return null) {
    .ident => |ident| {
      _ = tokens.take();
      const name = try self.symbols_alloc.dupe(u8, ident);
      return ast.Expr{
        .ident = .{ .val = name },
      };
    },

    .int => |int| {
      _ = tokens.take();
      return ast.Expr{
        .int = .{ .val = int },
      };
    },

    .float => |float| {
      _ = tokens.take();
      return ast.Expr{
        .float = .{ .val = float },
      };
    },

    .char => |char| {
      _ = tokens.take();
      return ast.Expr{
        .char = .{ .val = char },
      };
    },

    .string => |string| {
      _ = tokens.take();
      const dupe = try self.values_alloc.dupe(u8, string);
      return ast.Expr{
        .string = .{ .val = dupe },
      };
    },

    .tilde => {
      const next = tokens.peek(1) orelse return null;
      if (next != .ident)
        return null;

      _ = tokens.take();
      _ = tokens.take();

      const name = try self.symbols_alloc.dupe(u8, next.ident);
      return ast.Expr{
        .name = .{ .val = name },
      };
    },

    else => return null,
  }
}

test {
  std.testing.refAllDecls(@This());
}
