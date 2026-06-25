const std = @import("std");
const db = @import("../db.zig");
const common = @import("../common.zig");
const CStr = common.CStr;
const Connection = db.Connection;
const List = db.List;
const time_t = std.posix.time_t;

pub const Reservation = extern struct {
    assocs: ?CStr = null,
    cluster: ?CStr = null,
    comment: ?CStr = null,
    flags: u64,
    id: u32,
    name: ?CStr = null,
    nodes: ?CStr = null,
    node_inx: ?CStr = null,
    time_end: time_t = 0,
    time_force: time_t = 0,
    time_start: time_t = 0,
    time_start_prev: time_t = 0,
    tres_str: ?CStr = null,
    unused_wall: f64,
    tres_list: ?*List(*db.TrackableResource) = null,

    pub const Filter = extern struct {
        cluster_list: ?*List(CStr) = null,
        flags: u64,
        format_list: ?*List(CStr) = null,
        id_list: ?*List(CStr) = null,
        name_list: ?*List(CStr) = null,
        nodes: ?CStr = null,
        time_end: time_t = 0,
        time_start: time_t = 0,
        with_usage: u16,
    };
};
