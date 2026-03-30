const std = @import("std");
const err = @import("../error.zig");
const SlurmError = err.Error;
const time_t = std.os.linux.time_t;
const slurm_allocator = @import("../SlurmAllocator.zig").slurm_allocator;
const common = @import("../common.zig");
const NoValue = common.NoValue;
const Infinite = common.Infinite;
const CStr = common.CStr;
const BitString = common.BitString;
const cdef = @import("../slurm-ext.zig");
const db = @import("../db.zig");
const slurm = @import("../root.zig");
const Allocator = std.mem.Allocator;
const c = slurm.c;
const max_path_bytes = std.fs.max_path_bytes;

const AUTH_NOBODY: u32 = 99;

pub const JobSubmitDescription = extern struct {
    account: ?CStr = null,
    acctg_freq: ?CStr = null,
    admin_comment: ?CStr = null,
    alloc_node: ?CStr = null,
    alloc_resp_port: u16 = 0,
    alloc_tls_cert: ?CStr = null,
    alloc_sid: u32 = NoValue.u32,
    argc: u32 = 0,
    argv: ?*CStr = null,
    array_inx: ?CStr = null,
    array_bitmap: ?[*]BitString = null,
    batch_features: ?CStr = null,
    begin_time: time_t = 0,
    bitflags: u64 = 0,
    burst_buffer: ?CStr = null,
    clusters: ?CStr = null,
    cluster_features: ?CStr = null,
    comment: ?CStr = null,
    contiguous: u16 = NoValue.u16,
    container: ?CStr = null,
    container_id: ?CStr = null,
    core_spec: u16 = NoValue.u16,
    cpu_bind: ?CStr = null,
    cpu_bind_type: u16 = NoValue.u16,
    cpu_freq_min: u32 = NoValue.u16,
    cpu_freq_max: u32 = NoValue.u32,
    cpu_freq_gov: u32 = NoValue.u32,
    cpus_per_tres: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    crontab_entry: ?*anyopaque = null,
    deadline: time_t = @import("std").mem.zeroes(time_t),
    delay_boot: u32 = NoValue.u32,
    dependency: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    end_time: time_t = @import("std").mem.zeroes(time_t),
    environment: ?[*:null]?[*:0]u8 = null,
    env_hash: c.Hash = .{},
    env_size: u32 = @import("std").mem.zeroes(u32),
    exc_nodes: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    extra: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    features: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    fed_siblings_active: u64 = @import("std").mem.zeroes(u64),
    fed_siblings_viable: u64 = @import("std").mem.zeroes(u64),
    group_id: u32 = AUTH_NOBODY,
    het_job_offset: u32 = @import("std").mem.zeroes(u32),
    id: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    immediate: u16 = @import("std").mem.zeroes(u16),
    job_id_str: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    job_size_str: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    kill_on_node_fail: u16 = NoValue.u16,
    licenses: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    licenses_tot: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    mail_type: u16 = NoValue.u16,
    mail_user: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    mcs_label: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    mem_bind: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    mem_bind_type: u16 = NoValue.u16,
    mem_per_tres: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    name: ?CStr = null,
    network: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    nice: u32 = NoValue.u32,
    num_tasks: u32 = @import("std").mem.zeroes(u32),
    oom_kill_step: u16 = @import("std").mem.zeroes(u16),
    open_mode: u8 = @import("std").mem.zeroes(u8),
    origin_cluster: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    other_port: u16 = @import("std").mem.zeroes(u16),
    overcommit: u8 = @import("std").mem.zeroes(u8),
    partition: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    plane_size: u16 = @import("std").mem.zeroes(u16),
    prefer: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    priority: u32 = @import("std").mem.zeroes(u32),
    profile: u32 = @import("std").mem.zeroes(u32),
    qos: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    reboot: u16 = @import("std").mem.zeroes(u16),
    resp_host: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    restart_cnt: u16 = @import("std").mem.zeroes(u16),
    req_nodes: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    requeue: u16 = @import("std").mem.zeroes(u16),
    reservation: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    resv_port_cnt: u16 = @import("std").mem.zeroes(u16),
    script: ?CStr = null,
    script_buf: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    script_hash: c.Hash = .{},
    shared: u16 = @import("std").mem.zeroes(u16),
    site_factor: u32 = @import("std").mem.zeroes(u32),
    spank_job_env: [*c][*c]u8 = @import("std").mem.zeroes([*c][*c]u8),
    spank_job_env_size: u32 = @import("std").mem.zeroes(u32),
    step_id: slurm.Step.ID = .{},
    submit_line: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    task_dist: u32 = @import("std").mem.zeroes(u32),
    time_limit: u32 = @import("std").mem.zeroes(u32),
    time_min: u32 = @import("std").mem.zeroes(u32),
    tres_bind: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    tres_freq: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    tres_per_job: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    tres_per_node: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    tres_per_socket: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    tres_per_task: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    user_id: u32 = @import("std").mem.zeroes(u32),
    wait_all_nodes: u16 = @import("std").mem.zeroes(u16),
    warn_flags: u16 = @import("std").mem.zeroes(u16),
    warn_signal: u16 = @import("std").mem.zeroes(u16),
    warn_time: u16 = @import("std").mem.zeroes(u16),
    work_dir: ?CStr = null,
    cpus_per_task: u16 = NoValue.u16,
    min_cpus: u32 = NoValue.u32,
    max_cpus: u32 = NoValue.u32,
    min_nodes: u32 = NoValue.u32,
    max_nodes: u32 = NoValue.u32,
    boards_per_node: u16 = @import("std").mem.zeroes(u16),
    sockets_per_board: u16 = @import("std").mem.zeroes(u16),
    sockets_per_node: u16 = @import("std").mem.zeroes(u16),
    cores_per_socket: u16 = NoValue.u16,
    threads_per_core: u16 = @import("std").mem.zeroes(u16),
    ntasks_per_node: u16 = NoValue.u16,
    ntasks_per_socket: u16 = @import("std").mem.zeroes(u16),
    ntasks_per_core: u16 = @import("std").mem.zeroes(u16),
    ntasks_per_board: u16 = @import("std").mem.zeroes(u16),
    ntasks_per_tres: u16 = @import("std").mem.zeroes(u16),
    pn_min_cpus: u16 = @import("std").mem.zeroes(u16),
    pn_min_memory: u64 = @import("std").mem.zeroes(u64),
    pn_min_tmp_disk: u32 = @import("std").mem.zeroes(u32),
    req_context: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    req_switch: u32 = @import("std").mem.zeroes(u32),
    segment_size: u16 = @import("std").mem.zeroes(u16),
    selinux_context: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    std_err: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    std_in: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    std_out: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    tres_req_cnt: [*c]u64 = @import("std").mem.zeroes([*c]u64),
    wait4switch: u32 = @import("std").mem.zeroes(u32),
    wckey: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    x11: u16 = @import("std").mem.zeroes(u16),
    x11_magic_cookie: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    x11_target: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    x11_target_port: u16 = @import("std").mem.zeroes(u16),

    pub const Response = extern struct {
        step_id: slurm.Step.ID,
        error_code: u32,
        job_submit_user_msg: ?CStr = null,

        pub fn deinit(self: *Response) void {
            c.slurm_free_submit_response_response_msg(self);
        }
    };

    pub fn initDefault(allocator: std.mem.Allocator) !JobSubmitDescription {
        var job: JobSubmitDescription= .{};
        c.slurm_init_job_desc_msg(&job);

        var buf: [max_path_bytes:0]u8 = undefined;
        const cwd = try std.process.getCwd(&buf);

        job.work_dir = try allocator.dupeZ(u8, cwd);

        var env_count: u32 = 0;
        while (std.c.environ[env_count] != null) : (env_count += 1) {}
        const envp = std.c.environ[0..env_count :null];

        job.environment = envp;
        job.env_size = env_count;

        return job;
    }

    pub fn submit(self: *JobSubmitDescription) SlurmError!slurm.job.JobId {
        var resp: *JobSubmitDescription.Response = undefined;
        defer resp.deinit();

        try err.checkRpc(c.slurm_submit_batch_job(self, &resp));
        return resp.step_id.job_id;
    }
};
