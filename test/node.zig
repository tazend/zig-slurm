const std = @import("std");
const testing = std.testing;
const slurm = @import("slurm");

test "load all" {
    var node_resp = try slurm.node.load();
    defer node_resp.deinit();

    try testing.expect(node_resp.count > 0);

    var iter = node_resp.iter();
    while (iter.next()) |node| {
        const name = slurm.parseCStr(node.name);
        try testing.expect(name != null);
    }
}

test "update and load" {
    {
        const updates: slurm.Node.Updatable = .{
            .extra = "my extras",
            .node_names = "node001"
        };
        try slurm.node.update(updates);

        const node = try slurm.node.loadOne("node001");

        const name = slurm.parseCStr(node.name);
        try testing.expectEqualStrings(name.?, "node001");

        const extra = slurm.parseCStr(node.extra);
        try testing.expectEqualStrings(extra.?, "my extras");
    }
    {
        var node = try slurm.node.loadOne("node001");
        var updates: slurm.Node.Updatable = .{
            .extra = "my extras 2",
        };
        try node.update(&updates);

        node = try slurm.node.loadOne("node001");

        const name = slurm.parseCStr(node.name);
        try testing.expectEqualStrings(name.?, "node001");

        const extra = slurm.parseCStr(node.extra);
        try testing.expectEqualStrings(extra.?, "my extras 2");
    }
}
