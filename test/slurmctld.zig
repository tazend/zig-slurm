const std = @import("std");
const testing = std.testing;
const slurm = @import("slurm");

test "loadConfig" {
    const config = try slurm.slurmctld.Config.load();
    defer config.deinit();
}
