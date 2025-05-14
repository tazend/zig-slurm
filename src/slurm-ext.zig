const slurm = @import("root.zig");
const std = @import("std");
const time_t = std.posix.time_t;
const common = @import("common.zig");
const db = @import("db.zig");
const List = db.List;

pub const sluid_t = u64;

pub const MEM_PER_CPU = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x8000000000000000, .hex);

pub const DynamicPluginData = extern struct {
    data: ?*anyopaque,
    plugin_id: u32,
};

pub const AccountingGatherEnergy = extern struct {
    ave_watts: u32,
    base_consumed_energy: u64,
    consumed_energy: u64,
    current_watts: u32,
    previous_consumed_energy: u64,
    poll_time: time_t,
    slurmd_start_time: time_t,
};

pub const TresType = enum(c_int) {
    cpu = 1,
    mem,
    energy,
    node,
    billing,
    fs_disk,
    vmem,
    pages,
    static_count,
};

pub extern fn slurm_init(conf: ?common.CStr) void;
pub extern fn slurm_fini() void;

pub extern fn slurm_load_partitions(
    update_time: time_t,
    part_buffer_ptr: ?**slurm.Partition.LoadResponse,
    show_flags: slurm.ShowFlags,
) c_int;

pub extern fn slurm_load_node(
    update_time: time_t,
    resp: ?**slurm.Node.LoadResponse,
    show_flags: slurm.ShowFlags,
) c_int;

pub extern fn slurm_update_node(*slurm.Node.Updatable) c_int;
pub extern fn slurm_delete_node(*slurm.Node.Updatable) c_int;

pub extern fn slurm_get_select_nodeinfo(
    nodeinfo: ?*DynamicPluginData,
    data_type: slurm.Node.SelectDataType,
    state: slurm.Node.State,
    data: ?*anyopaque,
) c_int;

pub extern fn slurm_populate_node_partitions(
    node_buffer_ptr: ?*slurm.Node.LoadResponse,
    part_buffer_ptr: ?*slurm.Partition.LoadResponse,
) void;

pub extern fn slurm_load_jobs(
    update_time: time_t,
    job_info_msg_pptr: ?**slurm.Job.LoadResponse,
    show_flags: slurm.ShowFlags,
) c_int;

extern fn slurm_load_job(
    resp: ?**slurm.Job.LoadResponse,
    job_id: u32,
    show_flags: slurm.ShowFlags,
) c_int;

pub extern fn slurm_suspend(job_id: u32) c_int;
pub extern fn slurm_resume(job_id: u32) c_int;
pub extern fn slurm_kill_job(job_id: u32, signal: u16, flags: u16) c_int;

// TODO: Perhaps better handling for the requeue flags.
pub extern fn slurm_requeue(job_id: u32, flags: slurm.Job.State) c_int;

pub extern fn slurm_get_job_steps(
    update_time: time_t,
    job_id: u32,
    step_id: u32,
    step_response_pptr: ?**slurm.Step.LoadResponse,
    show_flags: slurm.ShowFlags,
) c_int;
