const std = @import("std");
const db = @import("../db.zig");
const common = @import("../common.zig");
const CStr = common.CStr;
const Connection = db.Connection;
const List = db.List;

pub const Reservation = extern struct {
    assocs: ?CStr = null,
    cluster: ?CStr = null,
    comment: ?CStr = null,
    flags: u64,
    id: u32,
    name: ?CStr = null,
    nodes: ?CStr = null,
    node_inx: ?CStr = null,
    time_end: std.os.linux.time_t = 0,
    time_start: std.os.linux.time_t = 0,
    time_start_prev: std.os.linux.time_t = 0,
    tres_str: ?CStr = null,
    unused_wall: f64,
    tres_list: ?*List(*opaque {}) = null,

    pub const Filter = extern struct {
        cluster_list: ?*List(*opaque {}) = null,
        flags: u64,
        format_list: ?*List(*opaque {}) = null,
        id_list: ?*List(*opaque {}) = null,
        name_list: ?*List(*opaque {}) = null,
        nodes: ?CStr = null,
        time_end: std.os.linux.time_t = 0,
        time_start: std.os.linux.time_t = 0,
        with_usage: u16,
    };
};
