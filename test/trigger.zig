const std = @import("std");
const testing = std.testing;
const slurm = @import("slurm");

test "loadAll" {
    var resp = try slurm.trigger.load();
    defer resp.deinit();

    var iter = resp.iter();
    while (iter.next()) |item| {
        try testing.expect(item.program != null);
        try testing.expect(item.trig_id > 0);
    }
}
