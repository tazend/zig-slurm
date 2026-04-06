const std = @import("std");
const slurm = @import("root.zig");
const common = @import("common.zig");
const err = slurm.err;
const Error = err.Error;
const time_t = std.posix.time_t;
const NoValue = common.NoValue;
const Infinite = common.Infinite;
const CStr = common.CStr;
const BitString = common.BitString;
const List = slurm.db.List;
const c = slurm.c;

pub const JobDefaults = extern struct {
    type: u16 = 0,
    value: u64 = 0,
};

pub const Partition = extern struct {
    allow_alloc_nodes: ?CStr = null,
    allow_accounts: ?CStr = null,
    allow_groups: ?CStr = null,
    allow_qos: ?CStr = null,
    alternate: ?CStr = null,
    billing_weights_str: ?CStr = null,
    cluster_name: ?CStr = null,
    cr_type: u16 = 0,
    cpu_bind: u32 = 0,
    def_mem_per_cpu: u64 = NoValue.u64,
    default_time: u32 = NoValue.u32,
    deny_accounts: ?CStr = null,
    deny_qos: ?CStr = null,
    flags: u32 = 0,
    grace_time: u32 = NoValue.u32,
    job_defaults_list: ?*List(*JobDefaults) = null,
    job_defaults_str: ?CStr = null,
    max_cpus_per_node: u32 = NoValue.u32,
    max_cpus_per_socket: u32 = NoValue.u32,
    max_mem_per_cpu: u64 = NoValue.u32,
    max_nodes: u32 = NoValue.u32,
    max_share: u16 = NoValue.u16,
    max_time: u32 = NoValue.u32,
    min_nodes: u32 = NoValue.u32,
    name: ?CStr = null,
    node_inx: ?[*]i32 = null,
    nodes: ?CStr = null,
    nodesets: ?CStr = null,
    over_time_limit: u16 = NoValue.u16,
    preempt_mode: u16 = NoValue.u16,
    priority_job_factor: u16 = NoValue.u16,
    priority_tier: u16 = NoValue.u16,
    qos_char: ?CStr = null,
    resume_timeout: u16 = NoValue.u16,
    state_up: u16 = NoValue.u16,
    suspend_time: u32 = NoValue.u32,
    suspend_timeout: u16 = NoValue.u16,
    topology_name: ?CStr = null,
    total_cpus: u32 = NoValue.u32,
    total_nodes: u32 = NoValue.u32,
    tres_fmt_str: ?CStr = null,

    pub const LoadResponse = extern struct {
        last_update: time_t = 0,
        count: u32,
        items: ?[*]Partition,

        pub fn deinit(self: *LoadResponse) void {
            c.slurm_free_partition_info_msg(self);
        }
        pub const Iterator = common.LoadResponseIterator(Partition);

        const methods = common.LoadResponseMethods(Partition);
        pub const iter = methods.iter;
        pub const get = methods.get;
        pub const toSlice = methods.toSlice;
    };

    pub const Updatable = Partition;
};

pub fn load() Error!*Partition.LoadResponse {
    var data: *Partition.LoadResponse = undefined;
    const flags: c.ShowFlags = .full;

    try err.checkRpc(c.slurm_load_partitions(0, &data, flags));
    return data;
}
