const std = @import("std");
const time_t = std.posix.time_t;
const slurm = @import("root.zig");
const CStr = slurm.CStr;
const c = slurm.c;
const common = slurm.common;
const Error = slurm.Error;
const err = slurm.err;

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

        pub fn deinit(self: *LoadResponse) void {
            c.slurm_free_license_info_msg(self);
        }
        pub const Iterator = common.LoadResponseIterator(License);

        const methods = common.LoadResponseMethods(License);
        pub const iter = methods.iter;
        pub const get = methods.get;
        pub const toSlice = methods.toSlice;

        pub fn find(self: *LoadResponse, name: [:0]const u8) ?*License {
            var itr = self.iter();
            while (itr.next()) |item| {
                const i_name = slurm.parseCStr(item.name) orelse continue;
                if (!std.mem.eql(u8, name, i_name)) continue;
                return item;
            }
            return null;
        }
    };

    pub fn isRemote(self: *const License) bool {
        return self.remote > 1;
    }
};

pub fn load() Error!*License.LoadResponse {
    var resp: ?*License.LoadResponse = null;
    const flags: u16 = 0;

    try err.checkRpc(c.slurm_load_licenses(0, &resp, flags));
    return if (resp) |r|
        r
    else
        error.Generic;
}
