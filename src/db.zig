const std = @import("std");
const common = @import("common.zig");
const time_t = std.os.linux.time_t;
const CStr = common.CStr;

pub const association = @import("db/association.zig");
pub const user = @import("db/user.zig");
pub const account = @import("db/account.zig");
pub const list = @import("db/list.zig");

pub const List = list.List;
pub const createCStrList = @import("db/list.zig").createCStrList;
pub const Job = @import("db/job.zig").Job;
pub const Connection = @import("db/connection.zig").Connection;
pub const Step = @import("db/step.zig").Step;
pub const Transaction = @import("db/transaction.zig").Transaction;
pub const WCKey = @import("db/wckey.zig").WCKey;
pub const Account = account.Account;
pub const User = user.User;
pub const TrackableResource = @import("db/tres.zig").TrackableResource;
pub const Cluster = @import("db/cluster.zig").Cluster;
pub const Association = association.Association;
pub const Archive = @import("db/archive.zig").Archive;
pub const Reservation = @import("db/reservation.zig").Reservation;
pub const QoS = @import("db/qos.zig").QoS;
pub const Event = @import("db/event.zig").Event;

pub extern var working_cluster_rec: *Cluster;
pub extern var assoc_mgr_tres_list: ?*List(*TrackableResource);

pub const BFUsage = extern struct {
    count: u64 = 0,
    last_sched: time_t = 0,
};

pub const AdminLevel = enum(u16) {
    not_set,
    none,
    operator,
    administrator,
};
