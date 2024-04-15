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

pub const SignalFlags = struct {
    pub const batch = c.KILL_JOB_BATCH;
    pub const array_task = c.KILL_ARRAY_TASK;
    pub const steps_only = c.KILL_STEPS_ONLY;
    pub const full = c.KILL_FULL_JOB;
    pub const fed_requeue = c.KILL_FED_REQUEUE;
    pub const hurry = c.KILL_HURRY;
    pub const oom = c.KILL_OOM;
    pub const no_sibs = c.KILL_NO_SIBS;
    pub const resv = c.KILL_JOB_RESV;
    pub const no_cron = c.KILL_NO_CRON;
    pub const no_sig_fail = c.KILL_NO_SIG_FAIL;
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
