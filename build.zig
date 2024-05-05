const std = @import("std");
const LazyPath = std.Build.LazyPath;
const path = std.fs.path;
const Compile = std.Build.Step.Compile;
const Allocator = std.mem.Allocator;

pub fn setupSlurmPath(target: *Compile, slurm_dir: ?[]const u8, allocator: Allocator) !void {
    const dir: ?[]const u8 = if (slurm_dir) |d| d else std.posix.getenv("SLURM_INSTALL_DIR");

    if (dir) |d| {
        const incpath = try path.join(allocator, &[_][]const u8{ d, "include" });
        const libpath = try path.join(allocator, &[_][]const u8{ d, "lib" });
        target.addIncludePath(.{ .path = incpath });
        target.addLibraryPath(.{ .path = libpath });
    }
}

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const slurm_dir = b.option([]const u8, "slurm-dir", "Slurm installation directory");

    const slurm = b.addModule("slurm", .{
        .root_source_file = .{ .path = "src/root.zig" },
    });

    const slurm_lib = b.addStaticLibrary(.{
        .name = "slurm",
        .root_source_file = .{ .path = "src/root.zig" },
        .target = target,
        .optimize = optimize,
    });

    try setupSlurmPath(slurm_lib, slurm_dir, allocator);

    slurm_lib.linkLibC();
    slurm_lib.linkSystemLibrary("slurm");
    b.installArtifact(slurm_lib);

    const test_step = b.step("test", "Run slurm tests");
    const tests = b.addTest(.{
        .name = "slurm-tests",
        .root_source_file = .{ .path = "src/root.zig" },
        .target = target,
        .optimize = optimize,
    });

    try setupSlurmPath(tests, slurm_dir, allocator);

    tests.linkLibrary(slurm_lib);
    tests.root_module.addImport("slurm", slurm);
    b.installArtifact(tests);
    test_step.dependOn(&b.addRunArtifact(tests).step);
}
