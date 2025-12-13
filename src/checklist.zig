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
        // allocator.free(self.items);
        self.items.deinit(allocator);
    }

    pub fn append(self: *@This(), allocator: Allocator, item: Item) !void {
        // self.items = try allocator.realloc(self.items, self.items.len + 1);
        // self.items[self.items.len - 1] = item;
        try self.items.append(allocator, item);
    }

    pub fn remove(self: *@This(), allocator: Allocator, i: usize) void {
        // self.items[i].deinit(allocator);
        // for (i..self.items.len - 1) |j| {
        //     self.items[j] = self.items[j + 1];
        // }
        // self.items.len -= 1;
        var removed = self.items.orderedRemove(i);
        removed.deinit(allocator);
    }

    pub fn newChallenge(self: *@This(), allocator: Allocator, title: []const u8, description: []const u8, response: []const u8) !void {
        const item: Item = .{ .challenge = try .new(allocator, title, description, response) };
        try self.append(allocator, item);
    }

    pub fn newText(self: *@This(), allocator: Allocator, item_type: ItemType, text: []const u8) !void {
        const item: Item = .{ .text = try .new(allocator, item_type, text) };
        try self.append(allocator, item);
    }

    pub fn insert(self: *@This(), allocator: Allocator, index: usize, item: Item) !void {
        // const len = self.items.len;
        // self.items = try allocator.realloc(self.items, len + 1);
        // for (index..len) |i| {
        //     self.items[i + 1] = self.items[i];
        // }
        // self.items[index] = item;
        try self.items.insert(allocator, index, item);
    }

    pub fn reorder(self: *@This(), new_pos: usize, index: usize) void {
        // const item = self.items[index];
        // for (new_pos..self.items.len - 1) |i| {
        //     self.items[i + 1] = self.items[i];
        // }
        // self.items[new_pos] = item;

        const item = self.items.orderedRemove(index);
        self.items.insertAssumeCapacity(new_pos, item);
    }

    pub fn jsonParse(allocator: Allocator, source: anytype, options: json.ParseOptions) !@This() {
        const I = struct {
            name: []const u8,
            items: []Item,
        };

        const inner: I = try json.innerParse(I, allocator, source, options);

        return .{
            .name = inner.name,
            .items = .fromOwnedSlice(inner.items),
        };
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
            return .{ .challenge = .{ .title = value.text, .description = value.comment, .response = value.response } };
        } else {
            return .{ .text = .{ .item_type = value.type, .text = value.text } };
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

    pub fn clone(self: *@This(), allocator: Allocator) !@This() {
        return try new(allocator, self.item_type, self.text);
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

    try checklist.newText(alloc, .caution, "test caution");
    try checklist.newChallenge(alloc, "test challenge", "subtitle", "response");

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

test "parse checklist" {
    const alloc = testing.allocator;

    const data =
        \\{
        \\  "name": "Test checklist",
        \\  "items": [
        \\      {
        \\          "type": "CHALLENGE",
        \\          "text": "Challenge item - Title max lenght 40",
        \\          "comment": "This is the place to describe your item action and response - Max length 100",
        \\          "response": "Response - Max length 40"
        \\      },
        \\      {
        \\          "type": "SUBTITLE",
        \\          "text": "Subtitle item - Max length 35",
        \\          "comment": "",
        \\          "response": ""
        \\      }
        \\  ]
        \\}
    ;

    const expected = Checklist{
        .name = "Test checklist",
        // @constCast because I trust myself to not modify this, and it is required to create the test data
        .items = .fromOwnedSlice(@constCast(&[_]Item{ Item{ .challenge = .{
            .title = "Challenge item - Title max lenght 40",
            .description = "This is the place to describe your item action and response - Max length 100",
            .response = "Response - Max length 40",
        } }, Item{ .text = .{
            .item_type = ItemType.subtitle,
            .text = "Subtitle item - Max length 35",
        } } })),
    };

    const parsed: json.Parsed(Checklist) = try json.parseFromSlice(Checklist, alloc, data, .{});
    defer parsed.deinit();

    try testing.expectEqualDeep(expected, parsed.value);
}
