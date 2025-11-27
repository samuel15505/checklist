const std = @import("std");
pub const items = @import("items/items.zig");
pub const Group = @import("Group.zig");
const Allocator = std.mem.Allocator;

const CheckFile = struct {
    groups: std.ArrayList(Group),
    gpa: Allocator,

    pub fn init(gpa: Allocator) @This() {
        return .{
            .groups = .empty,
            .gpa = gpa,
        };
    }

    pub fn deinit(self: @This()) void {
        for (self.groups.items) |group| {
            group.deinit();
        }

        self.groups.deinit(self.gpa);
    }
};

test {
    std.testing.refAllDeclsRecursive(@This());
}
