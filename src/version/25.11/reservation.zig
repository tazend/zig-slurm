const std = @import("std");
const SlurmError = @import("error.zig").Error;
const checkRpc = @import("error.zig").checkRpc;
const slurm = @import("root.zig");
const common = @import("common.zig");
const time_t = std.posix.time_t;
const List = @import("db.zig").List;
const NoValue = common.NoValue;
const Infinite = common.Infinite;
const CStr = common.CStr;
const BitString = common.BitString;
const err = slurm.err;
const Error = slurm.err.Error;
const c = slurm.c;

pub const Reservation = extern struct {
    accounts: ?CStr = null,
    allowed_parts: ?CStr = null,
    burst_buffer: ?CStr = null,
    comment: ?CStr = null,
    core_cnt: u32 = 0,
    core_spec_cnt: u32 = 0,
    core_spec: ?[*]Reservation.CoreSpec = null,
    end_time: time_t = 0,
    features: ?CStr = null,
    flags: Reservation.Flags = .{},
    groups: ?CStr = null,
    licenses: ?CStr = null,
    max_start_delay: u32 = 0,
    name: ?CStr = null,
    node_cnt: u32 = 0,
    node_inx: ?[*]i32 = null,
    node_list: ?CStr = null,
    partition: ?CStr = null,
    purge_comp_time: u32 = 0,
    qos: ?CStr = null,
    start_time: time_t = 0,
    tres_str: ?CStr = null,
    users: ?CStr = null,

    pub const CoreSpec = extern struct {
        node_name: ?CStr = null,
        core_id: ?CStr = null,
    };

    pub const LoadResponse = extern struct {
        last_update: time_t,
        count: u32 = 0,
        items: ?[*]Reservation = null,

        pub fn deinit(self: *LoadResponse) void {
            c.slurm_free_reservation_info_msg(self);
        }

        pub const Iterator = common.LoadResponseIterator(Reservation);

        const methods = common.LoadResponseMethods(Reservation);
        pub const iter = methods.iter;
        pub const get = methods.get;
        pub const toSlice = methods.toSlice;

        pub fn find(self: *LoadResponse, name: [:0]const u8) ?*Reservation {
            var itr = self.iter();
            while (itr.next()) |resv| {
                const r_name = slurm.parseCStr(resv.name) orelse continue;
                if (!std.mem.eql(u8, name, r_name)) continue;
                return resv;
            }
            return null;
        }
    };

    pub const Updatable = extern struct {
        accounts: ?CStr = null,
        allowed_parts: ?CStr = null,
        burst_buffer: ?CStr = null,
        comment: ?CStr = null,
        core_cnt: u32 = NoValue.u32,
        duration: u32 = NoValue.u32,
        end_time: time_t = NoValue.u32,
        features: ?CStr = null,
        flags: Reservation.Flags = .no_value,
        groups: ?CStr = null,
        job_ptr: ?*anyopaque = null,
        licenses: ?CStr = null,
        max_start_delay: u32 = NoValue.u32,
        name: ?CStr = null,
        node_cnt: u32 = NoValue.u32,
        node_list: ?CStr = null,
        partition: ?CStr = null,
        purge_comp_time: u32 = NoValue.u32,
        qos: ?CStr = null,
        start_time: time_t = NoValue.u32,
        time_force: time_t = 0,
        tres_str: ?CStr = null,
        users: ?CStr = null,

        pub fn create(self: Reservation.Updatable) !void {
            try slurm.reservation.create(self);
        }
    };

    pub const DeleteFilter = extern struct {
        name: ?CStr = null,
    };

    pub const Flags = slurm.ReservationFlags;

    pub fn update(self: *Reservation, changes: Updatable) !void {
        if (self.name) |name| {
            var msg = changes;
            msg.name = std.mem.span(name);
            try slurm.reservation.update(msg);
        }
    }

    pub fn delete(self: *Reservation) !void {
        if (self.name) |name| {
            const n = std.mem.span(name);
            try slurm.reservation.deleteByName(n);
        } else return error.ReservationInvalid;
    }
};

pub fn load() Error!*Reservation.LoadResponse {
    var resp: ?*Reservation.LoadResponse = null;
    try err.checkRpc(c.slurm_load_reservations(0, &resp));
    return if (resp) |r|
        r
    else
        error.Generic;
}

pub fn update(update_msg: Reservation.Updatable) !void {
    try err.checkRpc(c.slurm_update_reservation(@constCast(&update_msg)));
}

pub fn deleteByName(name: [:0]const u8) !void {
    const filter: Reservation.DeleteFilter = .{ .name = name };
    try slurm.reservation.delete(filter);
}

pub fn delete(filter: Reservation.DeleteFilter) !void {
    try err.checkRpc(c.slurm_delete_reservation(@constCast(&filter)));
}

pub fn create(resv: Reservation.Updatable) !void {
    if (c.slurm_create_reservation(@constCast(&resv))) |name| {
        std.heap.raw_c_allocator.free(std.mem.span(name));
    } else return err.getError();
}
