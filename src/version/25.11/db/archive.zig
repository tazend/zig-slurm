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
        purge_event: PurgeFlags,
        purge_job: PurgeFlags,
        purge_resv: PurgeFlags,
        purge_step: PurgeFlags,
        purge_suspend: PurgeFlags,
        purge_txn: PurgeFlags,
        purge_usage: PurgeFlags,
    };

    pub const PurgeAfter = enum(u19) {
        none = 0,
        hours = 1 << 16,
        days = 1 << 17,
        months = 1 << 18,
    };

    pub const PurgeFlags = packed struct(u32) {
        time: PurgeAfter = .none,
        archive: bool = false,
        _pad: u12 = 0,
    };
};
