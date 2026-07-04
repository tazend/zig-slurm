const std = @import("std");
const common = @import("common.zig");
const time_t = std.os.linux.time_t;
const CStr = common.CStr;

pub const association = @import("db/association.zig");
pub const job = @import("db/job.zig");
pub const step = @import("db/step.zig");
pub const user = @import("db/user.zig");
pub const wckey = @import("db/wckey.zig");
pub const account = @import("db/account.zig");
pub const list = @import("db/list.zig");
pub const tres = @import("db/tres.zig");
pub const coordinator = @import("db/coordinator.zig");
pub const transaction = @import("db/transaction.zig");
pub const cluster = @import("db/cluster.zig");
pub const archive = @import("db/archive.zig");
pub const qos = @import("db/qos.zig");
pub const reservation = @import("db/reservation.zig");
pub const event = @import("db/event.zig");

pub const List = list.List;
pub const createCStrList = @import("db/list.zig").createCStrList;
pub const Job = job.Job;
pub const Connection = @import("db/connection.zig").Connection;
pub const Step = step.Step;
pub const Transaction = transaction.Transaction;
pub const WCKey = wckey.WCKey;
pub const Account = account.Account;
pub const User = user.User;
pub const TrackableResource = tres.TrackableResource;
pub const Cluster = cluster.Cluster;
pub const Association = association.Association;
pub const Archive = archive.Archive;
pub const Reservation = reservation.Reservation;
pub const QoS = qos.QoS;
pub const Event = event.Event;
pub const Coordinator = coordinator.Coordinator;

pub extern var working_cluster_rec: ?*Cluster;
pub extern var assoc_mgr_tres_list: ?*List(*TrackableResource);

pub const BackfillUsage = extern struct {
    count: u64 = 0,
    last_sched: time_t = 0,
};

pub const AdminLevel = enum(u16) {
    not_set,
    none,
    operator,
    administrator,
};
