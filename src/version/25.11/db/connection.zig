const checkRpc = @import("../error.zig").checkRpc;
const slurm = @import("../root.zig");
const c = slurm.c;

pub const Connection = opaque {
    pub const OpenError = error{ConnectionFailed};

    pub fn open() OpenError!*Connection {
        var flags: u16 = 0;
        return try openGetFlags(&flags);
    }

    pub fn openGetFlags(flags: *u16) OpenError!*Connection {
        const handle = c.slurmdb_connection_get(flags);
        if (handle) |h| {
            return h;
        }
        return error.ConnectionFailed;
    }

    pub fn close(self: *Connection) void {
        _ = c.slurmdb_connection_close(@constCast(&self));
    }

    pub fn commit(self: *Connection) !void {
        const rc = c.slurmdb_connection_commit(self, true);
        try checkRpc(rc);
    }

    pub fn rollback(self: *Connection) !void {
        const rc = c.slurmdb_connection_commit(self, false);
        try checkRpc(rc);
    }
};
