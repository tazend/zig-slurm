const std = @import("std");
const SlurmError = @import("error.zig").Error;
const checkRpc = @import("error.zig").checkRpc;
const slurm = @import("root.zig");
const common = @import("common.zig");
const time_t = std.posix.time_t;
const List = @import("db.zig").List;
const NoValue = common.NoValue;
const Infinite = common.Infinite;
const CStr = common.CStr;
const BitString = common.BitString;

pub const Reservation = extern struct {
    accounts: ?CStr = null,
    burst_buffer: ?CStr = null,
    comment: ?CStr = null,
    core_cnt: u32 = 0,
    core_spec_cnt: u32 = 0,
    core_spec: ?*slurm.Reservation.CoreSpec = null,
    end_time: time_t = 0,
    features: ?CStr = null,
    flags: u64 = 0,
    groups: ?CStr = null,
    licenses: ?CStr = null,
    max_start_delay: u32 = 0,
    name: ?CStr = null,
    node_cnt: u32 = 0,
    node_inx: ?[*]i32 = null,
    node_list: ?CStr = null,
    partition: ?CStr = null,
    purge_comp_time: u32 = 0,
    start_time: time_t = 0,
    tres_str: ?CStr = null,
    users: ?CStr = null,

    pub const CoreSpec = extern struct {
        node_name: ?CStr = null,
        core_id: ?CStr = null,
    };

    pub const LoadResponse = extern struct {
        last_update: time_t,
        record_count: u32 = 0,
        items: ?[*]Reservation = null,
    };

    pub const Updatable = extern struct {
        accounts: ?CStr = null,
        burst_buffer: ?CStr = null,
        comment: ?CStr = null,
        core_cnt: u32 = null,
        duration: u32 = NoValue.u32,
        end_time: time_t = 0,
        features: ?CStr = null,
        flags: u64 = 0,
        groups: ?CStr = null,
        job_ptr: ?*anyopaque = null,
        licenses: ?CStr = null,
        max_start_delay: u32 = NoValue.u32,
        name: ?CStr = null,
        node_cnt: u32 = NoValue.u32,
        node_list: ?CStr = null,
        partition: ?CStr = null,
        purge_comp_time: u32 = 0,
        start_time: time_t = 0,
        tres_str: ?CStr = null,
        users: ?CStr = null,
    };
};
