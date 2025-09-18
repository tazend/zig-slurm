const std = @import("std");
const db = @import("../db.zig");
const common = @import("../common.zig");
const CStr = common.CStr;
const NoValue = common.NoValue;
const time_t = std.posix.time_t;
const List = db.List;
const Connection = db.Connection;

pub const WCKey = extern struct {
    accounting_list: ?*List(*opaque {}) = null,
    cluster: ?CStr = null,
    flags: u32 = 0,
    id: u32 = NoValue.u32,
    is_def: u16 = 0,
    name: ?CStr = null,
    uid: u32 = NoValue.u32,
    user: ?CStr = null,

    pub const Filter = extern struct {
        cluster_list: ?*List(CStr) = null,
        format_list: ?*List(*opaque {}) = null,
        id_list: ?*List(CStr) = null,
        name_list: ?*List(CStr) = null,
        only_defs: u16 = NoValue.u32,
        usage_end: time_t = 0,
        usage_start: time_t = 0,
        user_list: ?*List(CStr) = null,
        with_usage: u16 = NoValue.u16,
        with_deleted: u16 = NoValue.u16,
    };
};
