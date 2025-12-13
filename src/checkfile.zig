const std = @import("std");
const Allocator = std.mem.Allocator;

const groupslib = @import("groups.zig");
const Groups = groupslib.Groups;

pub const CheckFile = struct {
    contents: Groups,
    allocator: Allocator,
};
