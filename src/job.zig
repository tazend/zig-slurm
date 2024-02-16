const c = @import("c.zig");
const std = @import("std");

const Job = @This();
const JobId = u32;
const ResponseMessage = c.job_info_msg_t;
const JobInfo = c.slurm_job_info_t;

ptr: *JobInfo = undefined,
id: JobId,

pub const Jobs = struct {
    msg: *ResponseMessage = undefined,
    count: u32 = 0,
    items: [*c]JobInfo,

    const Self = @This();

    pub fn load(flags: u16) Jobs {
        var data: *ResponseMessage = undefined;
        _ = c.slurm_load_jobs(0, @ptrCast(&data), flags);
        return Jobs{
            .msg = data,
            .count = data.record_count,
            .items = data.job_array,
        };
    }

    pub fn load_one(id: JobId) Self {
        var data: *ResponseMessage = undefined;
        _ = c.slurm_load_job(@ptrCast(&data), id, c.SHOW_DETAIL);
        return Jobs{
            .msg = data,
            .count = data.record_count,
            .items = data.job_array,
        };
    }

    pub inline fn deinit(self: Self) void {
        c.slurm_free_job_info_msg(self.msg);
        self.items.* = undefined;
    }

    pub const Iterator = struct {
        jobs: *Jobs,
        count: usize,

        pub fn next(it: *Iterator) ?Job {
            if (it.count >= it.jobs.count) return null;
            const id = it.count;
            it.count += 1;
            const ptr: *JobInfo = @ptrCast(&it.jobs.items[id]);
            return Job{ .ptr = ptr, .id = ptr.job_id };
        }

        pub fn reset(it: *Iterator) void {
            it.count = 0;
        }
    };

    pub fn iter(self: *Self) Iterator {
        return Iterator{
            .jobs = self,
            .count = 0,
        };
    }

    pub fn slice_raw(self: *Self) []JobInfo {
        return self.items[0..self.count];
    }
};

pub fn send_signal(self: Job, signal: u16) void {
    _ = c.slurm_kill_job(self.id, signal, 0);
}

pub fn cancel(self: Job) void {
    _ = self.send_signal(9);
}
