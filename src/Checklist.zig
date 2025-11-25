const std = @import("std");
const Allocator = std.mem.Allocator;
const check_items = @import("items/items.zig");

name: []const u8,
items: std.ArrayList(Item),
allocator: Allocator,

const Item = union(enum) {
    challenge: check_items.Challenge,
    text: check_items.SimpleText,
};

pub fn init(gpa: Allocator, name: []const u8) !@This() {
    return .{
        .name = try gpa.dupe(u8, name),
        .items = .empty,
        .allocator = gpa,
    };
}

pub fn deinit(self: @This()) void {
    for (self.items) |item| {
        item.deinit(self.allocator);
    }
    self.items.deinit(self.allocator);
    self.allocator.free(self.name);
}
