const std = @import("std");
const testing = std.testing;
const slurm = @import("slurm");

fn submit() !u32 {
    var desc: slurm.Job.SubmitDescription = try .initDefault(testing.allocator);

    desc.name = "test-job";
    desc.std_out = "/dev/null";
    desc.script =
    \\#!/bin/bash
    \\/bin/env
    \\sleep 1000
    \\
    ;

    defer testing.allocator.free(std.mem.span(desc.work_dir.?));
    return try desc.submit();
}

fn waitForState(id: u32, state: slurm.Job.State) !void {
    const max_tries = 100;
    var tries: u16 = 0;

    while (true) {
        var job = try slurm.job.loadOne(id);
        defer job.deinit();

        if (job.state == state) return;

        std.Thread.sleep(250 * std.time.ns_per_ms);
        tries += 1;

        if (tries >= max_tries) {
            std.log.err("Job {d} did not reach expected state in time\n", .{id});
            try testing.expectEqualDeep(state, job.state);
        }
    }
}

test "load all" {
    var resp = try slurm.job.load();
    defer resp.deinit();

    var iter = resp.iter();
    while (iter.next()) |item| {
        const name = slurm.parseCStr(item.name);
        try testing.expect(name != null);
    }

    const job_slice = resp.toSlice();
    for (job_slice) |*job| {
        const name = slurm.parseCStr(job.name);
        try testing.expect(name != null);
    }
}

test "submit simple" {
    const id = try submit();
    defer slurm.job.cancel(id) catch {};
    try testing.expect(id > 0);
}

test "suspend/unsuspend" {
    const id = try submit();
    defer slurm.job.cancel(id) catch {};
    try testing.expect(id > 0);
    const job = try slurm.job.loadOne(id);

    {
        try waitForState(id, .{ .base = .running });
        try job.@"suspend"();
    }
    {
        try waitForState(id, .{ .base = .suspended });
        try job.unsuspend();
    }
    {
        try waitForState(id, .{ .base = .running });
    }
}

//  test "sendSignal/cancel" {
//      const id = try submit();
//      try testing.expect(id > 0);
//      const job = try slurm.job.loadOne(id);

//      {
//          try waitForState(id, .{ .base = .running, .flags = .{ .stopped = false } });
//          // SIGSTOP is somehow not honored. It is properly
//          // logged in the slurmctld, but the Job will not enter a stopped state.
//          try job.sendSignal(std.c.SIG.STOP, .{});
//      }
//      {
//          try waitForState(id, .{ .base = .running, .flags = .{ .stopped = true } });
//          try job.sendSignal(std.c.SIG.CONT, .{});
//      }
//      {
//          try waitForState(id, .{ .base = .running, .flags = .{ .stopped = false } });
//      }
//  }

test "requeue/requeueHold" {
    {
        const id = try submit();
        var job = try slurm.job.loadOne(id);
        defer job.cancel() catch {};
        try testing.expect(id > 0);
        try testing.expectEqual(0, job.restart_cnt);

        try waitForState(id, .{ .base = .running });
        try job.requeuex();

        try waitForState(id, .{ .base = .pending });
        job = try slurm.job.loadOne(id);
        try testing.expectEqual(1, job.restart_cnt);
    }
    {
        const id = try submit();
        var job = try slurm.job.loadOne(id);
        defer job.cancel() catch {};
        try testing.expect(id > 0);
        try testing.expectEqual(0, job.restart_cnt);

        try waitForState(id, .{ .base = .running });
        try job.requeueHold();

        job = try slurm.job.loadOne(id);
        try waitForState(id, .{ .base = .pending });
        try testing.expectEqual(1, job.restart_cnt);
        try testing.expect(job.state_reason == .wait_held_user);
        try testing.expectEqual(0, job.priority);
    }
}

test "getBatchScript" {
    const id = try submit();
    const job = try slurm.job.loadOne(id);
    defer job.cancel() catch {};
    try testing.expect(id > 0);

    const script = try job.batchScript(testing.allocator);
    defer testing.allocator.free(script);
    const expected =
    \\#!/bin/bash
    \\/bin/env
    \\sleep 1000
    \\
    ;
    try testing.expectEqualStrings(expected, script);
}

test "hold/release" {
    var desc: slurm.Job.SubmitDescription = try .initDefault(testing.allocator);

    desc.name = "test-job";
    desc.priority = 0;
    desc.std_out = "/dev/null";
    desc.script =
    \\#!/bin/bash
    \\/bin/env
    \\sleep 1000
    \\
    ;

    defer testing.allocator.free(std.mem.span(desc.work_dir.?));
    const id = try desc.submit();
    try testing.expect(id > 0);
    defer slurm.job.cancel(id) catch {};

    {
        // We submitted it with priority = 0, so it will be, by default,
        // JobHeldUser
        const job = try slurm.job.loadOne(id);
        try testing.expect(job.state_reason == .wait_held_user);
        try testing.expect(job.priority == 0);
        try job.release();
    }
    {
        const job = try slurm.job.loadOne(id);
        try testing.expect(job.state_reason == .wait_no_reason);
        try testing.expect(job.priority > 0);
        try job.hold(.admin);
    }
    {
        // This one should be held by admin.
        const job = try slurm.job.loadOne(id);
        try testing.expect(job.state_reason == .wait_held);
        try testing.expect(job.priority == 0);
    }
}
