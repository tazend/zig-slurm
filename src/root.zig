const std = @import("std");
const Allocator = std.mem.Allocator;
const SlurmAllocator = @import("SlurmAllocator.zig");
const builtin = std.builtin;
pub const c = @import("c.zig").c;
pub const Job = @import("Job.zig");
pub const Node = @import("Node.zig");
pub const uint = @import("uint.zig");

pub const slurm_allocator = Allocator{
    .ptr = undefined,
    .vtable = &slurm_allocator_vtable,
};
const slurm_allocator_vtable = Allocator.VTable{
    .alloc = SlurmAllocator.alloc,
    .resize = SlurmAllocator.resize,
    .free = SlurmAllocator.free,
};

pub const init = c.slurm_init;
pub const deinit = c.slurm_fini;

test "slurm_allocator" {
    try std.heap.testAllocator(slurm_allocator);
}
