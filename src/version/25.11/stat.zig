const std = @import("std");
const err = slurm.err;
const common = @import("common.zig");
const db = @import("db.zig");
const slurm = @import("root.zig");
const slurm_allocator = slurm.slurm_allocator;
const SlurmError = err.Error;
const time_t = std.os.linux.time_t;
const NoValue = common.NoValue;
const Infinite = common.Infinite;
const CStr = common.CStr;
const Allocator = std.mem.Allocator;
const Step = slurm.Step;
const AssociationManager = slurm.db.Association.Manager;
const AssociationManagerLocks = AssociationManager.Locks;
const c = slurm.c;

pub const stepd_step_rec_t = opaque {};

pub const StatError = SlurmError || error{OutOfMemory};

pub const InternalJobAccounting = extern struct {
    pid: std.posix.pid_t,
    sys_cpu_sec: u64,
    sys_cpu_usec: u32,
    user_cpu_sec: u64,
    user_cpu_usec: u32,
    act_cpufreq: u32,
    energy: slurm.AccountingGatherEnergy,
    last_total_cputime: f64, // double
    this_sampled_cputime: f64, // double
    current_weighted_freq: u32,
    current_weighted_power: u32,
    tres_count: u32,
    tres_ids: [*]u32,
    tres_list: ?*db.List(*db.TrackableResource),
    tres_usage_in_max: [*]u64,
    tres_usage_in_max_nodeid: [*]u64,
    tres_usage_in_max_taskid: [*]u64,
    tres_usage_in_min: [*]u64,
    tres_usage_in_min_nodeid: [*]u64,
    tres_usage_in_min_taskid: [*]u64,
    tres_usage_in_tot: [*]u64,
    tres_usage_out_max: [*]u64,
    tres_usage_out_max_nodeid: [*]u64,
    tres_usage_out_max_taskid: [*]u64,
    tres_usage_out_min: [*]u64,
    tres_usage_out_min_nodeid: [*]u64,
    tres_usage_out_min_taskid: [*]u64,
    tres_usage_out_tot: [*]u64,

    id: ID,
    dataset_id: c_int,

    last_tres_usage_in_tot: f64, // double
    last_tres_usage_out_tot: f64, // double
    cur_time: time_t,
    last_time: time_t,

    pub const ID = extern struct {
        taskid: u32,
        nodeid: u32,
        step: ?*stepd_step_rec_t = null,
    };
};

pub const StepPIDs = extern struct {
    node_name: ?CStr,
    pid: [*c]u32,
    pid_cnt: u32,
};

pub const StepStatItem = extern struct {
    jobacct: ?*InternalJobAccounting,
    num_tasks: u32,
    return_code: u32,
    step_pids: ?*StepPIDs,
};

pub const StepStatResponse = extern struct {
    stats_list: ?*db.List(*StepStatItem),
    step_id: Step.ID,
};

pub const TotalJobAccounting = struct {
    inner: ?*InternalJobAccounting,

    pub const empty: TotalJobAccounting = .{
        .inner = null,
    };

    pub fn isEmpty(self: *const TotalJobAccounting) bool {
        return self.inner == null;
    }

    pub fn init(self: *TotalJobAccounting, step_jobacct: *InternalJobAccounting) void {
        if (db.assoc_mgr_tres_list == null and step_jobacct.tres_list != null) {
            setupAssociationManagerTRES(step_jobacct);
        }
        self.inner = c.jobacctinfo_create(null);
    }

    pub fn aggregate(self: *TotalJobAccounting, step_jobacct: *InternalJobAccounting) void {
        c.jobacctinfo_aggregate(self.inner.?, step_jobacct);
    }

    pub fn convertToStep(self: *TotalJobAccounting) db.Step {
        var db_step: db.Step = std.mem.zeroInit(db.Step, .{});
        if (self.inner) |inner| {
            c.jobacctinfo_2_stats(&db_step.stats, inner);
            db_step.user_cpu_sec = inner.user_cpu_sec;
            db_step.sys_cpu_sec = inner.sys_cpu_sec;
            c.jobacctinfo_destroy(inner);
            inner.* = undefined;
        }
        return db_step;
    }
};

pub fn statStep(allocator: std.mem.Allocator, s: *Step) StatError!Step.Statistics {
    var total_jobacct: TotalJobAccounting = .empty;
    var stat_resp: ?*StepStatResponse = null;
    var ntasks: u32 = 0;

    const rc = c.slurm_job_step_stat(&s.step_id, s.nodes, s.start_protocol_ver, &stat_resp);
    try err.checkRpc(rc);
    const resp = stat_resp orelse return error.Generic;
    defer c.slurm_job_step_stat_response_msg_free(stat_resp);

    var node_list: std.ArrayList([:0]const u8) = .empty;
    defer node_list.deinit(allocator);

    const stat_list = resp.stats_list orelse return .{};
    var stat_iter = stat_list.iter();
    defer stat_iter.deinit();

    while (stat_iter.next()) |stat| {
        if (stat.step_pids == null or stat.step_pids.?.node_name == null) continue;

        // TODO: PIDs?

        if (stat.step_pids.?.node_name) |nn| {
            try node_list.append(allocator, std.mem.span(nn));
        }
        ntasks += stat.num_tasks;

        const step_jobacct = stat.jobacct orelse continue;

        if (total_jobacct.isEmpty()) total_jobacct.init(step_jobacct);
        total_jobacct.aggregate(step_jobacct);
    }

    var db_step = total_jobacct.convertToStep();
    var db_stats = &db_step.stats;
    defer c.slurmdb_free_slurmdb_stats_members(db_stats);

    if (ntasks > 0) {
        db_stats.act_cpufreq /= @floatFromInt(ntasks);
        setAverageUsage(&db_stats.tres_usage_in_ave, @intCast(ntasks));
        setAverageUsage(&db_stats.tres_usage_out_ave, @intCast(ntasks));
    }

    // TODO: this is just for prototyping, make this more ergonomic
    const cpus = if (s.num_cpus != NoValue.u32 and s.num_cpus > 0) s.num_cpus else 1;
    const run_time = if (s.run_time != NoValue.u32) s.run_time else 0;
    return parseStats(&db_step, node_list, cpus, run_time, true);
}

fn setupAssociationManagerTRES(jobacct: *InternalJobAccounting) void {
    var locks: AssociationManagerLocks = .{ .tres = .write_lock };
    AssociationManager.lock(&locks);
    AssociationManager.postTRESList(jobacct.tres_list.?);
    AssociationManager.unlock(&locks);
    jobacct.tres_list = null;
}

fn setAverageUsage(usage: *?CStr, ntasks: c_int) void {
    const tmp = usage.*;
    if (tmp) |t| {
        defer slurm_allocator.free(std.mem.span(t));
        usage.* = c.slurmdb_ave_tres_usage(t, ntasks);
    }
}

pub fn find_tres_count(tres_str_in: ?CStr, id: slurm.TresType) u64 {
    const out: u64 = c.slurmdb_find_tres_count_in_string(tres_str_in, id);
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
    pstats.max_disk_read_task = find_tres_count(stat.tres_usage_in_max_taskid, .fs_disk);

    pstats.max_disk_write = find_tres_count(stat.tres_usage_out_max, .fs_disk);
    pstats.max_disk_write_task = find_tres_count(stat.tres_usage_out_max_taskid, .fs_disk);

    pstats.max_resident_memory = find_tres_count(stat.tres_usage_in_max, .mem);
    pstats.max_resident_memory_task = find_tres_count(stat.tres_usage_in_max_taskid, .mem);

    pstats.max_virtual_memory = find_tres_count(stat.tres_usage_in_max, .vmem);
    pstats.max_virtual_memory_task = find_tres_count(stat.tres_usage_in_max_taskid, .vmem);

    pstats.min_cpu_time = @intCast(find_tres_count(stat.tres_usage_in_min, .cpu) / cpu_time_adj);
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
        const max_disk_read_nodeid = find_tres_count(stat.tres_usage_in_max_nodeid, .fs_disk);
        const max_disk_write_nodeid = find_tres_count(stat.tres_usage_out_max_nodeid, .fs_disk);
        const min_cpu_time_nodeid = find_tres_count(stat.tres_usage_in_min_nodeid, .cpu);
        const max_resident_memory_nodeid = find_tres_count(stat.tres_usage_in_max_nodeid, .mem);
        const max_virtual_memory_nodeid = find_tres_count(stat.tres_usage_in_max_nodeid, .vmem);
        // TODO: is this really safe without allocating?
        pstats.max_disk_write_node = nodes.items[max_disk_write_nodeid];
        pstats.max_disk_read_node = nodes.items[max_disk_read_nodeid];
        pstats.max_resident_memory_node = nodes.items[max_resident_memory_nodeid];
        pstats.max_virtual_memory_node = nodes.items[max_virtual_memory_nodeid];
        pstats.min_cpu_time_node = nodes.items[min_cpu_time_nodeid];
    }

    return pstats;
}
