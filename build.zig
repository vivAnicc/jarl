const std = @import("std");

const Interpreter = struct {
  pub const Parser = struct {
    self: *std.Build.Module,
    ast: *std.Build.Module,
  };

  self: *std.Build.Module,
  parser: Parser,
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    
    const tokenizer = b.addModule("tokenizer", .{
        .root_source_file = b.path("src/tokenizer.zig"),
        .target = target,
        .optimize = optimize,
    });

    const interpreter = make_interpreter(b, target, optimize, tokenizer);

    const exe = b.addExecutable(.{
        .name = "jarl",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "tokenizer", .module = tokenizer },
                .{ .name = "interpreter", .module = interpreter.self },
            },
        }),
    });

    b.installArtifact(exe);
    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const tokenizer_tests = add_tests(b, tokenizer);
    const interpreter_tests = add_tests(b, interpreter.self);
    const interpreter_parser_tests = add_tests(b, interpreter.parser.self);
    const interpreter_parser_ast_tests = add_tests(b, interpreter.parser.ast);
    const exe_tests = add_tests(b, exe.root_module);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&tokenizer_tests.step);
    test_step.dependOn(&interpreter_tests.step);
    test_step.dependOn(&interpreter_parser_tests.step);
    test_step.dependOn(&interpreter_parser_ast_tests.step);
    test_step.dependOn(&exe_tests.step);
}

fn add_tests(
  b: *std.Build,
  module: *std.Build.Module,
) *std.Build.Step.Run {
  const compile = b.addTest(.{
    .root_module = module,
  });
  return b.addRunArtifact(compile);
}

fn make_interpreter(
  b: *std.Build,
  target: std.Build.ResolvedTarget,
  optimize: std.builtin.OptimizeMode,
  tokenizer: *std.Build.Module,
) Interpreter {
  const ast = b.addModule("ast", .{
    .root_source_file = b.path("src/interpreter/parser/ast.zig"),
    .target = target,
    .optimize = optimize,
    .imports = &.{
      .{
        .name = "tokenizer",
        .module = tokenizer,
      },
    },
  });
  const parser = b.addModule("parser", .{
    .root_source_file = b.path("src/interpreter/parser.zig"),
    .target = target,
    .optimize = optimize,
    .imports = &.{
      .{
        .name = "tokenizer",
        .module = tokenizer,
      },
      .{
        .name = "ast",
        .module = ast,
      },
    },
  });
  const interpreter = b.addModule("interpreter", .{
    .root_source_file = b.path("src/interpreter.zig"),
    .target = target,
    .optimize = optimize,
    .imports = &.{
      .{
        .name = "tokenizer",
        .module = tokenizer,
      },
      .{
        .name = "parser",
        .module = parser,
      },
    },
  });
  return Interpreter{
    .self = interpreter,
    .parser = .{
      .self = parser,
      .ast = ast,
    },
  };
}
