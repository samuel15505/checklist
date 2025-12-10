const std = @import("std");
const Allocator = std.mem.Allocator;

pub const CheckFile = struct {
    contents: Groups,
    allocator: Allocator,
};

pub const Groups = struct {
    groups: []Group,
};

pub const Group = struct {
    name: []const u8,
    checklists: []Checklist,
};

pub const Checklist = struct {
    name: []const u8,
    items: []Item,
};

pub const Item = struct {
    item_type: ItemType,
    text: []const u8,
    comment: []const u8,
    response: []const u8,

    pub fn new(allocator: Allocator, item_type: ItemType, text: []const u8, comment: []const u8, response: []const u8) !@This() {
        const fields = [_]std.ArrayList(u8){.empty} ** 3;
        errdefer {
            for (fields) |field| {
                field.deinit(allocator);
            }
        }

        try fields[0].appendSlice(allocator, text);
        try fields[1].appendSlice(allocator, comment);
        try fields[2].appendSlice(allocator, response);

        return .{
            .item_type = item_type,
            .text = try fields[0].toOwnedSlice(allocator),
            .comment = try fields[1].toOwnedSlice(allocator),
            .response = try fields[2].toOwnedSlice(allocator),
        };
    }

    pub fn deinit(self: *@This(), allocator: Allocator) void {
        allocator.free(self.text);
        allocator.free(self.comment);
        allocator.free(self.response);
    }
};

pub const ItemType = enum {
    challenge,
    subtitle,
    text,
    note,
    warning,
    caution,
};
