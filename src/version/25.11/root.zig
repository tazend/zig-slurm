const std = @import("std");
const config = @import("config");

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

pub const api_version = config.slurm_version;
pub const slurm_allocator = SlurmAllocator.slurm_allocator;

pub const init = c.slurm_init;
pub const deinit = c.slurm_fini;
pub const ShowFlags = c.ShowFlags;

comptime {
    if (api_version.major == 0) {
        @compileError(
            "Unable to detect Slurm version\n\r" ++
            "Either provide the slurm include directory via --search-prefix <INCLUDE-DIR>\n\r" ++
            "Or specify the Target Slurm version directly by setting the 'version' build option to something like 25.11.0\n\r"
        );
    }
}

test {
    std.testing.refAllDecls(@This());
}
