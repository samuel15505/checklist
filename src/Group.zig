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

pub fn deinit(self: *@This()) void {
    for (self.checklists.items) |*checklist| {
        checklist.deinit();
    }

    self.checklists.deinit(self.gpa);
    self.gpa.free(self.name);
}

pub fn addChecklist(self: *@This(), checklist: Checklist) !void {
    try self.checklists.append(self.gpa, checklist);
}

pub fn newChecklist(self: *@This(), name: []const u8) !void {
    const checklist = try Checklist.init(self.gpa, name);
    try self.addChecklist(checklist);
}

pub fn format(
    self: @This(),
    writer: *std.Io.Writer,
) std.Io.Writer.Error!void {
    try writer.writeAll(self.name);

    for (self.checklists.items, 0..) |checklist, i| {
        try writer.print("\n{}. {s}", .{ i, checklist.name });
    }
}
