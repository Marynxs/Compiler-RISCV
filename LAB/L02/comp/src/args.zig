const std = @import("std");

pub const Config = struct {
    help: bool = false,
    verbose: bool = false,
};

pub fn configParser(args: []const [:0]const u8) !Config {
    var config = Config{};

    if (args.len == 1) {
        config.help = true;
        return config;
    }

    var i: usize = 1;

    std.debug.print("# de argumentos: {d}\n", .{args.len});

    while (i < args.len) : (i += 1) {
        const arg = args[i];

        std.debug.print("Arg [{d}] = {s}\n", .{ i, arg });

        if (std.mem.startsWith(u8, arg, "-")) {
            const option = arg[1];

            std.debug.print("Option: {c}\n", .{option});

            switch (option) {
                'h' => config.help = true,
                'v' => config.verbose = true,
                else => {},
            }
        }
    }

    return config;
}
