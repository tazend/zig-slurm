const std = @import("std");
const Compile = std.Build.Step.Compile;

pub fn setupSlurmPath(b: *std.Build, target: *Compile) void {
    for (b.search_prefixes.items) |o| {
        target.root_module.addLibraryPath(.{ .cwd_relative = o });
        target.root_module.addIncludePath(.{ .cwd_relative = o });
    }

    // Some common default include and library dirs for slurm
    target.root_module.addIncludePath(.{ .cwd_relative = "/usr/include/slurm" });
    target.root_module.addLibraryPath(.{ .cwd_relative = "/lib64" });
    target.root_module.addLibraryPath(.{ .cwd_relative = "/lib64/slurm" });
}

pub fn readSlurmVersionFile(b: *std.Build, target: *Compile) !std.SemanticVersion {
    for (target.root_module.include_dirs.items) |i| {
        const slurm_version_h = try i.path.join(b.allocator, "slurm_version.h");
        var file = std.fs.openFileAbsolute(slurm_version_h.cwd_relative, .{ .mode = .read_only }) catch |err| switch(err) {
           error.FileNotFound => continue,
           else => return err,
        };

        var read_buf: [4096]u8 = undefined;
        var reader = file.reader(&read_buf);

        var line: std.Io.Writer.Allocating = .init(b.allocator);
        defer line.deinit();

        while (true) {
            _ = reader.interface.streamDelimiter(&line.writer, '\n') catch |err| switch (err) {
                error.EndOfStream => break,
                else => return err,
            };
            _ = reader.interface.toss(1);

            const written = line.written();
            const needle = "#define SLURM_VERSION_NUMBER ";
            if (std.mem.startsWith(u8, written, needle)) {
                const ver_str = std.mem.trimStart(u8, written, needle);
                const ver = try std.fmt.parseInt(usize, ver_str, 0);

                return .{
                    .major = (ver >> 16) & 0xff,
                    .minor = (ver >> 8) & 0xff,
                    .patch = ver & 0xff,
                };
            }
            line.clearRetainingCapacity();
        }
    }

    return .{
        .major = 0,
        .minor = 0,
        .patch = 0,
    };
}

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const use_slurmfull = b.option(bool, "use-slurmfull", "Whether to use libslurmfull.so or not.") orelse false;
    const version: ?[]const u8 = b.option([]const u8, "version", "Which version of slurm to target") orelse null;

    const config = b.addOptions();

    const slurm_mod = b.addModule("slurm", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const slurm_lib = b.addLibrary(.{
        .name = "slurm",
        .root_module = slurm_mod,
        .linkage = .static,
    });

    setupSlurmPath(b, slurm_lib);

    const semver: std.SemanticVersion = if (version) |v|
        try .parse(v)
    else
        try readSlurmVersionFile(b, slurm_lib);

    // This does not work with an optional. It forgets to bring in std. Bug?
    config.addOption(std.SemanticVersion, "slurm_version", semver);
    slurm_mod.addOptions("config", config);

    const slurm_lib_name = if (use_slurmfull) "slurmfull" else "slurm";
    slurm_lib.linkSystemLibrary(slurm_lib_name);
    b.installArtifact(slurm_lib);

    const tests = b.addTest(.{
        .root_module = slurm_mod,
    });

    //   setupSlurmPath(b, tests);
    //    tests.linkLibrary(slurm_lib);
    //    tests.root_module.addImport("slurm", slurm_mod);
    const run_unit_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run slurm tests");
    b.installArtifact(tests);
    test_step.dependOn(&run_unit_tests.step);

    const integration_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("test/root.zig"),
            .optimize = optimize,
            .target = target,
            .link_libc = true,
        }),
        .name = "test-integration",
    });

    integration_tests.root_module.addImport("slurm", slurm_mod);
    const run_integration_tests = b.addRunArtifact(integration_tests);
    const integration_test_step = b.step("test-integration", "Run integration tests");
    b.installArtifact(integration_tests);
    integration_test_step.dependOn(&run_integration_tests.step);
}
