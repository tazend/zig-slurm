const std = @import("std");
const Allocator = std.mem.Allocator;
const SlurmAllocator = @import("SlurmAllocator.zig");
const builtin = std.builtin;

pub const job = @import("job/job.zig");
pub const node = @import("node.zig");
pub const step = @import("job/step.zig");
pub const partition = @import("partition.zig");
pub const reservation = @import("reservation.zig");

pub const Job = job.Job;
pub const Step = step.Step;
pub const Node = node.Node;
pub const Partition = partition.Partition;
pub const Reservation = reservation.Reservation;

pub const uint = @import("uint.zig");
pub const parseCStr = common.parseCStr;
pub const parseCStrZ = common.parseCStrZ;
pub const db = @import("db.zig");
pub const err = @import("error.zig");
pub const Error = err.Error;
pub const c = @import("slurm-ext.zig");
pub const tres = @import("tres.zig");
pub const gres = @import("gres.zig");
pub const common = @import("common.zig");
pub const slurmctld = @import("slurmctld.zig");
const time_t = std.os.linux.time_t;

pub const slurm_allocator = SlurmAllocator.slurm_allocator;

pub const init = c.slurm_init;
pub const deinit = c.slurm_fini;

pub fn loadJobs() Error!*Job.LoadResponse {
    var data: *Job.LoadResponse = undefined;
    const flags: ShowFlags = .full;

    try err.checkRpc(c.slurm_load_jobs(0, &data, flags));
    return data;
}

pub fn loadJob(id: u32) Error!*Job {
    var data: *Job.LoadResponse = undefined;
    defer data.deinit();
    const flags: ShowFlags = .{ .detail = true };

    try err.checkRpc(c.slurm_load_job(&data, id, flags));

    if (data.count != 1) return error.InvalidJobId;

    // This makes the deinit() above viable, because the deinit function will
    // think there are no Job records to free, since we extracted it here.
    data.count = 0;
    return &data.items.?[0];
}
pub const ShowFlags = c.ShowFlags;

test {
    std.testing.refAllDecls(@This());
}
