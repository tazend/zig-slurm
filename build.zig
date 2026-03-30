const std = @import("std");
const Compile = std.Build.Step.Compile;

pub fn setupSlurmPath(b: *std.Build, target: *Compile) void {
    for (b.search_prefixes.items) |o| {
        target.addLibraryPath(.{ .cwd_relative = o });
    }
}

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const use_slurmfull = b.option(bool, "use-slurmfull", "Whether to use libslurmfull.so or not.") orelse false;

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
