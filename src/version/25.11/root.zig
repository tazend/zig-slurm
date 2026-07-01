const std = @import("std");
const config = @import("config");

const Allocator = std.mem.Allocator;
const SlurmAllocator = @import("SlurmAllocator.zig");
const builtin = std.builtin;

pub const c = @import("c.zig");
pub const tres = @import("tres.zig");
pub const gres = @import("gres.zig");
pub const common = @import("common.zig");
pub const err = @import("error.zig");

pub const slurmctld = @import("slurmctld.zig");
pub const job = @import("job.zig");
pub const node = @import("node.zig");
pub const step = @import("step.zig");
pub const partition = @import("partition.zig");
pub const reservation = @import("reservation.zig");
pub const db = @import("db.zig");

pub const Job = job.Job;
pub const JobSubmitDescription = Job.SubmitDescription;
pub const Step = step.Step;
pub const Node = node.Node;
pub const Partition = partition.Partition;
pub const Reservation = reservation.Reservation;

pub const List = db.List;

pub const parseCStr = common.parseCStr;
pub const parseCStrZ = common.parseCStrZ;
pub const CStr = common.CStr;
pub const Error = err.Error;
const time_t = std.os.linux.time_t;

pub const api_version = config.slurm_version;
pub const slurm_allocator = SlurmAllocator.slurm_allocator;

pub const init = c.slurm_init;
pub const deinit = c.slurm_fini;

test {
    std.testing.refAllDecls(@This());
}

pub const SluID = u64;

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
    @"type": BindType = .unknown,
    one_thread_per_core: bool = false,
    _p1: u2 = 0,

    pub const BindType = enum(u12) {
        unknown = 0,
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
    _p1: u10 = 0,

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
    _p1: u7 = 0,

    pub const BindType = enum(u6) {
        none = 0x02,
        rank = 0x04,
        map = 0x08,
        mask = 0x10,
        local = 0x20,
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
    _p1: u4 = 0,


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
    _p: u20 = 0,
};

pub const PartitionFlags = packed struct(u32) {
    default: bool = false,
    hidden: bool = false,
    disable_root_jobs: bool = false,
    root_only: bool = false,
    reservation_required: bool = false,
    lln: bool = false,
    exclusive_user: bool = false,
    power_down_or_idle: bool = false,

    default_clear: bool = false,
    hidden_clear: bool = false,
    disable_root_jobs_clear: bool = false,
    root_only_clear: bool = false,
    reservation_required_clear: bool = false,
    lln_clear: bool = false,
    exclusive_user_clear: bool = false,
    power_down_or_idle_clear: bool = false,

    exclusive_topology: bool = false,
    exclusive_topology_clear: bool = false,
    sched_failed: bool = false,
    sched_cleared: bool = false,
    _p: u12 = 0,
};

pub const X11ForwardNode = packed struct(u16) {
    all: bool = false,
    batch: bool = false,
    first: bool = false,
    last: bool = false,
    _p: u12 = 0,
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
    _p: u23 = 0,

    pub const no_value: ReservationFlags = @bitCast(@as(u64, common.NoValue.u64));
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

    pub const none: PreemptMode = @bitCast(@as(u16, common.NoValue.u16));
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

pub const StepCtx = opaque {};

pub const DBJobFlags = packed struct(u32) {
    scheduler: SchedulerType = .unknown,
    start_rpc: bool = false,
    altered: bool = false,
    _p: u26 = 0,

    pub const none: DBJobFlags = @bitCast(@as(u32, 0));
};

pub const SchedulerType = enum(u4) {
    unknown = 1,
    submit = 2,
    main = 4,
    backfill = 8,
};

pub const TaskDistribution = packed struct(u32) {
    state: TaskDistribution.State,
    _p1: u5 = 0,
    // Bit 22
    no_pack_nodes: bool = false,
    pack_nodes: bool = false,
    _p2: u9 = 0,

    pub const State = enum(u16) {
        cyclic = 1,
        block = 2,
        arbitrary = 3,
        plane = 4,
        cyclic_cyclic = 17,
        cyclic_block = 33,
        cyclic_cfull = 49,
        block_cyclic = 18,
        block_block = 34,
        block_cfull = 50,
        cyclic_cyclic_cyclic = 273,
        cyclic_cyclic_block = 529,
        cyclic_cyclic_cfull = 785,
        cyclic_block_cyclic = 289,
        cyclic_block_block = 545,
        cyclic_block_cfull = 801,
        cyclic_cfull_cyclic = 305,
        cyclic_cfull_block = 561,
        cyclic_cfull_cfull = 817,
        block_cyclic_cyclic = 274,
        block_cyclic_block = 530,
        block_cyclic_cfull = 786,
        block_block_cyclic = 290,
        block_block_block = 546,
        block_block_cfull = 802,
        block_cfull_cyclic = 306,
        block_cfull_block = 562,
        block_cfull_cfull = 818,
        unknown = 8192,
    };
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
