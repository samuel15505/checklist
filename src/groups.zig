const std = @import("std");
const Allocator = std.mem.Allocator;

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

    pub fn addChecklist(self: *@This(), allocator: Allocator, checklist: Checklist) !void {
        try self.checklists.append(allocator, checklist);
    }

    pub fn delChecklist(self: *@This(), allocator: Allocator, index: usize) void {
        var checklist = self.checklists.orderedRemove(index);
        checklist.deinit(allocator);
    }

    pub fn newChecklist(self: *@This(), allocator: Allocator, name: []const u8) !void {
        const checklist = try Checklist.new(allocator, name);
        try self.addChecklist(allocator, checklist);
    }
};
