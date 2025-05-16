const std = @import("std");
const common = @import("common.zig");
const cdef = @import("slurm-ext.zig");
const SlurmError = @import("error.zig").Error;
const checkRpc = @import("error.zig").checkRpc;
const time_t = std.os.linux.time_t;
const CStr = common.CStr;
const JobState = @import("Job.zig").Job.State;
const BitString = common.BitString;
const StepID = @import("step.zig").Step.ID;
const xfree_ptr = @import("SlurmAllocator.zig").slurm_xfree_ptr;
const slurm_addr_t = @import("slurmctld.zig").slurm_addr_t;
const NoValue = common.NoValue;
const Infinite = common.Infinite;

pub extern var working_cluster_rec: *Cluster;
pub extern var assoc_mgr_tres_list: ?*List(*TrackableResource);

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

pub const Job = extern struct {
    account: ?CStr = null,
    admin_comment: ?CStr = null,
    alloc_nodes: u32 = 0,
    array_job_id: u32 = 0,
    array_max_tasks: u32 = 0,
    array_task_id: u32 = 0,
    array_task_str: ?CStr = null,
    associd: u32 = 0,
    blockid: ?CStr = null,
    cluster: ?CStr = null,
    constraints: ?CStr = null,
    container: ?CStr = null,
    db_index: u64 = 0,
    derived_ec: u32 = 0,
    derived_es: ?CStr = null,
    elapsed: u32 = 0,
    eligible: time_t = 0,
    end: time_t = 0,
    env: ?CStr = null,
    exitcode: u32 = 0,
    extra: ?CStr = null,
    failed_node: ?CStr = null,
    flags: u32 = 0,
    first_step_ptr: ?*anyopaque = null,
    gid: u32 = common.NoValue.u32,
    het_job_id: u32 = 0,
    het_job_offset: u32 = 0,
    job_id: u32 = 0,
    jobname: ?CStr = null,
    lft: u32 = 0,
    lineage: ?CStr = null,
    licenses: ?CStr = null,
    mcs_label: ?CStr = null,
    nodes: ?CStr = null,
    partition: ?CStr = null,
    priority: u32 = 0,
    qosid: u32 = 0,
    qos_req: ?CStr = null,
    req_cpus: u32 = 0,
    req_mem: u64 = 0,
    requid: u32 = 0,
    restart_cnt: u16 = 0,
    resvid: u32 = 0,
    resv_name: ?CStr = null,
    script: ?CStr = null,
    show_full: u32 = 0,
    start: time_t = 0,
    state: JobState = .empty,
    state_reason_prev: u32 = 0,
    steps: ?*List(*Step) = null,
    std_err: ?CStr = null,
    std_in: ?CStr = null,
    std_out: ?CStr = null,
    submit: time_t = 0,
    submit_line: ?CStr = null,
    suspended: u32 = 0,
    system_comment: ?CStr = null,
    sys_cpu_sec: u64 = 0,
    sys_cpu_usec: u64 = 0,
    timelimit: u32 = 0,
    tot_cpu_sec: u64 = 0,
    tot_cpu_usec: u64 = 0,
    tres_alloc_str: ?CStr = null,
    tres_req_str: ?CStr = null,
    uid: u32 = common.NoValue.u32,
    used_gres: ?CStr = null,
    user: ?CStr = null,
    user_cpu_sec: u64 = 0,
    user_cpu_usec: u64 = 0,
    wckey: ?CStr = null,
    wckeyid: u32 = 0,
    work_dir: ?CStr = null,
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

pub const TransactionFilter = extern struct {
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
};

pub const WCKeyFilter = extern struct {
    cluster_list: ?*List(CStr) = null,
    __format_list: ?*List(*opaque {}) = null,
    id_list: ?*List(CStr) = null,
    names: ?*List(CStr) = null,
    only_defs: u16 = NoValue.u32,
    usage_end: time_t = 0,
    usage_start: time_t = 0,
    user_list: ?*List(CStr) = null,
    with_usage: u16 = NoValue.u16,
    with_deleted: u16 = NoValue.u16,
};

pub const WCKey = extern struct {
    accounting_list: ?*List(*opaque {}) = null,
    cluster: ?CStr = null,
    flags: u32 = 0,
    id: u32 = NoValue.u32,
    is_def: u16 = 0,
    name: ?CStr = null,
    uid: u32 = NoValue.u32,
    user: ?CStr = null,
};

pub const SelectedStep = extern struct {
    array_bitmap: ?[*]BitString = null,
    array_task_id: u32 = NoValue.u32,
    het_job_offset: u32 = NoValue.u32,
    step_id: StepID,
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
    flags: JobFilterFlags = .{ .no_truncate = true },
    __format_list: ?*List(*opaque {}) = null,
    group_ids: ?*List(CStr) = null,
    names: ?*List(CStr) = null,
    nodes_max: u32 = 0,
    nodes_min: u32 = 0,
    partitions: ?*List(CStr) = null,
    qos_ids: ?*List(CStr) = null,
    reasons: ?*List(CStr) = null,
    reservations: ?*List(CStr) = null,
    __resvid_list: ?*List(*opaque {}) = null,
    states: ?*List(CStr) = null,
    steps: ?*List(*SelectedStep) = null,
    timelimit_max: u32 = 0,
    timelimit_min: u32 = 0,
    usage_end: time_t = 0,
    usage_start: time_t = 0,
    used_nodes: ?CStr = null,
    user_ids: ?*List(CStr) = null,
    wckeys: ?*List(CStr) = null,

    pub fn init() JobFilter {
        return .{
            .accounts = .init(),
            .user_ids = .init(),
        };
    }
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
    associations: ?*List(*Association) = null,
    coordinators: ?*List(*opaque {}) = null,
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
    associations: ?*List(*Association) = null,
    bf_usage: ?*BFUsage = null,
    coordinators: ?*List(*opaque {}) = null,
    default_account: ?CStr = null,
    default_wckey: ?CStr = null,
    flags: u32 = 0,
    name: ?CStr = null,
    old_name: ?CStr = null,
    user_id: u32 = 0,
    wckeys: ?*List(*WCKey) = null,

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

pub const AssociationUsage = extern struct {
    accrue_cnt: u32 = @import("std").mem.zeroes(u32),
    children_list: ?*List(*opaque {}) = null,
    grp_node_bitmap: ?[*]BitString = null,
    grp_node_job_cnt: [*c]u16 = @import("std").mem.zeroes([*c]u16),
    grp_used_tres: [*c]u64 = @import("std").mem.zeroes([*c]u64),
    grp_used_tres_run_secs: [*c]u64 = @import("std").mem.zeroes([*c]u64),
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

pub const Step = extern struct {
    container: ?CStr = null,
    elapsed: u32 = 0,
    end: time_t = 0,
    exitcode: i32 = 0,
    job_ptr: ?*Job = null,
    nnodes: u32 = 0,
    nodes: ?CStr = null,
    ntasks: u32 = 0,
    pid_str: ?CStr,
    req_cpufreq_min: u32 = 0,
    req_cpufreq_max: u32 = 0,
    req_cpufreq_gov: u32 = 0,
    requid: u32 = 0,
    start: time_t = 0,
    state: JobState,
    stats: StepStats = .{},
    step_id: StepID,
    stepname: ?CStr = null,
    submit_line: ?CStr = null,
    suspended: u32 = 0,
    sys_cpu_sec: u64 = 0,
    sys_cpu_usec: u32 = 0,
    task_dist: u32 = 0,
    tot_cpu_sec: u64 = 0,
    tot_cpu_usec: u32 = 0,
    tres_alloc_str: ?CStr = null,
    user_cpu_sec: u64 = 0,
    user_cpu_usec: u32 = 0,
};

pub const StepStats = extern struct {
    act_cpufreq: f64 = 0,
    consumed_energy: u64 = 0,
    tres_usage_in_ave: ?CStr = null,
    tres_usage_in_max: ?CStr = null,
    tres_usage_in_max_nodeid: ?CStr = null,
    tres_usage_in_max_taskid: ?CStr = null,
    tres_usage_in_min: ?CStr = null,
    tres_usage_in_min_nodeid: ?CStr = null,
    tres_usage_in_min_taskid: ?CStr = null,
    tres_usage_in_tot: ?CStr = null,
    tres_usage_out_ave: ?CStr = null,
    tres_usage_out_max: ?CStr = null,
    tres_usage_out_max_nodeid: ?CStr = null,
    tres_usage_out_max_taskid: ?CStr = null,
    tres_usage_out_min: ?CStr = null,
    tres_usage_out_min_nodeid: ?CStr = null,
    tres_usage_out_min_taskid: ?CStr = null,
    tres_usage_out_tot: ?CStr = null,
};

pub const Association = extern struct {
    __accounting_list: ?*List(*opaque {}) = null,
    account: ?CStr = null,
    __assoc_next: ?*Association = null,
    __assoc_next_id: ?*Association = null,
    __bf_usage: ?*BFUsage = null,
    cluster: ?CStr = null,
    comment: ?CStr = null,
    default_qos_id: u32 = 0,
    flags: AssociationFlags = .none,
    grp_jobs: u32 = NoValue.u32,
    grp_jobs_accrue: u32 = NoValue.u32,
    grp_submit_jobs: u32 = NoValue.u32,
    grp_tres: ?CStr = null,
    __grp_tres_ctld: ?*u64 = null,
    grp_tres_mins: ?CStr = null,
    __grp_tres_mins_ctld: ?*u64 = null,
    grp_tres_run_mins: ?CStr = null,
    __grp_tres_run_mins_ctld: ?*u64 = null,
    grp_wall: u32 = NoValue.u32,
    id: u32 = NoValue.u32,
    is_def: u16 = NoValue.u16,
    __leaf_usage: ?*AssociationUsage = null,
    lft: u32 = NoValue.u32,
    lineage: ?CStr = null,
    max_jobs: u32 = NoValue.u32,
    max_jobs_accrue: u32 = NoValue.u32,
    max_submit_jobs: u32 = NoValue.u32,
    max_tres_mins_pj: ?CStr = null,
    __max_tres_mins_ctld: ?*u64 = null,
    max_tres_run_mins: ?CStr = null,
    __max_tres_run_mins_ctld: ?*u64 = null,
    max_tres_pj: ?CStr = null,
    __max_tres_ctld: ?*u64 = null,
    max_tres_pn: ?CStr = null,
    __max_tres_pn_ctld: ?*u64 = null,
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
    usage: ?*AssociationUsage = null,
    user: ?CStr = null,
    __user_rec: ?*User = null,

    pub const get = loadAssociations;
};

pub const ClusterFederation = extern struct {
    feature_list: ?*List(*opaque {}) = null,
    id: u32 = @import("std").mem.zeroes(u32),
    name: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    recv: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    send: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    state: u32 = @import("std").mem.zeroes(u32),
    sync_recvd: bool = @import("std").mem.zeroes(bool),
    sync_sent: bool = @import("std").mem.zeroes(bool),
};

pub const Cluster = extern struct {
    accounting_list: ?*List(*opaque {}) = null,
    classification: u16 = 0,
    comm_fail_time: time_t = 0,
    control_addr: slurm_addr_t,
    control_host: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    control_port: u32 = @import("std").mem.zeroes(u32),
    dimensions: u16 = @import("std").mem.zeroes(u16),
    dim_size: [*c]c_int = @import("std").mem.zeroes([*c]c_int),
    id: u16 = @import("std").mem.zeroes(u16),
    fed: ClusterFederation = @import("std").mem.zeroes(ClusterFederation),
    flags: u32 = @import("std").mem.zeroes(u32),
    lock: std.c.pthread_mutex_t = @import("std").mem.zeroes(std.c.pthread_mutex_t),
    name: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    nodes: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    root_assoc: ?*Association = null,
    rpc_version: u16 = @import("std").mem.zeroes(u16),
    send_rpc: ?*List(*opaque {}) = null,
    tres_str: [*c]u8 = @import("std").mem.zeroes([*c]u8),
};

pub fn List(comptime T: type) type {
    return opaque {
        const Self = @This();

        const DestroyFunctionSignature = *const fn (object: ?*anyopaque) callconv(.C) void;

        pub extern fn slurmdb_destroy_assoc_usage(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_bf_usage(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_bf_usage_members(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_qos_usage(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_user_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_account_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_coord_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_clus_res_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_cluster_accounting_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_cluster_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_federation_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_accounting_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_assoc_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_event_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_instance_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_job_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_qos_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_reservation_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_step_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_res_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_txn_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_wckey_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_archive_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_tres_rec_noalloc(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_tres_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_report_assoc_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_report_user_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_report_cluster_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_user_cond(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_account_cond(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_cluster_cond(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_federation_cond(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_tres_cond(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_assoc_cond(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_event_cond(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_instance_cond(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_job_cond(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_job_cond_members(job_cond: *JobFilterFlags) void;
        pub extern fn slurmdb_destroy_qos_cond(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_reservation_cond(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_res_cond(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_txn_cond(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_wckey_cond(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_archive_cond(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_add_assoc_cond(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_update_object(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_used_limits(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_print_tree(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_hierarchical_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_report_job_grouping(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_report_acct_grouping(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_report_cluster_grouping(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_rpc_obj(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_rollup_stats(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_stats_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_slurmdb_stats(stats: *StepStats) void;

        const DestroyFunction: DestroyFunctionSignature = switch (T) {
            *User => slurmdb_destroy_user_rec,
            *Association => slurmdb_destroy_assoc_rec,
            CStr => xfree_ptr,
            else => @compileError("List destruction not implemented for: " ++ @typeName(T)),
        };

        pub const Iterator = struct {
            const list_itr_t = opaque {};
            c_handle: *list_itr_t,
            index: usize = 0,

            pub extern fn slurm_list_next(i: ?*list_itr_t) ?T;
            pub fn next(it: *Iterator) ?T {
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

        extern fn slurm_list_create(f: DestroyFunctionSignature) ?*List(T);
        pub fn init() *List(T) {
            const list = slurm_list_create(DestroyFunction);
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

        extern fn slurm_list_pop(l: ?*List(T)) ?T;
        pub fn pop(self: *Self) ?*T {
            return slurm_list_pop(self);
        }

        extern fn slurm_list_is_empty(l: ?*List(T)) c_int;
        pub fn isEmpty(self: *Self) bool {
            return slurm_list_is_empty(self) == 1;
        }

        pub extern fn slurm_list_append(l: ?*List(T), x: ?T) void;
        pub fn append(self: *Self, item: T) void {
            slurm_list_append(self, item);
        }

        pub fn toOwnedSlice(
            self: *Self,
            allocator: std.mem.Allocator,
        ) std.mem.Allocator.Error![]T {
            var data: []T = try allocator.alloc(T, @intCast(self.size()));

            var index = 0;
            while (self.pop()) |ptr| {
                const item = @as(T, @alignCast(@ptrCast(ptr)));
                data[index] = item;
                index += 1;
            }

            self.deinit();
            return data;
        }

        pub fn toArrayList(self: *Self, allocator: std.mem.Allocator) !std.ArrayList(T) {
            return std.ArrayList(T).fromOwnedSlice(
                allocator,
                try self.toOwnedSlice(allocator),
            );
        }

        pub fn fromOwnedSlice(items: []T) *List(T) {
            var list = List(T).init();
            for (items) |*i| {
                list.append(@ptrCast(i));
            }
            return list;
        }
    };
}

pub fn createCStrList(items: [][:0]const u8) *List(CStr) {
    var list = List(CStr).init();
    for (items) |*i| {
        //std.debug.print("name: {s}\n", .{&i.ptr});
        list.append(i.ptr);
    }
    return list;
}

pub extern fn slurmdb_associations_get(db_conn: ?*Connection, assoc_cond: *AssociationFilter) ?*List(*Association);
pub fn loadAssociations(conn: *Connection, filter: AssociationFilter) !*List(*Association) {
    const data = slurmdb_associations_get(conn, @constCast(&filter));
    if (data) |d| {
        return d;
    } else {
        // TODO: Better error, this is just temporary.
        return error.Generic;
    }
}

pub extern fn slurmdb_associations_add(db_conn: ?*Connection, assoc_list: ?*List(*Association)) c_int;
pub fn createAssociations(conn: *Connection, associations: *List(*Association)) !void {
    const rc = slurmdb_associations_add(conn, associations);
    try checkRpc(rc);
}

pub extern fn slurmdb_accounts_get(db_conn: ?*Connection, acct_cond: *AccountFilter) ?*List(*Account);
pub fn loadAccounts(conn: *Connection, filter: AccountFilter) !*List(*Account) {
    const data = slurmdb_accounts_get(conn, @constCast(&filter));
    if (data) |d| {
        return d;
    } else {
        // TODO: Better error, this is just temporary.
        return error.Generic;
    }
}

pub extern fn slurmdb_accounts_add(db_conn: ?*Connection, acct_list: ?*List(*Account)) c_int;
pub fn createAccounts(conn: *Connection, accounts: *List(*Account)) !void {
    const rc = slurmdb_accounts_add(conn, accounts);
    try checkRpc(rc);
}

pub extern fn slurmdb_users_get(db_conn: ?*Connection, user_cond: *UserFilter) ?*List(*User);
pub fn loadUsers(conn: *Connection, filter: UserFilter) !*List(*User) {
    const data = slurmdb_users_get(conn, @constCast(&filter));
    if (data) |d| {
        return d;
    } else {
        // TODO: Better error, this is just temporary.
        return error.Generic;
    }
}

pub extern fn slurmdb_users_add(db_conn: ?*Connection, user_list: ?*List(*User)) c_int;
pub fn createUsers(conn: *Connection, users: *List(*User)) !void {
    const rc = slurmdb_users_add(conn, users);
    try checkRpc(rc);
}

pub extern fn slurmdb_jobs_get(db_conn: ?*Connection, job_cond: *JobFilter) ?*List(*Job);
pub fn loadJobs(conn: *Connection, filter: JobFilter) !*List(*Job) {
    const data = slurmdb_jobs_get(conn, @constCast(&filter));
    if (data) |d| {
        return d;
    } else {
        return error.Generic;
    }
}
