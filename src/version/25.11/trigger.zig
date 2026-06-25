const std = @import("std");
const time_t = std.posix.time_t;
const slurm = @import("root.zig");

pub const Trigger = extern struct {
    flags: u16 = 0,
    trig_id: u32 = 0,
    res_type: u16 = 0,
    res_id: ?CStr = null,
    control_inx: u32 = 0,
    trig_type: u32 = 0,
    offset: u16 = 0,
    user_id: u32 = 0,
    program: ?CStr = null,

    pub const LoadResponse = extern struct {
        count: u32 = 0,
        items: ?[*]Trigger = null,
    };
};
