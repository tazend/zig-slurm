const std = @import("std");
const testing = std.testing;
const slurm = @import("slurm");

test "loadAll" {
    var resp = try slurm.license.load();
    defer resp.deinit();

    var iter = resp.iter();
    while (iter.next()) |item| {
        try testing.expect(item.total > 0);
        try testing.expect(item.name != null);
    }
}
