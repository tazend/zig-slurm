const std = @import("std");
const db = @import("../db.zig");
const common = @import("../common.zig");
const slurm = @import("../root.zig");
const c = slurm.c;
const CStr = common.CStr;
const List = db.List;
const Connection = db.Connection;
const err = slurm.err;
const checkRpc = err.checkRpc;

pub const Account = extern struct {
    assoc_list: ?*List(*db.Association) = null,
    coordinators: ?*List(*db.Coordinator) = null,
    description: ?CStr = null,
    flags: db.Account.Flags = .{},
    name: ?CStr = null,
    organization: ?CStr = null,

    pub const Filter = extern struct {
        assoc_cond: ?*db.Association.Filter = null,
        description_list: ?*List(CStr) = null,
        flags: db.Account.Flags = .{},
        organization_list: ?*List(CStr) = null,
    };

    pub const Flags = packed struct(c_uint) {
        deleted: bool = false,
        with_assocs: bool = false,
        with_coords: bool = false,
        no_users_are_coord: bool = false,
        _pad1: u12 = 0,
        users_are_coord: bool = false,
        _pad2: u15 = 0,

        const _bf_methods = common.BitflagMethods(@This());
        pub const toStr = _bf_methods.toStr;
        pub const jsonStringify = _bf_methods.jsonStringify;
        pub const fromSlice = _bf_methods.fromSlice;
        pub const toSlice = _bf_methods.toSlice;
    };
};

pub fn load(conn: *Connection, filter: Account.Filter) !*List(*Account) {
    const data = c.slurmdb_accounts_get(conn, @constCast(&filter));
    if (data) |d| {
        return d;
    } else {
        // TODO: Better error, this is just temporary.
        return error.Generic;
    }
}

pub fn add(conn: *Connection, accounts: *List(*Account)) !void {
    const rc = c.slurmdb_accounts_add(conn, accounts);
    try checkRpc(rc);
}

pub fn remove(conn: *db.Connection, filter: db.Account.Filter) !?*List(CStr) {
    const data = c.slurmdb_accounts_remove(conn, @constCast(&filter));
    try err.getError();

    return if (data) |d|
        d
    else
        return error.Generic;
}
