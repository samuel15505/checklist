const std = @import("std");
const Checklist = @import("Checklist.zig");
const Allocator = std.mem.Allocator;

checklists: std.ArrayList(Checklist),
name: []const u8,
gpa: Allocator,

pub fn init(gpa: Allocator, name: []const u8) !@This() {
    return .{
        .name = try gpa.dupe(u8, name),
        .checklists = .empty,
        .gpa = gpa,
    };
}

pub fn deinit(self: @This()) void {
    for (self.checklists.items) |checklist| {
        checklist.deinit();
    }

    self.checklists.deinit(self.gpa);
    self.gpa.free(self.name);
}
