const std = @import("std");
const time_t = std.posix.time_t;
const slurm = @import("root.zig");

pub const License = extern struct {
    name: ?CStr = null,
    total: u32 = 0,
    in_use: u32 = 0,
    available: u32 = 0,
    remote: u8 = 0,
    reserved: u32 = 0,
    last_consumed: u32 = 0,
    last_deficit: u32 = 0,
    last_update: time_t = 0,
    mode: u8 = 0,
    nodes: ?CStr = null,

    pub const LoadResponse = extern struct {
        last_update: time_t = 0,
        count: u32 = 0,
        items: ?[*]License = null,
    };
};
