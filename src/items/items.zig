const std = @import("std");
const Allocator = std.mem.Allocator;
pub const Challenge = @import("Challenge.zig");

pub const SimpleText = struct {
    text: []const u8,
    text_type: TextType,

    pub fn init(gpa: Allocator, text_type: TextType, text: []const u8) !@This() {
        const max_len = if (text_type == TextType.subtitle) 35 else 150;

        if (text.len > max_len) return error.TextTooLong;

        return .{
            .text = try gpa.dupe(u8, text),
            .text_type = text_type,
        };
    }

    pub fn deinit(self: @This(), gpa: Allocator) void {
        gpa.free(self.text);
    }
};

pub const TextType = enum {
    subtitle,
    text,
    note,
    warning,
    caution,
};
