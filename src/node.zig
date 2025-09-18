const std = @import("std");
const err = @import("error.zig");
const Error = @import("error.zig").Error;
const time_t = std.posix.time_t;
const common = @import("common.zig");
const parseCStr = common.parseCStr;
const NoValue = common.NoValue;
const Infinite = common.Infinite;
const CStr = common.CStr;
const slurm = @import("root.zig");
const c = slurm.c;

pub const Node = extern struct {
    arch: ?CStr = null,
    bcast_address: ?CStr = null,
    boards: u16 = 0,
    boot_time: time_t = 0,
    cluster_name: ?CStr = null,
    cores: u16 = 0,
    core_spec_cnt: u16 = 0,
    cpu_bind: u32 = 0,
    cpu_load: u32 = 0,
    free_mem: u64 = 0,
    cpus: u16 = 0,
    cpus_efctv: u16 = 0,
    cpu_spec_list: ?CStr = null,
    energy: ?*c.AccountingGatherEnergy = null,
    extra: ?CStr = null,
    features: ?CStr = null,
    features_act: ?CStr = null,
    gres: ?CStr = null,
    gres_drain: ?CStr = null,
    gres_used: ?CStr = null,
    instance_id: ?CStr = null,
    instance_type: ?CStr = null,
    last_busy: time_t = 0,
    mcs_label: ?CStr = null,
    mem_spec_limit: u64 = 0,
    name: ?CStr = null,
    next_state: u32 = 0,
    node_addr: ?CStr = null,
    node_hostname: ?CStr = null,
    state: State,
    os: ?CStr = null,
    owner: u32 = 0,
    partitions: ?CStr = null,
    port: u16 = 0,
    real_memory: u64 = 0,
    res_cores_per_gpu: u16 = 0,
    gpu_spec: ?CStr = null,
    comment: ?CStr = null,
    reason: ?CStr = null,
    reason_time: time_t = 0,
    reason_uid: u32 = 0,
    resume_after: time_t = 0,
    resv_name: ?CStr = null,
    select_nodeinfo: ?*c.DynamicPluginData = null,
    slurmd_start_time: time_t = 0,
    sockets: u16 = 0,
    threads: u16 = 0,
    tmp_disk: u32 = 0,
    weight: u32 = 0,
    tres_fmt_str: ?CStr = null,
    version: ?CStr = null,

    pub const LoadResponse = extern struct {
        last_update: time_t,
        count: u32,
        items: ?[*]Node,

        extern fn slurm_free_node_info_msg(node_buffer_ptr: ?*LoadResponse) void;
        pub fn deinit(self: *LoadResponse) void {
            slurm_free_node_info_msg(self);
        }

        pub const Iterator = struct {
            data: *LoadResponse,
            count: usize,

            pub fn next(it: *Iterator) ?*Node {
                const id = it.count;
                defer it.count += 1;
                return it.data.get_node_by_idx(id);
            }

            pub fn reset(it: *Iterator) void {
                it.count = 0;
            }
        };

        pub fn get_node_by_idx(self: *LoadResponse, idx: usize) ?*Node {
            if (idx >= self.count) return null;
            return &self.items.?[idx];
        }

        pub fn iter(self: *LoadResponse) Iterator {
            return Iterator{
                .data = self,
                .count = 0,
            };
        }

        pub fn asSlice(self: *LoadResponse) []Node {
            if (self.count == 0) return &.{};
            return self.items[0..self.count];
        }
    };

    pub const Updatable = extern struct {
        comment: ?CStr = null,
        cpu_bind: u32 = 0,
        cert_token: ?CStr = null,
        extra: ?CStr = null,
        features: ?CStr = null,
        features_active: ?CStr = null,
        gres: ?CStr = null,
        instance_id: ?CStr = null,
        instance_type: ?CStr = null,
        node_addr: ?CStr = null,
        node_hostname: ?CStr = null,
        node_names: ?CStr = null,
        state: u32 = NoValue.u32,
        reason: ?CStr = null,
        reason_uid: u32 = 0,
        resume_after: u32 = NoValue.u32,
        weight: u32 = NoValue.u32,
    };

    pub const Features = struct {
        available: ?[]const u8 = null,
        active: ?[]const u8 = null,
    };

    pub const Host = struct {
        address: ?[]const u8 = null,
        name: ?[]const u8 = null,
    };

    pub const SelectDataType = enum(c_uint) {
        subcount = 2,
        ptr = 5,
        mem_alloc = 8,
        tres_alloc_fmt_string = 9,
        tres_alloc_weighted = 10,
    };

    pub const Utilization = struct {
        alloc_cpus: u16 = 0,
        effective_cpus: u16 = 0,
        total_cpus: u16 = 0,
        idle_cpus: u16 = 0,
        real_memory: u128 = 0,
        free_memory: u128 = 0,
        idle_memory: u128 = 0,
        alloc_memory: u128 = 0,

        fn fromNode(node: *Node) Utilization {
            var util = Utilization{};
            util.alloc_memory += node.allocMemory();
            util.alloc_cpus += node.allocCpus();
            util.total_cpus += node.cpus;
            util.effective_cpus += node.cpus_efctv;
            util.idle_cpus += util.effective_cpus - util.alloc_cpus;
            util.real_memory += node.real_memory;
            util.free_memory += node.free_mem;
            util.idle_memory += util.real_memory - util.alloc_memory;

            return util;
        }

        pub fn add(self: *Utilization, other: Utilization) void {
            self.alloc_memory += other.alloc_memory;
            self.alloc_cpus += other.alloc_cpus;
            self.total_cpus += other.total_cpus;
            self.effective_cpus += other.effective_cpus;
            self.idle_cpus += other.idle_cpus;
            self.real_memory += other.real_memory;
            self.free_memory += other.free_memory;
            self.idle_memory += other.idle_memory;
        }

        pub fn fromNodes(node_resp: *Node.LoadResponse) Utilization {
            var util = Utilization{};

            var node_iter = node_resp.iter();
            while (node_iter.next()) |node| {
                const node_util = Utilization.fromNode(node);
                util.add(node_util);
            }
            return util;
        }

        pub fn groupByNode(node_resp: *Node.LoadResponse, allocator: std.mem.Allocator) !std.StringHashMap(Utilization) {
            var out = std.StringHashMap(Utilization).init(allocator);

            var node_iter = node_resp.iter();
            while (node_iter.next()) |node| {
                const util = Utilization.fromNode(node);
                if (parseCStr(node.name)) |name| {
                    try out.put(name, util);
                }
            }
            return out;
        }
    };

    pub fn utilization(self: *Node) Utilization {
        return Utilization.fromNode(self);
    }

    pub fn allocTresMalloced(self: Node) ?CStr {
        var alloc_tres: ?[:0]const u8 = null;
        if (self.select_nodeinfo != null) {
            _ = c.slurm_get_select_nodeinfo(
                self.select_nodeinfo,
                .tres_alloc_fmt_string,
                .allocated,
                &alloc_tres,
            );
        }
        if (alloc_tres) |a| return a.ptr else return null;
    }

    pub fn allocTres(self: Node, allocator: std.mem.Allocator) !?[:0]const u8 {
        const alloc_tres_malloced = self.allocTresMalloced();

        if (alloc_tres_malloced) |tres_malloc| {
            const tmp: []const u8 = std.mem.span(tres_malloc);
            defer slurm.slurm_allocator.free(tmp);
            return try allocator.dupeZ(u8, tmp);
        } else return null;
    }

    pub fn allocCpus(self: Node) u16 {
        var alloc_cpus: u16 = 0;
        if (self.select_nodeinfo != null) {
            _ = c.slurm_get_select_nodeinfo(
                self.select_nodeinfo,
                .subcount,
                .allocated,
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
                .mem_alloc,
                .allocated,
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

    pub fn delete(self: Node) !void {
        if (self.node_hostname) |name| {
            try slurm.deleteNodesByName(std.mem.span(name));
        }
    }

    pub fn update(self: Node, changes: *Updatable) !void {
        if (self.name) |name| {
            changes.node_names = std.mem.span(name);
            try slurm.updateNodes(changes.*);
        }
    }

    pub const State = packed struct(u32) {
        base: Base,
        flags: Flags = .{},
        _padding1: u4 = 0,

        pub const empty: State = .{ .base = .unknown };
        pub const down: State = .{ .base = .down };
        pub const idle: State = .{ .base = .idle };
        pub const allocated: State = .{ .base = .allocated };
        pub const mixed: State = .{ .base = .mixed };
        pub const future: State = .{ .base = .future };

        pub const Base = enum(u4) {
            unknown,
            down,
            idle,
            allocated,
            err,
            mixed,
            future,
            _end,
        };

        pub const Flags = packed struct(u24) {
            network: bool = false, // removed in 24.11
            reservation: bool = false,
            undrain: bool = false,
            cloud: bool = false,
            resuming: bool = false,
            drain: bool = false,
            completing: bool = false,
            not_responding: bool = false,
            powered_down: bool = false,
            fail: bool = false,
            powering_up: bool = false,
            maint: bool = false,
            reboot_requested: bool = false,
            reboot_cancel: bool = false,
            powering_down: bool = false,
            dynamic_future: bool = false,
            reboot_issued: bool = false,
            planned: bool = false,
            invalid_reg: bool = false,

            power_down: bool = false,
            power_up: bool = false,
            power_drain: bool = false,
            dynamic_norm: bool = false,
            blocked: bool = false,

            pub usingnamespace common.BitflagMethods(State.Flags, u24);
        };

        pub fn toStr(self: State, allocator: std.mem.Allocator) ![:0]const u8 {
            var base_str: [:0]const u8 = "invalid";
            if (@intFromEnum(self.base) < @intFromEnum(State.Base._end)) {
                base_str = @tagName(self.base);
            }

            const sep = "+";
            const flag_str: []const u8 = try self.flags.toStr(allocator, sep);
            defer allocator.free(flag_str);

            const size = blk: {
                var i = base_str.len;
                if (flag_str.len != 0) i += sep.len + flag_str.len;

                break :blk i;
            };

            const slice = try allocator.allocSentinel(u8, size, 0);
            @memcpy(slice[0..base_str.len], base_str);

            if (flag_str.len != 0) {
                @memcpy(slice[base_str.len..][0..sep.len], sep);
                @memcpy(slice[base_str.len + sep.len ..][0..flag_str.len], flag_str);
            }

            return slice;
        }
    };
};
