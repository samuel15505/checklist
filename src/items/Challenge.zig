const std = @import("std");
const Allocator = std.mem.Allocator;
const testing = std.testing;
const json = std.json;
const Value = json.Value;

title: []const u8,
description: []const u8,
response: []const u8,

pub const CreationError = error{
    TitleTooLong,
    DescriptionTooLong,
    ResponseTooLong,
    OutOfMemory,
};

pub fn new(gpa: Allocator, title: []const u8, description: []const u8, response: []const u8) CreationError!@This() {
    if (title.len > 40) return error.TitleTooLong;
    if (description.len > 100) return error.DescriptionTooLong;
    if (response.len > 40) return error.ResponseTooLong;

    const this_title = try gpa.dupe(u8, title);
    errdefer gpa.free(this_title);

    const this_description = try gpa.dupe(u8, description);
    errdefer gpa.free(this_description);

    const this_response = try gpa.dupe(u8, response);
    errdefer gpa.free(this_response);

    return .{
        .title = this_title,
        .description = this_description,
        .response = this_response,
    };
}

pub fn deinit(self: @This(), gpa: Allocator) void {
    gpa.free(self.title);
    gpa.free(self.description);
    gpa.free(self.response);
}

pub fn jsonParse(allocator: Allocator, source: anytype, options: json.ParseOptions) json.ParseError(@TypeOf(source.*))!@This() {
    const I = struct {
        type: []const u8,
        text: []const u8,
        comment: []const u8,
        response: []const u8,
    };

    const tmp: I = try json.innerParse(I, allocator, source, options);
    // const value = tmp.value;

    return .{
        .title = tmp.text,
        .description = tmp.comment,
        .response = tmp.response,
    };
}

pub fn format(
    self: @This(),
    writer: *std.Io.Writer,
) std.Io.Writer.Error!void {
    try writer.print("Challenge:\n- {s}\n- {s}\n- {s}", .{ self.title, self.description, self.response });
}

test "create new" {
    const title = "Check airspeed";
    const description = "Read airspeed and state 80 knots when speed reached";
    const response = "80 knots";

    const alloc = testing.allocator;

    const challenge = try new(alloc, title, description, response);
    defer challenge.deinit(alloc);

    const expected = @This(){
        .title = &title.*,
        .description = &description.*,
        .response = &response.*,
    };

    try std.testing.expectEqualDeep(expected, challenge);
}

test "leak test" {
    const title = [_]u8{'t'} ** 40;
    const description = [_]u8{'d'} ** 100;
    const response = [_]u8{'r'} ** 40;

    var failing_alloc = testing.FailingAllocator.init(testing.allocator, .{ .fail_index = 1 });
    const alloc = failing_alloc.allocator();

    const res = new(alloc, &title, &description, &response);

    try testing.expectError(error.OutOfMemory, res);
}

test "jsonParse" {
    const alloc = testing.allocator;
    const data =
        \\{
        \\   "type": "CHALLENGE",
        \\   "text": "Challenge item - Title max lenght 40",
        \\   "comment": "This is the place to describe your item action and response - Max length 100",
        \\   "response": "Response - Max length 40"
        \\}
    ;

    const expected = @This(){
        .title = "Challenge item - Title max lenght 40",
        .description = "This is the place to describe your item action and response - Max length 100",
        .response = "Response - Max length 40",
    };

    const parsed: json.Parsed(@This()) = try json.parseFromSlice(@This(), alloc, data, .{});
    defer parsed.deinit();

    const value = parsed.value;

    try testing.expectEqualDeep(expected, value);
}
