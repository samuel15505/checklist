const std = @import("std");
const Allocator = std.mem.Allocator;

pub const CheckFile = struct {
    contents: Groups,
    allocator: Allocator,
};

pub const Groups = struct {
    groups: std.ArrayList(Group) = .empty,
};

pub const Group = struct {
    name: []const u8,
    checklists: std.ArrayList(Checklist) = .empty,
};

pub const Checklist = struct {
    name: []const u8,
    items: std.ArrayList(Item) = .empty,
};

pub const Item = union(enum) {
    challenge: *Challenge,
    text: *Text,
};

const Challenge = struct {
    title: []const u8,
    description: []const u8,
    response: []const u8,

    pub fn new(allocator: Allocator, title: []const u8, description: []const u8, response: []const u8) !Challenge {
        var challenge: Challenge = undefined;
        challenge.title = try allocator.dupe(u8, title);
        errdefer allocator.free(challenge.title);

        challenge.description = try allocator.dupe(u8, description);
        errdefer allocator.free(challenge.description);

        challenge.response = try allocator.dupe(u8, response);

        return challenge;
    }

    pub fn deinit(self: *@This(), allocator: Allocator) void {
        for (@typeInfo(@This()).@"struct".fields) |field| {
            allocator.free(@field(self, field.name));
        }
    }

    pub fn validate(self: *const @This()) bool {
        return self.title.len <= 40 and self.description.len <= 100 and self.response.len <= 40;
    }

    pub fn trySetTitle(self: *@This(), allocator: Allocator, title: []const u8) !void {
        if (title.len <= 40) {
            self.title = try allocator.dupe(u8, title);
        } else {
            return error.TooLong;
        }
    }

    pub fn trySetDescription(self: *@This(), allocator: Allocator, description: []const u8) !void {
        if (description.len <= 100) {
            self.description = try allocator.dupe(u8, description);
        } else {
            return error.TooLong;
        }
    }

    pub fn trySetResponse(self: *@This(), allocator: Allocator, response: []const u8) !void {
        if (response.len <= 40) {
            self.response = try allocator.dupe(u8, response);
        } else {
            return error.TooLong;
        }
    }
};

const Text = struct {
    item_type: ItemType,
    text: []const u8,

    pub fn new(allocator: Allocator, item_type: ItemType, text: []const u8) !Text {
        return .{
            .item_type = item_type,
            .text = try allocator.dupe(u8, text),
        };
    }

    pub fn deinit(self: *@This(), allocator: Allocator) void {
        allocator.free(self.text);
    }

    // pub fn validate(self: *@This()) bool {

    // }
};

pub const ItemType = enum {
    challenge,
    subtitle,
    text,
    note,
    warning,
    caution,
};
