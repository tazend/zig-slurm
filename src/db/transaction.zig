const std = @import("std");
const db = @import("../db.zig");
const common = @import("../common.zig");
const CStr = common.CStr;
const List = db.List;
const time_t = std.posix.time_t;
const NoValue = common.NoValue;

pub const Transaction = extern struct {
    accounts: ?CStr = null,
    action: u16 = NoValue.u16, // slurmdb_msg_type
    actors: ?CStr = null,
    clusters: ?CStr = null,
    id: u32 = 0,
    set_info: ?CStr = null,
    timestamp: time_t = 0,
    users: ?CStr = null,
    where_query: ?CStr = null,

    pub const Filter = extern struct {
        accounts: ?*List(CStr) = null,
        actions: ?*List(CStr) = null,
        actors: ?*List(CStr) = null,
        clusters: ?*List(CStr) = null,
        __format_list: ?*List(*opaque {}) = null,
        ids: ?*List(CStr) = null,
        infos: ?*List(CStr) = null,
        names: ?*List(CStr) = null,
        time_end: time_t = 0,
        time_start: time_t = 0,
        users: ?*List(CStr) = null,
        with_assoc_info: u16 = NoValue.u16,
    };
};
