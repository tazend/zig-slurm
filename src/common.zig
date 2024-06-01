const std = @import("std");

pub inline fn parseCStr(s: ?[*:0]u8) ?[]const u8 {
    if (s == null) return null;
    return std.mem.span(s);
}
