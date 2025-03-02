const std = @import("std");
const Compile = std.Build.Step.Compile;

pub fn setupSlurmPath(b: *std.Build, target: *Compile, slurm_dir: ?[]const u8) !void {
    const dir: ?[]const u8 = if (slurm_dir) |d| d else std.posix.getenv("SLURM_INSTALL_DIR");

    if (dir) |d| {
        target.addIncludePath(.{ .cwd_relative = (b.fmt("{s}/include", .{d})) });
        target.addLibraryPath(.{ .cwd_relative = (b.fmt("{s}/lib64", .{d})) });
    }
}

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const slurm_dir = b.option([]const u8, "slurm-dir", "Slurm installation directory");

    const slurm = b.addModule("slurm", .{
        .root_source_file = b.path("src/root.zig"),
    });

    const slurm_lib = b.addStaticLibrary(.{
        .name = "slurm",
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    try setupSlurmPath(b, slurm_lib, slurm_dir);

    slurm_lib.linkLibC();
    slurm_lib.linkSystemLibrary("slurm");
    b.installArtifact(slurm_lib);

    const test_step = b.step("test", "Run slurm tests");
    const tests = b.addTest(.{
        .name = "slurm-tests",
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    try setupSlurmPath(b, tests, slurm_dir);

    tests.linkLibrary(slurm_lib);
    tests.root_module.addImport("slurm", slurm);
    b.installArtifact(tests);
    test_step.dependOn(&b.addRunArtifact(tests).step);
}
