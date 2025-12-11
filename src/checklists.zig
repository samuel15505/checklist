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

pub const Checklist = struct {
    name: []const u8,
    items: std.ArrayList(Item) = .empty,

    pub fn new(allocator: Allocator, name: []const u8) !Checklist {
        return .{
            .name = try allocator.dupe(u8, name),
        };
    }

    pub fn deinit(self: *@This(), allocator: Allocator) void {
        allocator.free(self.name);
        for (self.items.items) |*item| {
            item.deinit(allocator);
        }
        self.items.deinit(allocator);
    }

    pub fn addItem(self: *@This(), allocator: Allocator, item: Item) !void {
        try self.items.append(allocator, item);
    }

    pub fn delItem(self: *@This(), allocator: Allocator, i: usize) void {
        var removed = self.items.orderedRemove(i);
        removed.deinit(allocator);
    }

    pub fn addChallenge(self: *@This(), allocator: Allocator, title: []const u8, description: []const u8, response: []const u8) !void {
        const item: Item = .{ .challenge = try .new(allocator, title, description, response) };
        try self.addItem(allocator, item);
    }

    pub fn addText(self: *@This(), allocator: Allocator, item_type: TextType, text: []const u8) !void {
        const item: Item = .{ .text = try .new(allocator, item_type, text) };
        try self.addItem(allocator, item);
    }
};

pub const Item = union(enum) {
    challenge: Challenge,
    text: Text,

    pub fn deinit(self: *@This(), allocator: Allocator) void {
        switch (self.*) {
            .challenge => |*item| item.deinit(allocator),
            .text => |*item| item.deinit(allocator),
        }
    }
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
        allocator.free(self.title);
        allocator.free(self.description);
        allocator.free(self.response);
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
    item_type: TextType,
    text: []const u8,

    pub fn new(allocator: Allocator, item_type: TextType, text: []const u8) !Text {
        return .{
            .item_type = item_type,
            .text = try allocator.dupe(u8, text),
        };
    }

    pub fn deinit(self: *@This(), allocator: Allocator) void {
        allocator.free(self.text);
    }

    pub fn validate(self: *@This()) bool {
        if (self.item_type == .subtitle) {
            return self.len <= 35;
        } else {
            return self.len <= 150;
        }
    }
};

pub const TextType = enum {
    // challenge,
    subtitle,
    text,
    note,
    warning,
    caution,
};

const testing = std.testing;

test "make checklist" {
    const alloc = testing.allocator;

    var expected_items = [_]Item{
        .{ .text = .{ .item_type = .caution, .text = "test caution" } },
        .{ .challenge = .{ .title = "test challenge", .description = "subtitle", .response = "response" } },
    };

    const expected = Checklist{
        .items = .fromOwnedSlice(&expected_items),
        .name = "test checklist",
    };

    var checklist: Checklist = try .new(alloc, "test checklist");
    defer checklist.deinit(alloc);

    try checklist.addText(alloc, .caution, "test caution");
    try checklist.addChallenge(alloc, "test challenge", "subtitle", "response");

    try testing.expectEqualDeep(expected, checklist);
}
