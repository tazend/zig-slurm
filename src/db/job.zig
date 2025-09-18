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
    gid: u32 = NoValue.u32,
    het_job_id: u32 = 0,
    het_job_offset: u32 = 0,
    jobid: u32 = 0,
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
    steps: ?*List(*db.Step) = null,
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
    uid: u32 = NoValue.u32,
    used_gres: ?CStr = null,
    user: ?CStr = null,
    user_cpu_sec: u64 = 0,
    user_cpu_usec: u64 = 0,
    wckey: ?CStr = null,
    wckeyid: u32 = 0,
    work_dir: ?CStr = null,

    pub const Filter = extern struct {
        acct_list: ?*List(CStr) = null,
        associd_list: ?*List(CStr) = null,
        cluster_list: ?*List(CStr) = null,
        constraint_list: ?*List(CStr) = null,
        cpus_max: u32 = 0,
        cpus_min: u32 = 0,
        db_flags: u32 = NoValue.u32,
        exitcode: i32 = 0,
        flags: db.Job.Filter.Flags = .{ .no_truncate = true },
        format_list: ?*List(*opaque {}) = null,
        groupid_list: ?*List(CStr) = null,
        jobname_list: ?*List(CStr) = null,
        nodes_max: u32 = 0,
        nodes_min: u32 = 0,
        partition_list: ?*List(CStr) = null,
        qos_list: ?*List(CStr) = null,
        reason_list: ?*List(CStr) = null,
        resv_list: ?*List(CStr) = null,
        resvid_list: ?*List(*opaque {}) = null,
        state_list: ?*List(CStr) = null,
        step_list: ?*List(*db.SelectedStep) = null,
        timelimit_max: u32 = 0,
        timelimit_min: u32 = 0,
        usage_end: time_t = 0,
        usage_start: time_t = 0,
        used_nodes: ?CStr = null,
        userid_list: ?*List(CStr) = null,
        wckey_list: ?*List(CStr) = null,

        pub fn init() Filter {
            return .{
                .accounts = .init(),
                .user_ids = .init(),
            };
        }

        pub const Flags = packed struct(u32) {
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

            pub usingnamespace common.BitflagMethods(Flags, u32);
        };
    };
};

pub extern fn slurmdb_jobs_get(db_conn: ?*Connection, job_cond: *Job.Filter) ?*List(*Job);
pub fn loadJobs(conn: *Connection, filter: Job.Filter) !*List(*Job) {
    const data = slurmdb_jobs_get(conn, @constCast(&filter));
    if (data) |d| {
        return d;
    } else {
        return error.Generic;
    }
}
