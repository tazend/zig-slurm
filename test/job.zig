const std = @import("std");
const testing = std.testing;
const slurm = @import("slurm");

test "load all" {
    var resp = try slurm.job.load();
    defer resp.deinit();

    var iter = resp.iter();
    while (iter.next()) |item| {
        const name = slurm.parseCStr(item.name);
        try testing.expect(name != null);
    }
}

test "submit simple" {
    var desc: slurm.Job.SubmitDescription = try .initDefault(testing.allocator);

    desc.name = "test-job";
    desc.script =
    \\#!/bin/bash
    \\/bin/env
    \\sleep 1000
    \\
    ;

    defer testing.allocator.free(std.mem.span(desc.work_dir.?));
    const id = try desc.submit();
    try testing.expect(id > 0);
}
