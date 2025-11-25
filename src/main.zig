const std = @import("std");
const lib = @import("libchecklist");

pub fn main() !void {}

test {
    _ = std.testing.refAllDeclsRecursive(lib);
}
