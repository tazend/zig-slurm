const c = @import("c.zig").c;
const std = @import("std");
const SlurmError = @import("error.zig").Error;
const ListDestroyFunction = *const fn (object: ?*anyopaque) callconv(.C) void;
const common = @import("common.zig");
const checkRpc = @import("error.zig").checkRpc;
const time_t = std.os.linux.time_t;
const CStr = [*:0]const u8;
const list_t = opaque {};
const list_itr_t = opaque {};

const NoValue = struct {
    pub const @"u8": u8 = c.NO_VAL8;
    pub const @"u16": u16 = c.NO_VAL16;
    pub const @"u32": u32 = c.NO_VAL;
    pub const @"u64": u64 = c.NO_VAL64;
};

const Infinite = struct {
    pub const @"u8": u8 = c.INFINITE8;
    pub const @"u16": u16 = c.INFINITE16;
    pub const @"u32": u32 = c.INFINITE;
    pub const @"u64": u64 = c.INFINITE64;
};

pub const Connection = opaque {
    extern fn slurmdb_connection_get(persist_conn_flags: *u16) ?*Connection;
    pub fn open() !*Connection {
        var flags: u16 = 0;
        return try openGetFlags(&flags);
    }

    pub fn openGetFlags(flags: *u16) !*Connection {
        const handle = slurmdb_connection_get(@constCast(flags));
        if (handle) |h| {
            return h;
        }
        return error.Generic;
    }

    extern fn slurmdb_connection_close(db_conn: **Connection) c_int;
    pub fn close(self: *Connection) void {
        _ = slurmdb_connection_close(@constCast(&self));
    }

    extern fn slurmdb_connection_commit(db_conn: *Connection, commit: bool) c_int;
    pub fn commit(self: *Connection) !void {
        const rc = slurmdb_connection_commit(@constCast(self), true);
        try checkRpc(rc);
    }

    pub fn rollback(self: *Connection) !void {
        const rc = slurmdb_connection_commit(@constCast(self), false);
        try checkRpc(rc);
    }
};

pub const AccountFlags = enum(c_uint) {
    none = 0,
    deleted = 1,
    with_associations = 2,
    with_coordinators = 4,
    no_users_are_coordinators = 8,
    _base = 65535,
    users_are_coordinators = 65536,
    invalid = 65537,
};

pub const AssociationFlags = enum(c_uint) {
    none = 0,
    deleted = 1,
    no_update = 2,
    exact = 4,
    no_users_are_coordinators,
    _base = 65535,
    users_are_coordinators = 65536,
    invalid = 65537,
};

pub const BFUsage = extern struct {
    count: u64 = 0,
    last_sched: time_t = 0,
};

pub const JobFilterFlags = packed struct(u32) {
    duplicate: bool = false,
    no_step: bool = false,
    no_truncate: bool = false,
    runaway: bool = false,
    whole_hetjob: bool = false,
    no_whole_hetjob: bool = false,
    no_wait: bool = false,
    no_default_usage: bool = false,
    script: bool = false,
    environment: bool = false,

    _padding1: u22 = 0,

    pub usingnamespace common.BitflagMethods(JobFilterFlags, u32);
};

pub const WCKey = extern struct {
    accounting_list: ?*list_t = null,
    cluster: ?CStr = null,
    flags: u32 = 0,
    id: u32 = NoValue.u32,
    is_def: u16 = 0,
    name: ?CStr = null,
    uid: u32 = NoValue.u32,
    user: ?CStr = null,
};

pub const JobFilter = extern struct {
    accounts: ?*List(CStr) = null,
    association_ids: ?*List(CStr) = null,
    clusters: ?*List(CStr) = null,
    constraints: ?*List(CStr) = null,
    cpus_max: u32 = 0,
    cpus_min: u32 = 0,
    db_flags: u32 = NoValue.u32,
    exitcode: i32 = 0,
    flags: u32 = JobFilterFlags{ .no_truncate = true },
    __format_list: ?*list_t = null,
    group_ids: ?*List(CStr) = null,
    names: ?*List(CStr) = null,
    nodes_max: u32 = 0,
    nodes_min: u32 = 0,
    partitions: ?*List(CStr) = null,
    qos_ids: ?*List(CStr) = null,
    reasons: ?*List(CStr) = null,
    reservations: ?*List(CStr) = null,
    __resvid_list: ?*list_t = null,
    states: ?*List(CStr) = null,
    steps: ?*list_t = null, // TODO: selected_step_t
    timelimit_max: u32 = 0,
    timelimit_min: u32 = 0,
    usage_end: time_t = 0,
    usage_start: time_t = 0,
    used_nodes: ?CStr = null,
    user_ids: ?*List(CStr) = null,
    wckeys: ?*List(CStr) = null,
};

pub const TrackableResource = extern struct {
    alloc_secs: u64 = 0,
    rec_count: u32 = 0,
    count: u64 = 0,
    id: u32 = 0,
    name: ?CStr = null,
    type: ?CStr = null,
};

pub const AccountFilter = extern struct {
    association_filter: ?*AssociationFilter = null,
    descriptions: ?*List(CStr) = null,
    flags: AccountFlags = .none,
    organizations: ?*List(CStr) = null,
};

pub const Account = extern struct {
    associations: ?*List(Association) = null,
    coordinators: ?*list_t = null,
    description: ?CStr = null,
    flags: AccountFlags = .none,
    name: ?CStr = null,
    organization: ?CStr = null,

    pub const get = loadAccounts;
};

pub const AdminLevel = enum(u16) {
    not_set,
    none,
    operator,
    administrator,
};

pub const UserFilter = extern struct {
    admin_level: AdminLevel = AdminLevel.not_set,
    association_filter: ?*AssociationFilter = null,
    default_accounts: ?*List(CStr) = null,
    default_wckey_list: ?*List(CStr) = null,
    with_assocs: u16 = 0,
    with_coords: u16 = 0,
    with_deleted: u16 = 0,
    with_wckeys: u16 = 0,
    without_defaults: u16 = 0,
};

pub const User = extern struct {
    admin_level: AdminLevel = AdminLevel.not_set,
    associations: ?*List(Association) = null,
    bf_usage: ?*BFUsage = null,
    coordinators: ?*c.list_t = null,
    default_account: ?CStr = null,
    default_wckey: ?CStr = null,
    flags: u32 = 0,
    name: ?CStr = null,
    old_name: ?CStr = null,
    user_id: u32 = 0,
    wckeys: ?*List(WCKey) = null,

    pub const get = loadUsers;
    pub const create = createUsers;
};

pub const AssociationFilter = extern struct {
    accounts: ?*List(CStr) = null,
    clusters: ?*List(CStr) = null,
    def_qos_id_list: ?*List(CStr) = null,
    flags: AssociationFlags = .none,
    format_list: ?*List(CStr) = null,
    id_list: ?*List(CStr) = null,
    parent_accounts: ?*List(CStr) = null,
    partitions: ?*List(CStr) = null,
    qos_ids: ?*List(CStr) = null,
    usage_end: time_t = 0,
    usage_start: time_t = 0,
    users: ?*List(CStr) = null,
};

pub const Association = extern struct {
    __accounting_list: ?*list_t = null,
    account: ?CStr = null,
    __assoc_next: ?*Association = null,
    __assoc_next_id: ?*Association = null,
    __bf_usage: ?*BFUsage = null,
    cluster: ?CStr = null,
    comment: ?CStr = null,
    default_qos_id: u32 = 0,
    flags: AssociationFlags = .none,
    grp_jobs: u32 = c.NO_VAL,
    grp_jobs_accrue: u32 = c.NO_VAL,
    grp_submit_jobs: u32 = c.NO_VAL,
    grp_tres: ?CStr = null,
    __grp_tres_ctld: ?*u64 = null,
    grp_tres_mins: ?CStr = null,
    __grp_tres_mins_ctld: ?*u64 = null,
    grp_tres_run_mins: ?CStr = null,
    __grp_tres_run_mins_ctld: ?*u64 = null,
    grp_wall: u32 = c.NO_VAL,
    id: u32 = c.NO_VAL,
    is_def: u16 = c.NO_VAL16,
    __leaf_usage: ?*c.slurmdb_assoc_usage_t = null,
    lft: u32 = c.NO_VAL,
    lineage: ?CStr = null,
    max_jobs: u32 = c.NO_VAL,
    max_jobs_accrue: u32 = c.NO_VAL,
    max_submit_jobs: u32 = c.NO_VAL,
    max_tres_mins_pj: ?CStr = null,
    __max_tres_mins_ctld: ?*u64 = null,
    max_tres_run_mins: ?CStr = null,
    __max_tres_run_mins_ctld: ?*u64 = null,
    max_tres_pj: ?CStr = null,
    __max_tres_ctld: ?*u64 = null,
    max_tres_pn: ?CStr = null,
    __max_tres_pn_ctld: ?*u64 = null,
    max_wall_pj: u32 = c.NO_VAL,
    min_prio_thresh: u32 = c.NO_VAL,
    parent_acct: ?CStr = null,
    parent_id: u32 = c.NO_VAL,
    partition: ?CStr = null,
    priority: u32 = c.NO_VAL,
    qos_list: ?*list_t = null,
    rgt: u32 = c.NO_VAL,
    shares_raw: u32 = c.NO_VAL,
    uid: u32 = c.NO_VAL,
    usage: ?*c.slurmdb_assoc_usage_t = null,
    user: ?CStr = null,
    __user_rec: ?*User = null,

    pub const get = loadAssociations;
};

pub extern fn slurm_xcalloc(usize, usize, bool, bool, [*c]const u8, c_int, [*c]const u8) ?*anyopaque;
pub extern fn slurm_xfree([*c]?*anyopaque) void;
pub extern fn slurm_xfree_array([*c][*c]?*anyopaque) void;
pub extern fn slurm_xrecalloc([*c]?*anyopaque, usize, usize, bool, bool, [*c]const u8, c_int, [*c]const u8) ?*anyopaque;
pub extern fn slurm_xsize(item: ?*anyopaque) usize;
pub extern fn slurm_xfree_ptr(?*anyopaque) void;

pub fn List(comptime T: type) type {
    return opaque {
        const Self = @This();

        const DestroyFunc: ListDestroyFunction = switch (T) {
            User => c.slurmdb_destroy_user_rec,
            Association => c.slurmdb_destroy_assoc_rec,
            else => slurm_xfree_ptr,
        };

        pub const Iterator = struct {
            c_handle: *list_itr_t,
            index: usize = 0,

            pub extern fn slurm_list_next(i: ?*list_itr_t) ?*T;
            pub fn next(it: *Iterator) ?*T {
                defer it.index += 1;
                const item = slurm_list_next(it.c_handle);
                return item;
            }

            extern fn slurm_list_iterator_create(l: ?*List(T)) ?*list_itr_t;
            pub fn init(list: *Self) Iterator {
                const handle = slurm_list_iterator_create(list);
                return Iterator{
                    .c_handle = handle.?,
                };
            }

            extern fn slurm_list_iterator_destroy(i: ?*list_itr_t) void;
            pub fn deinit(it: *Iterator) void {
                slurm_list_iterator_destroy(it.c_handle);
                it.c_handle = undefined;
            }

            extern fn slurm_list_iterator_reset(i: ?*list_itr_t) void;
            pub fn reset(it: *Iterator) void {
                slurm_list_iterator_reset(it.c_handle);
                it.index = 0;
            }
        };

        extern fn slurm_list_create(f: ListDestroyFunction) ?*List(T);
        pub fn init() *List(T) {
            const list = slurm_list_create(DestroyFunc);
            const list_typed = @as(*List(T), @ptrCast(list.?));
            return list_typed;
        }

        extern fn slurm_list_destroy(l: ?*List(T)) void;
        pub fn deinit(self: *Self) void {
            slurm_list_destroy(self);
        }

        extern fn slurm_list_count(l: ?*List(T)) c_int;
        pub fn size(self: *Self) c_int {
            return slurm_list_count(self);
        }

        pub fn iter(self: *Self) Iterator {
            return Iterator.init(self);
        }

        extern fn slurm_list_pop(l: ?*List(T)) ?*T;
        pub fn pop(self: *Self) ?*T {
            return slurm_list_pop(self);
        }

        extern fn slurm_list_is_empty(l: ?*List(T)) c_int;
        pub fn isEmpty(self: *Self) bool {
            return slurm_list_is_empty(self) == 1;
        }

        pub extern fn slurm_list_append(l: ?*List(T), x: ?*T) void;
        pub fn append(self: *Self, item: *const T) void {
            slurm_list_append(self, @constCast(item));
        }

        pub fn toOwnedSlice(
            self: *Self,
            allocator: std.mem.Allocator,
        ) std.mem.Allocator.Error![]*T {
            var data: []*T = try allocator.alloc(*T, @intCast(self.size()));

            var index = 0;
            while (self.pop()) |ptr| {
                const item = @as(*T, @alignCast(@ptrCast(ptr)));
                data[index] = item;
                index += 1;
            }

            self.deinit();
            return data;
        }

        pub fn toArrayList(self: *Self, allocator: std.mem.Allocator) !std.ArrayList(*T) {
            return std.ArrayList(*T).fromOwnedSlice(
                allocator,
                try self.toOwnedSlice(allocator),
            );
        }

        pub fn fromOwnedSlice(items: []T) *List(T) {
            var list = List(T).init();
            for (items) |*i| {
                list.append(i);
            }
            return list;
        }
    };
}

pub extern fn slurmdb_associations_get(db_conn: ?*Connection, assoc_cond: *AssociationFilter) ?*List(Association);
pub fn loadAssociations(conn: *Connection, filter: AssociationFilter) !List(Association) {
    const data = slurmdb_associations_get(conn, @constCast(&filter));
    if (data) |d| {
        return d;
    } else {
        // TODO: Better error, this is just temporary.
        return error.Generic;
    }
}

pub extern fn slurmdb_associations_add(db_conn: ?*Connection, assoc_list: ?*List(Association)) c_int;
pub fn createAssociations(conn: *Connection, associations: *List(Association)) !void {
    const rc = slurmdb_associations_add(conn, associations);
    try checkRpc(rc);
}

pub extern fn slurmdb_accounts_get(db_conn: ?*Connection, acct_cond: *AccountFilter) ?*List(Account);
pub fn loadAccounts(conn: *Connection, filter: AccountFilter) !*List(Account) {
    const data = slurmdb_accounts_get(conn, @constCast(&filter));
    if (data) |d| {
        return d;
    } else {
        // TODO: Better error, this is just temporary.
        return error.Generic;
    }
}

pub extern fn slurmdb_accounts_add(db_conn: ?*Connection, acct_list: ?*List(Account)) c_int;
pub fn createAccounts(conn: *Connection, accounts: *List(Account)) !void {
    const rc = slurmdb_accounts_add(conn, accounts);
    try checkRpc(rc);
}

pub extern fn slurmdb_users_get(db_conn: ?*Connection, user_cond: *UserFilter) ?*List(User);
pub fn loadUsers(conn: *Connection, filter: UserFilter) !*List(User) {
    const data = slurmdb_users_get(conn, @constCast(&filter));
    if (data) |d| {
        return d;
    } else {
        // TODO: Better error, this is just temporary.
        return error.Generic;
    }
}

pub extern fn slurmdb_users_add(db_conn: ?*Connection, user_list: ?*List(User)) c_int;
pub fn createUsers(conn: *Connection, users: *List(User)) !void {
    const rc = slurmdb_users_add(conn, users);
    try checkRpc(rc);
}
