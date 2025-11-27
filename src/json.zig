pub const Item = struct {
    type: []const u8,
    text: []const u8,
    comment: []const u8,
    response: []const u8,
};

pub const Checklist = struct {
    name: []const u8,
    items: []const Item,
};

pub const Group = struct {
    name: []const u8,
    checklists: []const Checklist,
};
