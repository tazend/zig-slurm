const std = @import("std");

pub const CStr = [*:0]const u8;
pub const BitString = i64;
pub const NoValue = struct {
    pub const @"u8": u8 = (1 << 8) - 2;
    pub const @"u16": u16 = (1 << 16) - 2;
    pub const @"u32": u32 = (1 << 32) - 2;
    pub const @"u64": u64 = (1 << 64) - 2;
};

pub const Infinite = struct {
    pub const @"u8": u8 = (1 << 8) - 1;
    pub const @"u16": u16 = (1 << 16) - 1;
    pub const @"u32": u32 = (1 << 32) - 1;
    pub const @"u64": u64 = (1 << 64) - 1;
};

pub fn parseCStr(s: ?[*:0]u8) ?[]const u8 {
    if (s == null) return null;
    return std.mem.span(s);
}

pub fn parseCStrZ(s: ?[*:0]u8) ?[:0]const u8 {
    if (s == null) return null;
    return std.mem.span(s);
}

pub fn BitflagMethods(comptime T: type, comptime E: type) type {
    return struct {
        fn maxStrSize(comptime sep: []const u8) comptime_int {
            var max_size = 0;
            for (std.meta.fields(T)) |f| {
                if (f.type == bool) max_size += f.name.len + sep.len;
            }

            return max_size - sep.len;
        }

        pub fn toStr(self: T, allocator: std.mem.Allocator, comptime sep: []const u8) ![]const u8 {
            const max_size = comptime maxStrSize(sep);
            var result: [max_size]u8 = undefined;
            var bytes: usize = 0;
            inline for (std.meta.fields(T)) |f| {
                if (f.type == bool and @as(f.type, @field(self, f.name))) {
                    if (bytes == 0) {
                        @memcpy(result[0..f.name.len], f.name);
                        bytes += f.name.len;
                    } else {
                        @memcpy(result[bytes..][0..sep.len], sep);
                        bytes += sep.len;
                        @memcpy(result[bytes..][0..f.name.len], f.name);
                        bytes += f.name.len;
                    }
                }
            }

            if (bytes == 0) return "";
            return try allocator.dupe(u8, result[0..bytes]);
        }

        pub fn equal(a: T, b: T) bool {
            return @as(E, @bitCast(a)) == @as(E, @bitCast(b));
        }
    };
}
