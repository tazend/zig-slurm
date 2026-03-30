const std = @import("std");
const testing = std.testing;
const slurm = @import("slurm");

test {
    try testing.expect(true);
    slurm.init(null);

    _ = @import("node.zig");
    _ = @import("job.zig");
}
