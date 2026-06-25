const std = @import("std");
const time_t = std.posix.time_t;
const slurm = @import("root.zig");

pub const BurstBuffer = extern struct {
    allow_users: ?CStr = null,
    default_pool: ?CStr = null,
    create_buffer: ?CStr = null,
    deny_users: ?CStr = null,
    destroy_buffer: ?CStr = null,
    flags: u32 = 0,
    get_sys_state: ?CStr = null,
    get_sys_status: ?CStr = null,
    granularity: u64 = 0,
    pool_cnt: u32 = 0,
    pool_ptr: ?*BurstBuffer.Pool = null,
    name: ?CStr = null,
    poll_interval: u32 = 0,
    other_timeout: u32 = 0,
    stage_in_timeout: u32 = 0,
    stage_out_timeout: u32 = 0,
    start_stage_in: ?CStr = null,
    start_stage_out: ?CStr = null,
    stop_stage_in: ?CStr = null,
    stop_stage_out: ?CStr = null,
    total_space: u64 = 0,
    unfree_space: u64 = 0,
    used_space: u64 = 0,
    validate_timeout: u32 = 0,
    buffer_count: u32 = 0,
    burst_buffer_resv_ptr: ?*BurstBuffer.Reservation = null,
    use_count: u32 = 0,
    burst_buffer_use_ptr: ?*BurstBuffer.Use = null,

    pub const LoadResponse = extern struct {
        items: ?[*]BurstBuffer = null,
        count: u32 = 0,
    };

    pub const Pool = extern struct {
        granularity: u64 = 0,
        name: ?CStr = null,
        total_space: u64 = 0,
        used_space: u64 = 0,
        unfree_space: u64 = 0,
    };

    pub const Use = extern struct {
        user_id: u32 = 0,
        used: u64 = 0,
    };

    pub const Reservation = extern struct {
        account: ?CStr = null,
        array_job_id: u32 = 0,
        array_task_id: u32 = 0,
        create_time: time_t = 0,
        job_id: u32 = 0,
        name: ?CStr = null,
        partition: ?CStr = null,
        pool: ?CStr = null,
        qos: ?CStr = null,
        size: u64 = 0,
        state: u16 = 0,
        user_id: u32 = 0,
    };
};
