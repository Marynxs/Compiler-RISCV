const std = @import("std");

const cli = @import("args.zig");

const token = @import("token.zig");
const ast = @import("ast.zig");
const parser = @import("parser.zig");
const eval = @import("eval.zig");
const codegen = @import("codegen.zig");

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;

    const args = try init.minimal.args.toSlice(gpa);

    defer gpa.free(args);
    const config = try cli.configParser(args);

    if (config.help) {
        showHelp();
        std.process.exit(0);
    }
    else if (config.verbose) {
        std.debug.print("Modo verboso ativado\n", .{});
        std.process.exit(0);
    }
}

pub fn showHelp() void {
    const msg =
        \\Uso: comp [opções] <arquivo>
        \\
        \\Opções:
        \\  -h, --help     Mostra esta ajuda
        \\ -v, --verbose  Ativa o modo verboso
        \\
    ;
    std.debug.print("{s}\n", .{msg});
}

test "importações" {
    std.testing.refAllDecls(@This());

    _ = token;
    _ = ast;
    _ = parser;
    _ = eval;
}
