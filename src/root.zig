const std = @import("std");
const testing = std.testing;
pub const checklists = @import("checklists.zig");

test {
    testing.refAllDeclsRecursive(@This());
}