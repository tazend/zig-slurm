const std = @import("std");
const db = @import("../db.zig");
const common = @import("../common.zig");
const CStr = common.CStr;
const List = db.List;
const time_t = std.posix.time_t;
const NoValue = common.NoValue;

pub const Transaction = extern struct {
    accts: ?CStr = null,
    action: u16 = NoValue.u16, // slurmdb_msg_type
    actor_name: ?CStr = null,
    clusters: ?CStr = null,
    id: u32 = 0,
    set_info: ?CStr = null,
    timestamp: time_t = 0,
    users: ?CStr = null,
    where_query: ?CStr = null,

    pub const Filter = extern struct {
        acct_list: ?*List(CStr) = null,
        action_list: ?*List(CStr) = null,
        actor_list: ?*List(CStr) = null,
        cluster_list: ?*List(CStr) = null,
        format_list: ?*List(CStr) = null,
        id_list: ?*List(CStr) = null,
        info_list: ?*List(CStr) = null,
        name_list: ?*List(CStr) = null,
        time_end: time_t = 0,
        time_start: time_t = 0,
        user_list: ?*List(CStr) = null,
        with_assoc_info: u16 = NoValue.u16,
    };
};
