const std = @import("std");
pub const items = @import("items/items.zig");
pub const Group = @import("Group.zig");
pub const Checklist = @import("Checklist.zig");
const Allocator = std.mem.Allocator;

pub const CheckFile = struct {
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

    pub fn addGroup(self: @This(), group: Group) !void {
        try self.groups.append(self.gpa, group);
    }

    pub fn newGroup(self: *@This(), name: []const u8) !void {
        const group = try Group.init(self.gpa, name);
        try self.groups.append(self.gpa, group);
    }

    pub fn getGroup(self: *@This(), name: []const u8) ?*Group {
        for (self.groups.items) |group| {
            if (std.mem.eql(u8, group.name, name)) {
                return &group;
            }
            return null;
        }
    }
};

test {
    std.testing.refAllDeclsRecursive(@This());
}
