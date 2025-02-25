const c = @import("c.zig").c;
const std = @import("std");
const SlurmError = @import("error.zig").Error;

// TODO: Make Specific Errors
pub const DatabaseConnection = struct {
    handle: *anyopaque,
    flags: u16 = 0,

    pub fn open() SlurmError!DatabaseConnection {
        var flags: u16 = 0;
        const handle = c.slurmdb_connection_get(&flags);
        if (handle) |h| {
            return .{
                .handle = h,
                .flags = flags,
            };
        }

        return error.Generic;
    }

    pub fn close(self: DatabaseConnection) void {
        _ = c.slurmdb_connection_close(@constCast(@ptrCast(&self.handle)));
    }

    pub fn commit(self: DatabaseConnection) !void {
        const rc = c.slurmdb_connection_commit(
            @constCast(self.handle),
            true,
        );
        if (rc == c.SLURM_ERROR) {
            return error.Generic;
        }
    }

    pub fn rollback(self: DatabaseConnection) !void {
        const rc = c.slurmdb_connection_commit(
            @constCast(self.handle),
            false,
        );
        if (rc == c.SLURM_ERROR) {
            return error.Generic;
        }
    }
};
