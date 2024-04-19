const c = @import("c.zig").c;
const std = @import("std");
const err = @import("error.zig");
const Error = @import("error.zig").Error;
const time_t = std.os.linux.time_t;

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

    _padding: u6 = 0,
};

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
    _padding1: bool = false,
    _padding2: bool = false,
    _padding4: bool = false,
    _padding8: bool = false,
    _padding16: bool = false,
    _padding32: bool = false,
    _padding64: bool = false,
    _padding128: bool = false,

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

    _padding_end: u8 = 0,

    pub fn toStr(self: StateFlags) ?[:0]const u8 {
        inline for (std.meta.fields(@TypeOf(self))) |f| {
            if (f.type == bool and @as(f.type, @field(self, f.name))) {
                return f.name;
            }
        }
        return null;
    }
};

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

    _padding: u6 = 0,

    pub const all: MailFlags = @bitCast(@as(u16, (1 << @typeInfo(MailFlags).Struct.fields.len - 1) - 1));

    pub fn toStr(self: MailFlags, allocator: std.mem.Allocator) ![]const u8 {
        const sep = ",";

        comptime var max_size = sep.len * (@typeInfo(MailFlags).Struct.fields.len - 2);
        inline for (std.meta.fields(@TypeOf(self))) |f| {
            if (f.type == bool) max_size += f.name.len;
        }

        var result: [max_size]u8 = undefined;
        var bytes: usize = 0;
        inline for (std.meta.fields(@TypeOf(self))) |f| {
            if (f.type == bool and @as(f.type, @field(self, f.name))) {
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
};

pub const HoldMode = enum {
    user,
    admin,
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

pub inline fn stateStr(self: Job) [:0]const u8 {
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

pub fn getRunTime(self: Job) time_t {
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

pub fn getMemoryPerCpu(self: Job) ?u64 {
    const mem = self.c_ptr.pn_min_memory;
    if (mem != c.NO_VAL64 and (mem & c.MEM_PER_CPU) != 0) {
        return mem & (~c.MEM_PER_CPU);
    } else return null;
}

pub fn getMemoryPerNode(self: Job) ?u64 {
    const mem = self.c_ptr.pn_min_memory;
    if (mem != c.NO_VAL64 and (mem & c.MEM_PER_CPU) == 0) {
        return mem;
    } else return null;
}

pub fn getMemory(self: Job) u64 {
    if (self.getMemoryPerNode()) |mem| {
        return mem * self.c_ptr.num_nodes;
    } else if (self.getMemoryPerCpu()) |mem| {
        return mem * self.c_ptr.num_cpus;
    } // TODO: GPU

    return 0;
}

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

pub fn load_all() Error!InfoResponse {
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

pub fn load_one(id: JobId) Error!InfoResponse {
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

pub fn send_signal(self: Job, signal: u16, flags: u16) Error!void {
    try err.checkRpc(c.slurm_kill_job(self.id, signal, flags));
}

pub fn cancel(self: Job) Error!void {
    try self.send_signal(9, 0);
}

pub fn suspendx(self: Job) Error!void {
    try err.checkRpc(c.slurm_suspend(self.id));
}

pub fn unsuspend(self: Job) Error!void {
    try err.checkRpc(c.slurm_resume(self.id));
}

pub fn hold(self: Job, mode: HoldMode) void {
    _ = mode;
    _ = self;
}

pub fn release(self: Job) void {
    _ = self;
}

pub fn requeue(self: Job) Error!void {
    try err.checkRpc(c.slurm_requeue(self.id, 0));
}

pub fn requeue_hold(self: Job) Error!void {
    try err.checkRpc(c.slurm_requeue(self.id, c.JOB_REQUEUE_HOLD));
}
