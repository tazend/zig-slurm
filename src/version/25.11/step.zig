const common = @import("common.zig");
const slurm = @import("root.zig");
const std = @import("std");
const err = slurm.err;
const SlurmError = err.Error;
const time_t = std.os.linux.time_t;
const slurm_allocator = slurm.slurm_allocator;
const NoValue = common.NoValue;
const Infinite = common.Infinite;
const CStr = common.CStr;
const BitString = common.BitString;
const db = slurm.db;
const List = slurm.List;
const Job = slurm.Job;
const Allocator = std.mem.Allocator;
const c = slurm.c;

pub const stat = @import("stat.zig").statStep;

pub const Step = extern struct {
    array_job_id: u32 = 0,
    array_task_id: u32 = 0,
    cluster: ?CStr = null,
    container: ?CStr = null,
    container_id: ?CStr = null,
    cpu_freq_min: u32 = 0,
    cpu_freq_max: u32 = 0,
    cpu_freq_gov: u32 = 0,
    cpus_per_tres: ?CStr = null,
    cwd: ?CStr = null,
    mem_per_tres: ?CStr = null,
    name: ?CStr = null,
    job_name: ?CStr = null,
    network: ?CStr = null,
    nodes: ?CStr = null,
    node_inx: ?[*]i32 = null,
    num_cpus: u32 = 0,
    num_tasks: u32 = 0,
    partition: ?CStr = null,
    resv_ports: ?CStr = null,
    run_time: time_t = 0,
    srun_host: ?CStr = null,
    srun_pid: u32 = 0,
    start_time: time_t = 0,
    start_protocol_ver: u16 = 0,
    state: Job.State,
    step_id: Step.ID = .{},
    std_err: ?CStr = null,
    std_in: ?CStr = null,
    std_out: ?CStr = null,
    submit_line: ?CStr = null,
    task_dist: slurm.TaskDistribution,
    time_limit: u32 = 0,
    tres_bind: ?CStr = null,
    tres_fmt_alloc_str: ?CStr = null,
    tres_freq: ?CStr = null,
    tres_per_step: ?CStr = null,
    tres_per_node: ?CStr = null,
    tres_per_socket: ?CStr = null,
    tres_per_task: ?CStr = null,
    user_id: u32 = 0,

    pub const ID = extern struct {
        sluid: slurm.SluID = 0,
        job_id: u32 = NoValue.u32,
        step_het_comp: u32 = NoValue.u32,
        step_id: u32 = NoValue.u32,

        pub fn parseSluid(self: Step.ID, buf: *[15:0]u8) []const u8 {
            c.print_sluid(self.sluid, buf, buf.len);
            return buf[0..14];
        }

        pub fn toStr(self: Step.ID, allocator: Allocator) ![:0]const u8 {
            var buf: [128]u8 = undefined;
            const s = try self.toStrBuf(&buf);
            return allocator.dupeZ(u8, s);
        }

        pub fn toStrBuf(self: Step.ID, buf: []u8) ![:0]const u8 {
            const id = self.step_id;
            return switch (id) {
                PENDING => "pending",
                BATCH => "batch",
                EXTERN => "extern",
                INTERACTIVE => "interactive",
                else => std.fmt.bufPrintZ(buf, "{d}", .{id}),
            };
        }
    };

    pub const Updatable = extern struct {
        step_id: Step.ID = .{},
        time_limit: u32 = 0,
    };

    pub const LoadResponse = extern struct {
        last_update: time_t,
        count: u32,
        items: ?[*]Step = null,
        stepmgr_jobs: ?*List(*anyopaque),

        extern fn slurm_free_job_step_info_response_msg(msg: ?*LoadResponse) void;
        pub fn deinit(self: *LoadResponse) void {
            slurm_free_job_step_info_response_msg(self);
        }

        pub const Iterator = struct {
            data: *LoadResponse,
            count: usize,

            pub fn next(self: *Iterator) ?*Step {
                const id = self.count;
                defer self.count += 1;
                return self.data.get_step_by_index(id);
            }

            pub fn reset(self: *Iterator) void {
                self.count = 0;
            }
        };

        pub fn get_step_by_index(self: *LoadResponse, idx: usize) ?*Step {
            if (idx >= self.count) return null;
            return &self.items.?[idx];
        }

        pub fn iter(self: *LoadResponse) Iterator {
            return Iterator{
                .data = self,
                .count = 0,
            };
        }

        //      pub fn stat(self: *LoadResponse, allocator: Allocator) ![]Step.StatResponse {
        //          var step_iter = self.iter();
        //          var out = try std.ArrayList(Step.StatResponse).initCapacity(
        //              allocator,
        //              self.count,
        //          );
        //          while (step_iter.next()) |step| {
        //              var stat_item: Step.StatResponse = .{
        //                  .job_id = step.step_id.job_id,
        //                  .step_id = step.step_id.step_id,
        //              };

        //              stat_item.stats = try statStep(allocator, step);

        //              out.appendAssumeCapacity(stat_item);
        //          }

        //          return out.toOwnedSlice();
        //      }
    };

    pub const StatResponse = struct {
        job_id: u32,
        step_id: u32,
        stats: slurm.StepStatistics,
    };

    pub const INTERACTIVE = 0xfffffffa;
    pub const BATCH = 0xfffffffb;
    pub const EXTERN = 0xfffffffc;
    pub const PENDING = 0xfffffffd;

    pub const Statistics = struct {
        consumed_energy: u64 = 0,
        elapsed_cpu_time: u64 = 0,
        avg_cpu_time: u64 = 0,
        avg_cpu_frequency: u64 = 0,
        avg_disk_read: u64 = 0,
        avg_disk_write: u64 = 0,
        avg_page_faults: u64 = 0,
        avg_resident_memory: u64 = 0,
        avg_virtual_memory: u64 = 0,
        max_disk_read: u64 = 0,
        max_disk_read_node: ?[:0]const u8 = null,
        max_disk_read_task: u64 = 0,
        max_disk_write: u64 = 0,
        max_disk_write_node: ?[:0]const u8 = null,
        max_disk_write_task: u64 = 0,
        max_page_faults: u64 = 0,
        max_page_faults_node: ?[:0]const u8 = null,
        max_page_faults_task: u64 = 0,
        max_resident_memory: u64 = 0,
        max_resident_memory_node: ?[:0]const u8 = null,
        max_resident_memory_task: u64 = 0,
        max_virtual_memory: u64 = 0,
        max_virtual_memory_node: ?[:0]const u8 = null,
        max_virtual_memory_task: u64 = 0,
        min_cpu_time: u64 = 0,
        min_cpu_time_node: ?[:0]const u8 = null,
        min_cpu_time_task: u64 = 0,
        total_cpu_time: u64 = 0,
        user_cpu_time: u64 = 0,
        system_cpu_time: u64 = 0,
    };

    pub fn getStdioPath(self: *Step, path: ?CStr, buf: []u8) !?[]const u8 {
        return if (c.slurm_expand_step_stdio_fields(path, self)) |p|
            try std.fmt.bufPrint(buf, "{s}", .{std.mem.span(p)})
        else
            null;
    }

    pub fn stdout(self: *Step, allocator: std.mem.Allocator) ![]const u8 {
        var buf: [std.c.PATH_MAX]u8 = undefined;
        const path = try self.stdoutBuf(&buf);
        return allocator.dupe(u8, path);
    }

    pub fn stdoutBuf(self: *Step, buf: []u8) !?[]const u8 {
        return self.getStdioPath(self.std_out, buf);
    }

    pub fn stderr(self: *Step, allocator: std.mem.Allocator) ![]const u8 {
        var buf: [std.c.PATH_MAX]u8 = undefined;
        const path = try self.stderrBuf(&buf);
        return allocator.dupe(u8, path);
    }

    pub fn stderrBuf(self: *Step, buf: []u8) !?[]const u8 {
        return self.getStdioPath(self.std_err, buf);
    }

    pub fn stdin(self: *Step, allocator: std.mem.Allocator) ![]const u8 {
        var buf: [std.c.PATH_MAX]u8 = undefined;
        const path = try self.stdinBuf(&buf);
        return allocator.dupe(u8, path);
    }

    pub fn stdinBuf(self: *Step, buf: []u8) !?[]const u8 {
        return self.getStdioPath(self.std_in, buf);
    }

};

fn _load(job_id: ?u32) SlurmError!*Step.LoadResponse {
    var resp: ?*Step.LoadResponse = null;
    const flags: slurm.ShowFlags = .full;
    var step_id: ?Step.ID = if (job_id) |ji|
        .{ .job_id = ji }
    else
        null;

    try err.checkRpc(c.slurm_get_job_steps(
        if (step_id) |*id| id else null,
        &resp,
        flags,
    ));
    return if (resp) |r|
        r
    else
        error.Generic;
}

pub fn loadForJob(job_id: u32) SlurmError!*Step.LoadResponse {
    return try _load(job_id);
}

pub fn load() SlurmError!*Step.LoadResponse {
    return try _load(null);
}
