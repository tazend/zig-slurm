const c = @import("c.zig").c;
const std = @import("std");

const SlurmNoVal = struct {
    pub const @"u8": u8 = c.NO_VAL8;
    pub const @"u16": u16 = c.NO_VAL16;
    pub const @"u32": u32 = c.NO_VAL;
    pub const @"u64": u64 = c.NO_VAL64;
};

const SlurmInfinite = struct {
    pub const @"u8": u8 = c.INFINITE8;
    pub const @"u16": u16 = c.INFINITE16;
    pub const @"u32": u32 = c.INFINITE;
    pub const @"u64": u64 = c.INFINITE64;
};

pub fn parse_uint(comptime T: type, val: T, on_noval: ?T, zero_is_noval: bool) ?T {
    if (val == @field(SlurmNoVal, @typeName(T)) or (val == 0 and zero_is_noval)) {
        return on_noval;
        //    } else if (val == @field(SlurmInfinite, @typeName(T))) {
        //        return ?;
    } else {
        return val;
    }
}

pub fn is_infinite(val: u64) bool {
    return switch (val) {
        inline SlurmInfinite.u8,
        SlurmInfinite.u16,
        SlurmInfinite.u32,
        SlurmInfinite.u64,
        => true,
        else => false,
    };
}

pub inline fn parse_u32(val: u32) ?u32 {
    return parse_uint(u32, val, null, false);
}
