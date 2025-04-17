const std = @import("std");
const Allocator = std.mem.Allocator;
const SlurmAllocator = @import("SlurmAllocator.zig");
const builtin = std.builtin;
pub const c = @import("c.zig").c;
pub const Job = @import("Job.zig");
pub const Node = @import("Node.zig").Node;
pub const uint = @import("uint.zig");
pub const parseCStr = @import("common.zig").parseCStr;
pub const parseCStrZ = @import("common.zig").parseCStrZ;
pub const db = @import("db.zig");
pub const tres = @import("tres.zig");
pub const gres = @import("gres.zig");

pub const slurm_allocator = SlurmAllocator.slurm_allocator;

pub const init = c.slurm_init;
pub const deinit = c.slurm_fini;

pub const ShowFlags = packed struct(u16) {
    all: bool = false,
    detail: bool = false,
    mixed: bool = false,
    local: bool = false,
    sibling: bool = false,
    federation: bool = false,
    future: bool = false,
    __padding: u9 = 0,

    pub const full: ShowFlags = .{ .all = true, .detail = true };
};

test "slurm_allocator" {
    try std.heap.testAllocator(slurm_allocator);
}

test {
    std.testing.refAllDeclsRecursive(Job);
}
