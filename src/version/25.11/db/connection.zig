const checkRpc = @import("../error.zig").checkRpc;

pub const Connection = opaque {
    pub const OpenError = error{ConnectionFailed};

    extern fn slurmdb_connection_get(persist_conn_flags: *u16) ?*Connection;
    pub fn open() OpenError!*Connection {
        var flags: u16 = 0;
        return try openGetFlags(&flags);
    }

    pub fn openGetFlags(flags: *u16) OpenError!*Connection {
        const handle = slurmdb_connection_get(@constCast(flags));
        if (handle) |h| {
            return h;
        }
        return error.ConnectionFailed;
    }

    extern fn slurmdb_connection_close(db_conn: **Connection) c_int;
    pub fn close(self: *Connection) void {
        _ = slurmdb_connection_close(@constCast(&self));
    }

    extern fn slurmdb_connection_commit(db_conn: *Connection, commit: bool) c_int;
    pub fn commit(self: *Connection) !void {
        const rc = slurmdb_connection_commit(@constCast(self), true);
        try checkRpc(rc);
    }

    pub fn rollback(self: *Connection) !void {
        const rc = slurmdb_connection_commit(@constCast(self), false);
        try checkRpc(rc);
    }
};
