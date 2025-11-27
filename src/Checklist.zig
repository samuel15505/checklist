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

pub fn deinit(self: *@This()) void {
    for (self.items.items) |*item| {
        switch (item.*) {
            .challenge => |c| c.deinit(self.allocator),
            .text => |c| c.deinit(self.allocator),
        }
    }
    self.items.deinit(self.allocator);
    self.allocator.free(self.name);
}

pub fn addItem(self: *@This(), item: Item) !void {
    try self.items.append(self.allocator, item);
}
