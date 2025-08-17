const std = @import("std");
pub const ast = @import("ast");
pub const Token = @import("tokenizer").Token;
pub const Tokens = @import("parser/tokens.zig");
pub const Errors = @import("parser/errors.zig");

const Parser = @This();

ast_alloc: std.mem.Allocator,
symbols_alloc: std.mem.Allocator,
values_alloc: std.mem.Allocator,
temp_alloc: std.mem.Allocator,

pub var last: ?Token.Span = null;

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

// parse function signature:
// fn (*Parser, *Tokens, ?*Errors) Error!?..
pub fn probe(self: *Parser, func: anytype, tokens: *Tokens) Error!?Tokens {
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
    // tokens.* = local_tokens;
    arena.deinit();
  }

  const result = try func(self, tokens, null);
  if (result != null) {
    return local_tokens;
  } else {
    return null;
  }
}

pub fn parseTokenType(comptime t: Token.Type)
  fn(*Parser, *Tokens) 
    Error!?@FieldType(Token.Value, @tagName(t))
{
  const ReturnType = Error!?@FieldType(Token.Value, @tagName(t));
  return struct {
    fn parseTokenValue(_: *Parser, tokens: *Tokens, errors: ?*Errors) ReturnType {
      const next = tokens.peek(0) orelse {
        if (errors) |e| {
          try e.format(
            last orelse @panic("Unknown location"),
            "Expected {f}, found EOF",
            .{t}
          );
        }
        return null;
      };

        if (next == t) {
          _ = tokens.take();
          return @field(next, @tagName(t));
        }

        if (errors) |e| {
          try e.format(tokens.slice[0].span, "Expected {f}, found {f}", .{t, next});
        }
        return null;
    }
  }.parseTokenValue;
}

pub fn parseExprAlloc(self: *Parser, tokens: *Tokens, errors: ?*Errors) Error!?*const ast.Expr {
  const expr = try self.parseExpr(tokens, errors) orelse return null;
  const ptr = try self.ast_alloc.create(ast.Expr);
  ptr.* = expr;
  return ptr;
}

pub fn parseExpr(self: *Parser, tokens: *Tokens, errors: ?*Errors) Error!?ast.Expr {
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
      const next = tokens.peek(1) orelse {
        if (errors) |e| {
          try e.format(last orelse @panic("Unknown location"), "Expected identifier, found EOF. Note: a '~' should always be followed by an identifier and returns its name", .{});
        }
        return null;
      };

      if (next != .ident) {
        if (errors) |e| {
          try e.format(tokens.slice[0].span, "Expected identifier, found {f}. Note: a '~' should always be followed by an identifier and returns its name", .{next});
        }
        return null;
      }

      _ = tokens.take();
      _ = tokens.take();

      const name = try self.symbols_alloc.dupe(u8, next.ident);
      return ast.Expr{
        .name = .{ .val = name },
      };
    },

    else => |token| {
      if (errors) |e| {
        try e.format(tokens.slice[0].span, "Expected an expression, found {f}", .{token});
      }
      return null;
    },
  }
}

pub fn parseStmtAlloc(self: *Parser, tokens: *Tokens, errors: ?*Errors) Error!?*const ast.Stmt {
  const stmt = try self.parseStmt(tokens, errors) orelse return null;
  const ptr = try self.ast_alloc.create(ast.Stmt);
  ptr.* = stmt;
  return ptr;
}

// let: Let,
// expr: Expr,

pub fn parseStmt(self: *Parser, tokens: *Tokens, errors: ?*Errors) Error!?ast.Stmt {
  switch (tokens.peek(0) orelse return null) {
    .kw_let => {
      const start = tokens.*;
      const prev = tokens.take().?;

      const name = tokens.expect(.ident) orelse {
        if (errors) |e| {
          if (tokens.peek(0)) |next| {
            try e.format(tokens.slice[0].span, "Expected identifier, found {f}", .{next});
          } else {
            try e.format(prev.span, "Expected identifier, found EOF", .{});
          }
        }
        tokens.* = start;
        return null;
      };

      if (tokens.peek(0) == null) {
        tokens.* = start;
        if (errors) |e| {
          try e.format(last orelse @panic("Unkown location"), "Expected = or :, found EOF", .{});
        }
        return null;
      }

      // Parse type hint
      const type_expr = if (tokens.peek(0).? == .colon) hint: {
        _ = tokens.take();
        break :hint try self.parseExprAlloc(tokens, errors) orelse {
          tokens.* = start;
          return null;
        };
      } else null;

      if (tokens.peek(0) == null) {
        if (errors) |e| {
          try e.format(last orelse @panic("Unkown location"), "Expected =, found EOF", .{});
        }
        tokens.* = start;
        return null;
      }

      if (tokens.peek(0).? != .equals) {
        if (errors) |e| {
          try e.format(tokens.slice[0].span, "Expected =, found {f}", .{tokens.peek(0).?});
        }
        tokens.* = start;
        return null;
      } else {
        _ = tokens.take();
      }

      const expr = try self.parseExprAlloc(tokens, errors) orelse {
        tokens.* = start;
        return null;
      };

      const semi = tokens.take() orelse {
        if (errors) |e| {
          try e.format(last orelse @panic("Unkown location"), "Expected ;, found EOF", .{});
        }
        tokens.* = start;
        return null;
      };

      if (semi.value != .semi) {
        if (errors) |e| {
          try e.format(semi.span, "Expected ;, found {f}", .{semi.value});
        }
        tokens.* = start;
        return null;
      }

      return ast.Stmt{
        .let = .{
          .name = name,
          .type = type_expr,
          .expr = expr,
        },
      };
    },
    
    else => {
      const start = tokens.*;

      const expr = try self.parseExpr(tokens, errors) orelse {
        tokens.* = start;
        return null;
      };

      const semi = tokens.take() orelse {
        if (errors) |e| {
          try e.format(last orelse @panic("Unkown location"), "Expected ;, found EOF", .{});
        }
        tokens.* = start;
        return null;
      };

      if (semi.value != .semi) {
        if (errors) |e| {
          try e.format(semi.span, "Expected ;, found {f}", .{semi.value});
        }
        tokens.* = start;
        return null;
      }

      return ast.Stmt{
        .expr = expr,
      };
    },
  }
}

pub fn parseEvaluation(
  self: *Parser,
  tokens: *Tokens,
  errors: ?*Errors
) Error!?ast.Evaluation {
  const start = tokens.*;

  var stmts = std.ArrayList(ast.Stmt).init(self.ast_alloc);
  errdefer stmts.deinit();

  while (try self.probe(parseStmt, tokens)) |loc| {
    tokens.* = loc;
    const stmt = try self.parseStmt(tokens, errors);
    try stmts.append(stmt.?);
  }

  if (tokens.slice.len == 0) {
    return ast.Evaluation{
      .stmts = try stmts.toOwnedSlice(),
      .expr = null,
    };
  }

  if (try self.probe(parseExpr, tokens)) |last_stmt| {
    if (tokens.slice.len == 0) {
      tokens.* = last_stmt;

      return ast.Evaluation{
        .stmts = try stmts.toOwnedSlice(),
        .expr = try self.parseExprAlloc(tokens, errors) orelse unreachable,
      };
    }

    tokens.* = last_stmt;

    // report errors for a statement
    _ = try self.parseStmt(tokens, errors);
    tokens.* = start;
    return null;
  }

  // report errors for an expression
  _ = try self.parseExpr(tokens, errors);
  tokens.* = start;
  return null;
}

test {
  std.testing.refAllDecls(@This());
}
