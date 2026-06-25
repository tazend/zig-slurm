const std = @import("std");
const time_t = std.posix.time_t;
const slurm = @import("root.zig");

pub const Federation = extern struct {
    name: ?CStr = null,
    flags: u32 = 0,
    cluster_list: ?*List(*db.Cluster) = null,

    pub const Filter = extern struct {
        cluster_list: ?*List(CStr) = null,
        federation_list: ?*List(CStr) = null,
        format_list: ?*List(CStr) = null,
        with_deleted: u16 = 0,
    };
};
