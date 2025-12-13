const std = @import("std");
const Allocator = std.mem.Allocator;

const checklib = @import("checklist.zig");
const Checklist = checklib.Checklist;

pub const Groups = struct {
    groups: std.ArrayList(Group) = .empty,
};

pub const Group = struct {
    name: []const u8,
    checklists: []Checklist = &.{},

    pub fn new(allocator: Allocator, name: []const u8) !Group {
        return .{
            .name = try allocator.dupe(u8, name),
        };
    }

    pub fn deinit(self: *@This(), allocator: Allocator) void {
        allocator.free(self.name);
        for (self.checklists) |*checklist| {
            checklist.deinit(allocator);
        }
        allocator.free(self.checklists);
    }

    pub fn push(self: *@This(), allocator: Allocator, checklist: Checklist) !void {
        self.checklists = try allocator.realloc(self.checklists, self.checklists.len + 1);
        self.checklists[self.checklists.len - 1] = checklist;
    }

    pub fn remove(self: *@This(), allocator: Allocator, index: usize) void {
        var checklist = self.checklists.orderedRemove(index);
        checklist.deinit(allocator);
    }

    pub fn newChecklist(self: *@This(), allocator: Allocator, name: []const u8) !void {
        const checklist = try Checklist.new(allocator, name);
        try self.push(allocator, checklist);
    }
};

test "new checklist" {
    
}
