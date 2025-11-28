const std = @import("std");
const lib = @import("libchecklist");

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}).init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();
    _ = alloc;
    // var exit = false;

    var out_buf: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&out_buf);
    var stdout = &stdout_writer.interface;

    var in_buf: [4096]u8 = undefined;
    var stdin_reader = std.fs.File.stdin().reader(&in_buf);
    const stdin = &stdin_reader.interface;

    try stdout.writeAll("Checklist CLI: (n) for new checklist, (q) to quit: \n");
    try stdout.flush();

    // var input: []const u8 = undefined;

    // var checkfile: lib.CheckFile = .init(alloc);

    while (true) {
        if (try stdin.takeDelimiter('\n')) |input| {
            const trim = std.mem.trim(u8, input, "\r");

            if (std.mem.eql(u8, trim, "q")) {
                break;
            }

            if (std.mem.eql(u8, trim, "n")) {
                std.debug.print("todo(new)\n", .{});
            }
        }
    }

    try stdout.writeAll("Cleaning up...\n");
    try stdout.flush();
}

test {
    _ = std.testing.refAllDeclsRecursive(lib);
}

const Command = enum {
    open,
    close,
    new,
    select,
    quit,
    help,
};

const Target = enum {
    group,
    checklist,
    item,
};

const Input = struct {
    command: Command,
    target: Target,
};
