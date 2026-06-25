const std = @import("std");
const time_t = std.posix.time_t;
const slurm = @import("root.zig");

pub const Instance = extern struct {
    cluster: ?CStr = null,
    extra: ?CStr = null,
    instance_id: ?CStr = null,
    instance_type: ?CStr = null,
    node_name: ?CStr = null,
    time_end: time_t = 0,
    time_start: time_t = 0,

    pub const Filter = extern struct {
        cluster_list: ?*List(*anyopaque) = null,
        extra_list: ?*List(*anyopaque) = null,
        format_list: ?*List(*anyopaque) = null,
        instance_id_list: ?*List(*anyopaque) = null,
        instance_type_list: ?*List(*anyopaque) = null,
        node_list: ?CStr = null,
        time_end: time_t = 0,
        time_start: time_t = 0,
    };
};
