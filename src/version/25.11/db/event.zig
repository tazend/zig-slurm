const std = @import("std");
const db = @import("../db.zig");
const common = @import("../common.zig");
const CStr = common.CStr;
const time_t = std.posix.time_t;
const List = db.List;
const Connection = db.Connection;

pub const Event = extern struct {
    cluster: ?CStr = null,
    cluster_nodes: ?CStr = null,
    event_type: db.Event.Type,
    node_name: ?CStr = null,
    period_end: time_t = 0,
    period_start: time_t = 0,
    reason: ?CStr = null,
    reason_uid: u32,
    state: u32,
    tres_str: ?CStr = null,

    pub const Type = enum(u16) {
        all = 0,
        cluster,
        node,
    };

    pub const Filter = extern struct {
        cluster_list: ?*List(*opaque {}) = null,
        cond_flags: Filter.Flags,
        cpus_max: u32,
        cpus_min: u32,
        event_type: db.Event.Type,
        format_list: ?*List(*opaque {}) = null,
        node_list: ?CStr = null,
        period_end: time_t = 0,
        period_start: time_t = 0,
        reason_list: ?*List(*opaque {}) = null,
        reason_uid_list: ?*List(*opaque {}) = null,
        state_list: ?*List(*opaque {}) = null,

        pub const Flags = packed struct(u32) {
            only_open: bool = false,
        };
    };
};
