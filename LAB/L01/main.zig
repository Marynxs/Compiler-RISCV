const std = @import("std");
const print = std.debug.print;

const FILESTD = "zig.txt";

fn processFiles(io: std.Io, args: []const []const u8) !void {
    const args_quantity = args.len;
    
    if (args_quantity < 2) {
        print("Usage: {s} <file1> <file2> ...\n", .{args[0]});
        return;
    }

    for (1..args_quantity) |i| {
        const filename = args[i];
        const file = try std.Io.Dir.cwd().openFile(io, filename, .{});
        defer file.close(io);

        var file_buffer: [4096]u8 = undefined;
        var reader = file.reader(io, &file_buffer);
        var line_no: usize = 0;

        while (try reader.interface.takeDelimiter('\n')) |line| {
            line_no += 1;
            std.debug.print("Line {d}: {s}\n", .{line_no, line});
        }
    }
}


pub fn main(init: std.process.Init) !void {

    //const gpa = init.gpa;
    
    const io = init.io;
    //const gpa = init.gpa;

    const args = try init.minimal.args.toSlice(init.arena.allocator());


    //const filename = if (arfs.len == 2) args[1].?

    try processFiles(io, args);

    //var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    //const stdout = &stdout_writer.interface;
    //defer stdout.flush();

    //while (try reader.interface.takeDelimiter('\n')) |line| {
      //  line_no += 1;
        //print("Line {d}: {s}\n", .{line_no, line});
    //}

    //print( "total de linhas: {d}\n", .{line_no});

    //try stdout.print("ola mundo \n", .{});
    //

    //for (10..80) |i| {
    //    try stdout.print("{d}\n", .{i});
    //}

}
