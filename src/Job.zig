const c = @import("c.zig").c;
const std = @import("std");
const err = @import("error.zig");
const Error = @import("error.zig").Error;

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
