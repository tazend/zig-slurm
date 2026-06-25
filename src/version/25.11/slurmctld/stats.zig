const std = @import("std");
const time_t = std.posix.time_t;
const slurm = @import("../root.zig");
const CStr = slurm.common.CStr;

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
    rpc_dump_hostlist: ?[*]?CStr = null,

    pub const Request = extern struct {
        command_id: Request.Type,

        pub const Type = enum(u16) {
            reset = 0,
            get = 1,
        };
    };

    pub fn deinit(self: *Statistics) void {
        slurm.c.slurm_free_stats_response_msg(self);
    }

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
