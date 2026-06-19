const slurm = @import("root.zig");
const std = @import("std");
const time_t = std.posix.time_t;
const common = @import("common.zig");
const db = @import("db.zig");
const List = db.List;

pub const sluid_t = u64;

pub const MEM_PER_CPU = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x8000000000000000, .hex);

pub const Hash = extern struct {
    type: u8 = 0,
    hash: [32]u8 = @import("std").mem.zeroes([32]u8),
};

pub const ShowFlags = packed struct(u16) {
    all: bool = false,
    detail: bool = false,
    mixed: bool = false,
    local: bool = false,
    sibling: bool = false,
    federation: bool = false,
    future: bool = false,
    __padding: u9 = 0,

    pub const full: ShowFlags = .{ .all = true, .detail = true };
};

pub const SelectType = packed struct(u16) {
    cpu: bool = false,
    socket: bool = false,
    core: bool = false,
    board: bool = false,
    memory: bool = false,
    linear: bool = false,
    enforce_binding_gres: bool = false,
    one_task_per_sharing_gres: bool = false,
    one_task_per_core: bool = false,
    pack_nodes: bool = false,
    ll_shared_gres: bool = false,
    _p1: u1 = 0,
    core_default_dist_block: bool = false,
    _p2: u1 = 0,
    lln: bool = false,
    multiple_sharing_gres_pj: bool = false,
};

pub const CPUBinding = packed struct(u16) {
    verbose: bool = false,
    @"type": BindType,
    one_thread_per_core: bool = false,
    _p1: u3 = 0,

    pub const BindType = enum(u12) {
        threads = 2,
        cores = 4,
        sockets = 8,
        ldoms = 16,
        none = 0x0020,
        map = 0x0080,
        mask = 0x0100,
        ldrank = 0x0200,
        ldmap = 0x0400,
        ldmask = 0x0800,
    };
};

pub const TaskPluginParams = packed struct(u32) {
    auto_bind: AutoBinding,
    slurmd_off_spec: bool = false, // 1 << 18
    cpu_bind_off: bool = false,
    oom_kill_spec: bool = false,
    slurmd_spec_override: bool = false,
    _p1: u11 = 0,

    pub const AutoBinding = enum(u18) {
        threads = 0x04000,
        cores = 0x10000,
        sockets = 0x20000,
    };
};

pub const MemoryBinding = packed struct(u16) {
    verbose: bool = false,
    @"type": BindType,
    sort: bool = false,
    prefer: bool = false, // 1 << 7
    _p1: u9 = 0,

    pub const BindType = enum(u6) {
        none,
        rank,
        map,
        mask,
        local,
    };
};

pub const PriorityFlags = packed struct(u16) {
    accrue_always: bool = false,
    max_tres: bool = false,
    size_relative: bool = false,
    depth_oblivious: bool = false,
    calculate_running: bool = false,
    fair_tree: bool = false,
    increase_only: bool = false,
    no_normal: NoNormal,
    max_tres_gres: bool = false,
    _p1: u5 = false,


    pub const NoNormal = packed struct(u4) {
        assoc: bool = false,
        part: bool = false,
        qos: bool = false,
        tres: bool = false,

        pub const all: NoNormal = .{ .assoc = true, .part = true, .qos = true, .tres = true, };
    };
};

pub const PrivateData = packed struct(u16) {
    jobs: bool = false,
    nodes: bool = false,
    partitions: bool = false,
    usage: bool = false,
    users: bool = false,
    accounts: bool = false,
    reservations: bool = false,
    _p1: u1 = 0,
    events: bool = false,
    _p2: u7 = 0,
};

pub const PriorityResetPeriod = enum(u16) {
    none = 0,
    now,
    daily,
    weekly,
    monthly,
    quarterly,
    yearly,
};

pub const JobFlags = packed struct(u64) {
    kill_on_invalid_dependency: bool = false,
    no_kill_on_invalid_dependency: bool = false,
    has_state_dir: bool = false,
    backfill_test_in_progress: bool = false,
    enforce_gres_bind: bool = false,
    test_now_only: bool = false,
    send_environment_to_db: bool = false,
    grace_preempt: bool = false,
    spread: bool = false,
    prefer_min_nodes: bool = false,
    kill_hurry: bool = false,
    sib_job_flush: bool = false,
    is_heterogenous: bool = false,
    ntasks_set: bool = false,
    cpus_set: bool = false,
    backfill_whole_node_test: bool = false,
    top_prio_tmp: bool = false,
    accrue_over: bool = false,
    disable_gres_bind: bool = false,
    was_running: bool = false,
    reset_accrue_time: bool = false,
    is_cron_job: bool = false,
    memory_set: bool = false,
    external: bool = false,
    uses_default_account: bool = false,
    uses_default_partition: bool = false,
    uses_default_qos: bool = false,
    dependent: bool = false,
    magnetic_reservation: bool = false,
    partition_assigned: bool = false,
    backfill_sched: bool = false,
    backfill_last: bool = false,
    tasks_changed: bool = false,
    send_script_to_dbd: bool = false,
    reset_licenses_per_task: bool = false,
    reset_licenses_per_job: bool = false,
    gres_one_task_per_sharing: bool = false,
    gres_multiple_tasks_per_sharing: bool = false,
    gres_allow_task_sharing: bool = false,
    stepmgr_enabled: bool = false,
    purge_heterogenous_job: bool = false,
    spread_segments: bool = false,
    consolidate_segments: bool = false,
    expedited_requeue: bool = false,
};

pub const X11ForwardNode = packed struct(u16) {
    all: bool = false,
    batch: bool = false,
    first: bool = false,
    last: bool = false,
};

pub const ReservationFlags = packed struct(u64) {
    maintenace: bool = false,
    no_maintenance: bool = false,
    daily: bool = false,
    no_daily: bool = false,
    weekly: bool = false,
    no_weekly: bool = false,
    ignore_running_jobs: bool = false,
    no_ignore_running_jobs: bool = false,
    any_nodes: bool = false,
    no_any_nodes: bool = false,
    static: bool = false,
    no_static: bool = false,
    partition_nodes: bool = false,
    no_partition_nodes: bool = false,
    overlap: bool = false,
    specific_nodes: bool = false,
    time_float: bool = false,
    replace: bool = false,
    all_nodes: bool = false,
    purge_after_last_job_done: bool = false,
    weekday: bool = false,
    no_weekday: bool = false,
    weekend: bool = false,
    no_weekend: bool = false,
    flex: bool = false,
    no_flex: bool = false,
    add_duration: bool = false,
    remove_duration: bool = false,
    no_hold_jobs: bool = false,
    replace_down_nodes: bool = false,
    no_purge_after_last_job_done: bool = false,
    magnetic: bool = false,
    no_magnetic: bool = false,
    skip: bool = false,
    hourly: bool = false,
    no_hourly: bool = false,
    gres_required: bool = false,
    allow_user_deletion: bool = false,
    no_allow_user_deletion: bool = false,
    sched_failed: bool = false,
    force_start: bool = false,
};

pub const PreemptMode = packed struct(u16) {
    @"suspend": bool = false,
    requeue: bool = false,
    _p1: u1 = 0,
    cancel: bool = false,
    off: bool = false,
    priority: bool = false,
    within: bool = false,
    gang: bool = false,
    _p2: u8 = 0,

    pub const none: PreemptMode = @bitCast(@as(u16, 0));
};

pub const AccountingGatherEnergy = extern struct {
    ave_watts: u32,
    base_consumed_energy: u64,
    consumed_energy: u64,
    current_watts: u32,
    last_adjustment: u64,
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

pub extern fn slurm_load_node_single(resp: ?**slurm.Node.LoadResponse, node_name: ?common.CStr, show_flags: slurm.ShowFlags) c_int;

pub extern fn slurm_update_node(*slurm.Node.Updatable) c_int;
pub extern fn slurm_delete_node(*slurm.Node.Updatable) c_int;
pub extern fn slurm_free_node_info_msg(node_buffer_ptr: ?*slurm.Node.LoadResponse) void;
pub extern fn slurm_free_node_info_members(node: *slurm.Node) void;

pub extern fn slurm_init_job_desc_msg(job_desc_msg: *slurm.Job.SubmitDescription) void;
pub extern fn slurm_submit_batch_job(job_desc_msg: *slurm.Job.SubmitDescription, slurm_alloc_msg: **slurm.Job.SubmitDescription.Response) c_int;
pub extern fn slurm_free_submit_response_response_msg(msg: ?*slurm.Job.SubmitDescription.Response) void;
pub extern fn slurm_update_job(job_msg: *slurm.Job.SubmitDescription) c_int;
pub extern fn slurm_free_job_info_members(job: *slurm.Job) void;
pub extern fn slurm_free_job_info_msg(job_buffer_ptr: ?*slurm.Job.LoadResponse) void;
pub extern fn slurm_free_partition_info_msg(part_info_ptr: ?*slurm.Partition.LoadResponse) void;

pub extern fn slurm_free_reservation_info_msg(resv_info_ptr: ?*slurm.Reservation.LoadResponse) void;
pub extern fn slurm_create_reservation(resv_msg: ?*slurm.Reservation.Updatable) [*c]u8;
pub extern fn slurm_update_reservation(resv_msg: ?*slurm.Reservation.Updatable) c_int;
pub extern fn slurm_load_reservations(update_time: time_t, resp: ?**slurm.Reservation.LoadResponse) c_int;

pub extern fn slurm_populate_node_partitions(
    node_buffer_ptr: ?*slurm.Node.LoadResponse,
    part_buffer_ptr: ?*slurm.Partition.LoadResponse,
) void;

pub extern fn slurm_load_jobs(
    update_time: time_t,
    job_info_msg_pptr: ?**slurm.Job.LoadResponse,
    show_flags: slurm.ShowFlags,
) c_int;

pub extern fn slurm_load_job(
    resp: ?**slurm.Job.LoadResponse,
    job_id: u32,
    show_flags: slurm.ShowFlags,
) c_int;

pub extern fn slurm_suspend(job_id: u32) c_int;
pub extern fn slurm_resume(job_id: u32) c_int;
pub extern fn slurm_kill_job(job_id: u32, signal: u16, flags: slurm.job.SignalFlags) c_int;

// TODO: Perhaps better handling for the requeue flags.
pub extern fn slurm_requeue(job_id: u32, flags: slurm.Job.State) c_int;

pub extern fn slurm_get_job_steps(
    update_time: time_t,
    job_id: u32,
    step_id: u32,
    step_response_pptr: ?**slurm.Step.LoadResponse,
    show_flags: slurm.ShowFlags,
) c_int;

pub extern fn slurm_free_shares_response_msg(msg: ?*slurm.db.Association.Shares.LoadResponse) void;
pub extern fn slurm_get_statistics(buf: ?**slurm.slurmctld.Statistics, req: *slurm.slurmctld.Statistics.Request) c_int;
pub extern fn slurm_free_stats_response_msg(msg: ?*slurm.slurmctld.Statistics) void;
pub extern fn slurm_reconfigure() c_int;
pub extern fn slurm_shutdown(options: u16) c_int;
pub extern fn slurm_takeover(backup_inx: c_int) c_int;
