const std = @import("std");
const Allocator = std.mem.Allocator;
const SlurmAllocator = @import("SlurmAllocator.zig");
const builtin = std.builtin;

pub const job = @import("job/job.zig");
pub const node = @import("node.zig");
pub const step = @import("job/step.zig");
pub const partition = @import("partition.zig");

pub const Job = job.Job;
pub const Step = step.Step;
pub const Node = node.Node;
pub const Partition = partition.Partition;

pub const uint = @import("uint.zig");
pub const parseCStr = @import("common.zig").parseCStr;
pub const parseCStrZ = @import("common.zig").parseCStrZ;
pub const db = @import("db.zig");
pub const err = @import("error.zig");
pub const Error = err.Error;
pub const c = @import("slurm-ext.zig");
pub const tres = @import("tres.zig");
pub const gres = @import("gres.zig");
pub const common = @import("common.zig");
const time_t = std.os.linux.time_t;

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

pub fn loadPartitions() Error!*Partition.LoadResponse {
    var data: *Partition.LoadResponse = undefined;
    const flags: ShowFlags = .full;

    try err.checkRpc(c.slurm_load_partitions(0, &data, flags));
    return data;
}

pub fn loadNodes() Error!*Node.LoadResponse {
    var node_resp: *Node.LoadResponse = undefined;
    var flags: ShowFlags = .full;
    flags.mixed = true;

    try err.checkRpc(c.slurm_load_node(0, &node_resp, flags));

    const part_resp = try loadPartitions();
    defer part_resp.deinit();

    c.slurm_populate_node_partitions(node_resp, part_resp);

    if (flags.mixed) {
        var node_iter = node_resp.iter();
        while (node_iter.next()) |n| {
            if (n.name == null) continue;

            const idle_cpus = n.idleCpus();
            if (idle_cpus > 0 and idle_cpus < n.cpus_efctv) {
                n.state.base = .mixed;
                continue;
            }

            const alloc_tres = n.allocTresMalloced();
            if (alloc_tres != null and idle_cpus == n.cpus_efctv) {
                n.state.base = .mixed;
            }
        }
    }

    return node_resp;
}

pub fn updateNodes(update_msg: Node.Updatable) !void {
    try err.checkRpc(c.slurm_update_node(@constCast(&update_msg)));
}

pub fn deleteNodes(update_msg: Node.Updatable) !void {
    try err.checkRpc(c.slurm_delete_node(@constCast(&update_msg)));
}

pub fn deleteNodesByName(names: [:0]const u8) !void {
    const msg: Node.Updatable = .{ .node_names = names };
    try deleteNodes(msg);
}

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

test "slurm_allocator" {
    try std.heap.testAllocator(slurm_allocator);
}

test {
    std.testing.refAllDeclsRecursive(Job);
}
