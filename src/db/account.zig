const std = @import("std");
const db = @import("../db.zig");
const common = @import("../common.zig");
const CStr = common.CStr;
const List = db.List;
const Connection = db.Connection;
const checkRpc = @import("../error.zig").checkRpc;

pub const Account = extern struct {
    associations: ?*List(*db.Association) = null,
    coordinators: ?*List(*opaque {}) = null,
    description: ?CStr = null,
    flags: Flags = .{},
    name: ?CStr = null,
    organization: ?CStr = null,

    pub const Filter = extern struct {
        association_filter: ?*db.Association.Filter = null,
        descriptions: ?*List(CStr) = null,
        flags: Flags = .{},
        organizations: ?*List(CStr) = null,
    };

    pub const Flags = packed struct(u32) {
        deleted: bool = false,
        with_assocs: bool = false,
        with_coords: bool = false,
        no_users_are_coord: bool = false,
        _pad1: u11 = 0,
        users_are_coord: bool = false,
        _pad2: u16 = 0,
    };
};

pub extern fn slurmdb_accounts_get(
    db_conn: ?*Connection,
    acct_cond: *Account.Filter,
) ?*List(*Account);
pub fn load(conn: *Connection, filter: Account.Filter) !*List(*Account) {
    const data = slurmdb_accounts_get(conn, @constCast(&filter));
    if (data) |d| {
        return d;
    } else {
        // TODO: Better error, this is just temporary.
        return error.Generic;
    }
}

pub extern fn slurmdb_accounts_add(
    db_conn: ?*Connection,
    acct_list: ?*List(*Account),
) c_int;
pub fn add(conn: *Connection, accounts: *List(*Account)) !void {
    const rc = slurmdb_accounts_add(conn, accounts);
    try checkRpc(rc);
}

pub extern fn slurmdb_accounts_remove(
    db_conn: ?*Connection,
    acct_cond: *Account.Filter,
) ?*List(CStr);
pub const removeRaw = slurmdb_accounts_remove;
