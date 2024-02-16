const std = @import("std");
const Allocator = std.mem.Allocator;
const SlurmAllocator = @import("SlurmAllocator.zig");
const builtin = std.builtin;
const c = @import("c.zig");
pub const Job = @import("job.zig");

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

test {
    std.testing.refAllDeclsRecursive(@This());
}

test "slurm_allocator" {
    try std.heap.testAllocator(slurm_allocator);
}
