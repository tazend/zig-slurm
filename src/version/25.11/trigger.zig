const std = @import("std");
const time_t = std.posix.time_t;
const slurm = @import("root.zig");
const CStr = slurm.CStr;
const c = slurm.c;
const common = slurm.common;
const Error = slurm.Error;
const err = slurm.err;

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

    pub const Type = enum(u32) {

    };

    pub const LoadResponse = extern struct {
        count: u32 = 0,
        items: ?[*]Trigger = null,

        pub fn deinit(self: *LoadResponse) void {
            c.slurm_free_trigger_msg(self);
        }
        pub const Iterator = common.LoadResponseIterator(Trigger);

        const methods = common.LoadResponseMethods(Trigger);
        pub const iter = methods.iter;
        pub const get = methods.get;
        pub const toSlice = methods.toSlice;

        pub fn find(self: *LoadResponse, id: u32) ?*Trigger {
            var itr = self.iter();
            while (itr.next()) |item| {
                if (item.trig_id == id) return item;
            }
            return null;
        }
    };
};

pub fn load() Error!*Trigger.LoadResponse {
    var resp: ?*Trigger.LoadResponse = null;
    try err.checkRpc(c.slurm_get_triggers(&resp));
    return if (resp) |r|
        r
    else
        error.Generic;
}
