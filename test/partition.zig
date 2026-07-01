const std = @import("std");
const testing = std.testing;
const slurm = @import("slurm");

test "load all" {
    var resp = try slurm.partition.load();
    defer resp.deinit();

    try testing.expect(resp.count > 0);

    var iter = resp.iter();
    while (iter.next()) |part| {
        const name = slurm.parseCStr(part.name);
        try testing.expect(name != null);
    }
}

test "create and delete" {
    const part: slurm.Partition = .{
        .state = .up,
        .allow_groups = "root",
        .name = "testpart",
    };
    try part.create();
    try testing.expectError(error.InvalidPartitionName, part.create());

    var resp = try slurm.partition.load();
    const testpart = resp.find("testpart") orelse return error.InvalidPartition;

    try testpart.delete();
    try testing.expectError(error.InvalidPartitionName, testpart.delete());
}

test "update and load" {
    {
        const updates: slurm.Partition.Updatable = .{
            .state = .down,
            .allow_groups = "root",
            .name = "normal",
        };
        try slurm.partition.update(updates);

        var resp = try slurm.partition.load();
        const part = resp.find("normal") orelse return error.InvalidPartition;

        const deny_accounts = slurm.parseCStr(part.deny_accounts);
        try testing.expectEqualStrings(deny_accounts.?, "root");
        try testing.expect(part.state == .down);
    }
    {
        var resp = try slurm.partition.load();
        const part = resp.find("normal") orelse return error.InvalidPartition;

        const updates: slurm.Partition.Updatable = .{
            .allow_accounts = "slurm",
            .state = .up,
        };
        try part.update(updates);
    }
    {
        var resp = try slurm.partition.load();
        const part = resp.find("normal") orelse return error.InvalidPartition;

        const allow_accounts = slurm.parseCStr(part.allow_accounts);
        try testing.expectEqualStrings(allow_accounts.?, "slurm");
        try testing.expect(part.state == .up);
    }
}
