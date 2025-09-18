const std = @import("std");
const db = @import("../db.zig");
const common = @import("../common.zig");
const CStr = common.CStr;
const xfree_ptr = @import("../SlurmAllocator.zig").slurm_xfree_ptr;
const NoValue = common.NoValue;
const Infinite = common.Infinite;
const time_t = std.posix.time_t;
const slurm = @import("../root.zig");
const JobState = slurm.Job.State;
const List = db.List;
const Connection = db.Connection;
const checkRpc = @import("../error.zig").checkRpc;

pub const User = extern struct {
    admin_level: db.AdminLevel = .not_set,
    assoc_list: ?*List(*db.Association) = null,
    bf_usage: ?*db.BackfillUsage = null,
    coord_accts: ?*List(*opaque {}) = null,
    default_acct: ?CStr = null,
    default_wckey: ?CStr = null,
    flags: u32 = 0,
    name: ?CStr = null,
    old_name: ?CStr = null,
    uid: u32 = 0,
    wckey_list: ?*List(*db.WCKey) = null,

    extern fn slurmdb_destroy_user_rec(object: ?*User) void;
    pub fn deinit(self: *User) void {
        slurmdb_destroy_user_rec(self);
    }

    pub const Filter = extern struct {
        admin_level: db.AdminLevel = .not_set,
        assoc_cond: ?*db.Association.Filter = null,
        def_acct_list: ?*List(CStr) = null,
        def_wckey_list: ?*List(CStr) = null,
        with_assocs: u16 = 0,
        with_coords: u16 = 0,
        with_deleted: u16 = 0,
        with_wckeys: u16 = 0,
        without_defaults: u16 = 0,
    };
};

pub extern fn slurmdb_users_get(db_conn: ?*Connection, user_cond: *User.Filter) ?*List(*User);
pub fn load(conn: *Connection, filter: User.Filter) !*List(*User) {
    const data = slurmdb_users_get(conn, @constCast(&filter));
    if (data) |d| {
        return d;
    } else {
        // TODO: Better error, this is just temporary.
        return error.Generic;
    }
}

pub extern fn slurmdb_users_add(db_conn: ?*Connection, user_list: ?*List(*User)) c_int;
pub fn add(conn: *Connection, users: *List(*User)) !void {
    const rc = slurmdb_users_add(conn, users);
    try checkRpc(rc);
}

pub extern fn slurmdb_users_remove(db_conn: ?*Connection, user_cond: *User.Filter) ?*List(CStr);
pub const removeRaw = slurmdb_users_remove;
pub fn remove(conn: *Connection, filter: User.Filter) !*List(CStr) {
    const data = slurmdb_users_remove(conn, @constCast(&filter));
    try slurm.err.getError();

    return if (data) |d|
        d
    else
        return error.Generic;
}
