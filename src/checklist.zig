const std = @import("std");
const Allocator = std.mem.Allocator;
const testing = std.testing;
const json = std.json;
const Value = json.Value;

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

    pub fn addText(self: *@This(), allocator: Allocator, item_type: ItemType, text: []const u8) !void {
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

    pub fn jsonParse(allocator: Allocator, source: anytype, options: json.ParseOptions) !@This() {
        const I = struct {
            type: ItemType,
            text: []const u8,
            comment: []const u8,
            response: []const u8,
        };

        const value: I = try json.innerParse(I, allocator, source, options);

        if (value.type == .challenge) {
            return .{ .challenge = try Challenge.new(allocator, value.text, value.comment, value.response) };
        } else {
            return .{ .text = try Text.new(allocator, value.type, value.text) };
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

    pub fn validate(self: *@This()) bool {
        if (self.item_type == .subtitle) {
            return self.len <= 35;
        } else {
            return self.len <= 150;
        }
    }
};

pub const ItemType = enum {
    challenge,
    subtitle,
    text,
    note,
    warning,
    caution,

    pub fn jsonParse(allocator: Allocator, source: anytype, options: json.ParseOptions) json.ParseError(@TypeOf(source.*))!@This() {
        // const k_t: json.Token = try source.nextAllocMax(allocator, options.allocate.?, options.max_value_len.?);

        // const key: []const u8 = switch (k_t) {
        //     .string => |s| s,
        //     .allocated_string => |s| {
        //         defer allocator.free(s);
        //         s;
        //     },
        //     else => return error.InvalidType,
        // };

        // if (!std.mem.eql(u8, key, "type")) return error.InvalidKey;

        const v_t = try source.nextAllocMax(allocator, options.allocate.?, options.max_value_len.?);

        switch (v_t) {
            .string => |s| return fromSlice(s) catch |err| switch (err) {
                error.InvalidValue => json.ParseFromValueError.InvalidEnumTag,
            },
            .allocated_string => |s| {
                defer allocator.free(s);
                return fromSlice(s) catch |err| switch (err) {
                    error.InvalidValue => json.ParseFromValueError.InvalidEnumTag,
                };
            },
            else => return json.ParseFromValueError.InvalidEnumTag,
        }

        // return fromSlice(value);
    }

    fn fromSlice(s: []const u8) !@This() {
        const keys = [_][]const u8{
            "CHALLENGE",
            "SUBTITLE",
            "TEXT",
            "NOTE",
            "WARNING",
            "CAUTION",
        };

        for (keys, 0..) |key, i| {
            if (std.mem.eql(u8, s, key)) {
                switch (i) {
                    0 => return .challenge,
                    1 => return .subtitle,
                    2 => return .text,
                    3 => return .note,
                    4 => return .warning,
                    5 => return .caution,
                    else => unreachable,
                }
            }
        }

        return error.InvalidValue;
    }
};

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

test "parse item type" {
    const alloc = testing.allocator;

    const I = struct { type: ItemType };

    const data =
        \\{
        \\  "type": "CHALLENGE"
        \\}
    ;

    const expected = I{ .type = .challenge };
    const parsed: json.Parsed(I) = try json.parseFromSlice(I, alloc, data, .{});
    defer parsed.deinit();

    try testing.expectEqual(expected, parsed.value);
}

test "parse item" {
    const alloc = testing.allocator;

    const data =
        \\{
        \\"type": "CHALLENGE",
        \\"text": "Challenge item - Title max lenght 40",
        \\"comment": "This is the place to describe your item action and response - Max length 100",
        \\"response": "Response - Max length 40"
        \\}
    ;

    const expected: Item = .{ .challenge = .{
        .title = "Challenge item - Title max lenght 40",
        .description = "This is the place to describe your item action and response - Max length 100",
        .response = "Response - Max length 40",
    } };

    const parsed: json.Parsed(Item) = try json.parseFromSlice(Item, alloc, data, .{});
    defer parsed.deinit();

    try testing.expectEqualDeep(expected, parsed.value);
}
