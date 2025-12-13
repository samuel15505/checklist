const std = @import("std");
const testing = std.testing;

pub const checkfile = @import("checkfile.zig");

test {
    testing.refAllDeclsRecursive(@This());
}
