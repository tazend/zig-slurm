const std = @import("std");
const db = @import("../db.zig");
const common = @import("../common.zig");
const CStr = common.CStr;
const Connection = db.Connection;

pub const Archive = extern struct {
    archive_file: ?CStr = null,
    insert: ?CStr = null,

    pub const Filter = extern struct {
        archive_dir: ?CStr = null,
        archive_script: ?CStr = null,
        job_cond: ?*db.Job.Filter = null,
        purge_event: u32,
        purge_job: u32,
        purge_resv: u32,
        purge_step: u32,
        purge_suspend: u32,
        purge_txn: u32,
        purge_usage: u32,
    };
};
