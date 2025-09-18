const std = @import("std");
const db = @import("../db.zig");
const common = @import("../common.zig");
const CStr = common.CStr;
const NoValue = common.NoValue;
const time_t = std.posix.time_t;
const List = db.List;
const Connection = db.Connection;
const checkRpc = @import("../error.zig").checkRpc;
const slurm_addr_t = @import("../slurmctld.zig").slurm_addr_t;

pub const Cluster = extern struct {
    accounting_list: ?*List(*opaque {}) = null,
    classification: u16 = 0,
    comm_fail_time: time_t = 0,
    control_addr: slurm_addr_t,
    control_host: ?CStr = null,
    control_port: u32,
    dimensions: u16,
    dim_size: ?[*]c_int,
    id: u16 = @import("std").mem.zeroes(u16),
    fed: db.Cluster.Federation,
    flags: u32 = @import("std").mem.zeroes(u32),
    lock: std.c.pthread_mutex_t = @import("std").mem.zeroes(std.c.pthread_mutex_t),
    name: ?CStr = null,
    nodes: ?CStr = null,
    root_assoc: ?*db.Association = null,
    rpc_version: u16 = @import("std").mem.zeroes(u16),
    send_rpc: ?*List(*opaque {}) = null,
    tres_str: ?CStr = null,

    pub const Federation = extern struct {
        feature_list: ?*List(*opaque {}) = null,
        id: u32 = @import("std").mem.zeroes(u32),
        name: [*c]u8 = @import("std").mem.zeroes([*c]u8),
        recv: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
        send: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
        state: u32 = @import("std").mem.zeroes(u32),
        sync_recvd: bool = @import("std").mem.zeroes(bool),
        sync_sent: bool = @import("std").mem.zeroes(bool),
    };

    pub const Filter = extern struct {
        classification: u16,
        cluster_list: ?*List(*opaque {}) = null,
        federation_list: ?*List(*opaque {}) = null,
        flags: u32,
        format_list: ?*List(*opaque {}) = null,
        rpc_version_list: ?*List(*opaque {}) = null,
        usage_end: time_t = 0,
        usage_start: time_t = 0,
        with_deleted: u16,
        with_usage: u16,
    };
};
