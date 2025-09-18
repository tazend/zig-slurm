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
const BitString = common.BitString;

pub const QoS = extern struct {
    blocked_until: time_t = 0,
    description: ?CStr = null,
    id: u32,
    flags: u32,
    grace_time: u32,
    grp_jobs_accrue: u32,
    grp_jobs: u32,
    grp_submit_jobs: u32,
    grp_tres: ?CStr = null,
    grp_tres_ctld: ?[*]u64 = null,
    grp_tres_mins: ?CStr = null,
    grp_tres_mins_ctld: ?[*]u64 = null,
    grp_tres_run_mins: ?CStr = null,
    grp_tres_run_mins_ctld: ?[*]u64 = null,
    grp_wall: u32,
    limit_factor: f64,
    max_jobs_pa: u32,
    max_jobs_pu: u32,
    max_jobs_accrue_pa: u32,
    max_jobs_accrue_pu: u32,
    max_submit_jobs_pa: u32,
    max_submit_jobs_pu: u32,
    max_tres_mins_pj: ?CStr = null,
    max_tres_mins_pj_ctld: ?[*]u64 = null,
    max_tres_pa: ?CStr = null,
    max_tres_pa_ctld: ?[*]u64 = null,
    max_tres_pj: ?CStr = null,
    max_tres_pj_ctld: ?[*]u64 = null,
    max_tres_pn: ?CStr = null,
    max_tres_pn_ctld: ?[*]u64 = null,
    max_tres_pu: ?CStr = null,
    max_tres_pu_ctld: ?[*]u64 = null,
    max_tres_run_mins_pa: ?CStr = null,
    max_tres_run_mins_pa_ctld: ?[*]u64 = null,
    max_tres_run_mins_pu: ?CStr = null,
    max_tres_run_mins_pu_ctld: ?[*]u64 = null,
    max_wall_pj: u32,
    min_prio_thresh: u32,
    min_tres_pj: ?CStr = null,
    min_tres_pj_ctld: ?[*]u64 = null,
    name: ?CStr = null,
    preempt_bitstr: ?[*]BitString = null,
    preempt_list: ?*List(*opaque {}) = null,
    preempt_mode: u16,
    preempt_exempt_time: u32,
    priority: u32,
    relative_tres_cnt: ?[*]u64 = null,
    usage: ?*db.QoS.Usage = null,
    usage_factor: f64,
    usage_thres: f64,

    pub const Usage = extern struct {
        accrue_cnt: u32,
        acct_limit_list: ?*List(*opaque {}) = null,
        job_list: ?*List(*opaque {}) = null,
        grp_node_bitmap: ?[*]BitString = null,
        grp_node_job_cnt: ?[*]u16 = null,
        grp_used_jobs: u32,
        grp_used_submit_jobs: u32,
        grp_used_tres: ?[*]u64 = null,
        grp_used_tres_run_secs: ?[*]u64 = null,
        grp_used_wall: f64,
        norm_priority: f64,
        tres_cnt: u32,
        usage_raw: c_longdouble,
        usage_tres_raw: ?*c_longdouble = null,
        user_limit_list: ?*List(*opaque {}) = null,
    };

    pub const Filter = extern struct {
        description_list: ?*List(*opaque {}) = null,
        flags: u16,
        id_list: ?*List(*opaque {}) = null,
        format_list: ?*List(*opaque {}) = null,
        name_list: ?*List(*opaque {}) = null,
        preempt_mode: u16,
    };
};
