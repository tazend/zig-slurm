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
const slurmctld = slurm.slurmctld;
const c = slurm.c;

pub const Association = extern struct {
    accounting_list: ?*List(*opaque {}) = null,
    acct: ?CStr = null,
    assoc_next: ?*db.Association = null,
    assoc_next_id: ?*db.Association = null,
    bf_usage: ?*db.BackfillUsage = null,
    cluster: ?CStr = null,
    comment: ?CStr = null,
    def_qos_id: u32 = 0,
    flags: db.Association.Flags = .{},
    grp_jobs: u32 = NoValue.u32,
    grp_jobs_accrue: u32 = NoValue.u32,
    grp_submit_jobs: u32 = NoValue.u32,
    grp_tres: ?CStr = null,
    grp_tres_ctld: ?[*]u64 = null,
    grp_tres_mins: ?CStr = null,
    grp_tres_mins_ctld: ?[*]u64 = null,
    grp_tres_run_mins: ?CStr = null,
    grp_tres_run_mins_ctld: ?[*]u64 = null,
    grp_wall: u32 = NoValue.u32,
    id: u32 = NoValue.u32,
    is_def: u16 = NoValue.u16,
    leaf_usage: ?*db.Association.Usage = null,
    lineage: ?CStr = null,
    max_jobs: u32 = NoValue.u32,
    max_jobs_accrue: u32 = NoValue.u32,
    max_submit_jobs: u32 = NoValue.u32,
    max_tres_mins_pj: ?CStr = null,
    max_tres_mins_ctld: ?[*]u64 = null,
    max_tres_run_mins: ?CStr = null,
    max_tres_run_mins_ctld: ?[*]u64 = null,
    max_tres_pj: ?CStr = null,
    max_tres_ctld: ?[*]u64 = null,
    max_tres_pn: ?CStr = null,
    max_tres_pn_ctld: ?[*]u64 = null,
    max_wall_pj: u32 = NoValue.u32,
    min_prio_thresh: u32 = NoValue.u32,
    parent_acct: ?CStr = null,
    parent_id: u32 = NoValue.u32,
    partition: ?CStr = null,
    priority: u32 = NoValue.u32,
    qos_list: ?*List(*opaque {}) = null,
    shares_raw: u32 = NoValue.u32,
    uid: u32 = NoValue.u32,
    usage: ?*db.Association.Usage = null,
    user: ?CStr = null,
    user_rec: ?*db.User = null,

    pub const Filter = extern struct {
        acct_list: ?*List(CStr) = null,
        cluster_list: ?*List(CStr) = null,
        def_qos_id_list: ?*List(CStr) = null,
        flags: db.Association.Filter.Flags = .{},
        format_list: ?*List(CStr) = null,
        id_list: ?*List(CStr) = null,
        parent_acct_list: ?*List(CStr) = null,
        partition_list: ?*List(CStr) = null,
        qos_list: ?*List(CStr) = null,
        usage_end: time_t = 0,
        usage_start: time_t = 0,
        user_list: ?*List(CStr) = null,

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

    pub const Flags = packed struct(c_uint) {
        deleted: bool = false,
        no_update: bool = false,
        exact: bool = false,
        no_users_are_coordinators: bool = false,
        _pad1: u12 = 0,
        users_are_coordinators: bool = false,
        block_add: bool = false,
        _pad2: u14 = 0,
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
        parent_assoc_ptr: ?*db.Association = null,
        priority_norm: f64 = @import("std").mem.zeroes(f64),
        fs_assoc_ptr: ?*db.Association = null,
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

    pub const Shares = extern struct {
        assoc_id: u32 = 0,
        cluster: ?CStr = null,
        name: ?CStr = null,
        parent: ?CStr = null,
        partition: ?CStr = null,
        shares_norm: f64 = 0.0,
        shares_raw: u32 = 0,
        tres_run_secs: ?[*]u64 = null,
        tres_grp_mins: ?[*]u64 = null,
        usage_efctv: f64 = 0.0,
        usage_norm: f64 = 0.0,
        usage_raw: u64 = 0,
        // TODO: Can we just use f80?
        usage_tres_raw: ?[*]c_longdouble = null,
        fs_factor: f64 = 0.0,
        level_fs: f64 = 0.0,
        user: u16 = 0,

        pub const LoadResponse = extern struct {
            shares: ?*List(*Shares) = null,
            count: u64,
            tres_count: u32 = 0,
            tres_names: ?*CStr = null,

            pub fn deinit(self: *LoadResponse) void {
                c.slurm_free_shares_response_msg(self);
            }

            pub fn iter(self: *LoadResponse) !*db.List(*Shares).Iterator {
                return if (self.shares) |shares|
                    shares.iter()
                else
                    error.Generic;
            }
        };

        pub const Request = extern struct {
            accounts: ?*List(CStr) = null,
            users: ?*List(CStr) = null,
        };

        pub fn isUserAssociation(self: *Shares) bool {
            return if (self.user > 0)
                true
            else
                false;
        }
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


pub fn loadSharesAll() !*Association.Shares.LoadResponse {
    var msg: Association.Shares.Request = .{};
    var req: slurmctld.slurm_msg_t = undefined;
    var resp: slurmctld.slurm_msg_t = undefined;

    slurmctld.slurm_msg_t_init(&req);
    slurmctld.slurm_msg_t_init(&resp);

    req.msg_type = .request_share_info;
    req.data = &msg;

    try err.checkRpc(slurmctld.slurm_send_recv_controller_msg(
        &req,
        &resp,
        db.working_cluster_rec,
    ));

    switch (resp.msg_type) {
        .response_share_info => return @alignCast(@ptrCast(resp.data)),
        .response_slurm_rc => {
            const data: ?*slurmctld.return_code_msg_t = @alignCast(@ptrCast(resp.data));
            if (data) |d| { // TODO: properly handle this error
                _ = d.return_code;
                slurmctld.slurm_free_return_code_msg(d);
            }
            return error.Generic;
        },
        else => return error.UnexpectedMsg,
    }
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
