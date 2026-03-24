const std = @import("std");
const db = @import("db.zig");
const memzero = std.mem.zeroes;
const time_t = @import("std").posix.time_t;
const List = db.List;
const Cluster = db.Cluster;
pub const err = @import("error.zig");
pub const Error = err.Error;

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
};

pub const return_code_msg_t = extern struct {
    return_code: u32 = 0,
};

pub const job_id_msg_t = extern struct {
    job_id: u32 = 0,
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
    // conn_is_mtls: bool = memzero(bool), // This is since 25.11.3
    msg_type: slurm_msg_type_t = memzero(slurm_msg_type_t),
    protocol_version: u16 = memzero(u16),
    forward: forward_t = memzero(forward_t),
    forward_struct: ?*forward_struct_t = null,
    orig_addr: slurm_addr_t = memzero(slurm_addr_t),
    ret_list: ?*List(*opaque {}) = null,
};

pub extern fn slurm_free_return_code_msg(msg: *return_code_msg_t) void;
pub extern fn slurm_send_recv_controller_msg(request_msg: *slurm_msg_t, response_msg: *slurm_msg_t, comm_cluster_rec: ?*Cluster) c_int;
pub extern fn slurm_msg_t_init(msg: *slurm_msg_t) void;


pub const Statistics = extern struct {
    req_time: time_t = 0,
    req_time_start: time_t = 0,
    server_thread_count: u32 = 0,
    agent_queue_size: u32 = 0,
    agent_count: u32 = 0,
    agent_thread_count: u32 = 0,
    dbd_agent_queue_size: u32 = 0,
    gettimeofday_latency: u32 = 0,
    schedule_cycle_max: u32 = 0,
    schedule_cycle_last: u32 = 0,
    schedule_cycle_sum: u64 = 0,
    schedule_cycle_counter: u32 = 0,
    schedule_cycle_depth: u32 = 0,
    schedule_exit: ?[*]u32 = null,
    schedule_exit_cnt: u32 = 0,
    schedule_queue_len: u32 = 0,
    jobs_submitted: u32 = 0,
    jobs_started: u32 = 0,
    jobs_completed: u32 = 0,
    jobs_canceled: u32 = 0,
    jobs_failed: u32 = 0,
    jobs_pending: u32 = 0,
    jobs_running: u32 = 0,
    job_states_ts: time_t = 0,
    bf_backfilled_jobs: u32 = 0,
    bf_last_backfilled_jobs: u32 = 0,
    bf_backfilled_het_jobs: u32 = 0,
    bf_cycle_counter: u32 = 0,
    bf_cycle_sum: u64 = 0,
    bf_cycle_last: u32 = 0,
    bf_cycle_max: u32 = 0,
    bf_exit: ?[*]u32 = null,
    bf_exit_cnt: u32 = 0,
    bf_last_depth: u32 = 0,
    bf_last_depth_try: u32 = 0,
    bf_depth_sum: u32 = 0,
    bf_depth_try_sum: u32 = 0,
    bf_queue_len: u32 = 0,
    bf_queue_len_sum: u32 = 0,
    bf_table_size: u32 = 0,
    bf_table_size_sum: u32 = 0,
    bf_when_last_cycle: time_t = 0,
    bf_active: u32 = 0,
    rpc_type_size: u32 = 0,
    rpc_type_id: ?[*]u16 = null,
    rpc_type_cnt: ?[*]u32 = null,
    rpc_type_time: ?[*]u64 = null,
    rpc_queue_enabled: u8 = 0,
    rpc_type_queued: ?[*]u16 = null,
    rpc_type_dropped: ?[*]u64 = null,
    rpc_type_cycle_last: ?[*]u16 = null,
    rpc_type_cycle_max: ?[*]u16 = null,
    rpc_user_size: u32 = 0,
    rpc_user_id: ?[*]u32 = null,
    rpc_user_cnt: ?[*]u32 = null,
    rpc_user_time: ?[*]u64 = null,
    rpc_queue_type_count: u32 = 0,
    rpc_queue_type_id: ?[*]u32 = null,
    rpc_queue_count: ?[*]u32 = null,
    rpc_dump_count: u32 = 0,
    rpc_dump_types: ?[*]u32 = null,
    rpc_dump_hostlist: ?[*][*]u8 = null,

    pub const Request = extern struct {
        command_id: Request.Type,

        pub const Type = enum(u16) {
            reset = 0,
            get = 1,
        };
    };

    pub fn bfMeanTableSize(self: *Statistics) u32 {
        return if (self.bf_cycle_counter > 0)
            self.bf_table_size_sum / self.bf_cycle_counter
        else
            0;
    }

    pub fn bfMeanQueueLength(self: *Statistics) u32 {
        return if (self.bf_cycle_counter > 0)
            self.bf_queue_len_sum / self.bf_cycle_counter
        else
            0;
    }

    pub fn bfCycleMeanDepthTry(self: *Statistics) u32 {
        return if (self.bf_cycle_counter > 0)
            self.bf_depth_try_sum / self.bf_cycle_counter
        else
            0;
    }

    pub fn bfCycleMeanDepth(self: *Statistics) u32 {
        return if (self.bf_cycle_counter > 0)
            self.bf_depth_sum / self.bf_cycle_counter
        else
            0;
    }

    pub fn bfCycleMean(self: *Statistics) u64 {
        return if (self.bf_cycle_counter > 0)
            self.bf_cycle_sum / self.bf_cycle_counter
        else
            0;
    }

    pub fn cyclesPerMinute(self: *Statistics) isize {
        const ts = self.req_time - self.req_time_start;
        return if (ts > 60)
            return @divTrunc(self.schedule_cycle_counter, @divTrunc(ts, 60))
        else
            0;
    }

    pub fn meanCycle(self: *Statistics) u64 {
        return if (self.schedule_cycle_counter > 0)
            return self.schedule_cycle_sum / self.schedule_cycle_counter
        else
            0;
    }

    pub fn meanDepthCycle(self: *Statistics) u32 {
        return if (self.schedule_cycle_counter > 0)
            self.schedule_cycle_depth / self.schedule_cycle_counter
        else
            0;
    }
};

pub extern fn slurm_get_statistics(buf: ?**Statistics, req: *Statistics.Request) c_int;
pub fn loadStats() Error!*Statistics {
    var data: *Statistics = undefined;
    var req: Statistics.Request = .{ .command_id = .get };

    try err.checkRpc(slurm_get_statistics(&data, &req));
    return data;
}
