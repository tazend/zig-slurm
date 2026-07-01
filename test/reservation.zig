const std = @import("std");
const testing = std.testing;
const slurm = @import("slurm");

test "create, load, update and delete" {
    {
        // Create
        const resv: slurm.Reservation.Updatable = .{
            .name = "testresv",
            .duration = slurm.common.Infinite.u32,
            .start_time = std.time.timestamp(),
            .users = "root",
            .node_list = "ALL",
            .flags = .{
                .ignore_running_jobs = true,
            },
        };
        try resv.create();
    }
    {
        // Load
        var resp = try slurm.reservation.load();
        defer resp.deinit();
        const resv = resp.find("testresv") orelse return error.ReservationInvalid;

        const users = slurm.parseCStr(resv.users).?;
        try testing.expectEqualStrings("root", users);
        try testing.expect(resv.node_cnt > 1 and resv.node_cnt != slurm.common.NoValue.u32);
    }
    {
        // Update
        const changes: slurm.Reservation.Updatable = .{
            .users = "root,slurm",
            .name = "testresv"
        };
        try slurm.reservation.update(changes);

        var resp = try slurm.reservation.load();
        defer resp.deinit();
        const resv = resp.find("testresv") orelse return error.ReservationInvalid;

        const users = slurm.parseCStr(resv.users).?;
        try testing.expectEqualStrings("root,slurm", users);
    }
    {
        // Delete
        const filter: slurm.Reservation.DeleteFilter = .{ .name = "testresv" };
        try slurm.reservation.delete(filter);
        try testing.expectError(error.ReservationInvalid, slurm.reservation.delete(filter));
    }
}
