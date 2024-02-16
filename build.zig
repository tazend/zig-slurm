const std = @import("std");
const LazyPath = std.Build.LazyPath;
const path = std.fs.path;

pub const Options = struct {
    slurm_dir: ?[]const u8 = null,
};

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const defaults = Options{};
    const options = Options{
        .slurm_dir = b.option([]const u8, "slurm-dir", "Slurm installation directory") orelse defaults.slurm_dir,
    };

    const slurm = b.addModule("slurm", .{
        .root_source_file = .{ .path = "src/root.zig" },
    });

    const slurm_lib = b.addStaticLibrary(.{
        .name = "slurm",
        .root_source_file = .{ .path = "src/root.zig" },
        .target = target,
        .optimize = optimize,
    });

    if (options.slurm_dir) |dir| {
        slurm_lib.addIncludePath(.{ .path = try path.join(arena.allocator(), &[_][]const u8{ dir, "include" }) });
        slurm_lib.addLibraryPath(.{ .path = try path.join(arena.allocator(), &[_][]const u8{ dir, "lib" }) });
    }
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
    if (options.slurm_dir) |dir| {
        tests.addIncludePath(.{ .path = try path.join(arena.allocator(), &[_][]const u8{ dir, "include" }) });
        tests.addLibraryPath(.{ .path = try path.join(arena.allocator(), &[_][]const u8{ dir, "lib" }) });
    }

    tests.linkLibrary(slurm_lib);
    tests.root_module.addImport("slurm", slurm);
    b.installArtifact(tests);
    test_step.dependOn(&b.addRunArtifact(tests).step);
}
