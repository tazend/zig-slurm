const c = @import("c.zig").c;
const cx = @import("c.zig");
const std = @import("std");
const err = @import("error.zig");
const SlurmError = @import("error.zig").Error;
const time_t = std.os.linux.time_t;
const JobIdList = std.ArrayList(JobId);
const slurm_allocator = @import("SlurmAllocator.zig").slurm_allocator;
const common = @import("common.zig");
const NoValue = common.NoValue;
const Infinite = common.Infinite;
const CStr = common.CStr;
const BitString = common.BitString;

pub const JobId = u32;

pub const JobResources = opaque {};

pub const Job = extern struct {
    account: ?CStr = null,
    accrue_time: time_t = 0,
    admin_comment: ?CStr = null,
    alloc_node: ?CStr = null,
    alloc_sid: u32 = 0,
    array_bitmap: ?[*]BitString = null,
    array_job_id: u32 = 0,
    array_task_id: u32 = 0,
    array_max_tasks: u32 = 0,
    array_task_str: ?CStr = null,
    assoc_id: u32 = 0,
    batch_features: ?CStr = null,
    batch_flag: u16 = 0,
    batch_host: ?CStr = null,
    bitflags: u64 = 0,
    boards_per_node: u16 = 0,
    burst_buffer: ?CStr = null,
    burst_buffer_state: ?CStr = null,
    cluster: ?CStr = null,
    cluster_features: ?CStr = null,
    command: ?CStr = null,
    comment: ?CStr = null,
    container: ?CStr = null,
    container_id: ?CStr = null,
    contiguous: u16 = 0,
    core_spec: u16 = 0,
    cores_per_socket: u16 = 0,
    billable_tres: f64 = 0,
    cpus_per_task: u16 = 0,
    cpu_freq_min: u32 = 0,
    cpu_freq_max: u32 = 0,
    cpu_freq_gov: u32 = 0,
    cpus_per_tres: ?CStr = null,
    cronspec: ?CStr = null,
    deadline: time_t = 0,
    delay_boot: u32 = 0,
    dependency: ?CStr = null,
    derived_ec: u32 = 0,
    eligible_time: time_t = 0,
    end_time: time_t = 0,
    exc_nodes: ?CStr = null,
    exc_node_inx: ?[*]i32 = null,
    exit_code: u32 = 0,
    extra: ?CStr = null,
    failed_node: ?CStr = null,
    features: ?CStr = null,
    fed_origin_str: ?CStr = null,
    fed_siblings_active: u64 = 0,
    fed_siblings_active_str: ?CStr = null,
    fed_siblings_viable: u64 = 0,
    fed_siblings_viable_str: ?CStr = null,
    gres_detail_cnt: u32 = 0,
    gres_detail_str: ?*CStr = null,
    gres_total: ?CStr = null,
    group_id: u32 = NoValue.u32,
    het_job_id: u32 = 0,
    het_job_id_set: ?CStr = null,
    het_job_offset: u32 = 0,
    job_id: u32 = 0,
    job_resrcs: ?*JobResources = null,
    job_size_str: ?CStr = null,
    state: State,
    last_sched_eval: time_t = 0,
    licenses: ?CStr = null,
    mail_type: MailFlags = .{},
    mail_user: ?CStr = null,
    max_cpus: u32 = 0,
    max_nodes: u32 = 0,
    mcs_label: ?CStr = null,
    mem_per_tres: ?CStr = null,
    name: ?CStr = null,
    network: ?CStr = null,
    nodes: ?CStr = null,
    nice: u32 = NoValue.u32,
    node_inx: ?[*]i32 = null,
    ntasks_per_core: u16 = 0,
    ntasks_per_tres: u16 = 0,
    ntasks_per_node: u16 = 0,
    ntasks_per_socket: u16 = 0,
    ntasks_per_board: u16 = 0,
    num_cpus: u32 = 0,
    num_nodes: u32 = 0,
    num_tasks: u32 = 0,
    oom_kill_step: u16 = 0,
    partition: ?CStr = null,
    prefer: ?CStr = null,
    pn_min_memory: u64 = 0,
    pn_min_cpus: u16 = 0,
    pn_min_tmp_disk: u32 = 0,
    //    power_flags: u8 = 0,
    preempt_time: time_t = 0,
    preemptable_time: time_t = 0,
    pre_sus_time: time_t = 0,
    priority: u32 = 0,
    priority_array: ?[*]u32 = null,
    priority_array_names: ?CStr = null,
    profile: ProfileTypes = .{},
    qos: ?CStr = null,
    reboot: u8 = 0,
    req_nodes: ?CStr = null,
    req_node_inx: ?[*]i32 = null,
    req_switch: u32 = 0,
    requeue: u16 = 0,
    resize_time: time_t = 0,
    restart_cnt: u16 = 0,
    resv_name: ?CStr = null,
    resv_ports: ?CStr = null,
    sched_nodes: ?CStr = null,
    selinux_context: ?CStr = null,
    shared: Oversubscription = .no,
    site_factor: u32 = 0,
    sockets_per_board: u16 = 0,
    sockets_per_node: u16 = 0,
    start_time: time_t = 0,
    start_protocol_ver: u16 = 0,
    state_desc: ?CStr = null,
    state_reason: State.Reason = .wait_no_reason,
    std_err: ?CStr = null,
    std_in: ?CStr = null,
    std_out: ?CStr = null,
    submit_time: time_t = 0,
    suspend_time: time_t = 0,
    system_comment: ?CStr = null,
    time_limit: u32 = 0,
    time_min: u32 = 0,
    threads_per_core: u16 = 0,
    tres_bind: ?CStr = null,
    tres_freq: ?CStr = null,
    tres_per_job: ?CStr = null,
    tres_per_node: ?CStr = null,
    tres_per_socket: ?CStr = null,
    tres_per_task: ?CStr = null,
    tres_req_str: ?CStr = null,
    tres_alloc_str: ?CStr = null,
    user_id: u32 = NoValue.u32,
    user_name: ?CStr = null,
    wait4switch: u32 = 0,
    wckey: ?CStr = null,
    work_dir: ?CStr = null,

    pub const LoadResponse = extern struct {
        last_backfill: time_t,
        last_update: time_t,
        count: u32 = 0,
        items: ?[*]Job = null,

        extern fn slurm_free_job_info_msg(job_buffer_ptr: ?*LoadResponse) void;
        pub fn deinit(self: *LoadResponse) void {
            slurm_free_job_info_msg(self);
        }

        pub const Iterator = struct {
            data: *LoadResponse,
            count: usize,

            pub fn next(self: *Iterator) ?*Job {
                const id = self.count;
                defer self.count += 1;
                return self.data.get_job_by_index(id);
            }

            pub fn reset(self: *Iterator) void {
                self.count = 0;
            }
        };

        pub fn get_job_by_index(self: *LoadResponse, idx: usize) ?*Job {
            if (idx >= self.count) return null;
            return &self.items.?[idx];
        }

        pub fn iter(self: *LoadResponse) Iterator {
            return Iterator{
                .data = self,
                .count = 0,
            };
        }
    };

    pub const State = packed struct(u32) {
        base: Base,
        flags: Flags,

        pub const Base = enum(u8) {
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

        pub const Flags = packed struct(u24) {
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
            // TODO: Consider moving this out of here, ordered after "flags"
            // directly.
            __padding1: u8 = 0,

            pub fn toStr(self: State.Flags) ?[]const u8 {
                inline for (std.meta.fields(@TypeOf(self))) |f| {
                    if (f.type == bool and @as(f.type, @field(self, f.name))) {
                        return f.name;
                    }
                }
                return null;
            }

            pub fn eql(a: State.Flags, b: State.Flags) bool {
                return @as(u24, @bitCast(a)) == @as(u24, @bitCast(b));
            }
        };

        pub fn toStr(self: State) []const u8 {
            return if (!State.Flags.eql(self.flags, State.Flags{}))
                self.flags.toStr().?
            else if (@intFromEnum(self.base) < @intFromEnum(State.Base._end))
                @tagName(self.base)
            else
                "unknown";
        }

        pub const Reason = enum(u32) {
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
            _,

            pub fn hasVal(self: @This()) bool {
                return @intFromEnum(self) != NoValue.u32;
            }

            pub fn toStr(self: State.Reason) []const u8 {
                return @tagName(self);
            }
        };
    };

    pub const MemoryPerResource = union(enum) {
        cpu: u64,
        node: u64,
        gpu: u64,
    };

    const MemoryPerResourceError = error{NoValue};
    pub fn memoryPerResource(self: *Job) MemoryPerResourceError!MemoryPerResource {
        const mem = self.pn_min_memory;
        const mem_tres = self.mem_per_tres;

        if (mem != NoValue.u64) {
            return if ((mem & c.MEM_PER_CPU) == 0)
                .{ .node = mem }
            else
                .{ .cpu = mem & (~c.MEM_PER_CPU) };
        } else if (mem_tres) |v| {
            // TODO: TRES Parser
            _ = v;
            return .{ .gpu = 0 };
        }

        return error.NoValue;
    }

    pub fn memory(self: *Job) u64 {
        const mem = self.memoryPerResource() catch {
            return 0;
        };

        return switch (mem) {
            .cpu => |v| v,
            .node => |v| v,
            .gpu => |v| v,
        };
    }

    pub fn getBatchScript(self: Job, allocator: std.mem.Allocator) ![:0]const u8 {
        var msg: cx.job_id_msg_t = .{ .job_id = self.job_id };
        var req: cx.slurm_msg_t = undefined;
        var resp: cx.slurm_msg_t = undefined;
        cx.slurm_msg_t_init(&req);
        cx.slurm_msg_t_init(&resp);

        req.msg_type = cx.slurm_msg_type_t.request_batch_script;
        req.data = &msg;

        try err.checkRpc(cx.slurm_send_recv_controller_msg(
            &req,
            &resp,
            c.working_cluster_rec,
        ));

        if (resp.msg_type == cx.slurm_msg_type_t.response_batch_script) {
            const data: ?[*:0]const u8 = @ptrCast(resp.data);
            if (data) |d| {
                const tmp: []const u8 = std.mem.span(d);
                const script = try allocator.dupeZ(u8, tmp);
                slurm_allocator.free(tmp);
                return script;
            } else return error.Generic;
        } else if (resp.msg_type == cx.slurm_msg_type_t.response_slurm_rc) {
            const data: ?*cx.return_code_msg_t = @alignCast(@ptrCast(resp.data));
            if (data) |d| { // TODO: properly handle this error
                _ = d.return_code;
                cx.slurm_free_return_code_msg(d);
            }
            return error.Generic;
        } else {
            return error.Generic;
        }
    }

    extern fn slurm_get_job_stdout(buf: ?[*]u8, buf_size: c_int, job_ptr: *Job) void;
    pub fn getStdOut(self: *Job) [1024:0]u8 {
        var buf: [1024:0]u8 = std.mem.zeroes([1024:0]u8);
        slurm_get_job_stdout(&buf, buf.len, self);
        return buf;
    }

    extern fn slurm_get_job_stderr(buf: ?[*]u8, buf_size: c_int, job_ptr: *Job) void;
    pub fn getStdErr(self: *Job) [1024:0]u8 {
        var buf: [1024:0]u8 = std.mem.zeroes([1024:0]u8);
        slurm_get_job_stderr(&buf, buf.len, self);
        return buf;
    }

    extern fn slurm_get_job_stdin(buf: ?[*]u8, buf_size: c_int, job_ptr: *Job) void;
    pub fn getStdIn(self: *Job) [1024:0]u8 {
        var buf: [1024:0]u8 = std.mem.zeroes([1024:0]u8);
        slurm_get_job_stdin(&buf, buf.len, self);
        return buf;
    }

    const nice_offset = 2147483648;
    pub fn getNice(self: Job) ?i64 {
        return if (self.nice != NoValue.u32)
            @as(i64, self.nice) - nice_offset
        else
            null;
    }

    extern fn difftime(__time1: time_t, __time0: time_t) f64;
    pub fn runTime(self: Job) time_t {
        const job: Job = self;
        const status = self.state;
        var rtime: time_t = 0;
        var etime: time_t = undefined;

        return if (status.base == State.Base.pending or job.start_time == 0)
            rtime
        else if (status.base == State.Base.suspended)
            job.pre_sus_time
        else blk: {
            const is_running = status.base == State.Base.running;
            if (is_running or job.end_time == 0) {
                etime = std.time.timestamp();
            } else etime = job.end_time;

            if (job.suspend_time > 0) {
                rtime = @intFromFloat(difftime(etime, job.suspend_time));
                rtime += job.pre_sus_time;
            } else {
                rtime = @intFromFloat(difftime(etime, job.start_time));
            }

            break :blk rtime;
        };
    }

    pub fn cpuTime(self: Job) time_t {
        return if (self.num_cpus != NoValue.u32)
            self.num_cpus * self.runTime()
        else
            0;
    }

    pub fn arrayTasksWaiting(self: Job) ?[]const u8 {
        return if (self.array_task_str) |tasks|
            return std.mem.sliceTo(tasks, '%')
        else
            null;
    }

    pub fn dependencies(self: Job, allocator: std.mem.Allocator) !?Dependencies {
        return if (self.dependency) |dep|
            try parseDepStr(std.mem.span(dep), allocator)
        else
            null;
    }

    fn parseExitState(exit_code: u32) ExitState {
        if (exit_code == c.NO_VAL) return ExitState{};

        return if (std.posix.W.IFSIGNALED(exit_code))
            ExitState{ .code = 0, .signal = std.posix.W.TERMSIG(exit_code) }
        else if (std.posix.W.IFEXITED(exit_code)) blk: {
            var code = std.posix.W.EXITSTATUS(exit_code);
            if (code >= 128) code -= 128;
            break :blk ExitState{ .code = code, .signal = 0 };
        } else ExitState{};
    }

    pub fn exitState(self: Job) ExitState {
        return parseExitState(self.exit_code);
    }

    pub fn derivedExitState(self: Job) ExitState {
        return parseExitState(self.derived_ec);
    }

    pub fn sendSignal(self: Job, signal: u16, flags: u16) SlurmError!void {
        try err.checkRpc(c.slurm_kill_job(self.job_id, signal, flags));
    }

    pub fn cancel(self: Job) SlurmError!void {
        try self.sendSignal(9, 0);
    }

    pub fn @"suspend"(self: Job) SlurmError!void {
        try err.checkRpc(c.slurm_suspend(self.job_id));
    }

    pub fn unsuspend(self: Job) SlurmError!void {
        try err.checkRpc(c.slurm_resume(self.job_id));
    }

    pub fn hold(self: Job, mode: HoldMode) void {
        _ = mode;
        _ = self;
    }

    pub fn release(self: Job) void {
        _ = self;
    }

    pub fn requeuex(self: Job) SlurmError!void {
        try err.checkRpc(c.slurm_requeue(self.job_id, 0));
    }

    pub fn requeueHold(self: Job) SlurmError!void {
        try err.checkRpc(c.slurm_requeue(self.job_id, c.JOB_REQUEUE_HOLD));
    }
};

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
};

fn bitflagToStr(flags: anytype, allocator: std.mem.Allocator, padding_count: comptime_int) ![]const u8 {
    const sep = ",";

    comptime var max_size = sep.len * (@typeInfo(@TypeOf(flags)).@"struct".fields.len - 1 - padding_count);
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

    pub const all: MailFlags = @bitCast(@as(u16, (1 << @typeInfo(MailFlags).@"struct".fields.len - 1) - 1));

    pub fn toStr(self: MailFlags, allocator: std.mem.Allocator) ![]const u8 {
        return try bitflagToStr(self, allocator, 1);
    }
};

pub const HoldMode = enum {
    user,
    admin,
};

pub const Oversubscription = enum(u16) {
    no,
    yes,
    user,
    mcs,
    not_set = @as(u16, (1 << 16) - 2),

    pub fn hasVal(self: Oversubscription) bool {
        return self != Oversubscription.not_set;
    }

    pub fn toStr(self: Oversubscription) []const u8 {
        return if (self.hasVal())
            @tagName(self)
        else
            "no";
    }
};

pub const ExitState = struct {
    code: u32 = 0,
    signal: u32 = 0,
};

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
    var iter = std.mem.splitSequence(u8, deps, sep);
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
            var ci = type_or_count;
            if (gres_items.peek()) |it| {
                if (!std.mem.containsAtLeast(u8, it, 1, "gres") and !std.mem.containsAtLeast(u8, it, 1, ")")) {
                    ci = gres_items.next().?;
                }
            }

            // std.debug.print("ci is: {s}\n", .{ci});
            // std.debug.print("type_or_count is: {s}\n", .{type_or_count});
            // std.debug.print("rest is: {?s}\n", .{gres_items.peek()});
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
                }

                if (!std.mem.eql(u8, type_or_count, ci)) {
                    entry.type = type_or_count;
                }

                continue;
            } else if (std.mem.containsAtLeast(u8, ci, 1, ",")) {
                // count,gres or count, or ,gres
                if (std.mem.startsWith(u8, ci, ",")) {
                    continue;
                } else {
                    entry.count = try std.fmt.parseInt(u32, std.mem.sliceTo(ci, ','), 10);
                }
            } else {
                // type,count
                if (!std.mem.eql(u8, type_or_count, ci)) {
                    entry.count = try std.fmt.parseInt(u32, ci, 10);
                    entry.type = type_or_count;
                } else {
                    entry.count = try std.fmt.parseInt(u32, type_or_count, 10);
                }
            }
        }
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

extern fn slurm_load_jobs(update_time: time_t, job_info_msg_pptr: ?**Job.LoadResponse, show_flags: u16) c_int;
pub fn loadAll() SlurmError!*Job.LoadResponse {
    var data: *Job.LoadResponse = undefined;
    try err.checkRpc(slurm_load_jobs(0, &data, c.SHOW_DETAIL | c.SHOW_ALL));
    return data;
}

extern fn slurm_load_job(resp: ?**Job.LoadResponse, job_id: u32, show_flags: u16) c_int;
pub fn loadOne(id: JobId) SlurmError!*Job {
    var data: *Job.LoadResponse = undefined;
    defer data.deinit();
    try err.checkRpc(slurm_load_job(&data, id, c.SHOW_DETAIL));

    if (data.count != 1) return error.InvalidJobId;

    // This makes the deinit() above viable, because the deinit function will
    // think there are no Job records to free, since we extracted it here.
    data.count = 0;
    return &data.items.?[0];
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
    try std.testing.expect(entry.indexes != null);
    try std.testing.expectEqualSlices(u8, "nvidia-a100", entry.type.?);
    try std.testing.expectEqualSlices(u8, "gpu", entry.name);
    try std.testing.expectEqualSlices(u8, "0,1", entry.indexes.?);
    try std.testing.expect(entry.count == 2);

    const s2 = "gres:gpu:10(IDX:0,1)";
    const entry2 = try parseGresStr(s2);
    try std.testing.expect(entry2.type == null);
    try std.testing.expect(entry2.indexes != null);
    try std.testing.expectEqualSlices(u8, "gpu", entry2.name);
    try std.testing.expectEqualSlices(u8, "0,1", entry2.indexes.?);
    try std.testing.expect(entry2.count == 10);

    const s3 = "gres:gpu:nvidia-a100:20";
    const entry3 = try parseGresStr(s3);
    try std.testing.expect(entry3.type != null);
    try std.testing.expect(entry3.indexes == null);
    try std.testing.expectEqualSlices(u8, "gpu", entry3.name);
    try std.testing.expectEqualSlices(u8, "nvidia-a100", entry3.type.?);
    try std.testing.expect(entry3.count == 20);

    const s4 = "gres:gpu:30,";
    const entry4 = try parseGresStr(s4);
    try std.testing.expect(entry4.type == null);
    try std.testing.expect(entry4.indexes == null);
    try std.testing.expectEqualSlices(u8, "gpu", entry4.name);
    try std.testing.expect(entry4.count == 30);
}
