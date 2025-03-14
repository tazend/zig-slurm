const std = @import("std");
const slurm_allocator = @import("SlurmAllocator.zig").slurm_allocator;

pub inline fn parseCStr(s: ?[*:0]u8) ?[]const u8 {
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

        comptime {
            std.debug.assert(
                @sizeOf(T) == @sizeOf(E) and
                    @bitSizeOf(T) == @bitSizeOf(E),
            );
        }
    };
}

pub const TresString = struct {
    str: []const u8,
    delim1: u8 = ',',
    delim2: u8 = '=',
    _owned: bool = false,

    pub fn iter(self: TresString) std.mem.SplitIterator(u8, .scalar) {
        return std.mem.splitScalar(u8, self.str, self.delim1);
    }

    pub fn init(str: []const u8) TresString {
        return .{
            .str = str,
        };
    }

    pub fn initC(str: ?[*:0]u8) TresString {
        return .{
            .str = parseCStr(str) orelse "",
        };
    }

    //  pub fn initCAssumeNonNull(str: ?[*:0]u8) TresString {
    //      return .{
    //          .str = parseCStr(str).?,
    //      };
    //  }

    pub fn initCOwned(str: ?[*:0]u8) TresString {
        var tres = initC(str);
        tres._owned = true;
        return tres;
    }

    pub fn deinit(self: TresString) void {
        if (self._owned) {
            slurm_allocator.free(self.str);
        }
    }

    pub fn isEmpty(self: TresString) bool {
        return self.str.len == 0;
    }

    pub fn toHashMap(self: TresString, allocator: std.mem.Allocator) !std.StringHashMap([]const u8) {
        var hashmap = std.StringHashMap([]const u8).init(allocator);
        var it = self.iter();
        while (it.next()) |item| {
            var it2 = std.mem.splitScalar(u8, item, self.delim2);
            const k = it2.first();
            const v = it2.rest();
            try hashmap.put(k, v);
        }
        return hashmap;
    }
};
