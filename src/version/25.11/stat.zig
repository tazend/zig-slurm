const std = @import("std");
const err = slurm.err;
const common = @import("../common.zig");
const cdef = @import("../slurm-ext.zig");
const db = @import("../db.zig");
const slurm = @import("../root.zig");
const slurm_allocator = slurm.slurm_allocator;
const SlurmError = err.Error;
const time_t = std.os.linux.time_t;
const NoValue = common.NoValue;
const Infinite = common.Infinite;
const CStr = common.CStr;
const Allocator = std.mem.Allocator;
const Step = slurm.Step;
const Job = slurm.Job;

pub const stepd_step_rec_t = opaque {};

pub const Jobacctinfo = extern struct {
    pid: std.posix.pid_t,
    sys_cpu_sec: u64,
    sys_cpu_usec: u32,
    user_cpu_sec: u64,
    user_cpu_usec: u32,
    act_cpufreq: u32,
    energy: cdef.AccountingGatherEnergy,
    last_total_cputime: f64, // double
    this_sampled_cputime: f64, // double
    current_weighted_freq: u32,
    current_weighted_power: u32,
    tres_count: u32,
    tres_ids: [*]u32,
    tres_list: ?*db.List(*db.TrackableResource),
    tres_usage_in_max: u64,
    tres_usage_in_max_nodeid: u64,
    tres_usage_in_max_taskid: u64,
    tres_usage_in_min: u64,
    tres_usage_in_min_nodeid: u64,
    tres_usage_in_min_taskid: u64,
    tres_usage_in_tot: u64,
    tres_usage_out_max: u64,
    tres_usage_out_max_nodeid: u64,
    tres_usage_out_max_taskid: u64,
    tres_usage_out_min: u64,
    tres_usage_out_min_nodeid: u64,
    tres_usage_out_min_taskid: u64,
    tres_usage_out_tot: u64,

    id: JobacctID,
    dataset_id: c_int,

    last_tres_usage_in_tot: f64, // double
    last_tres_usage_out_tot: f64, // double
    cur_time: time_t,
    last_time: time_t,
};

pub const JobacctID = extern struct {
    taskid: u32,
    nodeid: u32,
    step: ?*stepd_step_rec_t = null,
};

pub const job_step_pids_t = extern struct {
    node_name: ?CStr = null,
    pid: [*c]u32 = @import("std").mem.zeroes([*c]u32),
    pid_cnt: u32 = @import("std").mem.zeroes(u32),
};

pub const job_step_stat_t = extern struct {
    jobacct: ?*Jobacctinfo = null,
    num_tasks: u32,
    return_code: u32,
    step_pids: ?*job_step_pids_t = null,
};

pub const job_step_stat_response_msg_t = extern struct {
    stats_list: ?*db.List(*job_step_stat_t),
    step_id: Step.ID,
};

pub const lock_level_t = enum(c_uint) {
    no_lock,
    read_lock,
    write_lock,
};

pub const assoc_mgr_lock_t = extern struct {
    assoc: lock_level_t = .no_lock,
    file: lock_level_t = .no_lock,
    qos: lock_level_t = .no_lock,
    res: lock_level_t = .no_lock,
    tres: lock_level_t = .no_lock,
    user: lock_level_t = .no_lock,
    wckey: lock_level_t = .no_lock,
};

pub extern fn assoc_mgr_lock(locks: *assoc_mgr_lock_t) void;
pub extern fn assoc_mgr_unlock(locks: *assoc_mgr_lock_t) void;
pub extern fn assoc_mgr_post_tres_list(new_list: *db.List(*db.TrackableResource)) void;
pub extern fn jobacctinfo_create(jobacct_id: ?*JobacctID) ?*Jobacctinfo;
pub extern fn jobacctinfo_destroy(object: *void) void;
pub extern fn jobacctinfo_aggregate(dest: *Jobacctinfo, from: *Jobacctinfo) void;
pub extern fn jobacctinfo_2_stats(stats: *db.Step.Stats, jobacct: *Jobacctinfo) void;
pub extern fn slurmdb_ave_tres_usage(tres_string: ?CStr, tasks: u32) ?CStr; // tasks was c_int
pub extern fn slurm_job_step_stat_response_msg_free(object: ?*anyopaque) void;
pub extern fn slurmdb_find_tres_count_in_string(tres_str_in: ?CStr, id: cdef.TresType) u64;
pub extern fn slurmdb_free_slurmdb_stats_members(stats: *db.StepStats) void;

pub extern fn slurm_job_step_stat(
    step_id: *Step.ID,
    node_list: ?CStr,
    use_protocol_ver: u16,
    resp: *?*job_step_stat_response_msg_t,
) c_int;

pub fn statStep(allocator: std.mem.Allocator, s: *Step) anyerror!Step.Statistics {
    var total_jobacct: ?*Jobacctinfo = null;
    var stat_resp: ?*job_step_stat_response_msg_t = null;
    var db_step: db.Step = std.mem.zeroInit(db.Step, .{});
    var db_stats = &db_step.stats;
    var ntasks: u32 = 0;

    const rc = slurm_job_step_stat(
        &s.step_id,
        null,
        s.start_protocol_ver,
        &stat_resp,
    );
    try err.checkRpc(rc);
    defer slurm_job_step_stat_response_msg_free(@ptrCast(stat_resp));
    //defer c.slurmdb_free_slurmdb_stats_members(&db_stats);

    // TODO: deinit stats members

    var node_list = std.ArrayList([:0]const u8).init(allocator);
    defer node_list.deinit();

    if (stat_resp.?.stats_list) |stat_list| {
        var stat_iter = stat_list.iter();
        defer stat_iter.deinit();

        while (stat_iter.next()) |stat| {
            if (stat.step_pids == null or stat.step_pids.?.node_name == null) continue;

            // TODO: PIDs?

            if (stat.step_pids.?.node_name) |nn| {
                try node_list.append(std.mem.span(nn));
            }
            ntasks += stat.num_tasks;

            if (stat.jobacct) |jobacct| {
                if (db.assoc_mgr_tres_list == null and jobacct.tres_list != null) {
                    const locks: assoc_mgr_lock_t = .{ .tres = .write_lock };
                    assoc_mgr_lock(@constCast(&locks));
                    assoc_mgr_post_tres_list(jobacct.tres_list.?);
                    assoc_mgr_unlock(@constCast(&locks));

                    jobacct.tres_list = null;
                }

                if (total_jobacct == null) {
                    total_jobacct = jobacctinfo_create(null);
                }

                jobacctinfo_aggregate(total_jobacct.?, jobacct);
            }
        }

        if (total_jobacct) |tj| {
            jobacctinfo_2_stats(db_stats, tj);
            jobacctinfo_destroy(@ptrCast(tj));
        }

        if (ntasks > 0) {
            db_stats.act_cpufreq /= @floatFromInt(ntasks);

            var usage_tmp = db_stats.tres_usage_in_ave;
            if (usage_tmp) |tmp| {
                db_stats.tres_usage_in_ave = slurmdb_ave_tres_usage(usage_tmp, ntasks);
                slurm_allocator.free(std.mem.span(tmp));
            }

            usage_tmp = db_stats.tres_usage_out_ave;
            if (usage_tmp) |tmp| {
                db_stats.tres_usage_out_ave = slurmdb_ave_tres_usage(usage_tmp, ntasks);
                slurm_allocator.free(std.mem.span(tmp));
            }
        }
    }

    // TODO: this is just for prototyping, make this more ergonomic
    const cpus = if (s.num_cpus != NoValue.u32 and s.num_cpus > 0) s.num_cpus else 1;
    const run_time = if (s.run_time != NoValue.u32) s.run_time else 0;
    return parseStats(&db_step, node_list, cpus, run_time, true);
}

pub fn find_tres_count(tres_str_in: ?CStr, id: cdef.TresType) u64 {
    const out: u64 = slurmdb_find_tres_count_in_string(tres_str_in, id);
    return if (out == NoValue.u64 or out == Infinite.u64)
        0
    else
        out;
}

pub fn parseStats(
    step: *db.Step,
    nodes: std.ArrayList([:0]const u8),
    cpus: u32,
    elapsed_time: time_t,
    is_live: bool,
) SlurmError!Step.Statistics {
    var pstats: Step.Statistics = .{};
    const cpu_time_adj: u64 = 1000;
    const stat = &step.stats;

    if (stat.consumed_energy != NoValue.u64) {
        pstats.consumed_energy = stat.consumed_energy;
    }

    pstats.avg_cpu_time = @intCast(
        find_tres_count(stat.tres_usage_in_ave, .cpu) / cpu_time_adj,
    );

    pstats.elapsed_cpu_time = @intCast(elapsed_time * cpus);

    const ave_freq: u64 = @intFromFloat(stat.act_cpufreq);
    if (ave_freq != NoValue.u64) {
        pstats.avg_cpu_frequency = ave_freq;
    }

    pstats.avg_disk_read = find_tres_count(stat.tres_usage_in_ave, .fs_disk);
    pstats.avg_disk_write = find_tres_count(stat.tres_usage_out_ave, .fs_disk);
    pstats.avg_page_faults = find_tres_count(stat.tres_usage_in_ave, .pages);
    pstats.avg_resident_memory = find_tres_count(stat.tres_usage_in_ave, .mem);
    pstats.avg_virtual_memory = find_tres_count(stat.tres_usage_in_ave, .vmem);

    pstats.max_disk_read = find_tres_count(stat.tres_usage_in_max, .fs_disk);
    const max_disk_read_nodeid = find_tres_count(stat.tres_usage_in_max_nodeid, .fs_disk);
    pstats.max_disk_read_task = find_tres_count(stat.tres_usage_in_max_taskid, .fs_disk);

    pstats.max_disk_write = find_tres_count(stat.tres_usage_out_max, .fs_disk);
    const max_disk_write_nodeid = find_tres_count(stat.tres_usage_out_max_nodeid, .fs_disk);
    pstats.max_disk_write_task = find_tres_count(stat.tres_usage_out_max_taskid, .fs_disk);

    pstats.max_resident_memory = find_tres_count(stat.tres_usage_in_max, .mem);
    const max_resident_memory_nodeid = find_tres_count(stat.tres_usage_in_max_nodeid, .mem);
    pstats.max_resident_memory_task = find_tres_count(stat.tres_usage_in_max_taskid, .mem);

    pstats.max_virtual_memory = find_tres_count(stat.tres_usage_in_max, .vmem);
    const max_virtual_memory_nodeid = find_tres_count(stat.tres_usage_in_max_nodeid, .vmem);
    pstats.max_virtual_memory_task = find_tres_count(stat.tres_usage_in_max_taskid, .vmem);

    pstats.min_cpu_time = @intCast(find_tres_count(stat.tres_usage_in_min, .cpu) / cpu_time_adj);
    const min_cpu_time_nodeid = find_tres_count(stat.tres_usage_in_min_nodeid, .cpu);
    pstats.min_cpu_time_task = find_tres_count(stat.tres_usage_in_min_taskid, .cpu);

    // The Total CPU-Time extracted here is only used for live-stats.
    // sacct does not use it from the tres_usage_in_tot string, but instead
    // the tot_cpu_sec value from the step pointer directly, so do that too.
    if (is_live) {
        pstats.total_cpu_time = @intCast(
            find_tres_count(stat.tres_usage_in_tot, .cpu) / cpu_time_adj,
        );
    } else if (step.tot_cpu_sec != NoValue.u64) {
        pstats.total_cpu_time += step.tot_cpu_sec;
    }

    if (step.user_cpu_sec != NoValue.u64) {
        pstats.user_cpu_time += step.user_cpu_sec;
    }

    if (step.sys_cpu_sec != NoValue.u64) {
        pstats.system_cpu_time += step.sys_cpu_sec;
    }

    if (nodes.items.len > 0) {
        // TODO: is this really safe without allocating?
        pstats.max_disk_write_node = nodes.items[max_disk_write_nodeid];
        pstats.max_disk_read_node = nodes.items[max_disk_read_nodeid];
        pstats.max_resident_memory_node = nodes.items[max_resident_memory_nodeid];
        pstats.max_virtual_memory_node = nodes.items[max_virtual_memory_nodeid];
        pstats.min_cpu_time_node = nodes.items[min_cpu_time_nodeid];
    }

    return pstats;
}
