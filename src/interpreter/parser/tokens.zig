const std = @import("std");
const Token = @import("tokenizer").Token;
const Parser = @import("../parser.zig");

const Tokens = @This();

slice: []const Token,

pub fn new(slice: []const Token) Tokens {
  if (slice.len != 0)
    Parser.last = slice[0].span;
  return Tokens{ .slice = slice };
}

pub fn peek(tokens: *const Tokens, offset: usize) ?Token.Value {
  if (tokens.slice.len <= offset)
    return null;
  return tokens.slice[offset].value;
}

pub fn take(tokens: *Tokens) ?Token {
  if (tokens.slice.len == 0)
    return null;
  const token = tokens.slice[0];
  tokens.slice = tokens.slice[1..];
  Parser.last = token.span;
  return token;
}

pub fn expect(self: *Tokens, comptime tag: Token.Type)
  ?@FieldType(Token.Value, @tagName(tag)) {
  const next = self.peek(0) orelse return null;

  if (next == tag) {
    _ = self.take();
    return @field(next, @tagName(tag));
  }

  return null;
}
