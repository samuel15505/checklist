const std = @import("std");
const Allocator = std.mem.Allocator;
const testing = std.testing;

const checklib = @import("checklist.zig");
const Checklist = checklib.Checklist;

pub const Groups = struct {
    groups: std.ArrayList(Group) = .empty,
};

pub const Group = struct {
    name: []const u8,
    checklists: std.ArrayList(Checklist) = .empty,

    pub fn new(allocator: Allocator, name: []const u8) !Group {
        return .{
            .name = try allocator.dupe(u8, name),
        };
    }

    pub fn deinit(self: *@This(), allocator: Allocator) void {
        allocator.free(self.name);
        for (self.checklists.items) |*checklist| {
            checklist.deinit(allocator);
        }
        self.checklists.deinit(allocator);
    }

    pub fn append(self: *@This(), allocator: Allocator, checklist: Checklist) !void {
        // self.checklists = try allocator.realloc(self.checklists, self.checklists.len + 1);
        // self.checklists[self.checklists.len - 1] = checklist;
        try self.checklists.append(allocator, checklist);
    }

    pub fn remove(self: *@This(), allocator: Allocator, index: usize) void {
        var checklist = self.checklists.orderedRemove(index);
        checklist.deinit(allocator);
    }

    pub fn newChecklist(self: *@This(), allocator: Allocator, name: []const u8) !void {
        const checklist = try Checklist.new(allocator, name);
        try self.append(allocator, checklist);
    }
};

test "new checklist" {
    // const Item = @import("checklist.zig").Checklist;
    const alloc = testing.allocator;

    const expected = Group{
        .name = "test group",
        .checklists = .fromOwnedSlice(@constCast(&[_]Checklist{
            Checklist{
                .name = "test checklist",
                .items = .empty,
            },
        })),
    };

    var group: Group = try .new(alloc, "test group");
    defer group.deinit(alloc);

    try group.newChecklist(alloc, "test checklist");

    try testing.expectEqualSlices(Checklist, expected.checklists.items, group.checklists.items);
    try testing.expectEqualStrings(expected.name, group.name);
}
