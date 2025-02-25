const c = @import("c.zig").c;
const std = @import("std");
const SlurmError = @import("error.zig").Error;
pub const DatabaseConnection = @import("connection.zig").DatabaseConnection;
pub const List = @import("list.zig").List;

pub const AdminLevel = enum(u16) {
    not_set,
    none,
    operator,
    administrator,
};

pub const User = extern struct {
    admin_level: AdminLevel = AdminLevel.not_set,
    associations: ?*c.list_t = null,
    bf_usage: ?*c.slurmdb_bf_usage_t = null,
    coordinators: ?*c.list_t = null,
    default_account: ?[*:0]const u8 = null,
    default_wckey: ?[*:0]const u8 = null,
    flags: u32 = 0,
    name: ?[*:0]const u8 = null,
    old_name: ?[*:0]const u8 = null,
    user_id: u32 = 0,
    wckeys: ?*c.list_t = null,

    pub fn loadAll(conn: DatabaseConnection) !List(User) {
        // TODO: have a cond as input
        var cond = c.slurmdb_user_cond_t{};
        const data = c.slurmdb_users_get(@constCast(conn.handle), &cond);
        if (data) |d| {
            return List(User).from_c(d);
        } else {
            // TODO: Better error, this is just temporary.
            return error.Generic;
        }
    }
};
