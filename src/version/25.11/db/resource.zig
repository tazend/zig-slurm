const std = @import("std");
const db = @import("../db.zig");
const common = @import("../common.zig");
const slurm = @import("../root.zig");
const CStr = common.CStr;
const Connection = db.Connection;
const List = db.List;
const err = slurm.err;
const checkRpc = err.checkRpc;

pub const Resource = extern struct {
    allocated: u32 = 0,
    last_consumed: u32 = 0,
    clus_res_list: ?*List(*opaque {}) = null,
    clus_res_rec: ?*slurmdb_clus_res_rec_t = null,
    count: u32 = 0,
    description: ?CStr = @import("std").mem.zeroes([*c]u8),
    flags: u32 = 0,
    id: u32 = 0,
    last_update: time_t = 0,
    manager: ?CStr = @import("std").mem.zeroes([*c]u8),
    name: ?CStr = @import("std").mem.zeroes([*c]u8),
    server: ?CStr = @import("std").mem.zeroes([*c]u8),
    type: u32 = 0,

    pub const Filter = extern struct {
        allowed_list: ?*List(*opaque {}) = null,
        cluster_list: ?*List(*opaque {}) = null,
        description_list: ?*List(*opaque {}) = null,
        flags: u32 = 0,
        format_list: ?*List(*opaque {}) = null,
        id_list: ?*List(*opaque {}) = null,
        manager_list: ?*List(*opaque {}) = null,
        name_list: ?*List(*opaque {}) = null,
        server_list: ?*List(*opaque {}) = null,
        type_list: ?*List(*opaque {}) = null,
        with_deleted: u16 = 0,
        with_clusters: u16 = 0,
    };
};

