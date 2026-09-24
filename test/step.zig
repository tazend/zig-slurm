const std = @import("std");
const testing = std.testing;
const slurm = @import("slurm");

test "stat" {
    if (!slurm.use_slurmfull) return error.SkipZigTest;

    const steps = try slurm.step.load();
    var iter = steps.iter();
    while (iter.next()) |step| {
        const stats = try slurm.step.stat(std.heap.page_allocator, step);
        _ = stats;
    }
}
