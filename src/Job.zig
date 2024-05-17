const c = @import("c.zig").c;
const std = @import("std");
const err = @import("error.zig");
const SlurmError = @import("error.zig").Error;
const time_t = std.os.linux.time_t;
const JobIdList = std.ArrayList(JobId);

const Job = @This();
pub const JobId = u32;
pub const ResponseMessage = c.job_info_msg_t;
pub const RawJob = c.slurm_job_info_t;

c_ptr: *RawJob = undefined,
id: JobId,

pub const SignalFlags = packed struct(u16) {
    batch: bool = false,
    array_task: bool = false,
    steps_only: bool = false,
    full: bool = false,
    fed_requeue: bool = false,
    hurry: bool = false,
    oom: bool = false,
    no_sibs: bool = false,
    resv: bool = false,
    no_cron: bool = false,
    no_sig_fail: bool = false,
    jobs_verbose: bool = false,

    _padding1: u4 = 0,

    comptime {
        std.debug.assert(
            @sizeOf(@This()) == @sizeOf(u16) and
                @bitSizeOf(@This()) == @bitSizeOf(u16),
        );
    }
};

pub const ProfileTypes = packed struct(u32) {
    _padding1: u1 = 0,
    energy: bool = false,
    task: bool = false,
    lustre: bool = false,
    network: bool = false,

    _padding2: u27 = 0,

    pub const all: ProfileTypes = @bitCast(@as(u32, (1 << 32) - 1));

    pub fn toStr(self: @This(), allocator: std.mem.Allocator) ![]const u8 {
        return try bitflagToStr(self, allocator, 2);
    }

    comptime {
        std.debug.assert(
            @sizeOf(@This()) == @sizeOf(u32) and
                @bitSizeOf(@This()) == @bitSizeOf(u32),
        );
    }
};

pub fn profileTypes(self: Job) ?ProfileTypes {
    if (self.c_ptr.profile == c.NO_VAL or self.c_ptr.profile == c.ACCT_GATHER_PROFILE_NOT_SET) {
        return null;
    }

    if ((self.c_ptr.profile & c.ACCT_GATHER_PROFILE_ALL) == 0) {
        return ProfileTypes.all;
    }

    return @bitCast(self.c_ptr.profile);
}

pub const State = enum {
    pending,
    running,
    suspended,
    complete,
    cancelled,
    failed,
    timeout,
    node_fail,
    preempted,
    boot_fail,
    deadline,
    oom,
    _end,
};

pub const StateFlags = packed struct(u32) {
    _padding1: u8 = 0,

    launch_failed: bool = false,
    update_job: bool = false,
    requeue: bool = false,
    requeue_hold: bool = false,
    special_exit: bool = false,
    resizing: bool = false,
    configuring: bool = false,
    completing: bool = false,
    stopped: bool = false,
    reconfig_fail: bool = false,
    power_up_node: bool = false,
    revoked: bool = false,
    requeue_fed: bool = false,
    resv_del_hold: bool = false,
    signaling: bool = false,
    stage_out: bool = false,

    _padding2: u8 = 0,

    pub fn toStr(self: StateFlags) ?[:0]const u8 {
        inline for (std.meta.fields(@TypeOf(self))) |f| {
            if (f.type == bool and @as(f.type, @field(self, f.name))) {
                return f.name;
            }
        }
        return null;
    }

    comptime {
        std.debug.assert(
            @sizeOf(@This()) == @sizeOf(u32) and
                @bitSizeOf(@This()) == @bitSizeOf(u32),
        );
    }
};

fn bitflagToStr(flags: anytype, allocator: std.mem.Allocator, padding_count: comptime_int) ![]const u8 {
    const sep = ",";

    comptime var max_size = sep.len * (@typeInfo(@TypeOf(flags)).Struct.fields.len - 1 - padding_count);
    inline for (std.meta.fields(@TypeOf(flags))) |f| {
        if (f.type == bool) max_size += f.name.len;
    }

    var result: [max_size]u8 = undefined;
    var bytes: usize = 0;
    inline for (std.meta.fields(@TypeOf(flags))) |f| {
        if (f.type == bool and @as(f.type, @field(flags, f.name))) {
            if (bytes == 0) {
                @memcpy(result[0..f.name.len], f.name);
                bytes += f.name.len;
            } else {
                @memcpy(result[bytes..][0..sep.len], sep);
                bytes += sep.len;
                @memcpy(result[bytes..][0..f.name.len], f.name);
                bytes += f.name.len;
            }
        }
    }
    return try allocator.dupe(u8, result[0..bytes]);
}

pub const MailFlags = packed struct(u16) {
    begin: bool = false,
    end: bool = false,
    fail: bool = false,
    requeue: bool = false,
    time100: bool = false,
    time90: bool = false,
    time50: bool = false,
    stage_out: bool = false,
    array_tasks: bool = false,
    invalid_depend: bool = false,

    _padding1: u6 = 0,

    pub const all: MailFlags = @bitCast(@as(u16, (1 << @typeInfo(MailFlags).Struct.fields.len - 1) - 1));

    pub fn toStr(self: MailFlags, allocator: std.mem.Allocator) ![]const u8 {
        return try bitflagToStr(self, allocator, 1);
    }

    comptime {
        std.debug.assert(
            @sizeOf(@This()) == @sizeOf(u16) and
                @bitSizeOf(@This()) == @bitSizeOf(u16),
        );
    }
};

pub const HoldMode = enum {
    user,
    admin,
};

pub const Oversubscription = enum {
    no,
    yes,
    user,
    mcs,
};

pub const StateReason = enum {
    wait_no_reason,
    wait_priority,
    wait_dependency,
    wait_resources,
    wait_part_node_limit,
    wait_part_time_limit,
    wait_part_down,
    wait_part_inactive,
    wait_held,
    wait_time,
    wait_licenses,
    wait_assoc_job_limit,
    wait_assoc_resource_limit,
    wait_assoc_time_limit,
    wait_reservation,
    wait_node_not_avail,
    wait_held_user,
    wait_front_end,
    fail_defer,
    fail_down_partition,
    fail_down_node,
    fail_bad_constraints,
    fail_system,
    fail_launch,
    fail_exit_code,
    fail_timeout,
    fail_inactive_limit,
    fail_account,
    fail_qos,
    wait_qos_thres,
    wait_qos_job_limit,
    wait_qos_resource_limit,
    wait_qos_time_limit,
    fail_signal,
    _defunct_wait_34,
    wait_cleaning,
    wait_prolog,
    wait_qos,
    wait_account,
    wait_dep_invalid,
    wait_qos_grp_cpu,
    wait_qos_grp_cpu_min,
    wait_qos_grp_cpu_run_min,
    wait_qos_grp_job,
    wait_qos_grp_mem,
    wait_qos_grp_node,
    wait_qos_grp_sub_job,
    wait_qos_grp_wall,
    wait_qos_max_cpu_per_job,
    wait_qos_max_cpu_mins_per_job,
    wait_qos_max_node_per_job,
    wait_qos_max_wall_per_job,
    wait_qos_max_cpu_per_user,
    wait_qos_max_job_per_user,
    wait_qos_max_node_per_user,
    wait_qos_max_sub_job,
    wait_qos_min_cpu,
    wait_assoc_grp_cpu,
    wait_assoc_grp_cpu_min,
    wait_assoc_grp_cpu_run_min,
    wait_assoc_grp_job,
    wait_assoc_grp_mem,
    wait_assoc_grp_node,
    wait_assoc_grp_sub_job,
    wait_assoc_grp_wall,
    wait_assoc_max_jobs,
    wait_assoc_max_cpu_per_job,
    wait_assoc_max_cpu_mins_per_job,
    wait_assoc_max_node_per_job,
    wait_assoc_max_wall_per_job,
    wait_assoc_max_sub_job,
    wait_max_requeue,
    wait_array_task_limit,
    wait_burst_buffer_resource,
    wait_burst_buffer_staging,
    fail_burst_buffer_op,
    wait_power_not_avail,
    wait_power_reserved,
    wait_assoc_grp_unk,
    wait_assoc_grp_unk_min,
    wait_assoc_grp_unk_run_min,
    wait_assoc_max_unk_per_job,
    wait_assoc_max_unk_per_node,
    wait_assoc_max_unk_mins_per_job,
    wait_assoc_max_cpu_per_node,
    wait_assoc_grp_mem_min,
    wait_assoc_grp_mem_run_min,
    wait_assoc_max_mem_per_job,
    wait_assoc_max_mem_per_node,
    wait_assoc_max_mem_mins_per_job,
    wait_assoc_grp_node_min,
    wait_assoc_grp_node_run_min,
    wait_assoc_max_node_mins_per_job,
    wait_assoc_grp_energy,
    wait_assoc_grp_energy_min,
    wait_assoc_grp_energy_run_min,
    wait_assoc_max_energy_per_job,
    wait_assoc_max_energy_per_node,
    wait_assoc_max_energy_mins_per_job,
    wait_assoc_grp_gres,
    wait_assoc_grp_gres_min,
    wait_assoc_grp_gres_run_min,
    wait_assoc_max_gres_per_job,
    wait_assoc_max_gres_per_node,
    wait_assoc_max_gres_mins_per_job,
    wait_assoc_grp_lic,
    wait_assoc_grp_lic_min,
    wait_assoc_grp_lic_run_min,
    wait_assoc_max_lic_per_job,
    wait_assoc_max_lic_mins_per_job,
    wait_assoc_grp_bb,
    wait_assoc_grp_bb_min,
    wait_assoc_grp_bb_run_min,
    wait_assoc_max_bb_per_job,
    wait_assoc_max_bb_per_node,
    wait_assoc_max_bb_mins_per_job,
    wait_qos_grp_unk,
    wait_qos_grp_unk_min,
    wait_qos_grp_unk_run_min,
    wait_qos_max_unk_per_job,
    wait_qos_max_unk_per_node,
    wait_qos_max_unk_per_user,
    wait_qos_max_unk_mins_per_job,
    wait_qos_min_unk,
    wait_qos_max_cpu_per_node,
    wait_qos_grp_mem_min,
    wait_qos_grp_mem_run_min,
    wait_qos_max_mem_mins_per_job,
    wait_qos_max_mem_per_job,
    wait_qos_max_mem_per_node,
    wait_qos_max_mem_per_user,
    wait_qos_min_mem,
    wait_qos_grp_energy,
    wait_qos_grp_energy_min,
    wait_qos_grp_energy_run_min,
    wait_qos_max_energy_per_job,
    wait_qos_max_energy_per_node,
    wait_qos_max_energy_per_user,
    wait_qos_max_energy_mins_per_job,
    wait_qos_min_energy,
    wait_qos_grp_node_min,
    wait_qos_grp_node_run_min,
    wait_qos_max_node_mins_per_job,
    wait_qos_min_node,
    wait_qos_grp_gres,
    wait_qos_grp_gres_min,
    wait_qos_grp_gres_run_min,
    wait_qos_max_gres_per_job,
    wait_qos_max_gres_per_node,
    wait_qos_max_gres_per_user,
    wait_qos_max_gres_mins_per_job,
    wait_qos_min_gres,
    wait_qos_grp_lic,
    wait_qos_grp_lic_min,
    wait_qos_grp_lic_run_min,
    wait_qos_max_lic_per_job,
    wait_qos_max_lic_per_user,
    wait_qos_max_lic_mins_per_job,
    wait_qos_min_lic,
    wait_qos_grp_bb,
    wait_qos_grp_bb_min,
    wait_qos_grp_bb_run_min,
    wait_qos_max_bb_per_job,
    wait_qos_max_bb_per_node,
    wait_qos_max_bb_per_user,
    wait_qos_max_bb_mins_per_job,
    wait_qos_min_bb,
    fail_deadline,
    wait_qos_max_bb_per_acct,
    wait_qos_max_cpu_per_acct,
    wait_qos_max_energy_per_acct,
    wait_qos_max_gres_per_acct,
    wait_qos_max_node_per_acct,
    wait_qos_max_lic_per_acct,
    wait_qos_max_mem_per_acct,
    wait_qos_max_unk_per_acct,
    wait_qos_max_job_per_acct,
    wait_qos_max_sub_job_per_acct,
    wait_part_config,
    wait_account_policy,
    wait_fed_job_lock,
    fail_oom,
    wait_pn_mem_limit,
    wait_assoc_grp_billing,
    wait_assoc_grp_billing_min,
    wait_assoc_grp_billing_run_min,
    wait_assoc_max_billing_per_job,
    wait_assoc_max_billing_per_node,
    wait_assoc_max_billing_mins_per_job,
    wait_qos_grp_billing,
    wait_qos_grp_billing_min,
    wait_qos_grp_billing_run_min,
    wait_qos_max_billing_per_job,
    wait_qos_max_billing_per_node,
    wait_qos_max_billing_per_user,
    wait_qos_max_billing_mins_per_job,
    wait_qos_max_billing_per_acct,
    wait_qos_min_billing,
    wait_resv_deleted,
    wait_resv_invalid,
    fail_constraints,

    pub fn toStr(self: StateReason) [:0]const u8 {
        return @tagName(self);
    }
};

pub fn getStdOut(self: Job) [1024:0]u8 {
    var buf: [1024:0]u8 = undefined;
    c.slurm_get_job_stdout(&buf, buf.len, self.c_ptr);
    return buf;
}

pub fn getStdErr(self: Job) [1024:0]u8 {
    var buf: [1024:0]u8 = undefined;
    c.slurm_get_job_stderr(&buf, buf.len, self.c_ptr);
    return buf;
}

pub fn getStdIn(self: Job) [1024:0]u8 {
    var buf: [1024:0]u8 = undefined;
    c.slurm_get_job_stdin(&buf, buf.len, self.c_ptr);
    return buf;
}

pub inline fn nice(self: Job) ?i64 {
    if (self.c_ptr.nice != c.NO_VAL) {
        return @as(i64, self.c_ptr.nice) - c.NICE_OFFSET;
    } else return null;
}

pub fn stateStr(self: Job) [:0]const u8 {
    const state_flags = self.c_ptr.job_state & c.JOB_STATE_FLAGS;
    const state_base = self.c_ptr.job_state & c.JOB_STATE_BASE;

    if (state_flags != 0) {
        const flags: StateFlags = @bitCast(state_flags);
        return flags.toStr().?;
    } else if (state_base < c.JOB_END) {
        return @tagName(@as(State, @enumFromInt(state_base)));
    } else {
        return "unknown";
    }
}

pub inline fn stateReasonStr(self: Job) []const u8 {
    return @tagName(@as(StateReason, @enumFromInt(self.c_ptr.state_reason)));
}

pub inline fn resourceSharingStr(self: Job) []const u8 {
    // I don't know... the devs have explicit values for "YES" and "NO", yet
    // most of the times this will be NO_VAL16, so not set, and the
    // job_share_string function which scontrol uses returns "OK" ???? Whats
    // the difference between "YES" and "OK", and why is it defaulting to "OK"
    // in the first place, when the Partition is set to OverSubscribe=NO per
    // default...
    // Just follow the Partition default, and put it to "no" here if it has no
    // value.
    if (self.c_ptr.shared == c.NO_VAL16) return "no";
    return @tagName(@as(Oversubscription, @enumFromInt(self.c_ptr.shared)));
}

pub fn runTime(self: Job) time_t {
    const job: *RawJob = self.c_ptr;
    const state = job.job_state & c.JOB_STATE_BASE;
    var rtime: time_t = undefined;
    var etime: time_t = undefined;

    if (state == c.JOB_PENDING or job.start_time == 0) {
        return 0;
    } else if (state == c.JOB_SUSPENDED) {
        return job.pre_sus_time;
    } else {
        const is_running = state == c.JOB_RUNNING;
        if (is_running or job.end_time == 0) {
            etime = std.time.timestamp();
        } else etime = job.end_time;

        if (job.suspend_time > 0) {
            rtime = @intFromFloat(c.difftime(etime, job.suspend_time));
            rtime += job.pre_sus_time;
        } else {
            rtime = @intFromFloat(c.difftime(etime, job.start_time));
        }
    }

    return rtime;
}

pub inline fn arrayTasksWaiting(self: Job) ?[]const u8 {
    if (self.c_ptr.array_task_str == null) return null;
    const task_str = std.mem.span(self.c_ptr.array_task_str);
    return std.mem.sliceTo(task_str, '%');
}

pub const DependencyCondition = enum {
    any,
    all,
};

pub const Dependencies = struct {
    after: ?JobIdList = undefined,
    afterany: ?JobIdList = undefined,
    afterburstbuffer: ?JobIdList = undefined,
    aftercorr: ?JobIdList = undefined,
    afternotok: ?JobIdList = undefined,
    afterok: ?JobIdList = undefined,
    singleton: bool = false,
    condition: DependencyCondition = DependencyCondition.any,

    pub fn deinit(self: @This()) void {
        if (self.after) |after| after.deinit();
        if (self.afterany) |afterany| afterany.deinit();
        if (self.afterburstbuffer) |afterbb| afterbb.deinit();
        if (self.aftercorr) |aftercorr| aftercorr.deinit();
        if (self.afternotok) |afternotok| afternotok.deinit();
        if (self.afterok) |afterok| afterok.deinit();
    }
};

pub inline fn dependencies(self: Job, allocator: std.mem.Allocator) !?Dependencies {
    if (self.c_ptr.dependency == null) return null;
    return try parseDepStr(std.mem.span(self.c_ptr.dependency), allocator);
}

fn parseDepStr(deps: []const u8, allocator: std.mem.Allocator) !?Dependencies {
    const sep = if (std.mem.containsAtLeast(u8, deps, 1, "?")) "?" else ",";
    const condition = if (std.mem.eql(u8, sep, "?")) DependencyCondition.any else DependencyCondition.all;
    var depout = Dependencies{
        .condition = condition,
    };

    // Syntax Rules for dependencies:
    // <type>:<jobid>+<time>(state)
    // <type>:<jobid>(state)
    // singleton(unfulfilled)
    //
    // There is always a state. There is no "fulfilled" state, because
    // fulfilled dependencies are already removed by the slurmctld from the
    // dependency list.
    var iter = std.mem.split(u8, deps, sep);
    while (iter.next()) |dep| {
        if (std.mem.eql(u8, dep, "singleton")) {
            depout.singleton = true;
            continue;
        }

        var it = std.mem.splitScalar(u8, dep, ':');
        const dep_type = it.first();

        // malformed string
        if (it.peek() == null) continue;

        var jobid: JobId = undefined;
        while (it.next()) |job_and_state| {
            // Ignore the dependency state and the optional "+time" for afterany
            var state_iter = std.mem.splitScalar(u8, job_and_state, '(');
            jobid = try std.fmt.parseUnsigned(JobId, state_iter.first(), 10);
        }

        inline for (std.meta.fields(@TypeOf(depout))) |f| {
            const v = @field(depout, f.name);
            switch (@TypeOf(v)) {
                ?JobIdList => {
                    if (std.mem.eql(u8, dep_type, f.name)) {
                        if (v == null) {
                            @field(depout, f.name) = JobIdList.init(allocator);
                        }
                        try @field(depout, f.name).?.append(jobid);
                    }
                },
                else => {},
            }
        }
    }
    return depout;
}

pub fn memoryPerCpu(self: Job) ?u64 {
    const mem = self.c_ptr.pn_min_memory;
    if (mem != c.NO_VAL64 and (mem & c.MEM_PER_CPU) != 0) {
        return mem & (~c.MEM_PER_CPU);
    } else return null;
}

pub fn memoryPerNode(self: Job) ?u64 {
    const mem = self.c_ptr.pn_min_memory;
    if (mem != c.NO_VAL64 and (mem & c.MEM_PER_CPU) == 0) {
        return mem;
    } else return null;
}

pub fn memory(self: Job) u64 {
    if (self.memoryPerNode()) |mem| {
        return mem * self.c_ptr.num_nodes;
    } else if (self.memoryPerCpu()) |mem| {
        return mem * self.c_ptr.num_cpus;
    } // TODO: GPU

    return 0;
}

pub const GresEntry = struct {
    name: []const u8 = undefined,
    type: ?[]const u8 = null,
    count: u32 = 1,
    indexes: ?[]const u8 = null,
};

pub const GresParseError = error{
    InvalidIDXFormat,
    MalformedString,
};

pub fn parseGresStr(gres: []const u8) !GresEntry {
    var entry = GresEntry{};
    // gres:gpu:nvidia-a100:2(IDX:0,1)
    if (std.mem.eql(u8, gres, "(null)")) {
        return entry;
    }

    var gres_items = std.mem.splitScalar(u8, gres, ':');

    while (gres_items.next()) |item| {
        if (std.mem.containsAtLeast(u8, item, 1, "gres")) {
            const maybe_name = gres_items.next() orelse return GresParseError.MalformedString;
            entry.name = maybe_name;
        } else entry.name = item;

        //        const item_no_delim = std.mem.trimLeft(u8, item, gres_delim);
        // Check if this item contains (IDX:i,ii,iii)
        //       const has_idx = item_no_delim[item_no_delim.len - 1] == ')';
        //
        // Remaining: nvidia-a100:2(IDX or nvidia-a100:(IDX or nvidia-a100 or 2(IDX
        if (gres_items.next()) |type_or_count| {
            // type_or_count can be:
            // - type
            // - count
            // - count(IDX

            // count_or_idx can be
            // - count
            // - count(IDX
            // - count,gres or count,
            // - (IDX
            // - idxrange),gres (contains start of next item)
            var has_count = false;
            const count_or_idx = gres_items.next();
            //        const item_no_delim = std.mem.trimLeft(u8, item, gres_delim);
            if (count_or_idx) |ci| {
                if (std.mem.containsAtLeast(u8, ci, 1, "gres") or std.mem.containsAtLeast(u8, ci, 1, ")")) {
                    // no type
                }

                if (std.mem.containsAtLeast(u8, ci, 1, "(")) {
                    // count(IDX or (IDX

                    const idx_or_next_entry = gres_items.next() orelse return GresParseError.InvalidIDXFormat;
                    if (std.mem.startsWith(u8, ci, "(")) {
                        // (IDX

                        // idxrange),gres or idxrange)
                        entry.indexes = std.mem.sliceTo(idx_or_next_entry, ')');
                    } else {
                        // count(IDX
                        entry.count = try std.fmt.parseInt(u32, std.mem.sliceTo(ci, '('), 10);
                        entry.indexes = std.mem.sliceTo(idx_or_next_entry, ')');
                        has_count = true;
                    }
                    entry.type = type_or_count;
                    continue;
                } else if (std.mem.containsAtLeast(u8, ci, 1, ",")) {
                    // count,gres or count, or ,gres
                    if (std.mem.startsWith(u8, ci, ",")) {
                        continue;
                    } else {
                        entry.count = try std.fmt.parseInt(u32, std.mem.sliceTo(ci, ','), 10);
                        has_count = true;
                    }
                } else {
                    // type,count
                    entry.type = type_or_count;
                    entry.count = try std.fmt.parseInt(u32, ci, 10);
                    has_count = true;
                }
            } else {
                entry.count = try std.fmt.parseInt(u32, type_or_count, 10);
            }

            // type or count
            if (has_count) {
                entry.count = try std.fmt.parseInt(u32, type_or_count, 10);
            } else entry.type = type_or_count;
        }

        //      const delim: u8 = if (has_idx) '(' else ':';
        //      var splitted = std.mem.splitScalar(u8, item_no_delim, delim);

        //      var main = if (has_idx) std.mem.splitScalar(u8, splitted.first(), ':') else splitted;
        //      const idx_str: ?[]const u8 = if (has_idx) splitted.rest() else null;

        //      //    var entry = GresEntry{ .name = main.first() };
        //      entry.name = main.first();
        //      entry.type = main.next();
        //      if (main.next()) |i| {
        //          entry.count = try std.fmt.parseInt(u32, i, 10);
        //      } else {
        //          entry.count = try std.fmt.parseInt(u32, entry.type.?, 10);
        //          entry.type = null;
        //      }

        //      if (idx_str) |val| {
        //          // IDX:i,ii-iv,v)
        //          const indexes = std.mem.trimRight(u8, val, ")");
        //          entry.indexes = indexes[3..];
        //      }
    }

    return entry;
}

pub const KeyValuePair = struct {
    raw: []const u8,
    delim1: u8,
    delim2: u8,

    const Self = @This();

    pub fn iter(self: Self) std.mem.SplitIterator(u8, .scalar) {
        return std.mem.splitScalar(u8, self.raw, self.delim1);
    }

    pub fn toHashMap(self: Self, allocator: std.mem.Allocator) !std.StringHashMap([]const u8) {
        var hashmap = std.StringHashMap([]const u8).init(allocator);
        var it = self.iter();
        while (it.next()) |item| {
            var it2 = std.mem.splitScalar(u8, item, self.delim2);
            const k = it2.first();
            const v = it2.rest();
            try hashmap.put(k, v);
        }
        return hashmap;
    }
};

pub const InfoResponse = struct {
    msg: *ResponseMessage = undefined,
    count: u32 = 0,
    items: [*c]RawJob,

    const Self = @This();

    pub inline fn deinit(self: Self) void {
        c.slurm_free_job_info_msg(self.msg);
        self.items.* = undefined;
    }

    pub const Iterator = struct {
        resp: *InfoResponse,
        count: usize,

        pub fn next(it: *Iterator) ?Job {
            if (it.count >= it.resp.count) return null;
            const id = it.count;
            it.count += 1;
            const c_ptr: *RawJob = @ptrCast(&it.resp.items[id]);
            return Job{
                .c_ptr = c_ptr,
                .id = c_ptr.job_id,
            };
        }

        pub fn reset(it: *Iterator) void {
            it.count = 0;
        }
    };

    pub fn iter(self: *Self) Iterator {
        return Iterator{
            .resp = self,
            .count = 0,
        };
    }

    pub fn slice_raw(self: *Self) []RawJob {
        if (self.count == 0) return &.{};
        return self.items[0..self.count];
    }
};

pub fn loadAll() SlurmError!InfoResponse {
    var data: *ResponseMessage = undefined;
    try err.checkRpc(
        c.slurm_load_jobs(0, @ptrCast(&data), c.SHOW_DETAIL | c.SHOW_ALL),
    );
    return InfoResponse{
        .msg = data,
        .count = data.record_count,
        .items = data.job_array,
    };
}

pub fn loadOne(id: JobId) SlurmError!InfoResponse {
    var data: *ResponseMessage = undefined;
    try err.checkRpc(
        c.slurm_load_job(@ptrCast(&data), id, c.SHOW_DETAIL),
    );
    return InfoResponse{
        .msg = data,
        .count = data.record_count,
        .items = data.job_array,
    };
}

pub fn sendSignal(self: Job, signal: u16, flags: u16) SlurmError!void {
    try err.checkRpc(c.slurm_kill_job(self.id, signal, flags));
}

pub fn cancel(self: Job) SlurmError!void {
    try self.sendSignal(9, 0);
}

pub fn suspendx(self: Job) SlurmError!void {
    try err.checkRpc(c.slurm_suspend(self.id));
}

pub fn unsuspend(self: Job) SlurmError!void {
    try err.checkRpc(c.slurm_resume(self.id));
}

pub fn hold(self: Job, mode: HoldMode) void {
    _ = mode;
    _ = self;
}

pub fn release(self: Job) void {
    _ = self;
}

pub fn requeue(self: Job) SlurmError!void {
    try err.checkRpc(c.slurm_requeue(self.id, 0));
}

pub fn requeueHold(self: Job) SlurmError!void {
    try err.checkRpc(c.slurm_requeue(self.id, c.JOB_REQUEUE_HOLD));
}

test "parse_dependencies_from_string" {
    const dep_str1 = "afterany:541(unfulfilled),afterany:542(unfulfilled),afterok:541(unfulfilled),aftercorr:510(failed)";
    const dep1 = try parseDepStr(dep_str1, std.testing.allocator);
    var dep: Dependencies = undefined;

    try std.testing.expect(dep1 != null);

    dep = dep1.?;
    defer dep.deinit();
    try std.testing.expect(dep.afterany != null);
    try std.testing.expect(dep.afterok != null);
    try std.testing.expect(dep.afternotok == null);
    try std.testing.expect(dep.aftercorr != null);
    try std.testing.expect(dep.afterburstbuffer == null);
    try std.testing.expect(dep.after == null);
    try std.testing.expect(dep.singleton == false);
    try std.testing.expect(dep.condition == DependencyCondition.all);

    const afterany_expected_jobs = [_]u32{ 541, 542 };
    try std.testing.expectEqualSlices(u32, &afterany_expected_jobs, dep.afterany.?.items);

    const afterok_expected_jobs = [_]u32{541};
    try std.testing.expectEqualSlices(u32, &afterok_expected_jobs, dep.afterok.?.items);

    const aftercorr_expected_jobs = [_]u32{510};
    try std.testing.expectEqualSlices(u32, &aftercorr_expected_jobs, dep.aftercorr.?.items);
}

test "bitflag_to_str" {
    const mf = MailFlags{ .end = true, .invalid_depend = true, .begin = true };
    const mf_str = try mf.toStr(std.testing.allocator);
    defer std.testing.allocator.free(mf_str);
    try std.testing.expectEqualSlices(u8, "begin,end,invalid_depend", mf_str);
}

test "parseGresStr" {
    const s = "gpu:nvidia-a100:2(IDX:0,1)";
    const entry = try parseGresStr(s);
    try std.testing.expect(entry.type != null);
    try std.testing.expectEqualSlices(u8, "nvidia-a100", entry.type.?);
    try std.testing.expectEqualSlices(u8, "gpu", entry.name);
    try std.testing.expect(entry.indexes != null);
    try std.testing.expectEqualSlices(u8, "0,1", entry.indexes.?);
    try std.testing.expect(entry.count == 2);

    const s2 = "gres:gpu:2(IDX:0,1)";
    const entry2 = try parseGresStr(s2);
    try std.testing.expect(entry2.type != null);
    try std.testing.expectEqualSlices(u8, "nvidia-a100", entry2.type.?);
    try std.testing.expectEqualSlices(u8, "gpu", entry2.name);
    try std.testing.expect(entry2.indexes != null);
    try std.testing.expectEqualSlices(u8, "0,1", entry2.indexes.?);
    try std.testing.expect(entry2.count == 2);
}
