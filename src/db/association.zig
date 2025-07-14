const std = @import("std");
const db = @import("../db.zig");
const common = @import("../common.zig");
const CStr = common.CStr;
const xfree_ptr = @import("../SlurmAllocator.zig").slurm_xfree_ptr;
const NoValue = common.NoValue;
const Infinite = common.Infinite;
const time_t = std.posix.time_t;
const slurm = @import("../root.zig");
const err = slurm.err;
const List = db.List;
const Connection = db.Connection;
const checkRpc = @import("../error.zig").checkRpc;
const BitString = common.BitString;

pub const Association = extern struct {
    __accounting_list: ?*List(*opaque {}) = null,
    account: ?CStr = null,
    __assoc_next: ?*Association = null,
    __assoc_next_id: ?*Association = null,
    __bf_usage: ?*db.BFUsage = null,
    cluster: ?CStr = null,
    comment: ?CStr = null,
    default_qos_id: u32 = 0,
    flags: Flags = .none,
    grp_jobs: u32 = NoValue.u32,
    grp_jobs_accrue: u32 = NoValue.u32,
    grp_submit_jobs: u32 = NoValue.u32,
    grp_tres: ?CStr = null,
    __grp_tres_ctld: ?[*]u64 = null,
    grp_tres_mins: ?CStr = null,
    __grp_tres_mins_ctld: ?[*]u64 = null,
    grp_tres_run_mins: ?CStr = null,
    __grp_tres_run_mins_ctld: ?[*]u64 = null,
    grp_wall: u32 = NoValue.u32,
    id: u32 = NoValue.u32,
    is_def: u16 = NoValue.u16,
    __leaf_usage: ?*Usage = null,
    lft: u32 = NoValue.u32,
    lineage: ?CStr = null,
    max_jobs: u32 = NoValue.u32,
    max_jobs_accrue: u32 = NoValue.u32,
    max_submit_jobs: u32 = NoValue.u32,
    max_tres_mins_pj: ?CStr = null,
    __max_tres_mins_ctld: ?[*]u64 = null,
    max_tres_run_mins: ?CStr = null,
    __max_tres_run_mins_ctld: ?[*]u64 = null,
    max_tres_pj: ?CStr = null,
    __max_tres_ctld: ?[*]u64 = null,
    max_tres_pn: ?CStr = null,
    __max_tres_pn_ctld: ?[*]u64 = null,
    max_wall_pj: u32 = NoValue.u32,
    min_prio_thresh: u32 = NoValue.u32,
    parent_acct: ?CStr = null,
    parent_id: u32 = NoValue.u32,
    partition: ?CStr = null,
    priority: u32 = NoValue.u32,
    qos_list: ?*List(*opaque {}) = null,
    rgt: u32 = NoValue.u32,
    shares_raw: u32 = NoValue.u32,
    uid: u32 = NoValue.u32,
    usage: ?*Usage = null,
    user: ?CStr = null,
    __user_rec: ?*db.User = null,

    pub const Filter = extern struct {
        accounts: ?*List(CStr) = null,
        clusters: ?*List(CStr) = null,
        def_qos_id_list: ?*List(CStr) = null,
        flags: Filter.Flags = .{},
        format_list: ?*List(CStr) = null,
        id_list: ?*List(CStr) = null,
        parent_accounts: ?*List(CStr) = null,
        partitions: ?*List(CStr) = null,
        qos_ids: ?*List(CStr) = null,
        usage_end: time_t = 0,
        usage_start: time_t = 0,
        users: ?*List(CStr) = null,

        pub const Flags = packed struct(u32) {
            with_deleted: bool = false,
            with_usage: bool = false,
            only_defs: bool = false,
            raw_qos: bool = false,
            sub_accts: bool = false,
            wopi: bool = false,
            wopl: bool = false,
            qos_usage: bool = false,

            _padding: u24 = 0,
        };
    };

    pub const Flags = enum(c_uint) {
        none = 0,
        deleted = 1,
        no_update = 2,
        exact = 4,
        no_users_are_coordinators,
        _base = 65535,
        users_are_coordinators = 65536,
        invalid = 65537,
    };

    pub const Usage = extern struct {
        accrue_cnt: u32 = @import("std").mem.zeroes(u32),
        children_list: ?*List(*opaque {}) = null,
        grp_node_bitmap: ?[*]BitString = null,
        grp_node_job_cnt: [*c]u16 = @import("std").mem.zeroes([*c]u16),
        grp_used_tres: [*c]u64 = @import("std").mem.zeroes([*c]u64),
        grp_used_tres_run_secs: ?[*]u64 = null,
        grp_used_wall: f64 = @import("std").mem.zeroes(f64),
        fs_factor: f64 = @import("std").mem.zeroes(f64),
        level_shares: u32 = @import("std").mem.zeroes(u32),
        parent_assoc_ptr: ?*Association = null,
        priority_norm: f64 = @import("std").mem.zeroes(f64),
        fs_assoc_ptr: ?*Association = null,
        shares_norm: f64 = @import("std").mem.zeroes(f64),
        tres_cnt: u32 = @import("std").mem.zeroes(u32),
        usage_efctv: c_longdouble = @import("std").mem.zeroes(c_longdouble),
        usage_norm: c_longdouble = @import("std").mem.zeroes(c_longdouble),
        usage_raw: c_longdouble = @import("std").mem.zeroes(c_longdouble),
        usage_tres_raw: [*c]c_longdouble = @import("std").mem.zeroes([*c]c_longdouble),
        used_jobs: u32 = @import("std").mem.zeroes(u32),
        used_submit_jobs: u32 = @import("std").mem.zeroes(u32),
        level_fs: c_longdouble = @import("std").mem.zeroes(c_longdouble),
        valid_qos: ?[*]BitString = null,
    };

    pub const Manager = struct {
        pub const LoadResponse = extern struct {
            assoc_list: ?*List(*Association) = null,
            qos_list: ?*List(*db.QoS) = null,
            tres_cnt: u32 = 0,
            tres_names: ?[*]CStr = null,
            user_list: ?*List(*db.User) = null,
        };

        pub const Request = extern struct {
            acct_list: ?*List(CStr) = null,
            flags: Request.Flags = .{},
            qos_list: ?*List(CStr) = null,
            user_list: ?*List(CStr) = null,

            pub const Flags = packed struct(u32) {
                assocs: bool = false,
                users: bool = false,
                qos: bool = false,
                _: u29 = 0,
            };
        };
    };

    pub const get = load;
};
pub extern fn slurm_load_assoc_mgr_info(
    *Association.Manager.Request,
    ?**Association.Manager.LoadResponse,
) c_int;
pub fn loadUsageAll() !*Association.Manager.LoadResponse {
    var resp: *Association.Manager.LoadResponse = undefined;
    var req: Association.Manager.Request = .{
        .flags = .{ .assocs = true },
    };

    try checkRpc(slurm_load_assoc_mgr_info(&req, &resp));
    return resp;
}

pub extern fn slurmdb_associations_get(db_conn: ?*Connection, assoc_cond: *Association.Filter) ?*List(*Association);
pub fn load(conn: *Connection, filter: Association.Filter) !*List(*Association) {
    const data = slurmdb_associations_get(conn, @constCast(&filter));
    if (data) |d| {
        return d;
    } else {
        // TODO: Better error, this is just temporary.
        return error.Generic;
    }
}

pub extern fn slurmdb_associations_add(db_conn: ?*Connection, assoc_list: ?*List(*Association)) c_int;
pub fn add(conn: *Connection, associations: *List(*Association)) !void {
    const rc = slurmdb_associations_add(conn, associations);
    try checkRpc(rc);
}

pub extern fn slurmdb_associations_remove(db_conn: ?*Connection, assoc_cond: *Association.Filter) ?*List(CStr);
pub const removeRaw = slurmdb_associations_remove;

pub fn remove(conn: *Connection, filter: Association.Filter) !?*List(CStr) {
    const data = slurmdb_associations_remove(conn, @constCast(&filter));
    try err.getError();

    return if (data) |d|
        d
    else
        return error.Generic;
}
