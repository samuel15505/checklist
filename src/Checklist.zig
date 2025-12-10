const std = @import("std");
const Allocator = std.mem.Allocator;
const check_items = @import("items/items.zig");
const Item = check_items.Item;

name: []const u8,
items: std.ArrayList(Item),
allocator: Allocator,

// const Item = union(enum) {
//     challenge: check_items.Challenge,
//     text: check_items.SimpleText,
// };

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

pub fn newChallenge(self: *@This(), title: []const u8, description: []const u8, response: []const u8) !void {
    const item = try Item{ .challenge = .new(self.allocator, title, description, response) };
    try self.addItem(item);
}

pub fn newSimpleText(self: *@This(), text: []const u8, text_type: check_items.SimpleText.TextType) !void {
    const item = try Item{ .text = .init(self.allocator, text_type, text) };
    try self.addItem(item);
}

pub fn format(
    self: @This(),
    writer: *std.Io.Writer,
) std.Io.Writer.Error!void {
    try writer.writeAll(self.name);
    for (self.items.items, 0..) |item, i| {
        try writer.print("\n{}, {f}", .{ i, item });
    }
}
