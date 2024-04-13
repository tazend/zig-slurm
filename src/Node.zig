const c = @import("c.zig").c;
const std = @import("std");
const err = @import("error.zig");
const Error = @import("error.zig").Error;

const Node = @This();
pub const NodeName = [:0]const u8;
pub const ResponseMessage = c.node_info_msg_t;
const ResponseMessagePartition = c.partition_info_msg_t;
pub const RawNode = c.node_info_t;

c_ptr: *RawNode = undefined,
name: NodeName,
data: ParsedNode = undefined,

pub const ParsedNode = struct {
    name: NodeName = undefined,
    alloc_cpus: u16 = 0,
    alloc_memory: u64 = 0,
    effective_cpus: u16 = 0,
    total_cpus: u16 = 0,
    idle_cpus: u16 = 0,
    real_memory: u64 = 0,
    free_memory: u64 = 0,
    idle_memory: u64 = 0,
};

pub const Utilization = struct {
    alloc_cpus: u16 = 0,
    effective_cpus: u16 = 0,
    total_cpus: u16 = 0,
    idle_cpus: u16 = 0,
    real_memory: u64 = 0,
    free_memory: u64 = 0,
    idle_memory: u64 = 0,
    alloc_memory: u64 = 0,

    pub fn from_nodes(node_resp: *InfoResponse) Utilization {
        var util = Utilization{};

        var node_iter = node_resp.iter();
        while (node_iter.next()) |node| {
            util.alloc_memory = node.get_alloc_memory();
            util.alloc_cpus = node.get_alloc_cpus();
            util.total_cpus = node.c_ptr.cpus;
            util.effective_cpus = node.c_ptr.cpus_efctv;
            util.idle_cpus = util.effective_cpus - util.alloc_cpus;
            util.real_memory = node.c_ptr.real_memory;
            util.free_memory = node.c_ptr.free_mem;
            util.idle_memory = util.real_memory - util.alloc_memory;
        }
        return util;
    }
};

pub fn get_alloc_cpus(self: Node) u16 {
    var alloc_cpus: u16 = 0;
    if (self.c_ptr.select_nodeinfo != null) {
        _ = c.slurm_get_select_nodeinfo(
            self.c_ptr.select_nodeinfo,
            c.SELECT_NODEDATA_SUBCNT,
            c.NODE_STATE_ALLOCATED,
            &alloc_cpus,
        );
    }
    return alloc_cpus;
}

pub fn get_alloc_memory(self: Node) u64 {
    var alloc_memory: u64 = 0;
    if (self.c_ptr.select_nodeinfo != null) {
        _ = c.slurm_get_select_nodeinfo(
            self.c_ptr.select_nodeinfo,
            c.SELECT_NODEDATA_MEM_ALLOC,
            c.NODE_STATE_ALLOCATED,
            &alloc_memory,
        );
    }
    return alloc_memory;
}

pub fn parse_c_ptr(self: Node) ParsedNode {
    var pnode = ParsedNode{};
    const ptr: *RawNode = self.c_ptr;
    _ = ptr;

    pnode.name = self.name;
    pnode.alloc_memory = self.get_alloc_memory();
    pnode.alloc_cpus = self.get_alloc_cpus();
    pnode.total_cpus = self.c_ptr.cpus;
    pnode.effective_cpus = self.c_ptr.cpus_efctv;
    pnode.idle_cpus = pnode.effective_cpus - pnode.alloc_cpus;
    pnode.real_memory = self.c_ptr.real_memory;
    pnode.free_memory = self.c_ptr.free_mem;
    pnode.idle_memory = pnode.real_memory - pnode.alloc_memory;

    return pnode;
}

pub const InfoResponse = struct {
    msg: *ResponseMessage = undefined,
    msg_part: *ResponseMessagePartition = undefined,
    count: u32 = 0,
    items: [*c]RawNode,

    const Self = @This();

    pub fn deinit(self: Self) void {
        c.slurm_free_node_info_msg(self.msg);
        c.slurm_free_partition_info_msg(self.msg_part);
        self.items.* = undefined;
    }

    pub const Iterator = struct {
        resp: *InfoResponse,
        count: usize,

        pub fn next(it: *Iterator) ?Node {
            const id = it.count;
            defer it.count += 1;
            return it.resp.get_node_by_idx(id);
        }

        pub fn reset(it: *Iterator) void {
            it.count = 0;
        }
    };

    pub fn get_node_by_idx(self: *Self, idx: usize) ?Node {
        if (idx >= self.count) return null;

        const c_ptr: *RawNode = @ptrCast(&self.items[idx]);

        return Node{
            .c_ptr = c_ptr,
            // TODO: c_ptr.name could be NULL
            .name = std.mem.span(c_ptr.name),
        };
    }

    pub fn iter(self: *Self) Iterator {
        return Iterator{
            .resp = self,
            .count = 0,
        };
    }

    pub fn slice_raw(self: *Self) []RawNode {
        if (self.count == 0) return &.{};
        return self.items[0..self.count];
    }
};

pub fn load_all() Error!InfoResponse {
    const flags = c.SHOW_DETAIL | c.SHOW_ALL;

    var node_resp: *ResponseMessage = undefined;
    try err.checkRpc(
        c.slurm_load_node(0, @ptrCast(&node_resp), flags),
    );

    var part_resp: *ResponseMessagePartition = undefined;
    try err.checkRpc(
        c.slurm_load_partitions(0, @ptrCast(&part_resp), flags),
    );
    c.slurm_populate_node_partitions(node_resp, part_resp);

    return InfoResponse{
        .msg = node_resp,
        .msg_part = part_resp,
        .count = node_resp.record_count,
        .items = node_resp.node_array,
    };
}
