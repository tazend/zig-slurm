const c = @import("../c.zig").c;
const common = @import("../common.zig");
const slurm = @import("../root.zig");
const cx = @import("../c.zig");
const std = @import("std");
const err = slurm.err;
const SlurmError = err.Error;
const time_t = std.os.linux.time_t;
const slurm_allocator = slurm.slurm_allocator;
const NoValue = common.NoValue;
const Infinite = common.Infinite;
const CStr = common.CStr;
const BitString = common.BitString;
const cdef = @import("../slurm-ext.zig");
const db = slurm.db;
const Allocator = std.mem.Allocator;

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
    mem_per_tres: ?CStr = null,
    name: ?CStr = null,
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
    state: u32 = 0, //TODO
    step_id: ID = .{},
    submit_line: ?CStr = null,
    task_dist: u32 = 0, // TODO
    time_limit: u32 = 0,
    tres_alloc_str: ?CStr = null,
    tres_bind: ?CStr = null,
    tres_freq: ?CStr = null,
    tres_per_step: ?CStr = null,
    tres_per_node: ?CStr = null,
    tres_per_socket: ?CStr = null,
    tres_per_task: ?CStr = null,
    user_id: u32 = 0,

    pub const INTERACTIVE = 0xfffffffa;
    pub const BATCH = 0xfffffffb;
    pub const EXTERN = 0xfffffffc;
    pub const PENDING = 0xfffffffd;

    pub fn idToString(self: *Step, allocator: Allocator) ![:0]const u8 {
        const id = self.step_id.step_id;
        return switch (id) {
            PENDING => "pending",
            BATCH => "batch",
            EXTERN => "extern",
            INTERACTIVE => "interactive",
            else => std.fmt.allocPrintZ(allocator, "{d}", .{id}),
        };
    }

    pub const ID = extern struct {
        sluid: cdef.sluid_t = 0,
        job_id: u32 = 0,
        step_het_comp: u32 = 0,
        step_id: u32 = 0,
    };

    pub const StatResponse = struct {
        job_id: u32,
        step_id: u32,
        stats: slurm.StepStatistics,
    };

    pub const LoadResponse = extern struct {
        last_update: time_t,
        count: u32,
        items: ?[*]Step = null,
        stepmgr_jobs: ?*db.List(*opaque {}),

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
};

fn _load(job_id: ?u32) SlurmError!*Step.LoadResponse {
    var data: *Step.LoadResponse = undefined;
    const flags: slurm.ShowFlags = .full;
    const job_or_all = if (job_id) |ji| ji else common.NoValue.u32;

    try err.checkRpc(cdef.slurm_get_job_steps(
        0,
        job_or_all,
        common.NoValue.u32,
        &data,
        flags,
    ));
    return data;
}

pub fn loadForJob(job_id: u32) SlurmError!*Step.LoadResponse {
    return try _load(job_id);
}

pub fn loadAll() SlurmError!*Step.LoadResponse {
    return try _load(null);
}
