const std = @import("std");
const testing = std.testing;
const slurm = @import("slurm");

test {
    slurm.init(null);

    _ = @import("node.zig");
    _ = @import("job.zig");
    _ = @import("partition.zig");
    _ = @import("reservation.zig");
    _ = @import("slurmctld.zig");
    _ = @import("license.zig");
    _ = @import("trigger.zig");
    _ = @import("step.zig");
}
