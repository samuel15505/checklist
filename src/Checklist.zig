const std = @import("std");
const check_items = @import("items/items.zig");

name: []const u8,
items: std.ArrayList(Item),

const Item = union(enum) {
    challenge: check_items.Challenge,
    text: check_items.SimpleText,
};
