const std = @import("std");
const db = @import("db.zig");
const memzero = std.mem.zeroes;
const time_t = @import("std").posix.time_t;
const List = db.List;
const Cluster = db.Cluster;
const err = @import("error.zig");
const Error = err.Error;
const slurm = @import("root.zig");

pub const Statistics = @import("slurmctld/stats.zig").Statistics;
pub const Config = @import("slurmctld/config.zig").Config;

pub const persist_conn_type_t = enum(c_uint) {
    PERSIST_TYPE_NONE,
    PERSIST_TYPE_DBD,
    PERSIST_TYPE_FED,
    PERSIST_TYPE_HA_CTL,
    PERSIST_TYPE_HA_DBD,
    PERSIST_TYPE_ACCT_UPDATE,
};

pub const persist_msg_t = extern struct {
    conn: ?*anyopaque = null,
    data: ?*anyopaque = null,
    msg_type: u16 = 0,
};

pub const slurm_trigger_callbacks_t = extern struct {
    acct_full: ?*const fn (...) callconv(.c) void = @import("std").mem.zeroes(?*const fn (...) callconv(.c) void),
    dbd_fail: ?*const fn (...) callconv(.c) void = @import("std").mem.zeroes(?*const fn (...) callconv(.c) void),
    dbd_resumed: ?*const fn (...) callconv(.c) void = @import("std").mem.zeroes(?*const fn (...) callconv(.c) void),
    db_fail: ?*const fn (...) callconv(.c) void = @import("std").mem.zeroes(?*const fn (...) callconv(.c) void),
    db_resumed: ?*const fn (...) callconv(.c) void = @import("std").mem.zeroes(?*const fn (...) callconv(.c) void),
};

pub const slurm_persist_conn_t = extern struct {
    auth_cred: ?*anyopaque = null,
    auth_uid: std.c.uid_t = memzero(std.c.uid_t),
    auth_gid: std.c.gid_t = memzero(std.c.uid_t),
    auth_ids_set: bool = memzero(bool),
    callback_proc: ?*const fn (?*anyopaque, [*c]persist_msg_t, [*c][*c]buf_t) callconv(.c) c_int = null,
    callback_fini: ?*const fn (?*anyopaque) callconv(.c) void = null,
    cluster_name: ?[*:0]u8 = null,
    comm_fail_time: time_t = memzero(time_t),
    my_port: u16 = memzero(u16),
    flags: u16 = memzero(u16),
    inited: bool = memzero(bool),
    persist_type: persist_conn_type_t = memzero(persist_conn_type_t),
    r_uid: std.c.uid_t = memzero(std.c.uid_t),
    rem_host: [*c]u8 = memzero([*c]u8),
    rem_port: u16 = memzero(u16),
    shutdown: [*c]time_t = memzero([*c]time_t),
    thread_id: std.c.pthread_t,
    timeout: c_int = memzero(c_int),
    conn: ?*anyopaque = null,
    trigger_callbacks: slurm_trigger_callbacks_t = memzero(slurm_trigger_callbacks_t),
    version: u16 = 0,
};

pub const buf_t = extern struct {
    magic: u32,
    head: ?[*:0]u8,
    size: u32,
    processed: u32 = 0,
    mmaped: bool = false,
    shadow: bool = false,

    pub const Magic = 0x42554545;
    pub const Size = 16 * 1024;

    pub fn create() buf_t {
        return .{
            .magic = Magic,
            .size = Size,
            .head = null,
        };
    }
};

pub const return_code_msg_t = extern struct {
    return_code: u32 = 0,
};

pub const job_id_msg_t = extern struct {
    id: slurm.Step.ID,
    show_flags: u16 = 0,
};

pub const slurm_msg_type_t = enum(u16) {
    request_share_info = 2022,
    response_share_info = 2023,
    request_batch_script = 2051,
    response_batch_script = 2052,
    response_slurm_rc = 8001,
    _,
};

pub const slurm_addr_t = std.posix.sockaddr.storage;

pub const slurm_node_alias_addrs_t = extern struct {
    expiration: time_t = @import("std").mem.zeroes(time_t),
    net_cred: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    node_addrs: *slurm_addr_t,
    node_cnt: u32 = @import("std").mem.zeroes(u32),
    node_list: [*c]u8 = @import("std").mem.zeroes([*c]u8),
};

pub const forward_t = extern struct {
    alias_addrs: slurm_node_alias_addrs_t = memzero(slurm_node_alias_addrs_t),
    cnt: u16 = 0,
    init: u16 = 0,
    nodelist: ?[*:0]u8 = null,
    timeout: u32 = 0,
    tree_width: u16 = 0,
    tree_depth: u16 = 0,
};

pub const forward_struct_t = extern struct {
    alias_addrs: ?*slurm_node_alias_addrs_t = null,
    buf: ?[*:0]u8 = null,
    buf_len: c_int = 0,
    fwd_cnt: u16 = 0,
    forward_mutex: std.c.pthread_mutex_t = memzero(std.c.pthread_mutex_t),
    notify: std.c.pthread_cond_t = memzero(std.c.pthread_cond_t),
    ret_list: ?*List(*opaque {}) = null,
    timeout: u32 = memzero(u32),
};

pub const conmgr_fd_t = opaque {};
pub const conmgr_fd_ref_t = opaque {};

fn maybeEnableField(comptime c : bool, comptime t : type) type {
    if (c) {
        return t;
    } else {
        return void;
    }
}

pub const slurm_msg_t = extern struct {
    address: slurm_addr_t = memzero(slurm_addr_t),
    auth_cred: ?*anyopaque = null,
    auth_index: c_int = memzero(c_int),
    auth_uid: std.c.uid_t = memzero(std.c.uid_t),
    auth_gid: std.c.gid_t = memzero(std.c.gid_t),
    auth_ids_set: bool = memzero(bool),
    restrict_uid: std.c.uid_t = memzero(std.c.uid_t),
    restrict_uid_set: bool = memzero(bool),
    body_offset: u32 = memzero(u32),
    buffer: ?*buf_t = null,
    pcon: ?*slurm_persist_conn_t = null,
    conmgr_con: ?*conmgr_fd_ref_t = null,
    data: ?*anyopaque = null,
    flags: u16 = memzero(u16),
    hash_index: u8 = memzero(u8),
    tls_cert: ?[*:0]u8 = null,
    conn: ?*anyopaque = null,
    // This is convenient and works, but adds potentially "dead" fields.
    // The alternative is declaring the struct anew for each possible version
    // Or programatically add/insert fields, but then no one knows whats going on.
    conn_is_mtls: maybeEnableField(slurm.api_version.patch >= 3, bool),
    msg_type: slurm_msg_type_t = memzero(slurm_msg_type_t),
    protocol_version: u16 = memzero(u16),
    forward: forward_t = memzero(forward_t),
    forward_struct: ?*forward_struct_t = null,
    orig_addr: slurm_addr_t = memzero(slurm_addr_t),
    ret_list: ?*List(*opaque {}) = null,

    pub fn init() slurm_msg_t {
        var msg: slurm_msg_t = undefined;
        slurm_msg_t_init(&msg);
        return msg;
    }
};

pub const MessageBuffers = extern struct {
    header: ?*buf_t = null,
    auth: ?*buf_t = null,
    body: ?*buf_t = null,
};

pub const Header = extern struct {
    version: u16,
    flags: u16,
    msg_type: u16,
    body_length: u32,
    ret_cnt: u16,
    forward: forward_t,
    orig_addr: slurm_addr_t,
    ret_list: ?*List(*opaque {}),

    pub fn fromMessage(msg: slurm_msg_t) Header {
        return .{
            .flags = msg.flags,
            .msg_type = @intFromEnum(msg.msg_type),
            .body_length = 0,
            .forward = msg.forward,
            .ret_list = @ptrCast(msg.ret_list),
            .ret_cnt = 0,
            .orig_addr = msg.orig_addr,
            .version = msg.protocol_version,
        };
    }
};

pub extern fn slurm_free_return_code_msg(msg: *return_code_msg_t) void;
pub extern fn slurm_send_recv_controller_msg(request_msg: *slurm_msg_t, response_msg: *slurm_msg_t, comm_cluster_rec: ?*Cluster) c_int;
pub extern fn slurm_msg_t_init(msg: *slurm_msg_t) void;


pub fn loadStats() Error!*Statistics {
    var data: *Statistics = undefined;
    var req: Statistics.Request = .{ .command_id = .get };

    try err.checkRpc(slurm.c.slurm_get_statistics(&data, &req));
    return data;
}

pub fn reconfigure() Error!void {
    return err.checkRpc(slurm.c.slurm_reconfigure());
}

pub const Ping = struct {
    hostname: [:0]const u8,
    responding: bool,
    latency: u32,
    offset: u8,
    primary: bool,
};
