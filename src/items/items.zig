const std = @import("std");
const Allocator = std.mem.Allocator;
pub const Challenge = @import("Challenge.zig");
pub const SimpleText = @import("SimpleText.zig");

const Item = union(enum) {
    challenge: Challenge,
    text: SimpleText,

    const ItemType = enum {
        CHALLENGE,
        SUBTITLE,
        TEXT,
        NOTE,
        WARNING,
        CAUTION,
    };

    pub fn jsonParse(allocator: Allocator, source: anytype, options: std.json.ParseOptions) !@This() {
        const I = struct {
            type: ItemType,
            text: []const u8,
            comment: []const u8,
            response: []const u8,
        };

        const value: I = try std.json.innerParse(I, allocator, source, options);

        switch (value.type) {
            .CHALLENGE => {
                return .{ .challenge = Challenge{
                    .title = value.text,
                    .description = value.comment,
                    .response = value.response,
                } };
            },
            else => {
                return .{ .text = SimpleText{ .text = value.text, .text_type = switch (value.type) {
                    .SUBTITLE => .subtitle,
                    .TEXT => .text,
                    .NOTE => .note,
                    .WARNING => .warning,
                    .CAUTION => .caution,
                    else => unreachable,
                } } };
            },
        }
    }
};

test "item parse" {
    const alloc = std.testing.allocator;

    const challenge_data =
        \\{
        \\   "type": "CHALLENGE",
        \\   "text": "Challenge item - Title max lenght 40",
        \\   "comment": "This is the place to describe your item action and response - Max length 100",
        \\   "response": "Response - Max length 40"
        \\}
    ;

    const expected_challenge: Item = .{ .challenge = .{
        .title = "Challenge item - Title max lenght 40",
        .description = "This is the place to describe your item action and response - Max length 100",
        .response = "Response - Max length 40",
    } };

    const title_data =
        \\{
        \\    "type": "SUBTITLE",
        \\    "text": "Subtitle item - Max length 35",
        \\    "comment": "",
        \\    "response": ""
        \\}
    ;

    const expected_title: Item = .{ .text = .{
        .text_type = .subtitle,
        .text = "Subtitle item - Max length 35",
    } };

    const parsed_challenge: std.json.Parsed(Item) = try std.json.parseFromSlice(Item, alloc, challenge_data, .{});
    defer parsed_challenge.deinit();

    try std.testing.expectEqualDeep(expected_challenge, parsed_challenge.value);

    const parsed_title: std.json.Parsed(Item) = try std.json.parseFromSlice(Item, alloc, title_data, .{});
    defer parsed_title.deinit();

    try std.testing.expectEqualDeep(expected_title, parsed_title.value);
}
