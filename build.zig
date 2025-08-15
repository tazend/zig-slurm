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

    const slurm = b.addModule("slurm", .{
        .root_source_file = b.path("src/root.zig"),
    });

    const slurm_lib = b.addStaticLibrary(.{
        .name = "slurm",
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    setupSlurmPath(b, slurm_lib);

    const slurm_lib_name = if (use_slurmfull) "slurmfull" else "slurm";
    slurm_lib.linkSystemLibrary(slurm_lib_name);
    b.installArtifact(slurm_lib);

    const test_step = b.step("test", "Run slurm tests");
    const tests = b.addTest(.{
        .name = "slurm-tests",
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    setupSlurmPath(b, tests);
    tests.linkLibrary(slurm_lib);
    tests.root_module.addImport("slurm", slurm);
    b.installArtifact(tests);
    test_step.dependOn(&b.addRunArtifact(tests).step);
}
