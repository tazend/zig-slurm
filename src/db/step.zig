const std = @import("std");
const db = @import("../db.zig");
const common = @import("../common.zig");
const slurm = @import("../root.zig");
const JobState = slurm.Job.State;
const CStr = common.CStr;
const NoValue = common.NoValue;
const Infinite = common.Infinite;
const BitString = common.BitString;
const time_t = std.posix.time_t;
const List = db.List;
const Connection = db.Connection;

pub const Step = extern struct {
    container: ?CStr = null,
    elapsed: u32 = 0,
    end: time_t = 0,
    exitcode: i32 = 0,
    job_ptr: ?*db.Job = null,
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
    stats: db.Step.Stats = .{},
    step_id: slurm.Step.ID,
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

    pub const Selected = extern struct {
        array_bitmap: ?[*]BitString = null,
        array_task_id: u32 = NoValue.u32,
        het_job_offset: u32 = NoValue.u32,
        step_id: slurm.Step.ID,
    };

    pub const Stats = extern struct {
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
};
