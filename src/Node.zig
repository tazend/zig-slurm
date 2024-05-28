const c = @import("c.zig").c;
const std = @import("std");
const err = @import("error.zig");
const Error = @import("error.zig").Error;
const time_t = std.posix.time_t;

pub const ResponseMessage = c.node_info_msg_t;
const ResponseMessagePartition = c.partition_info_msg_t;

pub const Node = extern struct {
    arch: ?[*:0]u8 = null,
    bcast_address: ?[*:0]u8 = null,
    boards: u16 = 0,
    boot_time: time_t = 0,
    cluster_name: ?[*:0]u8 = null,
    cores: u16 = 0,
    core_spec_cnt: u16 = 0,
    cpu_bind: u32 = 0,
    cpu_load: u32 = 0,
    free_mem: u64 = 0,
    cpus: u16 = 0,
    cpus_efctv: u16 = 0,
    cpu_spec_list: ?[*:0]u8 = null,
    energy: ?*c.acct_gather_energy_t = null,
    ext_sensors: ?*c.ext_sensors_data_t = null,
    extra: ?[*:0]u8 = null,
    power: ?*c.power_mgmt_data_t = null,
    features: ?[*:0]u8 = null,
    features_act: ?[*:0]u8 = null,
    gres: ?[*:0]u8 = null,
    gres_drain: ?[*:0]u8 = null,
    gres_used: ?[*:0]u8 = null,
    instance_id: ?[*:0]u8 = null,
    instance_type: ?[*:0]u8 = null,
    last_busy: time_t = 0,
    mcs_label: ?[*:0]u8 = null,
    mem_spec_limit: u64 = 0,
    name: ?[*:0]u8 = null,
    next_state: u32 = 0,
    node_addr: ?[*:0]u8 = null,
    node_hostname: ?[*:0]u8 = null,
    node_state: u32 = 0,
    os: ?[*:0]u8 = 0,
    owner: u32 = 0,
    partitions: ?[*:0]u8 = null,
    port: u16 = 0,
    real_memory: u64 = 0,
    comment: ?[*:0]u8 = null,
    reason: ?[*:0]u8 = null,
    reason_time: time_t = 0,
    reason_uid: u32 = 0,
    resume_after: time_t = 0,
    resv_name: ?[*:0]u8 = null,
    select_nodeinfo: ?*c.dynamic_plugin_data_t = null,
    slurmd_start_time: time_t = 0,
    sockets: u16 = 0,
    threads: u16 = 0,
    tmp_disk: u32 = 0,
    weight: u32 = 0,
    tres_fmt_str: ?[*:0]u8 = null,
    version: ?[*:0]u8 = null,

    pub const Utilization = struct {
        alloc_cpus: u16 = 0,
        effective_cpus: u16 = 0,
        total_cpus: u16 = 0,
        idle_cpus: u16 = 0,
        real_memory: u64 = 0,
        free_memory: u64 = 0,
        idle_memory: u64 = 0,
        alloc_memory: u64 = 0,

        pub fn fromNodes(node_resp: *InfoResponse) Utilization {
            var util = Utilization{};

            var node_iter = node_resp.iter();
            while (node_iter.next()) |node| {
                util.alloc_memory += node.getAllocMemory();
                util.alloc_cpus += node.getAllocCpus();
                util.total_cpus += node.cpus;
                util.effective_cpus += node.cpus_efctv;
                util.idle_cpus += util.effective_cpus - util.alloc_cpus;
                util.real_memory += node.real_memory;
                util.free_memory += node.free_mem;
                util.idle_memory += util.real_memory - util.alloc_memory;
            }
            return util;
        }
    };

    pub fn allocCpus(self: Node) u16 {
        var alloc_cpus: u16 = 0;
        if (self.select_nodeinfo != null) {
            _ = c.slurm_get_select_nodeinfo(
                self.select_nodeinfo,
                c.SELECT_NODEDATA_SUBCNT,
                c.NODE_STATE_ALLOCATED,
                &alloc_cpus,
            );
        }
        return alloc_cpus;
    }

    pub fn allocMemory(self: Node) u64 {
        var alloc_memory: u64 = 0;
        if (self.select_nodeinfo != null) {
            _ = c.slurm_get_select_nodeinfo(
                self.select_nodeinfo,
                c.SELECT_NODEDATA_MEM_ALLOC,
                c.NODE_STATE_ALLOCATED,
                &alloc_memory,
            );
        }
        return alloc_memory;
    }

    pub inline fn idleCpus(self: Node) u16 {
        return self.cpus_efctv - self.allocCpus();
    }

    pub inline fn idleMemory(self: Node) u64 {
        return self.real_memory - self.allocMemory();
    }

    pub const InfoResponse = struct {
        msg: *ResponseMessage = undefined,
        msg_part: *ResponseMessagePartition = undefined,
        count: u32 = 0,
        items: [*]Node,

        pub fn deinit(self: InfoResponse) void {
            c.slurm_free_node_info_msg(self.msg);
            c.slurm_free_partition_info_msg(self.msg_part);
        }

        pub const Iterator = struct {
            resp: *InfoResponse,
            count: usize,

            pub fn next(it: *Iterator) ?*Node {
                const id = it.count;
                defer it.count += 1;
                return it.resp.get_node_by_idx(id);
            }

            pub fn reset(it: *Iterator) void {
                it.count = 0;
            }
        };

        pub fn get_node_by_idx(self: *InfoResponse, idx: usize) ?*Node {
            if (idx >= self.count) return null;
            const c_ptr: *Node = @ptrCast(&self.items[idx]);
            return c_ptr;
        }

        pub fn iter(self: *InfoResponse) Iterator {
            return Iterator{
                .resp = self,
                .count = 0,
            };
        }

        pub fn slice_raw(self: *InfoResponse) []Node {
            if (self.count == 0) return &.{};
            return self.items[0..self.count];
        }
    };

    pub fn loadAll() Error!InfoResponse {
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
            .items = @ptrCast(node_resp.node_array),
        };
    }
};
