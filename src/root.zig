const std = @import("std");
const Allocator = std.mem.Allocator;
const SlurmAllocator = @import("SlurmAllocator.zig");
const builtin = std.builtin;
pub const c = @import("c.zig").c;
pub const Job = @import("Job.zig");
pub const Node = @import("Node.zig").Node;
pub const uint = @import("uint.zig");

pub const slurm_allocator = SlurmAllocator.slurm_allocator;

pub const init = c.slurm_init;
pub const deinit = c.slurm_fini;

pub inline fn parseCStr(s: ?[*:0]u8) ?[]const u8 {
    if (s == null) return null;
    return std.mem.span(s);
}

test "slurm_allocator" {
    try std.heap.testAllocator(slurm_allocator);
}

test {
    std.testing.refAllDeclsRecursive(Job);
}
